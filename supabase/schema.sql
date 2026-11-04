-- ==============================================================================
-- Cook-Ed: Supabase Database Schema & Atomic Functions
-- Modules Covered:
-- 1. Account & Pantry Management
-- 2. Recipe Storage & Ingestion
-- 3. Portion Scaling & Stock Checking
-- 4. Meal Confirmation with Atomic Stock Deduction
-- ==============================================================================

-- 1. Create profiles table (extends auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW())
);

-- Enable RLS for profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" 
ON public.profiles FOR SELECT 
USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" 
ON public.profiles FOR UPDATE 
USING (auth.uid() = id);

-- 2. Create pantry_items table
CREATE TABLE IF NOT EXISTS public.pantry_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    normalized_name TEXT NOT NULL, -- Lowercase, trimmed for fuzzy and standard matching
    category TEXT NOT NULL DEFAULT 'Other', -- 'Produce', 'Meat & Seafood', 'Dairy & Eggs', 'Pantry & Dry Goods', 'Spices & Seasonings', 'Canned Goods', 'Other'
    quantity NUMERIC(10, 2) NOT NULL DEFAULT 0,
    unit TEXT NOT NULL DEFAULT 'pcs', -- 'g', 'kg', 'ml', 'l', 'pcs', 'cloves', 'tbsp', 'tsp', 'pack', etc.
    expiry_date DATE,
    receipt_scan_id TEXT, -- Reference if added via receipt OCR
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW())
);

-- Index for fast user pantry lookup and case-insensitive matching
CREATE INDEX IF NOT EXISTS idx_pantry_user_id ON public.pantry_items(user_id);
CREATE INDEX IF NOT EXISTS idx_pantry_normalized_name ON public.pantry_items(user_id, normalized_name);

-- Enable RLS for pantry_items
ALTER TABLE public.pantry_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own pantry items" 
ON public.pantry_items FOR ALL 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 3. Create recipes table (ingested from videos or created)
CREATE TABLE IF NOT EXISTS public.recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    video_url TEXT,
    source_platform TEXT, -- 'TikTok', 'Instagram Reels', 'YouTube Shorts', 'Manual'
    default_servings INT NOT NULL DEFAULT 2,
    prep_time_minutes INT DEFAULT 15,
    cook_time_minutes INT DEFAULT 20,
    -- JSON structure: [{"name": "Chicken Breast", "amount": 500, "unit": "g", "category": "Meat & Seafood"}]
    ingredients JSONB NOT NULL DEFAULT '[]'::jsonb,
    -- JSON structure: [{"step_number": 1, "instruction": "Dice the chicken breast..."}]
    instructions JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW())
);

CREATE INDEX IF NOT EXISTS idx_recipes_user_id ON public.recipes(user_id);

-- Enable RLS for recipes
ALTER TABLE public.recipes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own recipes" 
ON public.recipes FOR ALL 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 4. Create meal_cooking_logs table
CREATE TABLE IF NOT EXISTS public.meal_cooking_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    recipe_id UUID REFERENCES public.recipes(id) ON DELETE SET NULL,
    recipe_title TEXT NOT NULL,
    servings_cooked INT NOT NULL,
    deducted_items JSONB NOT NULL DEFAULT '[]'::jsonb,
    cooked_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW())
);

CREATE INDEX IF NOT EXISTS idx_meal_logs_user_id ON public.meal_cooking_logs(user_id);

-- Enable RLS for cooking logs
ALTER TABLE public.meal_cooking_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own meal logs" 
ON public.meal_cooking_logs FOR ALL 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- ==============================================================================
-- 5. ATOMIC STORED PROCEDURE: deduct_pantry_stock
-- Finalizes cooking workflow and guarantees atomic pantry synchronization.
-- p_items is a JSONB array of objects:
-- [
--   {"name": "chicken breast", "amount": 400.0, "unit": "g"},
--   {"name": "garlic", "amount": 3.0, "unit": "cloves"}
-- ]
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.deduct_pantry_stock(
    p_user_id UUID,
    p_recipe_id UUID,
    p_recipe_title TEXT,
    p_servings INT,
    p_items JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    item RECORD;
    v_item_name TEXT;
    v_norm_name TEXT;
    v_deduct_amount NUMERIC;
    v_unit TEXT;
    v_pantry_rec RECORD;
    v_deducted_count INT := 0;
    v_results JSONB := '[]'::jsonb;
    v_new_qty NUMERIC;
BEGIN
    -- Verify that calling user matches p_user_id (or user is authenticated)
    IF auth.uid() IS NOT NULL AND auth.uid() <> p_user_id THEN
        RAISE EXCEPTION 'Unauthorized: User ID mismatch';
    END IF;

    -- Iterate over each item to deduct
    FOR item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(name TEXT, amount NUMERIC, unit TEXT)
    LOOP
        v_item_name := item.name;
        v_norm_name := lower(trim(item.name));
        v_deduct_amount := COALESCE(item.amount, 0);
        v_unit := COALESCE(item.unit, 'pcs');

        -- Find matching pantry item (by exact normalized name or substring match for user)
        SELECT * INTO v_pantry_rec
        FROM public.pantry_items
        WHERE user_id = p_user_id
          AND (normalized_name = v_norm_name OR v_norm_name ILIKE '%' || normalized_name || '%' OR normalized_name ILIKE '%' || v_norm_name || '%')
        ORDER BY (normalized_name = v_norm_name) DESC
        LIMIT 1;

        IF FOUND THEN
            -- Deduct quantity, ensuring it doesn't drop below 0
            v_new_qty := GREATEST(0, v_pantry_rec.quantity - v_deduct_amount);

            UPDATE public.pantry_items
            SET quantity = v_new_qty,
                updated_at = TIMEZONE('utc', NOW())
            WHERE id = v_pantry_rec.id;

            v_deducted_count := v_deducted_count + 1;

            v_results := v_results || jsonb_build_object(
                'item_name', v_item_name,
                'pantry_id', v_pantry_rec.id,
                'previous_quantity', v_pantry_rec.quantity,
                'deducted_amount', v_deduct_amount,
                'remaining_quantity', v_new_qty,
                'unit', v_pantry_rec.unit,
                'status', 'deducted'
            );
        ELSE
            -- Item not in pantry
            v_results := v_results || jsonb_build_object(
                'item_name', v_item_name,
                'deducted_amount', v_deduct_amount,
                'status', 'not_found'
            );
        END IF;
    END LOOP;

    -- Record the cooking log
    INSERT INTO public.meal_cooking_logs (
        user_id,
        recipe_id,
        recipe_title,
        servings_cooked,
        deducted_items
    ) VALUES (
        p_user_id,
        p_recipe_id,
        p_recipe_title,
        p_servings,
        v_results
    );

    RETURN jsonb_build_object(
        'success', true,
        'deducted_items_count', v_deducted_count,
        'details', v_results
    );
END;
$$;

-- Grant execution permission
GRANT EXECUTE ON FUNCTION public.deduct_pantry_stock(UUID, UUID, TEXT, INT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.deduct_pantry_stock(UUID, UUID, TEXT, INT, JSONB) TO anon;

-- Trigger to auto-create profile on auth.users sign up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name)
    VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)))
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
