import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:81';
  static String get webAppUrl => dotenv.env['WEB_APP_URL'] ?? 'http://10.0.2.2:80';

  // Users endpoints
  static String get registerUrl => '$baseUrl/users/register';
  static String get usersUrl => '$baseUrl/users';
  static String userByIdUrl(String userId) => '$baseUrl/users/$userId';
  static String get userByEmailUrl => '$baseUrl/users/by-email';

  // Blockchain endpoints
  static String get blockchainAccountsUrl => '$baseUrl/blockchain/accounts';
  static String blockchainBalanceUrl(String address) => '$baseUrl/blockchain/balance/$address';
  static String get blockchainTransactionUrl => '$baseUrl/blockchain/transaction';
  static String blockchainTransactionDetailUrl(String hash) => '$baseUrl/blockchain/transaction/$hash';

  // Listings endpoints
  static String get listingsUrl => '$baseUrl/listings';
  static String listingsSearchUrl(String query) => '$baseUrl/listings/search?q=$query';
  static String get analyzeCvUrl => '$baseUrl/analyze-cv';

  // Availability endpoints
  static String availabilityUrl({String? listingId}) =>
      listingId != null ? '$baseUrl/availability?listing_id=$listingId' : '$baseUrl/availability';
  static String get availabilityMineUrl => '$baseUrl/availability/mine';
  static String availabilityDeleteUrl(String slotId) => '$baseUrl/availability/$slotId';

  // Bookings endpoints
  static String get bookingsUrl => '$baseUrl/bookings';
}
