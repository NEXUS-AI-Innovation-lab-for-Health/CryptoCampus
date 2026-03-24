import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/listing_model.dart';
import '../models/blockchain_account_model.dart';

class ApiService {
  // ==================== USER ENDPOINTS ====================
  
  Future<User> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String role = 'STUDENT',
  }) async {
    print('📡 Tentative d\'inscription vers: ${ApiConfig.registerUrl}');
    
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'role': role,
        }),
      );

      print('📡 Status: ${response.statusCode}');
      print('📡 Body: ${response.body}');

      if (response.statusCode == 201) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to register: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur HTTP: $e');
      rethrow;
    }
  }

    Future<User?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiConfig.loginUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}), // Envoi email + mdp
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // The login API returns { userId, email, firstName, lastName }
      // But the User.fromJson expects { user_id, email, first_name, last_name, role, created_at, ... }
      // We need to map the fields correctly from the login payload to match standard user json format
      return User.fromJson({
        'user_id': data['userId'] ?? data['user_id'],
        'email': data['email'],
        'first_name': data['firstName'] ?? data['first_name'] ?? '',
        'last_name': data['lastName'] ?? data['last_name'] ?? '',
        'role': data['role'] ?? 'STUDENT',
        'is_verified': data['is_verified'] ?? true,
        'created_at': data['created_at'] ?? DateTime.now().toIso8601String(),
        'last_login': data['last_login'] ?? DateTime.now().toIso8601String(),
      });
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<User> getUserById(String userId) async {
    final response = await http.get(
      Uri.parse(ApiConfig.userByIdUrl(userId)),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get user: ${response.body}');
    }
  }

  Future<List<User>> getAllUsers() async {
    final response = await http.get(
      Uri.parse(ApiConfig.usersUrl),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get users: ${response.body}');
    }
  }

  // ==================== BLOCKCHAIN ENDPOINTS ====================

  Future<List<BlockchainAccount>> getBlockchainAccounts() async {
    final response = await http.get(
      Uri.parse(ApiConfig.blockchainAccountsUrl),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final List<dynamic> data = responseData['accounts'];
      return data.map((json) => BlockchainAccount.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get accounts: ${response.body}');
    }
  }

  Future<double> getBalance(String address) async {
    final response = await http.get(
      Uri.parse(ApiConfig.blockchainBalanceUrl(address)),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return double.parse(data['balance'].toString());
    } else {
      throw Exception('Failed to get balance: ${response.body}');
    }
  }

  Future<Transaction> sendTransaction({
    required String fromAddress,
    required String toAddress,
    required double amount,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.blockchainTransactionUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fromAddress': fromAddress,
        'toAddress': toAddress,
        'amount': amount,
      }),
    );

    if (response.statusCode == 200) {
      return Transaction.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to send transaction: ${response.body}');
    }
  }

  Future<Transaction> getTransactionDetails(String hash) async {
    final response = await http.get(
      Uri.parse(ApiConfig.blockchainTransactionDetailUrl(hash)),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Transaction.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get transaction: ${response.body}');
    }
  }

  // ==================== LISTINGS ENDPOINTS ====================

  Future<List<Listing>> getAllListings() async {
    final response = await http.get(
      Uri.parse(ApiConfig.listingsUrl),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final List<dynamic> data = responseData['listings'];
      return data.map((json) => Listing.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get listings: ${response.body}');
    }
  }

  Future<List<Listing>> searchListings(String query) async {
    final response = await http.get(
      Uri.parse(ApiConfig.listingsSearchUrl(query)),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final List<dynamic> data = responseData['results'];
      return data.map((json) => Listing.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search listings: ${response.body}');
    }
  }

  Future<Listing> createListing({
    required String title,
    required String description,
    required String subject,
    required String level,
    required double price,
    required String tutorName,
  }) async {
    print('📡 Tentative de création d\'annonce vers: ${ApiConfig.listingsUrl}');
    
    final response = await http.post(
      Uri.parse(ApiConfig.listingsUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': description,
        'subject': subject,
        'level': level,
        'price': price,
        'tutor_name': tutorName,
      }),
    );

    print('📡 Status: ${response.statusCode}');
    print('📡 Response: ${response.body}');

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return Listing.fromJson(responseData['listing']);
    } else {
      throw Exception('Failed to create listing: ${response.body}');
    }
  }

  // ==================== BOOKINGS ENDPOINTS ====================
  
  Future<List<Map<String, dynamic>>> getBookings(String userId) async {
    final uri = Uri.parse('${ApiConfig.bookingsUrl}?user_id=$userId');
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to get bookings: ${response.body}');
    }
  }

  // ==================== NOTIFICATIONS ENDPOINTS ====================

  Future<List<Map<String, dynamic>>> checkTutorNotifications(String userId, String email) async {
    final uri = Uri.parse('${ApiConfig.tutorNotificationsUrl}?user_id=$userId&tutor_email=$email');
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to get notifications: ${response.body}');
    }
  }

  Future<void> markNotificationsRead(List<String> bookingIds) async {
    final response = await http.put(
      Uri.parse(ApiConfig.markNotificationsReadUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'booking_ids': bookingIds}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notifications as read: ${response.body}');
    }
  }
}
