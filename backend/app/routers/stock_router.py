import logging
from fastapi import APIRouter, HTTPException
from app.models.schemas import MealConfirmRequest
from app.config import settings

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/stock", tags=["Meal Confirmation & Stock Deduction"])

@router.post("/confirm-meal")
async def confirm_meal_deduction(request: MealConfirmRequest):
    """
    Meal Confirmation & Stock Deduction Module:
    Guarantees continuous inventory synchronization by executing atomic deduction
    from the user's virtual pantry database.
    """
    if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
        # If backend doesn't have direct Supabase service key, deduction can be executed directly from client
        return {
            "success": True,
            "message": "Meal deduction payload validated. Ready for client Supabase RPC execution.",
            "data": request.dict()
        }

    try:
        from supabase import create_client
        supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)

        # Call the Supabase atomic RPC stored procedure
        payload = {
            "p_user_id": request.user_id,
            "p_recipe_id": request.recipe_id,
            "p_recipe_title": request.recipe_title,
            "p_servings": request.servings_cooked,
            "p_items": [item.dict() for item in request.items]
        }

        rpc_res = supabase.rpc("deduct_pantry_stock", payload).execute()

        return {
            "success": True,
            "result": rpc_res.data
        }

    except Exception as e:
        logger.error(f"Failed to execute atomic deduction: {e}")
        raise HTTPException(status_code=500, detail=f"Stock deduction failed: {str(e)}")
