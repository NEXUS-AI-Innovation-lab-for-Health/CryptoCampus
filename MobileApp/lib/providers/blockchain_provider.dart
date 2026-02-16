import 'package:flutter/material.dart';
import '../models/blockchain_account_model.dart';
import '../services/api_service.dart';

class BlockchainProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<BlockchainAccount> _accounts = [];
  BlockchainAccount? _selectedAccount;
  bool _isLoading = false;
  String? _error;

  List<BlockchainAccount> get accounts => _accounts;
  BlockchainAccount? get selectedAccount => _selectedAccount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAccounts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _accounts = await _apiService.getBlockchainAccounts();
      if (_accounts.isNotEmpty && _selectedAccount == null) {
        _selectedAccount = _accounts.first;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshBalance() async {
    if (_selectedAccount == null) return;

    try {
      final balance = await _apiService.getBalance(_selectedAccount!.address);
      _selectedAccount = BlockchainAccount(
        address: _selectedAccount!.address,
        balance: balance,
      );
      
      // Update in the list
      final index = _accounts.indexWhere((a) => a.address == _selectedAccount!.address);
      if (index != -1) {
        _accounts[index] = _selectedAccount!;
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void selectAccount(BlockchainAccount account) {
    _selectedAccount = account;
    notifyListeners();
  }

  Future<bool> sendTransaction({
    required String toAddress,
    required double amount,
  }) async {
    if (_selectedAccount == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.sendTransaction(
        fromAddress: _selectedAccount!.address,
        toAddress: toAddress,
        amount: amount,
      );
      
      // Refresh balance after transaction
      await refreshBalance();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
