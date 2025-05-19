-- Drop existing products table
DROP TABLE IF EXISTS products;

-- Create new products table
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    discount_price DECIMAL(10, 2),
    stock_quantity INTEGER NOT NULL DEFAULT 0,
    image TEXT,
    category_id UUID REFERENCES categories(id),
    is_featured BOOLEAN DEFAULT false,
    average_rating DECIMAL(3, 2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on category_id for faster joins
CREATE INDEX IF NOT EXISTS products_category_id_idx ON products(category_id);

-- Create index on is_featured for filtering featured products
CREATE INDEX IF NOT EXISTS products_is_featured_idx ON products(is_featured);

-- Add RLS (Row Level Security) policies
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Create policy for public read access
CREATE POLICY products_select_policy ON products
    FOR SELECT USING (true);

-- Create policy for authenticated insert
CREATE POLICY products_insert_policy ON products
    FOR INSERT 
    TO authenticated
    WITH CHECK (true);

-- Create policy for authenticated update
CREATE POLICY products_update_policy ON products
    FOR UPDATE 
    TO authenticated
    USING (true);

-- Create trigger to automatically update the updated_at column
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_products_updated_at
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- Example insert statements for sample data
-- Uncomment and customize as needed
/*
INSERT INTO products (name, description, price, stock_quantity, image, is_featured)
VALUES 
('Premium Dog Food', 'High-quality dog food for all breeds', 29.99, 100, 'https://example.com/dog-food.jpg', true),
('Cat Scratching Post', 'Durable post for your cat to scratch', 19.99, 50, 'https://example.com/cat-post.jpg', true),
('Bird Cage', 'Spacious cage for small to medium birds', 39.99, 25, 'https://example.com/bird-cage.jpg', false);
*/
