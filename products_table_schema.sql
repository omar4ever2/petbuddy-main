-- SQL Schema for Products Table in PetBuddy App

-- Check if table exists, if not create it
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'products') THEN
        -- If table exists but user_id column doesn't, add it
        IF NOT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'products' 
            AND column_name = 'user_id'
        ) THEN
            ALTER TABLE public.products ADD COLUMN user_id UUID;
        END IF;
    ELSE
        -- Create products table with all specified columns
        CREATE TABLE public.products (
            id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
            name TEXT NOT NULL,
            description TEXT,
            price DECIMAL(10, 2) NOT NULL,
            discount_price DECIMAL(10, 2),
            stock_quantity INTEGER NOT NULL DEFAULT 0,
            image TEXT,
            category_id UUID REFERENCES public.categories(id),
            is_featured BOOLEAN DEFAULT FALSE,
            average_rating DECIMAL(3, 2) DEFAULT 0,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            user_id UUID
        );
    END IF;
END
$$;

-- Enable Row Level Security
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Create policy for reading products (anyone can read) only if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'products' 
        AND policyname = 'Anyone can read products'
    ) THEN
        CREATE POLICY "Anyone can read products" 
        ON public.products 
        FOR SELECT 
        USING (true);
    END IF;
END
$$;

-- Create policy for inserting/updating products only if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'products' 
        AND policyname = 'Users can manage their own products'
    ) THEN
        CREATE POLICY "Users can manage their own products" 
        ON public.products 
        FOR ALL 
        USING (
            auth.uid() = user_id OR 
            (auth.uid() IS NOT NULL AND user_id IS NULL)
        );
    END IF;
END
$$;

-- Create indexes on frequently searched columns
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_featured ON public.products(is_featured);
CREATE INDEX IF NOT EXISTS idx_products_name ON public.products(name);
CREATE INDEX IF NOT EXISTS idx_products_user ON public.products(user_id);

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_products_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to update the updated_at column on update
DROP TRIGGER IF EXISTS update_products_updated_at ON public.products;
CREATE TRIGGER update_products_updated_at
BEFORE UPDATE ON public.products
FOR EACH ROW
EXECUTE FUNCTION update_products_updated_at_column();

-- Optional: Insert sample data
DO $$
BEGIN
    -- Only insert sample data if the categories table exists and has data
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'categories') AND
       EXISTS (SELECT 1 FROM public.categories LIMIT 1) THEN
        
        -- Insert sample products data
        INSERT INTO public.products (
            name, 
            description, 
            price, 
            discount_price, 
            stock_quantity, 
            image, 
            category_id, 
            is_featured, 
            average_rating,
            user_id
        )
        VALUES
            (
                'Premium Dog Food', 
                'High-quality nutrition for your canine companion', 
                29.99, 
                NULL, 
                100, 
                'https://images.unsplash.com/photo-1589924691995-400dc9ecc119', 
                (SELECT id FROM public.categories WHERE name LIKE '%Dog%' LIMIT 1), 
                TRUE, 
                4.5,
                NULL
            ),
            (
                'Cat Scratching Post', 
                'Durable scratching post with comfortable perch', 
                49.99, 
                39.99, 
                50, 
                'https://images.unsplash.com/photo-1545249390-6bdfa286032f', 
                (SELECT id FROM public.categories WHERE name LIKE '%Cat%' LIMIT 1), 
                TRUE, 
                4.2,
                NULL
            ),
            (
                'Bird Cage Deluxe', 
                'Spacious and stylish cage for your feathered friends', 
                89.99, 
                79.99, 
                25, 
                'https://images.unsplash.com/photo-1605001011156-cbf0b0f67a51', 
                (SELECT id FROM public.categories WHERE name LIKE '%Bird%' LIMIT 1), 
                FALSE, 
                4.7,
                NULL
            );
            
        RAISE NOTICE 'Sample products data inserted successfully.';
    ELSE
        RAISE NOTICE 'Skipping sample data insertion - categories table not found or empty.';
    END IF;
END;
$$;
