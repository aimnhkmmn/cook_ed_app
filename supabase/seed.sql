-- ==============================================================================
-- Cook-Ed: Supabase Sample Seed Data
-- ==============================================================================

-- Sample items to test the Pantry Management & Portion Scaling features
-- Replace 'YOUR_USER_ID' with an actual user UUID after signing up, or use inside testing environment.

-- Sample Pantry Items:
-- Chicken Breast (800g), Garlic (10 cloves), Onion (3 pcs), Olive Oil (500 ml), 
-- Soy Sauce (300 ml), Eggs (12 pcs), Spaghetti (500 g), Heavy Cream (250 ml), Salt (1000 g)

/*
INSERT INTO public.pantry_items (user_id, name, normalized_name, category, quantity, unit)
VALUES 
    (auth.uid(), 'Chicken Breast', 'chicken breast', 'Meat & Seafood', 800.0, 'g'),
    (auth.uid(), 'Garlic', 'garlic', 'Produce', 10.0, 'cloves'),
    (auth.uid(), 'Yellow Onion', 'yellow onion', 'Produce', 3.0, 'pcs'),
    (auth.uid(), 'Olive Oil', 'olive oil', 'Pantry & Dry Goods', 500.0, 'ml'),
    (auth.uid(), 'Soy Sauce', 'soy sauce', 'Pantry & Dry Goods', 300.0, 'ml'),
    (auth.uid(), 'Eggs', 'eggs', 'Dairy & Eggs', 12.0, 'pcs'),
    (auth.uid(), 'Spaghetti Pasta', 'spaghetti pasta', 'Pantry & Dry Goods', 500.0, 'g'),
    (auth.uid(), 'Heavy Cream', 'heavy cream', 'Dairy & Eggs', 250.0, 'ml'),
    (auth.uid(), 'Black Pepper', 'black pepper', 'Spices & Seasonings', 50.0, 'g');
*/
