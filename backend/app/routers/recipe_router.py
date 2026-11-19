import os
import logging
from fastapi import APIRouter, HTTPException, BackgroundTasks
from app.models.schemas import VideoIngestRequest, RecipeResponse, StockCheckRequest, StockCheckResponse
from app.services.video_service import download_audio_from_video, detect_platform
from app.services.transcription_service import transcribe_audio_file
from app.services.gemini_service import structure_recipe_from_transcript
from app.services.stock_service import check_stock_and_scale

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/recipe", tags=["Recipe Ingestion & Scaling"])

def cleanup_file(path: str):
    try:
        if path and os.path.exists(path):
            os.remove(path)
    except Exception as e:
        logger.warning(f"Failed to cleanup temp file {path}: {e}")

@router.post("/ingest-video", response_model=RecipeResponse)
async def ingest_video(request: VideoIngestRequest, background_tasks: BackgroundTasks):
    """
    Video Recipe Ingestion Module:
    1. Extracts audio from TikTok, Instagram Reels, or YouTube Shorts link using yt-dlp.
    2. Transcribes speech using OpenAI Whisper (or Gemini audio fallback).
    3. Formats dialog into a structured ingredient checklist and step-by-step instructions via Gemini Flash.
    """
    url = request.url.strip()
    if not url.startswith("http://") and not url.startswith("https://"):
        raise HTTPException(status_code=400, detail="Invalid video URL provided.")

    platform = detect_platform(url)
    logger.info(f"Ingesting video from platform {platform}: {url}")

    audio_path = None
    try:
        # Step 1: Download Audio Track
        audio_path, video_title = download_audio_from_video(url)
        background_tasks.add_task(cleanup_file, audio_path)

        # Step 2: Speech-to-Text Transcription via Whisper
        transcript = transcribe_audio_file(audio_path)
        logger.info(f"Transcription length: {len(transcript)} chars")

        # Step 3: Parse and Structure Recipe using Gemini Flash
        recipe = structure_recipe_from_transcript(
            transcript=transcript,
            video_title=video_title,
            audio_path=audio_path
        )
        recipe.video_url = url
        recipe.source_platform = platform

        return recipe

    except Exception as e:
        logger.error(f"Error in video ingestion: {str(e)}", exc_info=True)
        if audio_path and os.path.exists(audio_path):
            cleanup_file(audio_path)
        raise HTTPException(status_code=500, detail=f"Video ingestion failed: {str(e)}")

@router.post("/scale-check", response_model=StockCheckResponse)
async def scale_and_check_stock(request: StockCheckRequest):
    """
    Portion Scaling & Stock Checking Module:
    Dynamically recalculates ingredient proportions based on target servings (pax)
    and cross-references them against active pantry records, tagging each with
    visual status badges: adequate (\u2713), insufficient (!), or missing (\u00d7).
    """
    try:
        result = check_stock_and_scale(
            recipe_servings=request.recipe_servings,
            target_servings=request.target_servings,
            ingredients=request.ingredients,
            pantry_items=request.pantry_items
        )
        return result
    except Exception as e:
        logger.error(f"Error in portion scale check: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Stock check failed: {str(e)}")
