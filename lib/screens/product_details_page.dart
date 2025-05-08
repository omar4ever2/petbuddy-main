import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/theme_provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../screens/cart_page.dart';

class ProductDetailsPage extends StatefulWidget {
  final String productId;

  const ProductDetailsPage({
    Key? key,
    required this.productId,
  }) : super(key: key);

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _product;
  String? _errorMessage;
  int _selectedQuantity = 1;
  double _userRating = 0;
  bool _isRatingSubmitted = false;
  bool _isSubmittingRating = false;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
    _checkUserRating();
  }

  Future<void> _loadProductDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);

      // Load product details
      final product = await supabaseService.getProductById(widget.productId);

      setState(() {
        _product = product;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading product details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkUserRating() async {
    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);

      if (supabaseService.isAuthenticated) {
        // Check if user has already rated this product
        final userRating =
            await supabaseService.getUserProductRating(widget.productId);

        if (userRating != null) {
          setState(() {
            _userRating = userRating;
            _isRatingSubmitted = true;
          });
        }
      }
    } catch (e) {
      print('Error checking user rating: $e');
    }
  }

  Future<void> _submitRating(double rating) async {
    final supabaseService =
        Provider.of<SupabaseService>(context, listen: false);

    if (!supabaseService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to log in to rate products'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingRating = true;
    });

    try {
      await supabaseService.rateProduct(widget.productId, rating);

      // Refresh product details to get updated ratings
      final updatedProduct =
          await supabaseService.getProductById(widget.productId);

      setState(() {
        _product = updatedProduct;
        _isRatingSubmitted = true;
        _isSubmittingRating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your rating!'),
          backgroundColor: Color.fromARGB(255, 40, 108, 100),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit rating: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSubmittingRating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    const themeColor = Color.fromARGB(255, 40, 108, 100);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: themeColor,
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Oops! Something went wrong',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadProductDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _product == null
                  ? Center(
                      child: Text(
                        'Product not found',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        // App bar with product image
                        SliverAppBar(
                          expandedHeight: 300,
                          pinned: true,
                          backgroundColor:
                              isDarkMode ? Colors.grey[850] : Colors.white,
                          flexibleSpace: FlexibleSpaceBar(
                            background: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Product image
                                _product!['image'] != null &&
                                        _product!['image'].isNotEmpty
                                    ? Image.network(
                                        _product!['image'],
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: isDarkMode
                                                ? Colors.grey[800]
                                                : Colors.grey[200],
                                            child: const Center(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                size: 50,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: isDarkMode
                                            ? Colors.grey[800]
                                            : Colors.grey[200],
                                        child: const Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),

                                // Gradient overlay for better text visibility
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.7),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            // Favorite button
                            IconButton(
                              icon: Icon(
                                favoritesProvider.isFavorite(_product!['id'])
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: favoritesProvider
                                        .isFavorite(_product!['id'])
                                    ? Colors.red
                                    : isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                              ),
                              onPressed: () {
                                favoritesProvider
                                    .toggleFavorite(_product!['id']);
                              },
                            ),
                            // Share button
                            IconButton(
                              icon: Icon(
                                Icons.share,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                              onPressed: () {
                                // Share functionality
                              },
                            ),
                          ],
                        ),

                        // Product details
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product name
                                Text(
                                  _product!['name'],
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Price
                                Row(
                                  children: [
                                    if (_product!['discount_price'] !=
                                        null) ...[
                                      Text(
                                        'LE ${(_product!['price'] as num).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'LE ${(_product!['discount_price'] as num).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: themeColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: themeColor,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${(((_product!['price'] as num) - (_product!['discount_price'] as num)) / (_product!['price'] as num) * 100).round()}% OFF',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ] else
                                      Text(
                                        'LE ${(_product!['price'] as num).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: themeColor,
                                        ),
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Rating
                                Row(
                                  children: [
                                    Row(
                                      children: List.generate(5, (index) {
                                        final rating =
                                            (_product!['rating'] as num?)
                                                    ?.toDouble() ??
                                                0.0;
                                        return Icon(
                                          index < rating.floor()
                                              ? Icons.star
                                              : index < rating
                                                  ? Icons.star_half
                                                  : Icons.star_border,
                                          size: 20,
                                          color: const Color.fromARGB(
                                              255, 255, 193, 7),
                                        );
                                      }),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${(_product!['rating'] as num?)?.toStringAsFixed(1) ?? '0.0'} (${_product!['review_count'] ?? 0} reviews)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Rate this product
                                if (!_isRatingSubmitted)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Rate this product:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Center(
                                        child: RatingBar.builder(
                                          initialRating: _userRating,
                                          minRating: 1,
                                          direction: Axis.horizontal,
                                          allowHalfRating: true,
                                          itemCount: 5,
                                          itemSize: 40,
                                          itemPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 4.0),
                                          itemBuilder: (context, _) =>
                                              const Icon(
                                            Icons.star,
                                            color: Color.fromARGB(
                                                255, 255, 193, 7),
                                          ),
                                          onRatingUpdate: (rating) {
                                            setState(() {
                                              _userRating = rating;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Center(
                                        child: ElevatedButton(
                                          onPressed: _isSubmittingRating
                                              ? null
                                              : () =>
                                                  _submitRating(_userRating),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: themeColor,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: _isSubmittingRating
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Text('Submit Rating'),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                  )
                                else
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 24.0),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          RatingBar.builder(
                                            initialRating: _userRating,
                                            minRating: 1,
                                            direction: Axis.horizontal,
                                            allowHalfRating: true,
                                            itemCount: 5,
                                            itemSize: 30,
                                            ignoreGestures: true,
                                            itemPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 2.0),
                                            itemBuilder: (context, _) =>
                                                const Icon(
                                              Icons.star,
                                              color: Color.fromARGB(
                                                  255, 255, 193, 7),
                                            ),
                                            onRatingUpdate: (rating) {},
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Your rating: ${_userRating.toStringAsFixed(1)}',
                                            style: const TextStyle(
                                              color: themeColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // Description
                                Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _product!['description'] ??
                                      'No description available.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: isDarkMode
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Specifications
                                Text(
                                  'Specifications',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildSpecificationItem(
                                    'Brand',
                                    _product!['brand'] ?? 'Unknown',
                                    isDarkMode),
                                _buildSpecificationItem(
                                    'Category',
                                    _product!['category_name'] ?? 'General',
                                    isDarkMode),
                                _buildSpecificationItem(
                                    'Weight',
                                    '${_product!['weight'] ?? 'N/A'} kg',
                                    isDarkMode),
                                _buildSpecificationItem(
                                    'In Stock',
                                    _product!['in_stock'] == true
                                        ? 'Yes'
                                        : 'No',
                                    isDarkMode),

                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
      bottomNavigationBar: _isLoading ||
              _errorMessage != null ||
              _product == null
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[850] : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Quantity selector
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _selectedQuantity > 1
                              ? () {
                                  setState(() {
                                    _selectedQuantity--;
                                  });
                                }
                              : null,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        Text(
                          '$_selectedQuantity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              _selectedQuantity++;
                            });
                          },
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Add to cart button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final price = _product!['discount_price'] != null
                            ? (_product!['discount_price'] as num).toDouble()
                            : (_product!['price'] as num).toDouble();

                        cartProvider.addToCart(
                          _product!['id'],
                          _product!['name'],
                          price,
                          _product!['image'] ?? '',
                          _selectedQuantity,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${_product!['name']} added to cart'),
                            action: SnackBarAction(
                              label: 'VIEW CART',
                              onPressed: () {
                                // Navigate to cart page
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CartPage(),
                                  ),
                                );
                              },
                            ),
                            backgroundColor: themeColor,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'ADD TO CART',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSpecificationItem(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
