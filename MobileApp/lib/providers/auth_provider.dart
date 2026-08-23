import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _currentUser;
  bool _isLoading = false;
  // true une fois que la vérification de session initiale (checkAuth au démarrage) est
  // terminée — permet au splash screen de ne naviguer qu'une fois qu'on sait vraiment.
  bool _sessionChecked = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get sessionChecked => _sessionChecked;

  /// Vérifie la session côté serveur (cookie `sessionId`) au lancement de l'app —
  /// équivalent de useAuth.js côté web. À appeler une fois au démarrage (splash screen).
  Future<void> checkSession() async {
    try {
      final isAuthenticated = await _apiService.checkAuth();
      if (isAuthenticated) {
        final profile = await _apiService.getProfile();
        _currentUser = profile.user;
      } else {
        _currentUser = null;
      }
    } catch (e) {
      _currentUser = null;
    } finally {
      _sessionChecked = true;
      notifyListeners();
    }
  }

  /// Renvoie `null` si la connexion a réussi, sinon un message d'erreur précis — distingue
  /// un échec de login (identifiants invalides) d'un échec de `getProfile()` juste après
  /// (session/réseau), pour ne jamais afficher "mot de passe incorrect" à tort.
  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.login(email, password);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      final message = e.toString().replaceFirst('Exception: ', '');
      debugPrint('❌ Erreur de connexion (login): $e');
      return message;
    }

    try {
      // Le login ne renvoie qu'un résumé (userId/email/firstName/lastName/role) ; on
      // recharge le profil complet juste après pour avoir tous les champs réels
      // (le cookie de session est déjà posé par le navigateur à ce stade).
      final profile = await _apiService.getProfile();
      _currentUser = profile.user;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Erreur de connexion (getProfile après login réussi): $e');
      return 'Connecté, mais impossible de charger le profil : '
          '${e.toString().replaceFirst('Exception: ', '')}';
    }
  }

  /// [desiredRole] : 'student' ou 'tutor'. [referralCode] obligatoire côté serveur pour
  /// un compte étudiant. [lessonMode]/[visioTool]/[lessonPlaces] pour un compte tuteur.
  Future<String?> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String desiredRole,
    String? referralCode,
    String? lessonMode,
    String? visioTool,
    List<String>? lessonPlaces,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        desiredRole: desiredRole,
        referralCode: referralCode,
        lessonMode: lessonMode,
        visioTool: visioTool,
        lessonPlaces: lessonPlaces,
      );

      _isLoading = false;
      notifyListeners();
      return null; // pas d'erreur
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> refreshProfile() async {
    try {
      final profile = await _apiService.getProfile();
      _currentUser = profile.user;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur de rechargement du profil: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      // Non bloquant : même si l'appel serveur échoue, on nettoie l'état local.
      debugPrint('⚠️ Erreur logout serveur: $e');
    }
    _currentUser = null;
    notifyListeners();
  }
}
