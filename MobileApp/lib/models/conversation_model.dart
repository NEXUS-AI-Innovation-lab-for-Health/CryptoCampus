class ConversationOtherUser {
  final String userId;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String role;

  ConversationOtherUser({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    required this.role,
  });

  factory ConversationOtherUser.fromJson(Map<String, dynamic> json) {
    return ConversationOtherUser(
      userId: json['userId'].toString(),
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      avatarUrl: json['avatarUrl'],
      role: json['role'] ?? 'STUDENT',
    );
  }

  String get fullName => '$firstName $lastName';
}

class ConversationLastMessage {
  final String content;
  final DateTime createdAt;
  final String senderId;

  ConversationLastMessage({required this.content, required this.createdAt, required this.senderId});

  factory ConversationLastMessage.fromJson(Map<String, dynamic> json) {
    return ConversationLastMessage(
      content: json['content'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      senderId: json['senderId'].toString(),
    );
  }
}

class ConversationModel {
  final int conversationId;
  final ConversationOtherUser otherUser;
  final ConversationLastMessage? lastMessage;
  int unreadCount;

  ConversationModel({
    required this.conversationId,
    required this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      conversationId: json['conversationId'] is int
          ? json['conversationId']
          : int.parse(json['conversationId'].toString()),
      otherUser: ConversationOtherUser.fromJson(json['otherUser']),
      lastMessage: json['lastMessage'] != null ? ConversationLastMessage.fromJson(json['lastMessage']) : null,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}
