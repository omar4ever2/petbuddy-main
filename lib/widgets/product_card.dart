import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/product_details_page.dart';

class ProductCard extends StatelessWidget {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final double? discountPrice;
  final double rating;

  const ProductCard({
    Key? key,
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.discountPrice,
    this.rating = 0.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isFavorite = favoritesProvider.isFavorite(id);
    final isInCart = cartProvider.isInCart(id);
    final isDarkMode = themeProvider.isDarkMode;
    const themeColor = Color.fromARGB(255, 40, 108, 100);
    const priceColor = Color.fromARGB(255, 40, 108, 100);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(productId: id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode 
                  ? Colors.black.withOpacity(0.3) 
                  : themeColor.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: isDarkMode 
                                    ? const Color(0xFF2A2A2A) 
                                    : const Color(0xFFF5F5F5),
                                child: Center(
                                  child: Icon(
                                    Icons.pets,
                                    color: themeColor,
                                    size: 48,
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: isDarkMode 
                                ? const Color(0xFF2A2A2A) 
                                : const Color(0xFFF5F5F5),
                            child: Center(
                              child: Icon(
                                Icons.pets,
                                color: themeColor,
                                size: 48,
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      if (isFavorite) {
                        favoritesProvider.removeFavorite(id);
                      } else {
                        favoritesProvider.addFavorite(id);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDarkMode 
                            ? const Color(0xFF2A2A2A) 
                            : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode 
                                ? Colors.black.withOpacity(0.3) 
                                : Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                if (discountPrice != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(((price - discountPrice!) / price) * 100).round()}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  if (rating > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (index) {
                            return Icon(
                              index < rating.floor() 
                                  ? Icons.star 
                                  : index < rating 
                                      ? Icons.star_half
                                      : Icons.star_border,
                              size: 12,
                              color: const Color.fromARGB(255, 255, 193, 7),
                            );
                          }),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (discountPrice != null) ...[
                              Text(
                                'LE ${price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              Text(
                                'LE ${discountPrice!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: priceColor,
                                ),
                              ),
                            ] else
                              Text(
                                'LE ${price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: priceColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (isInCart) {
                            cartProvider.removeFromCart(id);
                          } else {
                            cartProvider.addToCart(id, name, price, imageUrl, 1);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: isInCart
                                ? Colors.red.withOpacity(isDarkMode ? 0.2 : 0.1)
                                : themeColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isInCart ? Icons.remove_shopping_cart : Icons.add_shopping_cart,
                            color: isInCart ? Colors.red : themeColor,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
