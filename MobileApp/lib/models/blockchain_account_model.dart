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
  final int? gasUsed;

  Transaction({
    required this.from,
    required this.to,
    required this.amount,
    this.transactionHash,
    this.blockNumber,
    this.gasUsed,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      from: json['from'] ?? json['fromAddress'] ?? '',
      to: json['to'] ?? json['toAddress'] ?? '',
      amount: double.parse(json['value']?.toString() ?? json['amount']?.toString() ?? '0'),
      transactionHash: json['transactionHash'] ?? json['hash'],
      blockNumber: json['blockNumber'],
      gasUsed: json['gasUsed'],
    );
  }
}
