-- SQL Schema for Product Images Table in PetBuddy App

-- Create product_images table with all specified columns
CREATE TABLE IF NOT EXISTS public.product_images (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- Track who uploaded the image
    user_id UUID
);

-- Enable Row Level Security
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;

-- Create policy for reading product images (anyone can read)
CREATE POLICY "Anyone can read product images" 
ON public.product_images 
FOR SELECT 
USING (true);

-- Create policy for inserting/updating product images (authenticated users can manage their own images)
CREATE POLICY "Users can manage their own images" 
ON public.product_images 
FOR ALL 
USING (
    auth.uid() = user_id OR 
    (auth.uid() IS NOT NULL AND user_id IS NULL)
);

-- Create indexes for faster lookups
CREATE INDEX idx_product_images_product ON public.product_images(product_id);
CREATE INDEX idx_product_images_primary ON public.product_images(is_primary);
CREATE INDEX idx_product_images_user ON public.product_images(user_id);

-- Add constraint to ensure only one primary image per product
CREATE OR REPLACE FUNCTION ensure_one_primary_image_per_product()
RETURNS TRIGGER AS $$
BEGIN
    -- If this is set as primary, unset any other primary images for this product
    IF NEW.is_primary = TRUE THEN
        UPDATE public.product_images
        SET is_primary = FALSE
        WHERE product_id = NEW.product_id AND id != NEW.id AND is_primary = TRUE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to enforce one primary image per product
CREATE TRIGGER ensure_one_primary_image_trigger
BEFORE INSERT OR UPDATE ON public.product_images
FOR EACH ROW
EXECUTE FUNCTION ensure_one_primary_image_per_product();

-- Only run the sample data insertion after successfully creating the table
DO $$
BEGIN
    -- Check if the table exists before trying to insert data
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'product_images') AND
       EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'products') THEN
        
        -- Insert sample data only if both tables exist
        INSERT INTO public.product_images (product_id, image_url, is_primary, user_id)
        SELECT 
            id,
            CASE 
                WHEN id = (SELECT id FROM public.products LIMIT 1 OFFSET 0) THEN 'https://images.unsplash.com/photo-1583337130417-3346a1be7dee'
                WHEN id = (SELECT id FROM public.products LIMIT 1 OFFSET 1) THEN 'https://images.unsplash.com/photo-1601758174114-e711c0cbaa69'
                ELSE 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd'
            END as image_url,
            TRUE,
            NULL -- user_id set to NULL for sample data
        FROM public.products
        LIMIT 3
        ON CONFLICT DO NOTHING;
        
        RAISE NOTICE 'Sample data inserted successfully.';
    ELSE
        RAISE NOTICE 'Skipping sample data insertion - tables not found.';
    END IF;
END;
$$;
