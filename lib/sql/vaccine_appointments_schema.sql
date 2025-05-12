-- SQL Schema for Vaccine Appointments Table in PetBuddy App

-- Create vaccine_types table if not exists
CREATE TABLE IF NOT EXISTS public.vaccine_types (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    pet_type TEXT, -- Optional: to filter vaccines by pet type
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create vaccine_appointments table if not exists
CREATE TABLE IF NOT EXISTS public.vaccine_appointments (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    pet_name TEXT NOT NULL,
    pet_type TEXT NOT NULL,
    vaccine_type TEXT NOT NULL,
    appointment_date TIMESTAMP WITH TIME ZONE NOT NULL,
    notes TEXT,
    status TEXT CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled')) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on user_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_vaccine_appointments_user_id ON public.vaccine_appointments(user_id);

-- Create index on appointment_date for faster sorting and filtering
CREATE INDEX IF NOT EXISTS idx_vaccine_appointments_date ON public.vaccine_appointments(appointment_date);

-- Add some default vaccine types if table is empty
INSERT INTO public.vaccine_types (name, description, pet_type)
SELECT 'Rabies', 'Protection against rabies virus', 'Dog'
WHERE NOT EXISTS (SELECT 1 FROM public.vaccine_types WHERE name = 'Rabies');

INSERT INTO public.vaccine_types (name, description, pet_type)
SELECT 'Distemper', 'Protection against canine distemper', 'Dog'
WHERE NOT EXISTS (SELECT 1 FROM public.vaccine_types WHERE name = 'Distemper');

INSERT INTO public.vaccine_types (name, description, pet_type)
SELECT 'Parvovirus', 'Protection against parvovirus', 'Dog'
WHERE NOT EXISTS (SELECT 1 FROM public.vaccine_types WHERE name = 'Parvovirus');

INSERT INTO public.vaccine_types (name, description, pet_type)
SELECT 'Bordetella', 'Protection against kennel cough', 'Dog'
WHERE NOT EXISTS (SELECT 1 FROM public.vaccine_types WHERE name = 'Bordetella');

INSERT INTO public.vaccine_types (name, description, pet_type)
SELECT 'Leptospirosis', 'Protection against leptospirosis', 'Dog'
WHERE NOT EXISTS (SELECT 1 FROM public.vaccine_types WHERE name = 'Leptospirosis');

INSERT INTO public.vaccine_types (name, description, pet_type)
SELECT 'Feline Distemper', 'Protection against feline distemper (panleukopenia)', 'Cat'
WHERE NOT EXISTS (SELECT 1 FROM public.vaccine_types WHERE name = 'Feline Distemper');

INSERT INTO public.vaccine_types (name, description, pet_type)
SELECT 'Feline Herpesvirus', 'Protection against feline herpesvirus', 'Cat'
WHERE NOT EXISTS (SELECT 1 FROM public.vaccine_types WHERE name = 'Feline Herpesvirus');

INSERT INTO public.vaccine_types (name, description, pet_type)
SELECT 'Feline Calicivirus', 'Protection against feline calicivirus', 'Cat'
WHERE NOT EXISTS (SELECT 1 FROM public.vaccine_types WHERE name = 'Feline Calicivirus');

INSERT INTO public.vaccine_types (name, description, pet_type)
SELECT 'Avian Polyomavirus', 'Protection against avian polyomavirus', 'Bird'
WHERE NOT EXISTS (SELECT 1 FROM public.vaccine_types WHERE name = 'Avian Polyomavirus');

INSERT INTO public.vaccine_types (name, description, pet_type)
SELECT 'Psittacine Beak and Feather Disease', 'Protection against PBFD virus', 'Bird'
WHERE NOT EXISTS (SELECT 1 FROM public.vaccine_types WHERE name = 'Psittacine Beak and Feather Disease');

-- Add rabbit-specific vaccines
INSERT INTO public.vaccine_types (name, description, pet_type)
SELECT 'Myxomatosis', 'Protection against myxomatosis virus', 'Rabbit'
WHERE NOT EXISTS (SELECT 1 FROM public.vaccine_types WHERE name = 'Myxomatosis');

INSERT INTO public.vaccine_types (name, description, pet_type)
SELECT 'R(V)HD', 'Protection against Rabbit Viral Haemorrhagic Disease', 'Rabbit'
WHERE NOT EXISTS (SELECT 1 FROM public.vaccine_types WHERE name = 'R(V)HD');

-- Create Row Level Security policies
ALTER TABLE public.vaccine_appointments ENABLE ROW LEVEL SECURITY;

-- Users can only view their own appointments
CREATE POLICY view_own_appointments ON public.vaccine_appointments
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can only insert their own appointments
CREATE POLICY insert_own_appointments ON public.vaccine_appointments
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can only update their own appointments
CREATE POLICY update_own_appointments ON public.vaccine_appointments
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can only delete their own appointments
CREATE POLICY delete_own_appointments ON public.vaccine_appointments
    FOR DELETE
    USING (auth.uid() = user_id);

-- Vaccine types are accessible to all authenticated users
ALTER TABLE public.vaccine_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY view_vaccine_types ON public.vaccine_types
    FOR SELECT
    TO authenticated
    USING (true); 