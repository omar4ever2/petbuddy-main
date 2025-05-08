import 'package:flutter/material.dart';
import '../widgets/product_card.dart';
import '../widgets/category_item.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/theme_provider.dart';
import '../services/supabase_service.dart';
import '../screens/cart_page.dart';
import '../screens/categories_page.dart';
import '../screens/favorites_page.dart';
import '../screens/search_page.dart';
import '../screens/profile_page.dart';
import '../screens/adoptions_page.dart';
import '../models/adoptable_pet.dart';
import '../widgets/adoptable_pet_card.dart';
import '../widgets/vaccine_section.dart';
import '../screens/vaccine_booking_page.dart';
import '../utils/theme_utils.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../screens/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _featuredProducts = [];
  String? _errorMessage;

  // Define the theme color
  final Color themeColor = ThemeUtils.themeColor;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);

      // Debug print to check if service is available
      print('Fetching categories and products from Supabase...');

      final categories = await supabaseService.getCategories();
      print('Categories fetched: ${categories.length}');

      final featuredProducts = await supabaseService.getFeaturedProducts();
      print('Featured products fetched: ${featuredProducts.length}');

      // Debug print to see what data we got
      if (categories.isNotEmpty) {
        print('First category: ${categories[0]}');
      }

      if (featuredProducts.isNotEmpty) {
        print('First product: ${featuredProducts[0]}');
      }

      setState(() {
        _categories = categories;
        _featuredProducts = featuredProducts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: ThemeUtils.backgroundColor(isDarkMode),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: _isLoading
                  ? Center(
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
                                color: Colors.red[400],
                                size: 70,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Something went wrong',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: ThemeUtils.textColor(isDarkMode),
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: ThemeUtils.secondaryTextColor(isDarkMode),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _loadData,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Try Again'),
                                style: ThemeUtils.primaryButtonStyle(),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: themeColor,
                          onRefresh: _loadData,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  _buildWelcomeSection(context),
                                  const SizedBox(height: 24),
                                  _buildCategories(),
                                  const SizedBox(height: 24),
                                  _buildFeaturedProducts(),
                                  const SizedBox(height: 24),
                                  const VaccineSection(),
                                  const SizedBox(height: 24),
                                  _buildAdoptablePetsSection(),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ThemeUtils.cardColor(isDarkMode),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.1) 
                : Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search, 
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600], 
                        size: 20
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Search for pets and supplies...',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600], 
                          fontSize: 14
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.shopping_cart_outlined,
                    color: themeColor,
                    size: 24,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CartPage(),
                      ),
                    );
                  },
                ),
                if (cartProvider.itemCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red[400],
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cartProvider.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.favorite_border_outlined,
                color: themeColor,
                size: 24,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FavoritesPage(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: themeColor,
                size: 24,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
              tooltip: 'Settings',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final supabaseService = Provider.of<SupabaseService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final username =
        supabaseService.currentUser?.userMetadata?['username'] as String? ??
            'Pet Lover';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [themeColor, themeColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? themeColor.withOpacity(0.4) 
                : themeColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $username!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Find everything your pet needs',
            style: TextStyle(
              fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pets,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode 
                      ? Colors.black.withOpacity(0.2) 
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_basket,
                  color: themeColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Start Buying Your Pet Supplies',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: themeColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Categories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ThemeUtils.textColor(isDarkMode),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CategoriesPage()),
                );
              },
              icon: Text(
                'See All',
                style: TextStyle(
                  fontSize: 14,
                  color: themeColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              label: Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: themeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: ThemeUtils.cardColor(isDarkMode),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDarkMode 
                    ? Colors.black.withOpacity(0.2) 
                    : Colors.grey.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: _categories.isEmpty
              ? Center(
                  child: Text(
                    'No categories found',
                    style: TextStyle(color: ThemeUtils.secondaryTextColor(isDarkMode)),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return CategoryItem(
                      id: category['id'],
                      icon: _getCategoryIcon(category['icon_name']),
                      title: category['name'],
                      color: themeColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoriesPage(
                              categoryId: category['id'],
                              categoryName: category['name'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'pets':
        return FontAwesomeIcons.dog;
      case 'content_cut':
        return FontAwesomeIcons.cat;
      case 'front_hand':
        return FontAwesomeIcons.crow;
      case 'water':
        return FontAwesomeIcons.fish;
      case 'home':
        return FontAwesomeIcons.otter;
      default:
        return FontAwesomeIcons.s;
    }
  }

  Widget _buildFeaturedProducts() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured Products',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ThemeUtils.textColor(isDarkMode),
              ),
            ),
            GestureDetector(
              onTap: () {
                // Navigate to all products page
              },
              child: Text(
                'See All',
                style: TextStyle(
                  fontSize: 14,
                  color: themeColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _featuredProducts.isEmpty
            ? Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No featured products found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _featuredProducts.length,
                itemBuilder: (context, index) {
                  final product = _featuredProducts[index];
                  return ProductCard(
                    id: product['id'],
                    name: product['name'],
                    price: (product['price'] as num).toDouble(),
                    imageUrl: product['image'] ?? '',
                    discountPrice: product['discount_price'] != null
                        ? (product['discount_price'] as num).toDouble()
                        : null,
                    rating: product['average_rating'] != null
                        ? (product['average_rating'] as num).toDouble()
                        : 0.0,
                  );
                },
              ),
      ],
    );
  }

  Widget _buildAdoptablePetsSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pets for Adoption',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ThemeUtils.textColor(isDarkMode),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdoptionsPage()),
                );
              },
              child: Text(
                'See All',
                style: TextStyle(
                  fontSize: 14,
                  color: themeColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: Provider.of<SupabaseService>(context, listen: false)
              .getFeaturedAdoptablePets(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(
                    color: themeColor,
                    strokeWidth: 3,
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Container(
                height: 190,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: ThemeUtils.cardColor(isDarkMode),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode 
                          ? Colors.black.withOpacity(0.2) 
                          : Colors.grey.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 40,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(color: ThemeUtils.secondaryTextColor(isDarkMode)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                height: 190,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: ThemeUtils.cardColor(isDarkMode),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode 
                          ? Colors.black.withOpacity(0.2) 
                          : Colors.grey.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pets,
                        size: 40,
                        color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No pets available for adoption',
                        style: TextStyle(color: ThemeUtils.secondaryTextColor(isDarkMode)),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              final pets = snapshot.data!
                  .map((data) => AdoptablePet.fromJson(data))
                  .toList();

              return Container(
                height: 210,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: pets.length,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: 16,
                        left: index == 0 ? 4 : 0,
                      ),
                      child: AdoptablePetCard(
                        pet: pets[index],
                      ),
                    );
                  },
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Builder(
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: ThemeUtils.cardColor(isDarkMode),
          boxShadow: [
            BoxShadow(
              color: isDarkMode 
                  ? Colors.black.withOpacity(0.3) 
                  : Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            backgroundColor: ThemeUtils.cardColor(isDarkMode),
            selectedItemColor: themeColor,
            unselectedItemColor: isDarkMode ? Colors.grey[500] : Colors.grey,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.category_outlined),
                activeIcon: Icon(Icons.category),
                label: 'Categories',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.vaccines_outlined),
                activeIcon: Icon(Icons.vaccines),
                label: 'Vaccines',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.pets_outlined),
                activeIcon: Icon(Icons.pets),
                label: 'Adoptions',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: 0,
            onTap: (index) {
              if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CategoriesPage()),
                );
              } else if (index == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const VaccineBookingPage()),
                );
              } else if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdoptionsPage()),
                );
              } else if (index == 4) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
