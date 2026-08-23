class BookingModel {
  final String bookingId;
  final String userId; // l'étudiant qui a réservé
  final int? listingId;
  final String title;
  final String? description;
  final String? subject;
  final DateTime startTime;
  final DateTime endTime;
  final String status; // pending | confirmed | completed | cancelled
  final String? tutorName;
  final String? studentName;
  final double? price;
  final String? notes;

  BookingModel({
    required this.bookingId,
    required this.userId,
    this.listingId,
    required this.title,
    this.description,
    this.subject,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.tutorName,
    this.studentName,
    this.price,
    this.notes,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      bookingId: json['booking_id'].toString(),
      userId: json['user_id'].toString(),
      listingId: json['listing_id'] != null ? int.tryParse(json['listing_id'].toString()) : null,
      title: json['title'] ?? 'Réservation',
      description: json['description'],
      subject: json['subject'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      status: json['status'] ?? 'pending',
      tutorName: json['tutor_name'],
      studentName: json['student_name'],
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      notes: json['notes'],
    );
  }

  /// L'API ne renvoie pas explicitement "êtes-vous l'élève ou le tuteur de cette
  /// réservation" : on le déduit en comparant `userId` (l'élève) à l'utilisateur connecté.
  bool isOwnedByStudent(String currentUserId) => userId == currentUserId;
}
