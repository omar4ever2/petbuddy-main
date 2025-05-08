import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'providers/cart_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/theme_provider.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // New Supabase connection details
  const String supabaseUrl = 'https://fmlfjbkmeegzsnwpqhqf.supabase.co';
  const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZtbGZqYmttZWVnenNud3BxaHFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY3MzUyMjAsImV4cCI6MjA2MjMxMTIyMH0.TrgDO4OrCWSYf-2BmMhRuLl4z1qmUVqeOowzXK1UwaU';

  try {
    print('Initializing Supabase with URL: $supabaseUrl');

    // Initialize Supabase with the new values
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true, // Enable debug logs
    );

    print('***** Supabase init completed ${Supabase.instance}');
  } catch (e) {
    print('Error initializing Supabase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => CartProvider()),
        ChangeNotifierProvider(create: (ctx) => FavoritesProvider()),
        ChangeNotifierProvider(create: (ctx) => SupabaseService(supabase)),
        ChangeNotifierProvider(create: (ctx) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentTheme,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
