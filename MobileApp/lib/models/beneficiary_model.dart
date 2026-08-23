class BeneficiaryModel {
  final String beneficiaryId;
  final String label;
  final String address;
  final DateTime? createdAt;

  BeneficiaryModel({
    required this.beneficiaryId,
    required this.label,
    required this.address,
    this.createdAt,
  });

  factory BeneficiaryModel.fromJson(Map<String, dynamic> json) {
    return BeneficiaryModel(
      beneficiaryId: json['beneficiary_id'].toString(),
      label: json['label'] ?? '',
      address: json['address'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  String get shortAddress {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}
