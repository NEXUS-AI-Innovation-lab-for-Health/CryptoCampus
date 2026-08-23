class Listing {
  final int listingId;
  final String tutorUserId;
  final String title;
  final String description;
  final String subject;
  final String level;
  final double pricePerHour;
  final bool isActive;
  final DateTime createdAt;
  final String? tutorName;

  Listing({
    required this.listingId,
    required this.tutorUserId,
    required this.title,
    required this.description,
    required this.subject,
    required this.level,
    required this.pricePerHour,
    required this.isActive,
    required this.createdAt,
    this.tutorName,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      listingId: json['listing_id'] ?? json['id'] ?? 0,
      tutorUserId: json['tutor_user_id']?.toString() ?? '',
      title: json['title'],
      description: json['description'],
      subject: json['subject'],
      level: json['level'],
      pricePerHour: (json['price_per_hour'] ?? json['price'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? true,
      // POST /api/listings renvoie l'annonce fraîchement créée SANS created_at (ce champ
      // n'est ajouté qu'à l'indexation Qdrant, invisible dans la réponse de création) —
      // DateTime.parse(null) plantait ici et faisait échouer silencieusement toute
      // publication malgré un enregistrement réussi côté serveur.
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) ?? DateTime.now() : DateTime.now(),
      tutorName: json['tutor_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'listing_id': listingId,
      'tutor_user_id': tutorUserId,
      'title': title,
      'description': description,
      'subject': subject,
      'level': level,
      'price_per_hour': pricePerHour,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'tutor_name': tutorName,
    };
  }
}
