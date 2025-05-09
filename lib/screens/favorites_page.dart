import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../services/supabase_service.dart';
import '../widgets/product_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _favoriteProducts = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFavoriteProducts();
  }

  Future<void> _loadFavoriteProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if user is authenticated first
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      if (!supabaseService.isAuthenticated) {
        print('FavoritesPage: User is not authenticated');
        setState(() {
          _errorMessage = 'Please sign in to see your favorites';
          _isLoading = false;
        });
        return;
      }

      print('FavoritesPage: User is authenticated, loading favorites');
      final favoritesProvider =
          Provider.of<FavoritesProvider>(context, listen: false);

      // Refresh favorites from Supabase
      await favoritesProvider.refreshFavorites();

      // Debug: Print favorite IDs
      print('FavoritesPage: Favorite IDs: ${favoritesProvider.favoriteIds}');

      // Get favorite products with details
      final products = await supabaseService.getFavoriteProducts();

      // Debug: Print retrieved products
      print('FavoritesPage: Retrieved ${products.length} favorite products');

      setState(() {
        _favoriteProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      print('FavoritesPage: Error loading favorite products: $e');
      setState(() {
        _errorMessage = 'Error loading favorites: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Favorites',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Test button to add a sample product
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Add test product to favorites',
            onPressed: () async {
              // Try to add a sample product ID to favorites for testing
              try {
                final supabaseService =
                    Provider.of<SupabaseService>(context, listen: false);
                print('Testing: Adding sample product to favorites');

                // Get a product ID from the products table
                // Use Supabase.instance.client instead of accessing private _client
                final supabaseClient = supabase.Supabase.instance.client;
                final products =
                    await supabaseClient.from('products').select('id').limit(1);

                if (products != null && products.isNotEmpty) {
                  final productId = products[0]['id'] as String;
                  print('Testing: Got sample product ID: $productId');
                  await favoritesProvider.addFavorite(productId);
                  print('Testing: Added to favorites, refreshing...');
                  _loadFavoriteProducts();
                } else {
                  print('Testing: No products found in database');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('No products found in database')),
                  );
                }
              } catch (e) {
                print('Testing: Error adding test favorite: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
          ),
          if (_favoriteProducts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Favorites'),
                    content: const Text(
                        'Are you sure you want to remove all favorites?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await favoritesProvider.clearFavorites();
                          _loadFavoriteProducts();
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadFavoriteProducts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Something went wrong',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadFavoriteProducts,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 40, 108, 100),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : _favoriteProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 40, 108, 100)
                                  .withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite_border,
                              size: 80,
                              color: Color.fromARGB(255, 40, 108, 100),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No favorites yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Start adding items you like',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 40, 108, 100),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Browse Products'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFavoriteProducts,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.6,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _favoriteProducts.length,
                          itemBuilder: (context, index) {
                            final product = _favoriteProducts[index];
                            return ProductCard(
                              id: product['id'] as String,
                              name: product['name'] as String,
                              price: (product['price'] as num).toDouble(),
                              // Use image_url if available, fallback to image field
                              imageUrl: (product['image'] as String?) ?? '',
                              // Handle discount_price
                              discountPrice: product['discount_price'] != null
                                  ? (product['discount_price'] as num)
                                      .toDouble()
                                  : null,
                              // Handle rating with default value
                              rating: product['rating'] != null
                                  ? (product['rating'] as num).toDouble()
                                  : 0.0,
                            );
                          },
                        ),
                      ),
                    ),
    );
  }
}
