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
