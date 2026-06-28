class ChatMessageModel {
  final String id;
  final String senderEmail;
  final String senderName;
  final String senderRole;
  final String message;
  final DateTime timestamp;
  bool isRead;

  ChatMessageModel({
    required this.id,
    required this.senderEmail,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  ChatMessageModel copyWith({
    String? id,
    String? senderEmail,
    String? senderName,
    String? senderRole,
    String? message,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      senderEmail: senderEmail ?? this.senderEmail,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] as String,
      senderEmail: map['senderEmail'] as String,
      senderName: map['senderName'] as String,
      senderRole: map['senderRole'] as String,
      message: map['message'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderEmail': senderEmail,
      'senderName': senderName,
      'senderRole': senderRole,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}
