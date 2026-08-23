class User {
  final String userId;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final bool isVerified;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  // Champs additionnels renvoyés par GET /api/profile (absents des réponses login/register).
  final String? lessonMode;
  final String? visioTool;
  final List<String>? lessonPlaces;
  final String? referralCode;
  final String? linkedinEmail;
  final String? avatarUrl;

  User({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.isVerified = false,
    this.createdAt,
    this.lastLogin,
    this.lessonMode,
    this.visioTool,
    this.lessonPlaces,
    this.referralCode,
    this.linkedinEmail,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'].toString(),
      email: json['email'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: json['role'] ?? 'STUDENT',
      isVerified: json['is_verified'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      lastLogin: json['last_login'] != null ? DateTime.tryParse(json['last_login']) : null,
      lessonMode: json['lesson_mode'],
      visioTool: json['visio_tool'],
      lessonPlaces: json['lesson_places'] != null
          ? List<String>.from(json['lesson_places'] as List)
          : null,
      referralCode: json['referral_code'],
      linkedinEmail: json['linkedin_email'],
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'is_verified': isVerified,
      'created_at': createdAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'lesson_mode': lessonMode,
      'visio_tool': visioTool,
      'lesson_places': lessonPlaces,
      'referral_code': referralCode,
      'linkedin_email': linkedinEmail,
      'avatar_url': avatarUrl,
    };
  }

  bool get isTutor => role == 'TUTOR';

  String get fullName => '$firstName $lastName';
}
