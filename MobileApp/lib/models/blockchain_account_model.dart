class BlockchainAccount {
  final String address;
  final double balance;

  BlockchainAccount({
    required this.address,
    required this.balance,
  });

  factory BlockchainAccount.fromJson(Map<String, dynamic> json) {
    return BlockchainAccount(
      address: json['address'],
      balance: double.parse(json['balanceEth']?.toString() ?? json['balance']?.toString() ?? '0'),
    );
  }

  String get shortAddress {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}

class Transaction {
  final String from;
  final String to;
  final double amount;
  final String? transactionHash;
  final int? blockNumber;
  final String? gasUsed;

  Transaction({
    required this.from,
    required this.to,
    required this.amount,
    this.transactionHash,
    this.blockNumber,
    this.gasUsed,
  });

  // POST /api/blockchain/transaction renvoie `from`/`to` comme des objets
  // {address, balanceBefore, balanceAfter} (pas de simples chaînes), et
  // GET /api/blockchain/transaction/:hash renvoie des chaînes plates — on gère les deux.
  static String _extractAddress(dynamic value, String fallback) {
    if (value is Map) return value['address']?.toString() ?? fallback;
    if (value is String) return value;
    return fallback;
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      from: _extractAddress(json['from'], json['fromAddress']?.toString() ?? ''),
      to: _extractAddress(json['to'], json['toAddress']?.toString() ?? ''),
      amount: double.tryParse(json['value']?.toString() ?? json['amount']?.toString() ?? '0') ?? 0,
      transactionHash: json['transactionHash'] ?? json['hash'],
      blockNumber: json['blockNumber'] is int
          ? json['blockNumber']
          : int.tryParse(json['blockNumber']?.toString() ?? ''),
      gasUsed: json['gasUsed']?.toString(),
    );
  }
}
