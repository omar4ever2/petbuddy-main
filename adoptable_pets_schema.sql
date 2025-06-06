-- SQL Schema for Adoptable Pets Table in PetBuddy App

-- Create adoptable_pets table with all specified columns
CREATE TABLE IF NOT EXISTS public.adoptable_pets (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    name TEXT NOT NULL,
    species TEXT NOT NULL,
    breed TEXT,
    age_years INTEGER,
    age_months INTEGER,
    gender TEXT CHECK (gender IN ('male', 'female', 'unknown')),
    size TEXT CHECK (size IN ('small', 'medium', 'large', 'extra_large')),
    description TEXT,
    image_url TEXT,
    is_vaccinated BOOLEAN DEFAULT FALSE,
    is_neutered BOOLEAN DEFAULT FALSE,
    is_house_trained BOOLEAN DEFAULT FALSE,
    is_featured BOOLEAN DEFAULT FALSE,
    adoption_fee DECIMAL(10, 2),
    contact_email TEXT,
    contact_phone TEXT,
    location TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Add owner_id to track who listed the pet
    owner_id UUID
);

-- Enable Row Level Security
ALTER TABLE public.adoptable_pets ENABLE ROW LEVEL SECURITY;

-- Create policy for reading pets (anyone can read)
CREATE POLICY "Anyone can read adoptable pets" 
ON public.adoptable_pets 
FOR SELECT 
USING (true);

-- Create policy for inserting/updating pets (any authenticated user can add/edit their own pets)
CREATE POLICY "Users can manage their own pets" 
ON public.adoptable_pets 
FOR ALL 
USING (auth.uid() = owner_id OR auth.uid() IS NOT NULL AND owner_id IS NULL);

-- Create indexes on frequently searched columns
CREATE INDEX idx_pets_species ON public.adoptable_pets(species);
CREATE INDEX idx_pets_featured ON public.adoptable_pets(is_featured);
CREATE INDEX idx_pets_owner ON public.adoptable_pets(owner_id);
CREATE INDEX idx_pets_location ON public.adoptable_pets(location);

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_pets_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to update the updated_at column on update
CREATE TRIGGER update_pets_updated_at
BEFORE UPDATE ON public.adoptable_pets
FOR EACH ROW
EXECUTE FUNCTION update_pets_updated_at_column();

-- Optional: Insert some sample data
INSERT INTO public.adoptable_pets (
    name, species, breed, age_years, age_months, gender, size, 
    description, image_url, is_vaccinated, is_neutered, is_house_trained, 
    is_featured, adoption_fee, contact_email, contact_phone, location
) VALUES
    (
        'Max', 'Dog', 'Golden Retriever', 2, 3, 'male', 'large',
        'Friendly and energetic Golden Retriever looking for an active family',
        'https://images.unsplash.com/photo-1552053831-71594a27632d',
        TRUE, TRUE, TRUE, TRUE, 150.00, 'adoption@petbuddy.com', '555-123-4567', 'New York, NY'
    ),
    (
        'Luna', 'Cat', 'Siamese', 1, 6, 'female', 'small',
        'Playful Siamese cat who loves attention and toys',
        'https://images.unsplash.com/photo-1526336024174-e58f5cdd8e13',
        TRUE, TRUE, TRUE, TRUE, 75.00, 'adoption@petbuddy.com', '555-123-4567', 'Los Angeles, CA'
    ),
    (
        'Charlie', 'Dog', 'Beagle', 3, 0, 'male', 'medium',
        'Sweet beagle who loves walks and cuddles',
        'https://images.unsplash.com/photo-1505628346881-b72b27e84530',
        TRUE, FALSE, TRUE, FALSE, 125.00, 'adoption@petbuddy.com', '555-123-4567', 'Chicago, IL'
    );

-- Add function to search pets by various criteria
CREATE OR REPLACE FUNCTION search_adoptable_pets(
    search_species TEXT DEFAULT NULL,
    search_breed TEXT DEFAULT NULL,
    search_size TEXT DEFAULT NULL,
    search_gender TEXT DEFAULT NULL,
    max_age_years INTEGER DEFAULT NULL,
    is_vacc BOOLEAN DEFAULT NULL,
    is_neut BOOLEAN DEFAULT NULL,
    is_trained BOOLEAN DEFAULT NULL,
    max_fee DECIMAL DEFAULT NULL,
    search_location TEXT DEFAULT NULL
) 
RETURNS SETOF public.adoptable_pets AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM public.adoptable_pets
    WHERE
        (search_species IS NULL OR species ILIKE '%' || search_species || '%') AND
        (search_breed IS NULL OR breed ILIKE '%' || search_breed || '%') AND
        (search_size IS NULL OR size = search_size) AND
        (search_gender IS NULL OR gender = search_gender) AND
        (max_age_years IS NULL OR age_years <= max_age_years) AND
        (is_vacc IS NULL OR is_vaccinated = is_vacc) AND
        (is_neut IS NULL OR is_neutered = is_neut) AND
        (is_trained IS NULL OR is_house_trained = is_trained) AND
        (max_fee IS NULL OR adoption_fee <= max_fee) AND
        (search_location IS NULL OR location ILIKE '%' || search_location || '%');
END;
$$ LANGUAGE plpgsql;
