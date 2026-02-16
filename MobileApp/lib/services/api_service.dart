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

  Future<User?> getUserByEmail(String email) async {
    final response = await http.post(
      Uri.parse(ApiConfig.userByEmailUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data == null) return null;
      return User.fromJson(data);
    } else {
      throw Exception('Failed to get user: ${response.body}');
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
}
