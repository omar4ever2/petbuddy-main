import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/product_details_page.dart';
import '../utils/theme_utils.dart';

class ProductCard extends StatefulWidget {
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
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: ThemeUtils.animationDurationFast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isFavorite = favoritesProvider.isFavorite(widget.id);
    final isInCart = cartProvider.isInCart(widget.id);
    final isDarkMode = themeProvider.isDarkMode;
    const themeColor = ThemeUtils.themeColor;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(productId: widget.id),
          ),
        );
      },
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? ThemeUtils.cardColor(isDarkMode) : Colors.white,
            borderRadius: BorderRadius.circular(ThemeUtils.borderRadiusLarge),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.08),
                spreadRadius: 0,
                blurRadius: 8,
                offset: const Offset(0, 3),
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
                      topLeft: Radius.circular(ThemeUtils.borderRadiusLarge),
                      topRight: Radius.circular(ThemeUtils.borderRadiusLarge),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: widget.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: isDarkMode
                                    ? const Color(0xFF2A2A2A)
                                    : const Color(0xFFF5F5F5),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: themeColor,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: isDarkMode
                                    ? const Color(0xFF2A2A2A)
                                    : const Color(0xFFF5F5F5),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.pets,
                                        color: themeColor,
                                        size: 40,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Image not available',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: ThemeUtils.secondaryTextColor(
                                              isDarkMode),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: isDarkMode
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFFF5F5F5),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.pets,
                                      color: themeColor,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'No image',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: ThemeUtils.secondaryTextColor(
                                            isDarkMode),
                                      ),
                                    ),
                                  ],
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
                          favoritesProvider.removeFavorite(widget.id);
                        } else {
                          favoritesProvider.addFavorite(widget.id);
                        }
                      },
                      child: AnimatedContainer(
                        duration: ThemeUtils.animationDuration,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isFavorite
                              ? Colors.red.withOpacity(0.9)
                              : (isDarkMode
                                  ? const Color(0xFF2A2A2A).withOpacity(0.8)
                                  : Colors.white.withOpacity(0.8)),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 0,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite
                              ? Colors.white
                              : (isDarkMode ? Colors.white : Colors.grey[600]),
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  if (widget.discountPrice != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeUtils.secondaryColor,
                          borderRadius: BorderRadius.circular(
                              ThemeUtils.borderRadiusMedium),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 0,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${(((widget.price - widget.discountPrice!) / widget.price) * 100).round()}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ThemeUtils.textColor(isDarkMode),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (widget.rating > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < widget.rating.floor()
                                      ? Icons.star
                                      : index < widget.rating
                                          ? Icons.star_half
                                          : Icons.star_border,
                                  size: 10,
                                  color: const Color(0xFFFFC107),
                                );
                              }),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              widget.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color:
                                    ThemeUtils.secondaryTextColor(isDarkMode),
                              ),
                            ),
                          ],
                        ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.discountPrice != null) ...[
                                    Text(
                                      'EGP ${widget.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: ThemeUtils.secondaryTextColor(
                                            isDarkMode),
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    Text(
                                      'EGP ${widget.discountPrice!.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: themeColor,
                                      ),
                                    ),
                                  ] else
                                    Text(
                                      'EGP ${widget.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: themeColor,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (isInCart) {
                                  cartProvider.removeFromCart(widget.id);
                                } else {
                                  cartProvider.addToCart(
                                      widget.id,
                                      widget.name,
                                      widget.discountPrice ?? widget.price,
                                      widget.imageUrl,
                                      1);
                                }
                              },
                              child: AnimatedContainer(
                                duration: ThemeUtils.animationDuration,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isInCart
                                      ? themeColor
                                      : themeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      ThemeUtils.borderRadiusMedium),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                child: Icon(
                                  isInCart
                                      ? Icons.shopping_cart
                                      : Icons.add_shopping_cart_outlined,
                                  size: 14,
                                  color: isInCart ? Colors.white : themeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
