import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import recipe_router, receipt_router, stock_router
from app.config import settings

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("cook_ed_backend")

app = FastAPI(
    title="Cook-Ed Backend & AI Pipeline",
    description="Backend services for Cook-Ed: Video Ingestion, Whisper Transcription, Gemini Flash OCR & NLP, and Portion Scaling.",
    version="1.0.0"
)

# Enable CORS for Flutter app (Android emulator 10.0.2.2, localhost, physical devices)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(recipe_router.router)
app.include_router(receipt_router.router)
app.include_router(stock_router.router)

@app.get("/")
async def root():
    return {
        "app": "Cook-Ed Backend API",
        "version": "1.0.0",
        "status": "online",
        "modules": [
            "Account & Pantry Management (Receipt OCR)",
            "Video Recipe Ingestion (yt-dlp + Whisper + Gemini Flash)",
            "Portion Scaling & Stock Checking",
            "Meal Confirmation & Stock Deduction"
        ],
        "docs_url": "/docs"
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "gemini_configured": bool(settings.GEMINI_API_KEY),
        "whisper_model": settings.WHISPER_MODEL
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host=settings.HOST, port=settings.PORT, reload=True)
