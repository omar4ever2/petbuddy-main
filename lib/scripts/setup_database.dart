import 'package:supabase_flutter/supabase_flutter.dart';
import 'setup_tracking_tables.dart';

Future<void> setupDatabase(SupabaseClient client) async {
  try {
    print('Setting up database tables...');

    // Set up tracking tables
    await setupTrackingTables(client);

    print('✅ Database setup complete!');
  } catch (e) {
    print('❌ Error setting up database: $e');
    rethrow;
  }
}

// Function to run the setup independently
Future<void> main() async {
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL',
      defaultValue: 'https://your-project-url.supabase.co');
  const supabaseKey =
      String.fromEnvironment('SUPABASE_KEY', defaultValue: 'your-anon-key');

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );

    final client = Supabase.instance.client;
    await setupDatabase(client);

    print('Setup completed successfully');
  } catch (e) {
    print('Failed to set up database: $e');
  }
}
