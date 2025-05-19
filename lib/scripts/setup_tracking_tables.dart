import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> setupTrackingTables(SupabaseClient client) async {
  try {
    print('Setting up order tracking tables...');

    // Read the SQL schema file
    final scriptPath =
        path.join(Directory.current.path, 'order_tracking_schema.sql');
    final sqlScript = await File(scriptPath).readAsString();

    // Execute the SQL script
    await client.rpc('exec_sql', params: {'query': sqlScript});

    print('✅ Order tracking tables setup complete!');
  } catch (e) {
    print('❌ Error setting up order tracking tables: $e');
    rethrow;
  }
}

// Function to run the setup independently (for testing)
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
    await setupTrackingTables(client);

    print('Setup completed successfully');
  } catch (e) {
    print('Failed to set up database: $e');
  }
}
