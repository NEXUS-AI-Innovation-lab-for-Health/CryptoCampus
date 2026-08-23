import 'user_model.dart';

/// Stats affichées sur les écrans Wallet/Profil (même trio que Balance.vue/Profile.vue
/// côté web : nombre d'étudiants aidés, total gagné, requêtes créées).
class WalletStats {
  final int helpedCount;
  final double totalEarned;
  final int requestsCreated;

  WalletStats({
    required this.helpedCount,
    required this.totalEarned,
    required this.requestsCreated,
  });

  factory WalletStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return WalletStats(helpedCount: 0, totalEarned: 0, requestsCreated: 0);
    }
    return WalletStats(
      helpedCount: int.tryParse(json['helpedCount']?.toString() ?? '0') ?? 0,
      totalEarned: double.tryParse(json['totalEarned']?.toString() ?? '0') ?? 0,
      requestsCreated: int.tryParse(json['requestsCreated']?.toString() ?? '0') ?? 0,
    );
  }
}

/// Une ligne de l'historique de transactions tel que renvoyé par GET /api/balance
/// (`{id, description, date, amount}`), déjà signé (+/-) et déjà décrit côté serveur —
/// distinct du reçu on-chain brut (voir `Transaction` dans blockchain_account_model.dart).
class WalletTransaction {
  final int id;
  final String description;
  final DateTime date;
  final double amount;

  WalletTransaction({
    required this.id,
    required this.description,
    required this.date,
    required this.amount,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      description: json['description'] ?? '',
      date: DateTime.tryParse(json['date'].toString()) ?? DateTime.now(),
      amount: double.tryParse(json['amount'].toString()) ?? 0,
    );
  }

  bool get isPositive => amount > 0;
}

/// Solde + stats (+ historique quand disponible) — le wallet CCT d'un utilisateur.
/// Alimenté soit par GET /api/profile (pas d'historique), soit par GET /api/balance
/// (historique complet).
class WalletProfile {
  final double balance;
  final String? blockchainAddress;
  final WalletStats stats;
  final List<WalletTransaction> transactions;

  WalletProfile({
    required this.balance,
    required this.blockchainAddress,
    required this.stats,
    this.transactions = const [],
  });

  factory WalletProfile.fromJson(Map<String, dynamic> json) {
    return WalletProfile(
      balance: double.tryParse(json['balance'].toString()) ?? 0,
      blockchainAddress: json['blockchainAddress'],
      stats: WalletStats.fromJson(json['stats']),
      transactions: json['transactions'] != null
          ? (json['transactions'] as List)
              .map((t) => WalletTransaction.fromJson(t as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }
}

/// Réponse de GET /api/profile : identité (User) + wallet (WalletProfile), le tout dans
/// un seul appel — miroir du comportement de Profile.vue côté web.
class ProfileResponse {
  final User user;
  final WalletProfile wallet;

  ProfileResponse({required this.user, required this.wallet});

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      user: User.fromJson(json),
      wallet: WalletProfile.fromJson(json),
    );
  }
}
