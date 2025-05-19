import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

/// This utility script helps set up the vaccine appointments tables in Supabase
/// Run this script if you need to create the database schema for vaccine functionality
class VaccineTablesSetup {
  final SupabaseClient client;

  VaccineTablesSetup(this.client);

  Future<void> setupTables() async {
    // Schema for vaccine tables
    const String schema = '''
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
''';

    // Default vaccine types data
    const String defaultData = '''
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
''';

    // RLS policies
    const String rlsPolicies = '''
-- Create Row Level Security policies
ALTER TABLE public.vaccine_appointments ENABLE ROW LEVEL SECURITY;

-- Users can only view their own appointments
CREATE POLICY IF NOT EXISTS view_own_appointments ON public.vaccine_appointments
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can only insert their own appointments
CREATE POLICY IF NOT EXISTS insert_own_appointments ON public.vaccine_appointments
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can only update their own appointments
CREATE POLICY IF NOT EXISTS update_own_appointments ON public.vaccine_appointments
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can only delete their own appointments
CREATE POLICY IF NOT EXISTS delete_own_appointments ON public.vaccine_appointments
    FOR DELETE
    USING (auth.uid() = user_id);

-- Vaccine types are accessible to all authenticated users
ALTER TABLE public.vaccine_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS view_vaccine_types ON public.vaccine_types
    FOR SELECT
    TO authenticated
    USING (true);
''';

    try {
      // Execute schema creation
      await client.rpc('exec_sql', params: {'query': schema});
      print('✅ Vaccine tables schema created successfully');

      // Insert default data
      await client.rpc('exec_sql', params: {'query': defaultData});
      print('✅ Default vaccine types added successfully');

      // Set up RLS policies
      await client.rpc('exec_sql', params: {'query': rlsPolicies});
      print('✅ RLS policies created successfully');

      // Add new rabbit vaccines
      await _addRabbitVaccines();

      print('✅ Vaccine tables setup complete!');
    } catch (e) {
      print('❌ Error setting up vaccine tables: $e');
      rethrow;
    }
  }

  Future<void> _addRabbitVaccines() async {
    try {
      // Check if Myxomatosis vaccine already exists
      final myxoExists = await client
          .from('vaccine_types')
          .select('id')
          .eq('name', 'Myxomatosis')
          .maybeSingle();

      // Add Myxomatosis vaccine if it doesn't exist
      if (myxoExists == null) {
        await client.from('vaccine_types').insert({
          'name': 'Myxomatosis',
          'description': 'Protection against myxomatosis virus',
          'pet_type': 'Rabbit'
        });
        print('Added Myxomatosis vaccine for rabbits');
      }

      // Check if R(V)HD vaccine already exists
      final rvhdExists = await client
          .from('vaccine_types')
          .select('id')
          .eq('name', 'R(V)HD')
          .maybeSingle();

      // Add R(V)HD vaccine if it doesn't exist
      if (rvhdExists == null) {
        await client.from('vaccine_types').insert({
          'name': 'R(V)HD',
          'description': 'Protection against Rabbit Viral Haemorrhagic Disease',
          'pet_type': 'Rabbit'
        });
        print('Added R(V)HD vaccine for rabbits');
      }
    } catch (e) {
      print('Error adding rabbit vaccines: $e');
      rethrow;
    }
  }
}

// Example of how to use this utility
void main() async {
  // Replace with your Supabase URL and key
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  final client = Supabase.instance.client;
  final setup = VaccineTablesSetup(client);

  try {
    await setup.setupTables();
    print('Database setup successful.');
  } catch (e) {
    print('Failed to set up database: $e');
  }

  exit(0);
}
