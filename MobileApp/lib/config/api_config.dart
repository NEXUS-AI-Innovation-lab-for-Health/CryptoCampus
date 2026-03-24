import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get webAppUrl => dotenv.env['WEB_APP_URL'] ?? 'http://127.0.0.1:80';
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:81';

  // Users endpoints
  static String get registerUrl => "$baseUrl/api/register";
  static String get usersUrl => "$baseUrl/api/users";
  static String userByIdUrl(String userId) => "$baseUrl/api/users/$userId";
  static String get loginUrl => "$baseUrl/api/login";

  // Blockchain endpoints
  static String get blockchainAccountsUrl => "$baseUrl/api/blockchain/accounts";
  static String blockchainBalanceUrl(String address) => "$baseUrl/api/blockchain/balance/$address";
  static String get blockchainTransactionUrl => "$baseUrl/api/blockchain/transaction";
  static String blockchainTransactionDetailUrl(String hash) => "$baseUrl/api/blockchain/transaction/$hash";

  // Listings endpoints
  static String get listingsUrl => "$baseUrl/api/listings";
  static String listingsSearchUrl(String query) => "$baseUrl/api/listings/search?q=$query";
  static String get analyzeCvUrl => "$baseUrl/api/analyze-cv";

  // Availability endpoints
  static String availabilityUrl({String? listingId}) =>
      listingId != null ? "$baseUrl/api/availability?listing_id=$listingId" : "$baseUrl/api/availability";
  static String get availabilityMineUrl => "$baseUrl/api/availability/mine";
  static String availabilityDeleteUrl(String slotId) => "$baseUrl/api/availability/$slotId";

  // Bookings endpoints
  static String get bookingsUrl => "$baseUrl/api/bookings";
  static String get tutorNotificationsUrl => "$baseUrl/api/tutor/notifications";
  static String get markNotificationsReadUrl => "$baseUrl/api/tutor/notifications/mark-read";
}
