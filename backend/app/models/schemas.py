from typing import List, Optional
from pydantic import BaseModel, Field

# --- Recipe Models ---
class IngredientItem(BaseModel):
    name: str = Field(..., description="Cleaned name of ingredient, e.g., 'Chicken Breast'")
    amount: float = Field(..., description="Quantity as a numeric float, e.g., 500")
    unit: str = Field(..., description="Standardized unit: 'g', 'kg', 'ml', 'l', 'pcs', 'cloves', 'tbsp', 'tsp'")
    category: Optional[str] = Field("Other", description="Pantry category, e.g., 'Meat & Seafood', 'Produce'")

class InstructionStep(BaseModel):
    step_number: int
    instruction: str

class RecipeResponse(BaseModel):
    title: str
    description: Optional[str] = ""
    video_url: Optional[str] = ""
    source_platform: Optional[str] = "Social Video"
    default_servings: int = 2
    prep_time_minutes: int = 15
    cook_time_minutes: int = 20
    ingredients: List[IngredientItem]
    instructions: List[InstructionStep]
    raw_transcript: Optional[str] = None

class VideoIngestRequest(BaseModel):
    url: str = Field(..., description="URL from TikTok, Instagram Reels, or YouTube Shorts")
    user_id: Optional[str] = None

# --- Receipt OCR Models ---
class ReceiptItem(BaseModel):
    name: str
    quantity: float
    unit: str
    category: str
    estimated_price: Optional[float] = None
    selected: bool = True

class ReceiptScanResponse(BaseModel):
    store_name: Optional[str] = "Store"
    purchase_date: Optional[str] = None
    items: List[ReceiptItem]
    raw_text: Optional[str] = None

# --- Portion Scaling & Stock Checking Models ---
class PantryItemDTO(BaseModel):
    id: Optional[str] = None
    name: str
    quantity: float
    unit: str
    category: Optional[str] = "Other"

class ScaledIngredient(BaseModel):
    name: str
    original_amount: float
    scaled_amount: float
    unit: str
    pantry_amount: float
    pantry_unit: str
    # Badge: 'adequate' (checkmark), 'insufficient' (exclamation), 'missing' (cross)
    status: str
    difference: float # positive means surplus, negative means shortage

class StockCheckRequest(BaseModel):
    recipe_servings: int = 2
    target_servings: int = 4
    ingredients: List[IngredientItem]
    pantry_items: List[PantryItemDTO]

class StockCheckResponse(BaseModel):
    target_servings: int
    all_adequate: bool
    scaled_ingredients: List[ScaledIngredient]

# --- Meal Confirmation & Deduction ---
class DeductionItemRequest(BaseModel):
    name: str
    amount: float
    unit: str

class MealConfirmRequest(BaseModel):
    user_id: str
    recipe_id: Optional[str] = None
    recipe_title: str
    servings_cooked: int
    items: List[DeductionItemRequest]
