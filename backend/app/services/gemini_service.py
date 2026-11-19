import os
import json
import logging
from typing import Dict, Any, Optional
from google import genai
from google.genai import types
from app.config import settings
from app.models.schemas import RecipeResponse, IngredientItem, InstructionStep, ReceiptScanResponse, ReceiptItem

logger = logging.getLogger(__name__)

def get_gemini_client():
    api_key = settings.GEMINI_API_KEY
    if not api_key:
        api_key = os.getenv("GEMINI_API_KEY", "")
    if not api_key:
        raise ValueError("GEMINI_API_KEY is not configured in .env or environment variables.")
    return genai.Client(api_key=api_key)

def _call_gemini_json_with_fallback(client, contents, temperature: float = 0.2):
    preferred_model = settings.GEMINI_MODEL or "gemini-3.8-flash"
    models_to_try = [preferred_model]
    for fallback in ["gemini-3.8-flash", "gemini-2.5-flash", "gemini-2.0-flash"]:
        if fallback not in models_to_try:
            models_to_try.append(fallback)

    last_error = None
    for model_name in models_to_try:
        try:
            logger.info(f"Invoking Gemini model: {model_name}")
            return client.models.generate_content(
                model=model_name,
                contents=contents,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    temperature=temperature,
                )
            )
        except Exception as e:
            logger.warning(f"Gemini call with '{model_name}' failed ({e}). Attempting next model...")
            last_error = e

    raise RuntimeError(f"All Gemini model attempts failed: {last_error}")

def structure_recipe_from_transcript(transcript: str, video_title: Optional[str] = None, audio_path: Optional[str] = None) -> RecipeResponse:
    """
    Uses Gemini Flash to parse dialogue transcript (or audio) into a structured recipe
    with standardized ingredient units and sequential instructions.
    """
    client = get_gemini_client()

    prompt = f"""
You are an expert culinary AI for the Cook-Ed kitchen management platform.
Analyze the following cooking video information:

Video Title: {video_title or 'Cooking Video'}
Spoken Audio Transcription:
\"\"\"{transcript}\"\"\"

Task:
Convert this unstructured cooking dialogue/notes into a complete, well-organized recipe JSON.
Rules:
1. Standardize all ingredient units into clean culinary units: 'g', 'kg', 'ml', 'l', 'pcs', 'cloves', 'tbsp', 'tsp', 'cup', 'pinch'.
2. Provide precise numeric amounts (floats or integers). If unspecified in video, make a realistic estimation based on the serving size.
3. Categorize ingredients into: 'Meat & Seafood', 'Produce', 'Dairy & Eggs', 'Pantry & Dry Goods', 'Spices & Seasonings', 'Canned Goods', 'Other'.
4. Break cooking instructions into sequential, chronological steps.
5. Provide a clear title, estimated prep_time_minutes, cook_time_minutes, and default_servings (default to 2 if not stated).

Return ONLY valid JSON matching this schema:
{{
    "title": "String",
    "description": "Short culinary summary",
    "default_servings": 2,
    "prep_time_minutes": 15,
    "cook_time_minutes": 20,
    "ingredients": [
        {{
            "name": "Chicken Breast",
            "amount": 400.0,
            "unit": "g",
            "category": "Meat & Seafood"
        }}
    ],
    "instructions": [
        {{
            "step_number": 1,
            "instruction": "Detailed instruction here"
        }}
    ]
}}
"""

    contents = []
    # If audio is available and transcript was empty, attach the audio file directly to Gemini!
    if not transcript and audio_path and os.path.exists(audio_path):
        with open(audio_path, "rb") as f:
            audio_bytes = f.read()
            contents.append(types.Part.from_bytes(data=audio_bytes, mime_type="audio/mp3"))
        contents.append(prompt)
    else:
        contents.append(prompt)

    try:
        response = _call_gemini_json_with_fallback(client, contents=contents, temperature=0.2)

        data = json.loads(response.text)

        ingredients = [
            IngredientItem(
                name=ing.get("name", "Unknown item"),
                amount=float(ing.get("amount", 1.0)),
                unit=ing.get("unit", "pcs"),
                category=ing.get("category", "Other")
            )
            for ing in data.get("ingredients", [])
        ]

        instructions = [
            InstructionStep(
                step_number=int(step.get("step_number", idx + 1)),
                instruction=step.get("instruction", "")
            )
            for idx, step in enumerate(data.get("instructions", []))
        ]

        return RecipeResponse(
            title=data.get("title", video_title or "Cook-Ed Ingested Recipe"),
            description=data.get("description", ""),
            default_servings=int(data.get("default_servings", 2)),
            prep_time_minutes=int(data.get("prep_time_minutes", 15)),
            cook_time_minutes=int(data.get("cook_time_minutes", 20)),
            ingredients=ingredients,
            instructions=instructions,
            raw_transcript=transcript
        )
    except Exception as e:
        logger.error(f"Gemini recipe parsing failed: {e}")
        raise RuntimeError(f"Gemini Flash recipe structuring error: {str(e)}")

def parse_receipt_image(image_bytes: bytes, mime_type: str = "image/jpeg") -> ReceiptScanResponse:
    """
    Uses Gemini Flash multimodal vision to parse a supermarket receipt into structured pantry inventory items.
    """
    client = get_gemini_client()

    prompt = """
You are an expert grocery receipt OCR & inventory assistant for Cook-Ed.
Analyze this grocery store receipt image and extract all purchased grocery/food items into a structured list.

Rules:
1. Clean up cryptic abbreviations on receipts into clear readable grocery names:
   e.g. "CHCKN BRST FLT" -> "Chicken Breast Fillet", "ORG MILK 2L" -> "Organic Milk", "GARLIC 250G" -> "Garlic".
2. Extract the item quantity (number of packages or count).
3. Extract the standard unit: 'pcs', 'kg', 'g', 'l', 'ml', 'pack'.
4. Categorize each item into: 'Produce', 'Meat & Seafood', 'Dairy & Eggs', 'Pantry & Dry Goods', 'Spices & Seasonings', 'Canned Goods', 'Other'.
5. Extract the price for each item (if visible).
6. Ignore non-grocery items like bags, coupons, tax line, change, total lines.

Return ONLY a valid JSON object matching this schema:
{
    "store_name": "Supermarket / Store Name",
    "purchase_date": "YYYY-MM-DD or readable date",
    "items": [
        {
            "name": "Chicken Breast",
            "quantity": 1.0,
            "unit": "kg",
            "category": "Meat & Seafood",
            "estimated_price": 14.50
        }
    ]
}
"""

    image_part = types.Part.from_bytes(data=image_bytes, mime_type=mime_type)

    try:
        response = _call_gemini_json_with_fallback(client, contents=[image_part, prompt], temperature=0.1)

        data = json.loads(response.text)

        items = [
            ReceiptItem(
                name=item.get("name", "Unknown grocery item"),
                quantity=float(item.get("quantity", 1.0)),
                unit=item.get("unit", "pcs"),
                category=item.get("category", "Other"),
                estimated_price=item.get("estimated_price"),
                selected=True
            )
            for item in data.get("items", [])
        ]

        return ReceiptScanResponse(
            store_name=data.get("store_name", "Supermarket"),
            purchase_date=data.get("purchase_date"),
            items=items,
            raw_text=response.text[:200]
        )
    except Exception as e:
        logger.error(f"Gemini receipt parsing failed: {e}")
        raise RuntimeError(f"Gemini Flash receipt OCR error: {str(e)}")
