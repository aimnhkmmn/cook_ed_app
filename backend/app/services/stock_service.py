from typing import List, Dict, Tuple, Optional
from app.models.schemas import IngredientItem, PantryItemDTO, ScaledIngredient, StockCheckResponse

# Standard unit conversion factors to base unit (e.g. g or ml)
MASS_CONVERSIONS = {
    'g': 1.0,
    'kg': 1000.0,
    'mg': 0.001,
    'oz': 28.3495,
    'lb': 453.592,
}

VOLUME_CONVERSIONS = {
    'ml': 1.0,
    'l': 1000.0,
    'cup': 240.0,
    'tbsp': 15.0,
    'tsp': 5.0,
}

def normalize_name(name: str) -> str:
    return name.strip().lower()

def convert_units(amount: float, from_unit: str, to_unit: str) -> Optional[float]:
    f_u = from_unit.strip().lower()
    t_u = to_unit.strip().lower()

    if f_u == t_u:
        return amount

    if f_u in MASS_CONVERSIONS and t_u in MASS_CONVERSIONS:
        base_g = amount * MASS_CONVERSIONS[f_u]
        return base_g / MASS_CONVERSIONS[t_u]

    if f_u in VOLUME_CONVERSIONS and t_u in VOLUME_CONVERSIONS:
        base_ml = amount * VOLUME_CONVERSIONS[f_u]
        return base_ml / VOLUME_CONVERSIONS[t_u]

    return None

def check_stock_and_scale(
    recipe_servings: int,
    target_servings: int,
    ingredients: List[IngredientItem],
    pantry_items: List[PantryItemDTO]
) -> StockCheckResponse:
    """
    Module: Portion Scaling & Stock Checking
    Recalculates ingredient proportions dynamically and cross-references against active pantry records.
    Status badges:
    - 'adequate' (Checkmark \u2713): Adequate stock available
    - 'insufficient' (Exclamation !): Current stock insufficient
    - 'missing' (Cross \u00d7): Ingredient missing entirely
    """
    scale_factor = target_servings / max(1, recipe_servings)
    scaled_results: List[ScaledIngredient] = []
    all_adequate = True

    # Build normalized pantry dictionary for lookup
    pantry_map: Dict[str, PantryItemDTO] = {}
    for p in pantry_items:
        pantry_map[normalize_name(p.name)] = p

    for ing in ingredients:
        scaled_amount = round(ing.amount * scale_factor, 2)
        norm_recipe_name = normalize_name(ing.name)

        # Lookup matching pantry item (exact match or partial substring)
        matched_pantry: Optional[PantryItemDTO] = None
        if norm_recipe_name in pantry_map:
            matched_pantry = pantry_map[norm_recipe_name]
        else:
            for p_name, p_item in pantry_map.items():
                if p_name in norm_recipe_name or norm_recipe_name in p_name:
                    matched_pantry = p_item
                    break

        if matched_pantry is None:
            # Ingredient missing entirely
            scaled_results.append(ScaledIngredient(
                name=ing.name,
                original_amount=ing.amount,
                scaled_amount=scaled_amount,
                unit=ing.unit,
                pantry_amount=0.0,
                pantry_unit=ing.unit,
                status="missing", # \u00d7
                difference=-scaled_amount
            ))
            all_adequate = False
        else:
            # Item found in pantry. Check units and quantities.
            p_amount = matched_pantry.quantity
            p_unit = matched_pantry.unit

            converted_pantry_amount = convert_units(p_amount, p_unit, ing.unit)

            if converted_pantry_amount is not None:
                effective_pantry = converted_pantry_amount
            else:
                effective_pantry = p_amount

            difference = round(effective_pantry - scaled_amount, 2)

            if effective_pantry >= scaled_amount:
                status = "adequate" # \u2713
            elif effective_pantry > 0:
                status = "insufficient" # !
                all_adequate = False
            else:
                status = "missing" # \u00d7
                all_adequate = False

            scaled_results.append(ScaledIngredient(
                name=ing.name,
                original_amount=ing.amount,
                scaled_amount=scaled_amount,
                unit=ing.unit,
                pantry_amount=matched_pantry.quantity,
                pantry_unit=matched_pantry.unit,
                status=status,
                difference=difference
            ))

    return StockCheckResponse(
        target_servings=target_servings,
        all_adequate=all_adequate,
        scaled_ingredients=scaled_results
    )
