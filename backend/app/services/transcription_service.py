import os
import logging
from app.config import settings

logger = logging.getLogger(__name__)

# Cache for local Whisper model
_whisper_model = None

def get_whisper_model():
    global _whisper_model
    if _whisper_model is None:
        try:
            import whisper
            model_name = settings.WHISPER_MODEL
            logger.info(f"Loading local OpenAI Whisper model: {model_name}")
            _whisper_model = whisper.load_model(model_name)
        except Exception as e:
            logger.warning(f"Could not load local Whisper model: {e}. Will rely on Gemini multimodal fallback.")
            return None
    return _whisper_model

def transcribe_audio_file(audio_path: str) -> str:
    """
    Transcribes audio track using local OpenAI Whisper.
    Returns plain text transcript.
    """
    model = get_whisper_model()
    if model is not None:
        try:
            logger.info(f"Transcribing audio with Whisper: {audio_path}")
            result = model.transcribe(audio_path)
            transcript = result.get("text", "").strip()
            if transcript:
                return transcript
        except Exception as e:
            logger.warning(f"Local Whisper transcription failed: {e}")

    # Fallback: Read audio bytes and let Gemini Flash handle audio transcription directly
    return ""
