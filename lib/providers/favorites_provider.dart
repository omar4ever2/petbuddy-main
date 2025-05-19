import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class FavoritesProvider with ChangeNotifier {
  final List<String> _favoriteIds = [];
  bool _isInitialized = false;
  SupabaseService? _supabaseService;

  List<String> get favoriteIds => [..._favoriteIds];

  int get favoriteCount => _favoriteIds.length;

  // Initialize with Supabase service
  Future<void> initialize(SupabaseService supabaseService) async {
    print('FavoritesProvider: Initializing with SupabaseService');
    _supabaseService = supabaseService;

    // Only fetch favorites if user is authenticated
    if (supabaseService.isAuthenticated) {
      print('FavoritesProvider: User is authenticated, refreshing favorites');
      await refreshFavorites();
      _isInitialized = true;
      print(
          'FavoritesProvider: Initialization complete, favorites count: ${_favoriteIds.length}');
    } else {
      // Clear any existing favorites if user is not authenticated
      print('FavoritesProvider: User is not authenticated, clearing favorites');
      _favoriteIds.clear();
      notifyListeners();
    }

    // Listen for auth state changes
    supabaseService.addListener(() {
      print(
          'FavoritesProvider: Auth state changed, authenticated: ${supabaseService.isAuthenticated}');
      if (supabaseService.isAuthenticated) {
        // User logged in, refresh favorites
        if (!_isInitialized) {
          print('FavoritesProvider: User logged in, refreshing favorites');
          refreshFavorites();
          _isInitialized = true;
        }
      } else {
        // User logged out, clear favorites
        print('FavoritesProvider: User logged out, clearing favorites');
        _favoriteIds.clear();
        _isInitialized = false;
        notifyListeners();
      }
    });
  }

  bool isFavorite(String id) {
    return _favoriteIds.contains(id);
  }

  Future<void> addFavorite(String id) async {
    if (!_favoriteIds.contains(id)) {
      print('FavoritesProvider: Adding product $id to favorites');

      // Sync with Supabase if authenticated
      if (_supabaseService != null && _supabaseService!.isAuthenticated) {
        try {
          await _supabaseService!.addToFavorites(id);
          // Only add to local list after successful Supabase operation
          _favoriteIds.add(id);
          notifyListeners();
          print('FavoritesProvider: Added product $id to favorites');
        } catch (e) {
          print('FavoritesProvider: Error adding favorite: $e');
          // Notify error through SnackBar or other means
          rethrow;
        }
      } else {
        print('FavoritesProvider: Not authenticated, adding only locally');
        _favoriteIds.add(id);
        notifyListeners();
      }
    } else {
      print('FavoritesProvider: Product $id is already in favorites');
    }
  }

  Future<void> removeFavorite(String id) async {
    if (_favoriteIds.contains(id)) {
      print('FavoritesProvider: Removing product $id from favorites');

      // Sync with Supabase if authenticated
      if (_supabaseService != null && _supabaseService!.isAuthenticated) {
        try {
          await _supabaseService!.removeFromFavorites(id);
          // Only remove from local list after successful Supabase operation
          _favoriteIds.remove(id);
          notifyListeners();
          print('FavoritesProvider: Removed product $id from favorites');
        } catch (e) {
          print('FavoritesProvider: Error removing favorite: $e');
          // Notify error through SnackBar or other means
          rethrow;
        }
      } else {
        print('FavoritesProvider: Not authenticated, removing only locally');
        _favoriteIds.remove(id);
        notifyListeners();
      }
    } else {
      print('FavoritesProvider: Product $id is not in favorites');
    }
  }

  Future<void> toggleFavorite(String id) async {
    if (_favoriteIds.contains(id)) {
      await removeFavorite(id);
    } else {
      await addFavorite(id);
    }
  }

  Future<void> clearFavorites() async {
    final oldFavorites = [..._favoriteIds];
    _favoriteIds.clear();
    notifyListeners();

    // Sync with Supabase if authenticated
    if (_supabaseService != null && _supabaseService!.isAuthenticated) {
      try {
        for (final id in oldFavorites) {
          await _supabaseService!.removeFromFavorites(id);
        }
      } catch (e) {
        // Revert on error
        _favoriteIds.addAll(oldFavorites);
        notifyListeners();
        debugPrint('Error clearing favorites: $e');
      }
    }
  }

  // Refresh favorites from Supabase
  Future<void> refreshFavorites() async {
    if (_supabaseService != null && _supabaseService!.isAuthenticated) {
      print('FavoritesProvider: Refreshing favorites from Supabase');
      try {
        final favIds = await _supabaseService!.getFavoriteIds();
        print(
            'FavoritesProvider: Got ${favIds.length} favorite IDs from Supabase');
        _favoriteIds.clear();
        _favoriteIds.addAll(favIds);
        print('FavoritesProvider: Updated favorite IDs: $_favoriteIds');
        notifyListeners();
      } catch (e) {
        print('FavoritesProvider: Error refreshing favorites: $e');
      }
    } else {
      print(
          'FavoritesProvider: Cannot refresh favorites, not authenticated or service is null');
    }
  }
}
