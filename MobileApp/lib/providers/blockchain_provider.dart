import 'package:flutter/material.dart';
import '../models/wallet_profile_model.dart';
import '../models/beneficiary_model.dart';
import '../services/api_service.dart';

class BlockchainProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  WalletProfile? _wallet;
  List<BeneficiaryModel> _beneficiaries = [];
  bool _isLoading = false;
  String? _error;

  WalletProfile? get wallet => _wallet;
  List<BeneficiaryModel> get beneficiaries => _beneficiaries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Charge le solde réel de l'utilisateur connecté (avec historique des transactions)
  /// et son carnet de bénéficiaires. Source : GET /api/balance + GET /api/beneficiaries
  /// (jamais GET /api/blockchain/accounts, qui est réservé aux admins).
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.getBalance(),
        _apiService.getBeneficiaries(),
      ]);
      _wallet = results[0] as WalletProfile;
      _beneficiaries = results[1] as List<BeneficiaryModel>;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshBalance() async {
    try {
      _wallet = await _apiService.getBalance();
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> addBeneficiary(String label, String address) async {
    try {
      final beneficiary = await _apiService.addBeneficiary(label, address);
      _beneficiaries = [beneficiary, ..._beneficiaries];
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeBeneficiary(String beneficiaryId) async {
    try {
      await _apiService.removeBeneficiary(beneficiaryId);
      _beneficiaries = _beneficiaries.where((b) => b.beneficiaryId != beneficiaryId).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Envoie des CCT vers une adresse (bénéficiaire ou adresse libre) puis recharge le
  /// solde. Renvoie un message d'erreur (ou `null` si succès), pour affichage direct.
  Future<String?> sendTransaction({required String toAddress, required double amount}) async {
    try {
      await _apiService.sendTransaction(toAddress: toAddress, amount: amount);
      await refreshBalance();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}
