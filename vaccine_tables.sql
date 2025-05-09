-- SQL Schema for Vaccine Appointments in PetBuddy App

-- Create vaccine_types table
CREATE TABLE IF NOT EXISTS public.vaccine_types (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    pet_type TEXT NOT NULL, -- dog, cat, bird, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create vaccine_appointments table
CREATE TABLE IF NOT EXISTS public.vaccine_appointments (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    pet_name TEXT NOT NULL,
    pet_type TEXT NOT NULL, -- dog, cat, bird, etc.
    pet_age INTEGER,
    pet_weight DECIMAL(10, 2),
    vaccine_type TEXT NOT NULL,
    appointment_date TIMESTAMP WITH TIME ZONE NOT NULL,
    vet_name TEXT,
    clinic_location TEXT,
    notes TEXT,
    status TEXT NOT NULL DEFAULT 'pending', -- pending, confirmed, completed, cancelled
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on user_id for faster queries
CREATE INDEX IF NOT EXISTS idx_vaccine_appointments_user_id ON public.vaccine_appointments(user_id);

-- Create index on appointment_date for faster date-based queries
CREATE INDEX IF NOT EXISTS idx_vaccine_appointments_date ON public.vaccine_appointments(appointment_date);

-- Create index on status for filtering by status
CREATE INDEX IF NOT EXISTS idx_vaccine_appointments_status ON public.vaccine_appointments(status);

-- Enable Row Level Security
ALTER TABLE public.vaccine_appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vaccine_types ENABLE ROW LEVEL SECURITY;

-- Create policy for reading vaccine types (anyone can read)
CREATE POLICY "Anyone can read vaccine types" 
ON public.vaccine_types 
FOR SELECT 
USING (true);

-- Create policy for reading vaccine appointments (users can only see their own)
CREATE POLICY "Users can view their own appointments" 
ON public.vaccine_appointments 
FOR SELECT 
USING (auth.uid() = user_id);

-- Create policy for inserting vaccine appointments (authenticated users only)
CREATE POLICY "Users can insert their own appointments" 
ON public.vaccine_appointments 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Create policy for updating vaccine appointments (users can only update their own)
CREATE POLICY "Users can update their own appointments" 
ON public.vaccine_appointments 
FOR UPDATE 
USING (auth.uid() = user_id);

-- Create policy for deleting vaccine appointments (users can only delete their own)
CREATE POLICY "Users can delete their own appointments" 
ON public.vaccine_appointments 
FOR DELETE 
USING (auth.uid() = user_id);

-- Insert default vaccine types
INSERT INTO public.vaccine_types (name, description, pet_type) 
VALUES 
('Rabies', 'Protection against rabies virus', 'Dog'),
('Distemper', 'Protection against canine distemper', 'Dog'),
('Parvovirus', 'Protection against parvovirus infection', 'Dog'),
('Bordetella', 'Protection against kennel cough', 'Dog'),
('Leptospirosis', 'Protection against leptospirosis bacteria', 'Dog'),
('Rabies', 'Protection against rabies virus', 'Cat'),
('Feline Distemper', 'Protection against panleukopenia', 'Cat'),
('Feline Herpesvirus', 'Protection against viral rhinotracheitis', 'Cat'),
('Feline Calicivirus', 'Protection against calicivirus infection', 'Cat'),
('Avian Polyomavirus', 'Protection against polyomavirus', 'Bird'),
('Psittacine Beak and Feather Disease', 'Protection against PBFD virus', 'Bird')
ON CONFLICT (id) DO NOTHING; 