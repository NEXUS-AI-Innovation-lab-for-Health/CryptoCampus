import 'package:flutter/material.dart';
import '../models/listing_model.dart';
import '../services/api_service.dart';

class ListingsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Listing> _listings = [];
  List<Listing> _filteredListings = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<Listing> get listings => _filteredListings.isEmpty && _searchQuery.isEmpty
      ? _listings
      : _filteredListings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  Future<void> loadListings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _listings = await _apiService.getAllListings();
      _filteredListings = [];
      _searchQuery = '';
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchListings(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      _filteredListings = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _filteredListings = await _apiService.searchListings(query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredListings = [];
    notifyListeners();
  }
}

/// Favoris/Intérêts de l'utilisateur connecté sur les annonces (parité Favorites.vue) —
/// provider séparé car ils ont un cycle de vie différent de la liste d'annonces elle-même.
class ListingEngagementProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final Set<int> _favoriteIds = {};
  final Set<int> _interestedIds = {};
  bool _loaded = false;

  bool isFavorite(int listingId) => _favoriteIds.contains(listingId);
  bool isInterested(int listingId) => _interestedIds.contains(listingId);
  Set<int> get favoriteIds => _favoriteIds;

  Future<void> load() async {
    try {
      final results = await Future.wait([
        _apiService.getFavoriteListingIds(),
        _apiService.getInterestedListingIds(),
      ]);
      _favoriteIds
        ..clear()
        ..addAll(results[0]);
      _interestedIds
        ..clear()
        ..addAll(results[1]);
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Erreur chargement favoris/intérêts: $e');
    }
  }

  Future<void> ensureLoaded() async {
    if (!_loaded) await load();
  }

  Future<void> toggleFavorite(int listingId) async {
    final wasFavorite = _favoriteIds.contains(listingId);
    // Optimiste : on met à jour l'UI tout de suite, puis on corrige si l'appel échoue.
    if (wasFavorite) {
      _favoriteIds.remove(listingId);
    } else {
      _favoriteIds.add(listingId);
    }
    notifyListeners();

    try {
      await _apiService.setFavorite(listingId, !wasFavorite);
    } catch (e) {
      if (wasFavorite) {
        _favoriteIds.add(listingId);
      } else {
        _favoriteIds.remove(listingId);
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleInterest(int listingId) async {
    final wasInterested = _interestedIds.contains(listingId);
    if (wasInterested) {
      _interestedIds.remove(listingId);
    } else {
      _interestedIds.add(listingId);
    }
    notifyListeners();

    try {
      await _apiService.setInterest(listingId, !wasInterested);
    } catch (e) {
      if (wasInterested) {
        _interestedIds.add(listingId);
      } else {
        _interestedIds.remove(listingId);
      }
      notifyListeners();
      rethrow;
    }
  }
}
