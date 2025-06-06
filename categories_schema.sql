-- SQL Schema for Categories Table in PetBuddy App

-- Create categories table with all specified columns
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    icon_name TEXT,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Create policy for reading categories (anyone can read)
CREATE POLICY "Anyone can read categories" 
ON public.categories 
FOR SELECT 
USING (true);

-- Create policy for inserting/updating categories (any authenticated user can modify)
CREATE POLICY "Authenticated users can modify categories" 
ON public.categories 
FOR ALL 
USING (auth.uid() IS NOT NULL);

-- Create index on frequently searched columns
CREATE INDEX idx_categories_name ON public.categories(name);

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_category_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to update the updated_at column on update
CREATE TRIGGER update_categories_updated_at
BEFORE UPDATE ON public.categories
FOR EACH ROW
EXECUTE FUNCTION update_category_updated_at_column();

-- Insert some sample categories (optional)
INSERT INTO public.categories (name, description, icon_name, image_url)
VALUES
    ('Dogs', 'Products for dogs', 'pets', 'https://images.unsplash.com/photo-1543466835-00a7907e9de1'),
    ('Cats', 'Products for cats', 'pets', 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba'),
    ('Birds', 'Products for birds', 'pets', 'https://images.unsplash.com/photo-1452570053594-1b985d6ea890'),
    ('Fish', 'Products for fish', 'pets', 'https://images.unsplash.com/photo-1524704654690-b56c05c78a00'),
    ('Small Pets', 'Products for small pets', 'pets', 'https://images.unsplash.com/photo-1591561582301-7ce6587cc286')
ON CONFLICT (name) DO NOTHING;

-- Update foreign key in products table to ensure referential integrity
ALTER TABLE IF EXISTS public.products
ADD CONSTRAINT fk_product_category
FOREIGN KEY (category_id) REFERENCES public.categories(id)
ON DELETE SET NULL;
