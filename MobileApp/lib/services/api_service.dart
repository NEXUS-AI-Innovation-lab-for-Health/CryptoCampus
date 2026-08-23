import 'dart:typed_data';

import 'package:dio/dio.dart';
// Adaptateur web uniquement : c'est lui qui permet au navigateur de gérer le cookie de
// session (`sessionId`) comme le ferait le frontend Vue avec `credentials: 'include'`.
// Cible actuelle de l'app : `flutter run -d chrome` (web). Pour un vrai build mobile
// natif (Android/iOS) il faudrait basculer sur `package:dio/io.dart` + `cookie_jar`
// pour obtenir le même comportement de persistance de session.
import 'package:dio/browser.dart';

import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/listing_model.dart';
import '../models/blockchain_account_model.dart';
import '../models/beneficiary_model.dart';
import '../models/wallet_profile_model.dart';
import '../models/booking_model.dart';

class ApiService {
  static final Dio _dio = _buildDio();

  static Dio _buildDio() {
    final dio = Dio(BaseOptions(
      headers: {'Content-Type': 'application/json'},
      validateStatus: (_) => true, // on gère nous-mêmes les codes d'erreur
    ));
    dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);
    return dio;
  }

  Exception _errorFrom(Response response, String fallback) {
    final data = response.data;
    if (data is Map && data['error'] != null) {
      return Exception(data['error'].toString());
    }
    return Exception('$fallback (${response.statusCode})');
  }

  // ==================== AUTH ENDPOINTS ====================

  Future<User> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String desiredRole, // 'student' | 'tutor'
    String? referralCode,
    String? lessonMode,
    String? visioTool,
    List<String>? lessonPlaces,
  }) async {
    final response = await _dio.post(ApiConfig.registerUrl, data: {
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'desired_role': desiredRole,
      if (referralCode != null && referralCode.isNotEmpty) 'referral_code': referralCode,
      if (lessonMode != null) 'lesson_mode': lessonMode,
      if (visioTool != null) 'visio_tool': visioTool,
      if (lessonPlaces != null) 'lesson_places': lessonPlaces,
    });

    if (response.statusCode == 201) {
      return User.fromJson(response.data['user']);
    }
    throw _errorFrom(response, 'Échec de l\'inscription');
  }

  Future<User> login(String email, String password) async {
    final response = await _dio.post(ApiConfig.loginUrl, data: {
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200) {
      final data = response.data;
      // /api/login renvoie un résumé { userId, email, firstName, lastName, role } ;
      // on recharge le profil complet juste après pour avoir tous les champs réels.
      return User.fromJson({
        'user_id': data['userId'] ?? data['user_id'],
        'email': data['email'],
        'first_name': data['firstName'] ?? data['first_name'] ?? '',
        'last_name': data['lastName'] ?? data['last_name'] ?? '',
        'role': data['role'] ?? 'STUDENT',
      });
    }
    throw _errorFrom(response, 'Échec de la connexion');
  }

  /// Vérifie la session côté serveur (équivalent de useAuth.js côté web) sans jamais
  /// lever d'erreur — renvoie simplement `true`/`false`. Ne fournit pas le profil complet
  /// (l'endpoint ne renvoie que id/role/email/avatar) : appeler `getProfile()` ensuite si
  /// la session est valide.
  Future<bool> checkAuth() async {
    final response = await _dio.get(ApiConfig.checkAuthUrl);
    return response.statusCode == 200 && response.data['isAuthenticated'] == true;
  }

  Future<void> logout() async {
    await _dio.post(ApiConfig.logoutUrl);
  }

  Future<void> deleteAccount() async {
    final response = await _dio.delete(ApiConfig.accountUrl);
    if (response.statusCode != 200) {
      throw _errorFrom(response, 'Échec de la suppression du compte');
    }
  }

  Future<User> getUserById(String userId) async {
    final response = await _dio.get(ApiConfig.userByIdUrl(userId));
    if (response.statusCode == 200) {
      return User.fromJson(response.data);
    }
    throw _errorFrom(response, 'Utilisateur introuvable');
  }

  // ==================== PROFILE ENDPOINTS ====================

  /// Profil complet de l'utilisateur connecté : infos perso + wallet (solde, adresse,
  /// stats) + code de parrainage, en un seul appel. Source de vérité pour l'écran Profil.
  /// Ne contient PAS l'historique des transactions (voir `getBalance()`).
  Future<ProfileResponse> getProfile() async {
    final response = await _dio.get(ApiConfig.profileUrl);
    if (response.statusCode == 200) {
      return ProfileResponse.fromJson(response.data);
    }
    throw _errorFrom(response, 'Impossible de charger le profil');
  }

  /// Solde + stats + historique réel des transactions (le carnet complet, contrairement
  /// à /api/profile qui ne renvoie que le solde courant). Source de vérité pour l'écran
  /// Wallet.
  Future<WalletProfile> getBalance() async {
    final response = await _dio.get(ApiConfig.balanceUrl);
    if (response.statusCode == 200) {
      return WalletProfile.fromJson(response.data);
    }
    throw _errorFrom(response, 'Impossible de charger le solde');
  }

  Future<void> resetPassword(String currentPassword, String newPassword) async {
    final response = await _dio.post(ApiConfig.resetPasswordUrl, data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    if (response.statusCode != 200) {
      throw _errorFrom(response, 'Échec du changement de mot de passe');
    }
  }

  Future<void> updateLessonLocations({
    required String lessonMode,
    required String visioTool,
    required List<String> lessonPlaces,
  }) async {
    final response = await _dio.put(ApiConfig.lessonLocationsUrl, data: {
      'lesson_mode': lessonMode,
      'visio_tool': visioTool,
      'lesson_places': lessonPlaces,
    });
    if (response.statusCode != 200) {
      throw _errorFrom(response, 'Échec de la mise à jour');
    }
  }

  Future<void> becomeTutor({
    required String lessonMode,
    required String visioTool,
    required List<String> lessonPlaces,
  }) async {
    final response = await _dio.post(ApiConfig.becomeTutorUrl, data: {
      'lesson_mode': lessonMode,
      'visio_tool': visioTool,
      'lesson_places': lessonPlaces,
    });
    if (response.statusCode != 200) {
      throw _errorFrom(response, 'Échec du passage en tuteur');
    }
  }

  Future<String> uploadAvatar(Uint8List bytes, String filename) async {
    final formData = FormData.fromMap({
      'avatar': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _dio.post(ApiConfig.avatarUrl, data: formData);
    if (response.statusCode == 200) {
      return response.data['avatar_url'] as String;
    }
    throw _errorFrom(response, 'Échec de l\'envoi de la photo');
  }

  Future<void> deleteAvatar() async {
    final response = await _dio.delete(ApiConfig.avatarUrl);
    if (response.statusCode != 200) {
      throw _errorFrom(response, 'Échec de la suppression de la photo');
    }
  }

  // ==================== WALLET / BLOCKCHAIN ENDPOINTS ====================

  Future<List<BlockchainAccount>> getBlockchainAccounts() async {
    final response = await _dio.get(ApiConfig.blockchainAccountsUrl);
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data['accounts'];
      return data.map((json) => BlockchainAccount.fromJson(json)).toList();
    }
    throw _errorFrom(response, 'Impossible de charger les comptes');
  }

  /// Envoie des CCT depuis le wallet de l'utilisateur connecté (résolu côté serveur via
  /// la session — jamais d'adresse source fournie par le client).
  Future<Transaction> sendTransaction({
    required String toAddress,
    required double amount,
  }) async {
    final response = await _dio.post(ApiConfig.blockchainTransactionUrl, data: {
      'toAddress': toAddress,
      'amount': amount,
    });
    if (response.statusCode == 200) {
      return Transaction.fromJson(response.data);
    }
    throw _errorFrom(response, 'Échec de la transaction');
  }

  Future<List<BeneficiaryModel>> getBeneficiaries() async {
    final response = await _dio.get(ApiConfig.beneficiariesUrl);
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data['beneficiaries'];
      return data.map((json) => BeneficiaryModel.fromJson(json)).toList();
    }
    throw _errorFrom(response, 'Impossible de charger les bénéficiaires');
  }

  Future<BeneficiaryModel> addBeneficiary(String label, String address) async {
    final response = await _dio.post(ApiConfig.beneficiariesUrl, data: {
      'label': label,
      'address': address,
    });
    if (response.statusCode == 201) {
      return BeneficiaryModel.fromJson(response.data['beneficiary']);
    }
    throw _errorFrom(response, 'Échec de l\'ajout du bénéficiaire');
  }

  Future<void> removeBeneficiary(String beneficiaryId) async {
    final response = await _dio.delete(ApiConfig.beneficiaryDeleteUrl(beneficiaryId));
    if (response.statusCode != 200) {
      throw _errorFrom(response, 'Échec de la suppression du bénéficiaire');
    }
  }

  // ==================== LISTINGS ENDPOINTS ====================

  Future<List<Listing>> getAllListings() async {
    final response = await _dio.get(ApiConfig.listingsUrl);
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data['listings'];
      return data.map((json) => Listing.fromJson(json)).toList();
    }
    throw _errorFrom(response, 'Impossible de charger les annonces');
  }

  Future<List<Listing>> getMyListings() async {
    final response = await _dio.get(ApiConfig.listingsMineUrl);
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data['listings'];
      return data.map((json) => Listing.fromJson(json)).toList();
    }
    throw _errorFrom(response, 'Impossible de charger vos annonces');
  }

  Future<List<Listing>> searchListings(String query) async {
    final response = await _dio.get(ApiConfig.listingsSearchUrl(query));
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data['results'];
      return data.map((json) => Listing.fromJson(json)).toList();
    }
    throw _errorFrom(response, 'Échec de la recherche');
  }

  Future<Listing> createListing({
    required String title,
    required String description,
    required String subject,
    required String level,
    required double price,
    String? tutorName,
  }) async {
    final response = await _dio.post(ApiConfig.listingsUrl, data: {
      'title': title,
      'description': description,
      'subject': subject,
      'level': level,
      'price': price,
      if (tutorName != null) 'tutor_name': tutorName,
    });
    if (response.statusCode == 201) {
      return Listing.fromJson(response.data['listing']);
    }
    throw _errorFrom(response, 'Échec de la création de l\'annonce');
  }

  Future<Listing> updateListing({
    required int listingId,
    required String title,
    required String description,
    required String subject,
    required String level,
    required double price,
  }) async {
    final response = await _dio.put(ApiConfig.listingUrl(listingId), data: {
      'title': title,
      'description': description,
      'subject': subject,
      'level': level,
      'price': price,
    });
    if (response.statusCode == 200) {
      return Listing.fromJson(response.data['listing']);
    }
    throw _errorFrom(response, 'Échec de la mise à jour de l\'annonce');
  }

  Future<void> deleteListing(int listingId) async {
    final response = await _dio.delete(ApiConfig.listingUrl(listingId));
    if (response.statusCode != 200) {
      throw _errorFrom(response, 'Échec de la suppression de l\'annonce');
    }
  }

  Future<Map<String, dynamic>> getListingInterests(int listingId) async {
    final response = await _dio.get(ApiConfig.listingInterestsUrl(listingId));
    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    }
    throw _errorFrom(response, 'Impossible de charger les intéressés');
  }

  Future<void> setFavorite(int listingId, bool favorite) async {
    final response = favorite
        ? await _dio.post(ApiConfig.listingFavoriteUrl(listingId))
        : await _dio.delete(ApiConfig.listingFavoriteUrl(listingId));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _errorFrom(response, 'Échec de la mise à jour des favoris');
    }
  }

  Future<void> setInterest(int listingId, bool interested) async {
    final response = interested
        ? await _dio.post(ApiConfig.listingInterestsUrl(listingId))
        : await _dio.delete(ApiConfig.listingInterestsUrl(listingId));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _errorFrom(response, 'Échec de la mise à jour des intérêts');
    }
  }

  Future<List<int>> getFavoriteListingIds() async {
    final response = await _dio.get(ApiConfig.favoritesUrl);
    if (response.statusCode == 200) {
      final List<dynamic> ids = response.data['listingIds'] ?? response.data;
      return ids.map((e) => int.parse(e.toString())).toList();
    }
    throw _errorFrom(response, 'Impossible de charger les favoris');
  }

  Future<List<int>> getInterestedListingIds() async {
    final response = await _dio.get(ApiConfig.interestsUrl);
    if (response.statusCode == 200) {
      final List<dynamic> ids = response.data['listingIds'] ?? response.data;
      return ids.map((e) => int.parse(e.toString())).toList();
    }
    throw _errorFrom(response, 'Impossible de charger les intérêts');
  }

  Future<Map<String, dynamic>> analyzeCv(Uint8List bytes, String filename) async {
    final formData = FormData.fromMap({
      'cv': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _dio.post(ApiConfig.analyzeCvUrl, data: formData);
    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    }
    throw _errorFrom(response, 'Échec de l\'analyse du CV');
  }

  // ==================== AVAILABILITY ENDPOINTS ====================

  Future<List<Map<String, dynamic>>> getAvailability({String? listingId, String? tutorUserId}) async {
    final response = await _dio.get(
      ApiConfig.availabilityUrl(listingId: listingId, tutorUserId: tutorUserId),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    }
    throw _errorFrom(response, 'Impossible de charger les créneaux');
  }

  Future<List<Map<String, dynamic>>> getMyAvailability() async {
    final response = await _dio.get(ApiConfig.availabilityMineUrl);
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    }
    throw _errorFrom(response, 'Impossible de charger vos créneaux');
  }

  Future<void> createAvailability(DateTime start, DateTime end) async {
    final response = await _dio.post(ApiConfig.availabilityUrl(), data: {
      'start_time': start.toIso8601String(),
      'end_time': end.toIso8601String(),
    });
    if (response.statusCode != 201) {
      throw _errorFrom(response, 'Échec de la création du créneau');
    }
  }

  Future<void> deleteAvailability(String slotId) async {
    final response = await _dio.delete(ApiConfig.availabilityDeleteUrl(slotId));
    if (response.statusCode != 200) {
      throw _errorFrom(response, 'Échec de la suppression du créneau');
    }
  }

  // ==================== BOOKINGS ENDPOINTS ====================

  /// Réservations de l'utilisateur connecté (élève et/ou tuteur) — le backend filtre
  /// toujours sur la session, aucun paramètre à fournir.
  Future<List<BookingModel>> getBookings() async {
    final response = await _dio.get(ApiConfig.bookingsUrl);
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => BookingModel.fromJson(json)).toList();
    }
    throw _errorFrom(response, 'Impossible de charger les réservations');
  }

  Future<void> createBooking({
    required List<String> slotIds,
    int? listingId,
    required String title,
    String? description,
    String? subject,
    String? tutorName,
    String? tutorEmail,
    double? price,
    String? notes,
  }) async {
    final response = await _dio.post(ApiConfig.bookingsUrl, data: {
      'slot_ids': slotIds,
      if (listingId != null) 'listing_id': listingId,
      'title': title,
      if (description != null) 'description': description,
      if (subject != null) 'subject': subject,
      if (tutorName != null) 'tutor_name': tutorName,
      if (tutorEmail != null) 'tutor_email': tutorEmail,
      if (price != null) 'price': price,
      if (notes != null) 'notes': notes,
    });
    if (response.statusCode != 201) {
      throw _errorFrom(response, 'Échec de la réservation');
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    final response = await _dio.patch(ApiConfig.bookingStatusUrl(bookingId), data: {
      'status': status,
    });
    if (response.statusCode != 200) {
      throw _errorFrom(response, 'Échec de la mise à jour du statut');
    }
  }

  // ==================== NOTIFICATIONS ENDPOINTS ====================

  Future<List<Map<String, dynamic>>> checkTutorNotifications() async {
    final response = await _dio.get(ApiConfig.tutorNotificationsUrl);
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    }
    throw _errorFrom(response, 'Impossible de charger les notifications');
  }

  Future<void> markNotificationsRead(List<String> bookingIds) async {
    final response = await _dio.put(ApiConfig.markNotificationsReadUrl, data: {
      'booking_ids': bookingIds,
    });
    if (response.statusCode != 200) {
      throw _errorFrom(response, 'Échec du marquage des notifications');
    }
  }
}
