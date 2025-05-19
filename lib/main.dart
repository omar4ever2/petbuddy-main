import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/pet_walkers_page.dart';
import 'screens/book_pet_walk_page.dart';
import 'screens/my_pet_walks_page.dart';
import 'providers/cart_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/theme_provider.dart';
import 'services/supabase_service.dart';
import 'models/pet_walking.dart';

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
        ChangeNotifierProvider(create: (ctx) => ThemeProvider()),
        // Ensure SupabaseService is created before FavoritesProvider
        ChangeNotifierProvider(create: (ctx) => SupabaseService(supabase)),
        ChangeNotifierProxyProvider<SupabaseService, FavoritesProvider>(
          create: (_) => FavoritesProvider(),
          update: (_, supabaseService, previousFavoritesProvider) {
            final provider = previousFavoritesProvider ?? FavoritesProvider();
            // Initialize favorites provider with supabase service
            provider.initialize(supabaseService);
            return provider;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentTheme,
            home: const SplashScreen(),
            routes: {
              '/pet_walkers': (context) => const PetWalkersPage(),
              '/my_pet_walks': (context) => const MyPetWalksPage(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/book_pet_walk') {
                final walker = settings.arguments as PetWalker;
                return MaterialPageRoute(
                  builder: (context) => BookPetWalkPage(walker: walker),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
