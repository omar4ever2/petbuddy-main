-- SQL Schema for Favorites Table in PetBuddy App

-- Create favorites table to store user product favorites
CREATE TABLE IF NOT EXISTS public.favorites (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Add a unique constraint to prevent duplicate favorites
    UNIQUE (user_id, product_id)
);

-- Enable Row Level Security
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

-- Create policy for reading favorites (users can only see their own favorites)
CREATE POLICY "Users can view their own favorites" 
ON public.favorites 
FOR SELECT 
USING (auth.uid() = user_id);

-- Create policy for inserting favorites (users can only add their own favorites)
CREATE POLICY "Users can insert their own favorites" 
ON public.favorites 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Create policy for deleting favorites (users can only delete their own favorites)
CREATE POLICY "Users can delete their own favorites" 
ON public.favorites 
FOR DELETE 
USING (auth.uid() = user_id);

-- Create index on user_id for faster queries
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON public.favorites(user_id);

-- Create index on product_id for faster queries
CREATE INDEX IF NOT EXISTS idx_favorites_product_id ON public.favorites(product_id);

-- Optional: Create a view to easily get favorite products with their details
CREATE OR REPLACE VIEW public.user_favorite_products AS
SELECT 
    f.id AS favorite_id,
    f.user_id,
    p.*
FROM 
    public.favorites f
JOIN 
    public.products p ON f.product_id = p.id;

-- Optional: Create a function to toggle favorite status
CREATE OR REPLACE FUNCTION toggle_favorite(product_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    existing_favorite UUID;
    is_favorited BOOLEAN;
BEGIN
    -- Check if user is authenticated
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'User must be authenticated to toggle favorites';
    END IF;
    
    -- Check if product is already favorited
    SELECT id INTO existing_favorite 
    FROM public.favorites 
    WHERE user_id = auth.uid() AND product_id = toggle_favorite.product_id;
    
    -- Toggle favorite status
    IF existing_favorite IS NULL THEN
        -- Add to favorites
        INSERT INTO public.favorites (user_id, product_id)
        VALUES (auth.uid(), toggle_favorite.product_id);
        is_favorited := TRUE;
    ELSE
        -- Remove from favorites
        DELETE FROM public.favorites
        WHERE user_id = auth.uid() AND product_id = toggle_favorite.product_id;
        is_favorited := FALSE;
    END IF;
    
    RETURN is_favorited;
END;
$$; 