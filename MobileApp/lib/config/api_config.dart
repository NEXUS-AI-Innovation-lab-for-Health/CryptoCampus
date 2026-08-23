import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get webAppUrl => dotenv.env['WEB_APP_URL'] ?? 'http://127.0.0.1:80';
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:81';

  // Auth endpoints
  static String get registerUrl => "$baseUrl/api/register";
  static String get loginUrl => "$baseUrl/api/login";
  static String get logoutUrl => "$baseUrl/api/logout";
  static String get checkAuthUrl => "$baseUrl/api/check-auth";
  static String get accountUrl => "$baseUrl/api/account";

  // Users endpoints
  static String get usersUrl => "$baseUrl/api/users";
  static String userByIdUrl(String userId) => "$baseUrl/api/users/$userId";

  // Profile endpoints
  static String get profileUrl => "$baseUrl/api/profile";
  static String get resetPasswordUrl => "$baseUrl/api/reset-password";
  static String get lessonLocationsUrl => "$baseUrl/api/profile/lesson-locations";
  static String get becomeTutorUrl => "$baseUrl/api/profile/become-tutor";
  static String get avatarUrl => "$baseUrl/api/profile/avatar";

  // Blockchain / wallet endpoints
  static String get balanceUrl => "$baseUrl/api/balance";
  static String get blockchainAccountsUrl => "$baseUrl/api/blockchain/accounts";
  static String blockchainBalanceUrl(String address) => "$baseUrl/api/blockchain/balance/$address";
  static String get blockchainTransactionUrl => "$baseUrl/api/blockchain/transaction";
  static String blockchainTransactionDetailUrl(String hash) => "$baseUrl/api/blockchain/transaction/$hash";

  // Beneficiaries endpoints
  static String get beneficiariesUrl => "$baseUrl/api/beneficiaries";
  static String beneficiaryDeleteUrl(String beneficiaryId) => "$baseUrl/api/beneficiaries/$beneficiaryId";

  // Listings endpoints
  static String get listingsUrl => "$baseUrl/api/listings";
  static String get listingsMineUrl => "$baseUrl/api/listings/mine";
  static String listingsSearchUrl(String query) => "$baseUrl/api/listings/search?q=$query";
  static String listingUrl(int listingId) => "$baseUrl/api/listings/$listingId";
  static String listingInterestsUrl(int listingId) => "$baseUrl/api/listings/$listingId/interests";
  static String listingFavoriteUrl(int listingId) => "$baseUrl/api/listings/$listingId/favorite";
  static String get favoritesUrl => "$baseUrl/api/favorites";
  static String get interestsUrl => "$baseUrl/api/interests";
  static String listingsEngagementUrl(String listingIds) => "$baseUrl/api/listings/engagement?listing_ids=$listingIds";
  static String get analyzeCvUrl => "$baseUrl/api/analyze-cv";

  // Availability endpoints
  static String availabilityUrl({String? listingId, String? tutorUserId}) {
    final params = <String>[];
    if (listingId != null) params.add('listing_id=$listingId');
    if (tutorUserId != null) params.add('tutor_user_id=$tutorUserId');
    return params.isEmpty ? "$baseUrl/api/availability" : "$baseUrl/api/availability?${params.join('&')}";
  }
  static String get availabilityMineUrl => "$baseUrl/api/availability/mine";
  static String availabilityDeleteUrl(String slotId) => "$baseUrl/api/availability/$slotId";

  // Bookings endpoints
  static String get bookingsUrl => "$baseUrl/api/bookings";
  static String bookingStatusUrl(String bookingId) => "$baseUrl/api/bookings/$bookingId/status";
  static String get tutorNotificationsUrl => "$baseUrl/api/tutor/notifications";
  static String get markNotificationsReadUrl => "$baseUrl/api/tutor/notifications/mark-read";

  // Messaging endpoints
  static String get conversationsUrl => "$baseUrl/api/conversations";
  static String conversationMessagesUrl(int conversationId) => "$baseUrl/api/conversations/$conversationId/messages";
  static String conversationReadUrl(int conversationId) => "$baseUrl/api/conversations/$conversationId/read";
  // path: '/api/socket.io' — reste sous le même préfixe que le reste de l'API (voir
  // server.js, nginx.conf) ; le socket se connecte au host de l'API (baseUrl), pas à
  // celui de l'app elle-même.
  static const String socketPath = '/api/socket.io';
}
