import logging
from fastapi import APIRouter, File, UploadFile, HTTPException
from app.models.schemas import ReceiptScanResponse
from app.services.gemini_service import parse_receipt_image

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/receipt", tags=["Receipt OCR & NLP"])

@router.post("/scan", response_model=ReceiptScanResponse)
async def scan_receipt(file: UploadFile = File(...)):
    """
    Account & Pantry Management Module:
    Extracts purchased grocery items and counts directly from a physical store receipt photo
    using Gemini Flash multimodal OCR & NLP.
    """
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Uploaded file must be an image (JPEG, PNG, WEBP).")

    try:
        image_bytes = await file.read()
        logger.info(f"Processing receipt image of size: {len(image_bytes)} bytes, content_type: {file.content_type}")

        parsed_data = parse_receipt_image(image_bytes=image_bytes, mime_type=file.content_type)
        return parsed_data

    except Exception as e:
        logger.error(f"Receipt scanning failed: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to parse receipt: {str(e)}")
