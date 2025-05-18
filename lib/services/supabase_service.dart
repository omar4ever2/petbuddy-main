import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' as io;

class SupabaseService with ChangeNotifier {
  final SupabaseClient _client;
  User? _user;
  Map<String, dynamic> _userData = {};
  final Map<String, double> _userRatings = {};

  SupabaseService(this._client) {
    _init();
  }

  // Initialize and set up auth state listener
  Future<void> _init() async {
    // Set up auth state change listener
    _client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn) {
        _user = session?.user;
        notifyListeners();
      } else if (event == AuthChangeEvent.signedOut) {
        _user = null;
        notifyListeners();
      }
    });

    // Get initial auth state
    final session = _client.auth.currentSession;
    _user = session?.user;
  }

  // Get current user
  User? get currentUser => _user;

  // Check if user is authenticated
  bool get isAuthenticated => _user != null;

  // Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      // Ensure we have a direct reference to Supabase
      final supabase = Supabase.instance.client;

      // Attempt signup with proper error handling
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: username != null ? {'username': username} : null,
      );

      if (response.user == null) {
        throw Exception('Signup failed: User is null. Check your credentials.');
      }

      _user = response.user;
      notifyListeners();
    } catch (e) {
      print('Signup error: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _user = response.user;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Fetch products from database
  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final response = await _client
          .from('products')
          .select("*")
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Fetch categories from database
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      // Use a simpler query first to debug
      final response = await _client.from('categories').select('*');

      if (response == null) {
        return [];
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Fetch featured products from database
  Future<List<Map<String, dynamic>>> getFeaturedProducts() async {
    try {
      print('Fetching featured products from Supabase...');

      // Use a simpler query first to debug
      final response =
          await _client.from('products').select('*').eq('is_featured', true);

      print('Featured products response raw: $response');

      if (response == null) {
        print('Featured products response is null');
        return [];
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching featured products: $e');
      return [];
    }
  }

  // Fetch products by category
  Future<List<Map<String, dynamic>>> getProductsByCategory(
      String categoryId) async {
    try {
      final response = await _client
          .from('products')
          .select('*, categories(name)')
          .eq('category_id', categoryId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Add product to favorites
  Future<void> addToFavorites(String productId) async {
    if (_user == null) {
      print('addToFavorites: User is null, cannot add to favorites');
      throw Exception('User not authenticated');
    }

    try {
      print(
          'addToFavorites: Adding product $productId to favorites for user ${_user!.id}');

      await _client.from('favorites').insert({
        'user_id': _user!.id,
        'product_id': productId,
      });

      print('addToFavorites: Successfully added product to favorites');
      notifyListeners();
    } catch (e) {
      print('Error in addToFavorites: $e');
      rethrow;
    }
  }

  // Remove product from favorites
  Future<void> removeFromFavorites(String productId) async {
    if (_user == null) {
      print('removeFromFavorites: User is null, cannot remove from favorites');
      throw Exception('User not authenticated');
    }

    try {
      print(
          'removeFromFavorites: Removing product $productId from favorites for user ${_user!.id}');

      final result = await _client
          .from('favorites')
          .delete()
          .eq('user_id', _user!.id)
          .eq('product_id', productId);

      print('removeFromFavorites: Successfully removed product from favorites');
      notifyListeners();
    } catch (e) {
      print('Error in removeFromFavorites: $e');
      rethrow;
    }
  }

  // Get user favorites
  Future<List<String>> getFavoriteIds() async {
    if (_user == null) {
      print('getFavoriteIds: User is null, returning empty list');
      return [];
    }

    try {
      print('getFavoriteIds: Fetching favorites for user ${_user!.id}');

      final response = await _client
          .from('favorites')
          .select('product_id')
          .eq('user_id', _user!.id);

      print('getFavoriteIds: Raw response: $response');

      if (response == null) {
        print('getFavoriteIds: Response is null');
        return [];
      }

      final ids = List<String>.from(
        response.map((item) => item['product_id'] as String),
      );

      print('getFavoriteIds: Parsed ${ids.length} favorite IDs: $ids');
      return ids;
    } catch (e) {
      print('Error in getFavoriteIds: $e');
      return [];
    }
  }

  // Get favorite products with details
  Future<List<Map<String, dynamic>>> getFavoriteProducts() async {
    if (_user == null) {
      print('getFavoriteProducts: User is null, returning empty list');
      return [];
    }

    try {
      print('getFavoriteProducts: Fetching favorites for user ${_user!.id}');

      // First approach: Join favorites with products in a single query
      final response = await _client
          .from('favorites')
          .select('product_id, products(*)')
          .eq('user_id', _user!.id);

      print('getFavoriteProducts: Raw response: $response');

      if (response == null || response.isEmpty) {
        print('getFavoriteProducts: No favorites found');
        return [];
      }

      // Extract the product data from the response
      final products = List<Map<String, dynamic>>.from(
        response.map((item) {
          final product = item['products'] as Map<String, dynamic>;
          // Ensure the image field is correctly mapped
          return {
            ...product,
            'image': product['image_url'] ?? product['image'],
          };
        }),
      );

      print('getFavoriteProducts: Returning ${products.length} products');
      return products;
    } catch (e) {
      print('Error in getFavoriteProducts: $e');

      // Fallback approach: Get IDs first, then fetch products individually
      try {
        // Get favorite product IDs
        final favoriteIds = await getFavoriteIds();

        if (favoriteIds.isEmpty) {
          print('getFavoriteProducts fallback: No favorite IDs found');
          return [];
        }

        print(
            'getFavoriteProducts fallback: Fetching products for IDs: $favoriteIds');

        // Fetch full product details for each favorite ID
        final productsResponse =
            await _client.from('products').select('*').in_('id', favoriteIds);

        print(
            'getFavoriteProducts fallback: Response length: ${productsResponse.length}');

        final products =
            List<Map<String, dynamic>>.from(productsResponse.map((product) {
          // Ensure the image field is correctly mapped
          return {
            ...product,
            'image': product['image_url'] ?? product['image'],
          };
        }));

        print(
            'getFavoriteProducts fallback: Returning ${products.length} products');
        return products;
      } catch (fallbackError) {
        print('Error in getFavoriteProducts fallback: $fallbackError');
        return [];
      }
    }
  }

  // Rate a product
  Future<void> rateProduct(String productId, double rating) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      // In a real implementation, this would update the rating in the database
      // For now, we'll store it in a local variable for demo purposes
      print('Product $productId rated: $rating by user ${_user!.id}');

      // Store the user's rating in our local map
      _userRatings[productId] = rating;

      // Return success
      return;
    } catch (e) {
      print('Error rating product: $e');
      throw Exception('Failed to submit rating: $e');
    }
  }

  // Get user's rating for a product
  Future<double?> getUserProductRating(String productId) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Return the user's rating for this product if it exists
    return _userRatings[productId];
  }

  // Search products
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .ilike('name', '%$query%')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Upload product image
  Future<String> uploadImage(String filePath, String fileName) async {
    try {
      final file = io.File(filePath);
      final bytes = await file.readAsBytes();

      final response = await _client.storage
          .from('product_images')
          .uploadBinary(fileName, bytes);

      return _client.storage.from('product_images').getPublicUrl(fileName);
    } catch (e) {
      rethrow;
    }
  }

  // Debug function to insert test data
  Future<void> insertTestData() async {
    try {
      // Insert test category
      final categoryResponse = await _client.from('categories').insert([
        {
          'name': 'Test Category',
          'description': 'Test description',
          'icon_name': 'pets',
        }
      ]).select();

      print('Inserted test category: $categoryResponse');

      if (categoryResponse != null && categoryResponse.isNotEmpty) {
        // Insert test product
        final productResponse = await _client.from('products').insert([
          {
            'name': 'Test Product',
            'description': 'Test product description',
            'price': 19.99,
            'stock_quantity': 10,
            'category_id': categoryResponse[0]['id'],
            'is_featured': true,
          }
        ]).select();

        print('Inserted test product: $productResponse');
      }
    } catch (e) {
      print('Error inserting test data: $e');
    }
  }

  // Fetch featured adoptable pets
  Future<List<Map<String, dynamic>>> getFeaturedAdoptablePets() async {
    try {
      print('Fetching featured adoptable pets from Supabase...');

      final response = await _client
          .from('adoptable_pets')
          .select('*')
          .eq('is_featured', true)
          .order('created_at', ascending: false);

      print('Featured adoptable pets response: $response');

      if (response == null) {
        print('Featured adoptable pets response is null');
        return [];
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching featured adoptable pets: $e');
      return [];
    }
  }

  // Fetch all adoptable pets
  Future<List<Map<String, dynamic>>> getAllAdoptablePets() async {
    try {
      final response = await _client
          .from('adoptable_pets')
          .select('*')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching all adoptable pets: $e');
      return [];
    }
  }

  // Fetch adoptable pets by species
  Future<List<Map<String, dynamic>>> getAdoptablePetsBySpecies(
      String species) async {
    try {
      final response = await _client
          .from('adoptable_pets')
          .select('*')
          .eq('species', species)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching adoptable pets by species: $e');
      return [];
    }
  }

  // Get user orders
  Future<List<Map<String, dynamic>>> getUserOrders() async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      // Use real Supabase query instead of mock data
      print('Getting orders for user ID: ${_user!.id}');

      final response = await _client
          .from('orders')
          .select('*, order_items(*)')
          .eq('user_id', _user!.id)
          .order('created_at', ascending: false);

      // Transform the response to ensure a consistent format with items array
      final transformedOrders =
          List<Map<String, dynamic>>.from(response).map((order) {
        // Extract order_items from the nested structure
        final orderItems = order['order_items'];

        // Remove the original nested structure
        order.remove('order_items');

        // Add items as a list, ensuring it's never null
        order['items'] = orderItems != null
            ? List<Map<String, dynamic>>.from(orderItems)
            : [];

        return order;
      }).toList();

      print(
          'Retrieved ${transformedOrders.length} orders for user ${_user!.id}');
      return transformedOrders;
    } catch (e) {
      print('Error getting user orders: $e');
      throw Exception('Failed to get user orders: $e');
    }
  }

  // Get user profile data
  Future<Map<String, dynamic>> getUserProfile() async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      // Use real Supabase query instead of mock data
      print('Getting user profile data for user ID: ${_user!.id}');

      final response = await _client
          .from('user_profiles')
          .select('*')
          .eq('id', _user!.id)
          .maybeSingle();

      if (response == null) {
        // If profile doesn't exist yet, return basic info - no email
        return {
          'id': _user!.id,
          'created_at': DateTime.now().toIso8601String(),
        };
      }

      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateUserProfile(
      Map<String, dynamic> data) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      // Add updated_at timestamp
      data['updated_at'] = DateTime.now().toIso8601String();

      // Check if profile already exists
      final existingProfile = await _client
          .from('user_profiles')
          .select()
          .eq('id', _user!.id)
          .maybeSingle();

      if (existingProfile == null) {
        // Create new profile with user ID
        data['id'] = _user!.id;

        final response =
            await _client.from('user_profiles').insert(data).select().single();

        return response;
      } else {
        // Update existing profile
        final response = await _client
            .from('user_profiles')
            .update(data)
            .eq('id', _user!.id)
            .select()
            .single();

        return response;
      }
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Upload profile image
  Future<String> uploadProfileImage(io.File imageFile) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final fileBytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName =
          '${_user!.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Upload the file to Supabase Storage
      final response = await _client.storage
          .from('avatars')
          .uploadBinary(fileName, fileBytes);

      // Get public URL for the uploaded image
      final imageUrl = _client.storage.from('avatars').getPublicUrl(fileName);

      // Update user profile with the new avatar URL
      await _client
          .from('user_profiles')
          .update({'avatar_url': imageUrl}).eq('id', _user!.id);

      return imageUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Refreshes the user data from Supabase
  Future<void> refreshUserData() async {
    if (!isAuthenticated) return;

    try {
      final userId = _client.auth.currentUser!.id;
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        // Update cached user data
        _userData = response;
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing user data: $e');
      rethrow;
    }
  }

  Future<void> createUserProfile(Map<String, dynamic> profileData) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final userId = _client.auth.currentUser!.id;

      // Check if profile already exists
      final existingProfile = await _client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      // Add timestamps
      profileData['updated_at'] = DateTime.now().toIso8601String();

      if (existingProfile != null) {
        // Update existing profile
        await _client
            .from('user_profiles')
            .update(profileData)
            .eq('id', userId);
      } else {
        // Create new profile with user ID and created_at
        profileData['id'] = userId;
        profileData['created_at'] = DateTime.now().toIso8601String();

        await _client.from('user_profiles').insert(profileData);
      }
    } catch (e) {
      print('Error creating user profile: $e');
      throw Exception('Failed to create user profile: $e');
    }
  }

  Future<bool> checkUserHasProfile() async {
    try {
      if (!isAuthenticated) return false;

      final userId = _client.auth.currentUser!.id;

      final profile = await _client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return profile != null;
    } catch (e) {
      print('Error checking user profile: $e');
      return false;
    }
  }

  // Get order tracking information
  Future<Map<String, dynamic>> getOrderTracking(String orderId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Using real Supabase query
      print('Getting tracking data for order ID: $orderId');

      final userId = _client.auth.currentUser!.id;

      final response = await _client
          .from('order_tracking')
          .select('*, tracking_updates(*)')
          .eq('order_id', orderId)
          .eq('user_id', userId)
          .single();

      return response;
    } catch (e) {
      print('Error getting order tracking: $e');
      throw Exception('Failed to get order tracking: $e');
    }
  }

  // Update order status which will trigger tracking updates
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final userId = _client.auth.currentUser!.id;

      // First verify user owns this order
      final order = await _client
          .from('orders')
          .select('id')
          .eq('id', orderId)
          .eq('user_id', userId)
          .single();

      if (order == null) {
        throw Exception('Order not found or access denied');
      }

      // Update order status
      await _client
          .from('orders')
          .update({'status': newStatus}).eq('id', orderId);

      print('Order status updated to $newStatus for order $orderId');
    } catch (e) {
      print('Error updating order status: $e');
      throw Exception('Failed to update order status: $e');
    }
  }

  // Add a custom tracking update
  Future<void> addTrackingUpdate(
      String orderId, String status, String description,
      {Map<String, double>? location}) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final userId = _client.auth.currentUser!.id;

      // Get the tracking ID
      final tracking = await _client
          .from('order_tracking')
          .select('id')
          .eq('order_id', orderId)
          .eq('user_id', userId)
          .single();

      if (tracking == null) {
        throw Exception('Tracking record not found');
      }

      // Create the tracking update
      await _client.from('tracking_updates').insert({
        'tracking_id': tracking['id'],
        'status': status,
        'description': description,
        'location': location,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Update the tracking last_updated field
      await _client
          .from('order_tracking')
          .update({'last_updated': DateTime.now().toIso8601String()}).eq(
              'id', tracking['id']);

      print('Added tracking update for order $orderId: $status');
    } catch (e) {
      print('Error adding tracking update: $e');
      throw Exception('Failed to add tracking update: $e');
    }
  }

  // Update current location of an order
  Future<void> updateOrderLocation(
      String orderId, double latitude, double longitude) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final userId = _client.auth.currentUser!.id;

      // Get the tracking ID
      final tracking = await _client
          .from('order_tracking')
          .select('id')
          .eq('order_id', orderId)
          .eq('user_id', userId)
          .single();

      if (tracking == null) {
        throw Exception('Tracking record not found');
      }

      // Update current location
      await _client.from('order_tracking').update({
        'current_location': {'latitude': latitude, 'longitude': longitude},
        'last_updated': DateTime.now().toIso8601String(),
      }).eq('id', tracking['id']);

      // Add a tracking update with location information
      await _client.from('tracking_updates').insert({
        'tracking_id': tracking['id'],
        'status': 'Location Updated',
        'description': 'The package location has been updated.',
        'location': {'latitude': latitude, 'longitude': longitude},
        'timestamp': DateTime.now().toIso8601String(),
      });

      print('Updated order location for $orderId');
    } catch (e) {
      print('Error updating order location: $e');
      throw Exception('Failed to update order location: $e');
    }
  }

  // Helper method to get a random status for demo purposes
  String _getRandomStatus(String orderId) {
    // Use the orderId to determine a consistent status
    final statusOptions = [
      'processing',
      'shipped',
      'out_for_delivery',
      'delivered',
    ];

    // Use the last character of the orderId to pick a status
    final lastChar = orderId.characters.last;
    final index = lastChar.codeUnitAt(0) % statusOptions.length;

    return statusOptions[index];
  }

  // Get upcoming vaccine appointments for the current user
  Future<List<Map<String, dynamic>>> getUpcomingVaccineAppointments() async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Using real Supabase query
      print('Getting upcoming vaccine appointments for user: ${_user!.id}');

      final userId = _client.auth.currentUser!.id;
      final now = DateTime.now().toIso8601String();

      final response = await _client
          .from('vaccine_appointments')
          .select()
          .eq('user_id', userId)
          .gte('appointment_date', now)
          .order('appointment_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting upcoming vaccine appointments: $e');
      return [];
    }
  }

  // Create a new vaccine appointment
  Future<Map<String, dynamic>> createVaccineAppointment(
      Map<String, dynamic> appointmentData) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Using real Supabase query
      print('Creating vaccine appointment with data: $appointmentData');

      final userId = _client.auth.currentUser!.id;

      final data = {
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending',
        ...appointmentData,
      };

      final response = await _client
          .from('vaccine_appointments')
          .insert(data)
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error creating vaccine appointment: $e');
      throw Exception('Failed to create vaccine appointment: $e');
    }
  }

  // Cancel a vaccine appointment
  Future<void> cancelVaccineAppointment(String appointmentId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Using real Supabase query
      print('Cancelling vaccine appointment with ID: $appointmentId');

      final userId = _client.auth.currentUser!.id;

      await _client
          .from('vaccine_appointments')
          .update({'status': 'cancelled'})
          .eq('id', appointmentId)
          .eq('user_id', userId);
    } catch (e) {
      print('Error cancelling vaccine appointment: $e');
      throw Exception('Failed to cancel vaccine appointment: $e');
    }
  }

  // Get available vaccine types
  Future<List<Map<String, dynamic>>> getVaccineTypes() async {
    try {
      // Using real Supabase query
      print('Getting vaccine types');

      final response = await _client
          .from('vaccine_types')
          .select()
          .order('name', ascending: true);

      // Convert to list and ensure no duplicates by name
      final vaccineList = List<Map<String, dynamic>>.from(response);
      final uniqueVaccines = <String>{};

      return vaccineList.where((vaccine) {
        final name = vaccine['name'] as String;
        final isUnique = !uniqueVaccines.contains(name);
        if (isUnique) {
          uniqueVaccines.add(name);
        }
        return isUnique;
      }).toList();
    } catch (e) {
      print('Error getting vaccine types: $e');
      // Return some default vaccine types if there's an error
      return [
        {
          'id': '1',
          'name': 'Rabies',
          'description': 'Protection against rabies virus'
        },
        {
          'id': '2',
          'name': 'Distemper',
          'description': 'Protection against canine distemper'
        },
        {
          'id': '3',
          'name': 'Parvovirus',
          'description': 'Protection against parvovirus'
        },
        {
          'id': '4',
          'name': 'Bordetella',
          'description': 'Protection against kennel cough'
        },
        {
          'id': '5',
          'name': 'Leptospirosis',
          'description': 'Protection against leptospirosis'
        },
      ];
    }
  }

  // Create a new order
  Future<Map<String, dynamic>> createOrder(
      Map<String, dynamic> orderData) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      print('Creating order with data: $orderData');

      final userId = _client.auth.currentUser!.id;

      // Add user ID to order data
      orderData['user_id'] = userId;

      // Add created_at timestamp if not present
      if (!orderData.containsKey('created_at')) {
        orderData['created_at'] = DateTime.now().toIso8601String();
      }

      // Ensure we have the items list
      if (!orderData.containsKey('items') ||
          (orderData['items'] as List).isEmpty) {
        throw Exception('Order must contain at least one item');
      }

      // Extract items to be inserted separately
      final items = List<Map<String, dynamic>>.from(orderData['items'] as List);

      // Remove items from the order data as they go in a separate table
      orderData.remove('items');

      // Insert order into orders table
      final orderResponse =
          await _client.from('orders').insert(orderData).select().single();

      print('Order created with ID: ${orderResponse['id']}');

      // Get order ID
      final orderId = orderResponse['id'];

      // Insert order items
      for (var item in items) {
        item['order_id'] = orderId;
        await _client.from('order_items').insert(item);
      }

      print('Added ${items.length} items to order $orderId');

      // Fetch the complete order with items
      final completeOrder = await _client
          .from('orders')
          .select('*, order_items(*)')
          .eq('id', orderId)
          .single();

      // Transform the order to ensure a consistent format
      final transformedOrder = Map<String, dynamic>.from(completeOrder);

      // Extract order items from the nested structure
      final orderItems = transformedOrder['order_items'];

      // Remove the nested structure
      transformedOrder.remove('order_items');

      // Add items as a list, ensuring it's never null
      transformedOrder['items'] =
          orderItems != null ? List<Map<String, dynamic>>.from(orderItems) : [];

      return transformedOrder;
    } catch (e) {
      print('Error creating order: $e');
      throw Exception('Failed to create order: $e');
    }
  }

  // Get user pets
  Future<List<Map<String, dynamic>>> getUserPets() async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      // Use real Supabase query
      print('Getting pets for user ID: ${_user!.id}');

      final response = await _client
          .from('pets')
          .select('*')
          .eq('user_id', _user!.id)
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting user pets: $e');
      throw Exception('Failed to get user pets: $e');
    }
  }

  // Add a new pet
  Future<Map<String, dynamic>> addPet(Map<String, dynamic> petData) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      // Add user ID
      petData['user_id'] = _user!.id;

      // Add timestamps
      final now = DateTime.now().toIso8601String();
      petData['created_at'] = now;
      petData['updated_at'] = now;

      // Insert pet into pets table
      final response =
          await _client.from('pets').insert(petData).select().single();

      return response;
    } catch (e) {
      print('Error adding pet: $e');
      throw Exception('Failed to add pet: $e');
    }
  }

  // Update a pet
  Future<Map<String, dynamic>> updatePet(
      String petId, Map<String, dynamic> petData) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      // Add updated_at timestamp
      petData['updated_at'] = DateTime.now().toIso8601String();

      // Update pet in pets table
      final response = await _client
          .from('pets')
          .update(petData)
          .eq('id', petId)
          .eq('user_id', _user!.id)
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error updating pet: $e');
      throw Exception('Failed to update pet: $e');
    }
  }

  // Delete a pet
  Future<void> deletePet(String petId) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      await _client
          .from('pets')
          .delete()
          .eq('id', petId)
          .eq('user_id', _user!.id);
    } catch (e) {
      print('Error deleting pet: $e');
      throw Exception('Failed to delete pet: $e');
    }
  }

  // Get product by ID
  Future<Map<String, dynamic>> getProductById(String id) async {
    try {
      print('Getting product with ID: $id');

      final response = await _client
          .from('products')
          .select('*, categories(*)')
          .eq('id', id)
          .single();

      return response;
    } catch (e) {
      print('Error getting product details: $e');
      throw Exception('Failed to load product details: $e');
    }
  }

  // Get adoptable pet by ID
  Future<Map<String, dynamic>> getAdoptablePetById(String id) async {
    try {
      print('Getting adoptable pet with ID: $id');

      final response = await _client
          .from('adoptable_pets')
          .select('*')
          .eq('id', id)
          .single();

      return response;
    } catch (e) {
      print('Error getting adoptable pet details: $e');
      throw Exception('Failed to load adoptable pet details: $e');
    }
  }

  // Get all vaccine appointments for the current user
  Future<List<Map<String, dynamic>>> getAllVaccineAppointments() async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      print('Getting all vaccine appointments for user: ${_user!.id}');

      final userId = _client.auth.currentUser!.id;

      final response = await _client
          .from('vaccine_appointments')
          .select()
          .eq('user_id', userId)
          .order('appointment_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting all vaccine appointments: $e');
      return [];
    }
  }

  // Get available pet walkers
  Future<List<Map<String, dynamic>>> getAvailablePetWalkers() async {
    try {
      print('Getting available pet walkers');

      final response = await _client
          .from('pet_walkers')
          .select('*')
          .eq('is_available', true)
          .order('rating', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting pet walkers: $e');
      return [];
    }
  }

  // Get pet walker details
  Future<Map<String, dynamic>> getPetWalkerDetails(String walkerId) async {
    try {
      print('Getting details for walker ID: $walkerId');

      final response = await _client
          .from('pet_walkers')
          .select('*')
          .eq('id', walkerId)
          .single();

      return response;
    } catch (e) {
      print('Error getting walker details: $e');
      throw Exception('Failed to load walker details: $e');
    }
  }

  // Schedule a pet walk
  Future<Map<String, dynamic>> schedulePetWalk(
      Map<String, dynamic> walkData) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      print('Scheduling pet walk with data: $walkData');

      // Add user ID and timestamp
      walkData['user_id'] = _user!.id;
      walkData['created_at'] = DateTime.now().toIso8601String();
      walkData['status'] = 'pending';

      final response =
          await _client.from('pet_walks').insert(walkData).select().single();

      return response;
    } catch (e) {
      print('Error scheduling pet walk: $e');
      throw Exception('Failed to schedule pet walk: $e');
    }
  }

  // Get user's pet walks
  Future<List<Map<String, dynamic>>> getUserPetWalks() async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      print('Getting pet walks for user: ${_user!.id}');

      final response = await _client
          .from('pet_walks')
          .select('*, pet_walkers(*)')
          .eq('user_id', _user!.id)
          .order('walk_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting pet walks: $e');
      return [];
    }
  }

  // Cancel a pet walk
  Future<void> cancelPetWalk(String walkId) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      print('Cancelling pet walk with ID: $walkId');

      await _client
          .from('pet_walks')
          .update({'status': 'cancelled'})
          .eq('id', walkId)
          .eq('user_id', _user!.id);
    } catch (e) {
      print('Error cancelling pet walk: $e');
      throw Exception('Failed to cancel pet walk: $e');
    }
  }

  // Rate a pet walker
  Future<void> ratePetWalker(
      String walkerId, double rating, String walkId) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      print('Rating pet walker $walkerId with rating: $rating');

      // Create/update the rating in the ratings table
      await _client.from('walker_ratings').upsert({
        'walker_id': walkerId,
        'user_id': _user!.id,
        'rating': rating,
        'walk_id': walkId,
        'created_at': DateTime.now().toIso8601String()
      });

      // Update the walk with the rating
      await _client
          .from('pet_walks')
          .update({'walker_rating': rating})
          .eq('id', walkId)
          .eq('user_id', _user!.id);

      // Calculate average rating and update the pet walker
      final ratingResponse = await _client
          .from('walker_ratings')
          .select('rating')
          .eq('walker_id', walkerId);

      if (ratingResponse != null && ratingResponse.isNotEmpty) {
        final ratings = List<double>.from(
            ratingResponse.map((r) => (r['rating'] as num).toDouble()));
        final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;

        await _client
            .from('pet_walkers')
            .update({'rating': averageRating}).eq('id', walkerId);
      }
    } catch (e) {
      print('Error rating pet walker: $e');
      throw Exception('Failed to rate pet walker: $e');
    }
  }

  // Get pet walker availability for a specific date
  Future<List<Map<String, dynamic>>> getPetWalkerAvailability(
      String walkerId, String date) async {
    try {
      print('Getting availability for walker $walkerId on date: $date');

      final response = await _client
          .from('walker_availability')
          .select('*')
          .eq('walker_id', walkerId)
          .eq('date', date)
          .order('start_time', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting walker availability: $e');
      return [];
    }
  }
}
