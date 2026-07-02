class ChatMessageModel {
  final String id;
  final String senderEmail;
  final String senderName;
  final String senderRole;
  final String message;
  final DateTime timestamp;
  final String? receiverEmail; // To track who the message is for
  final String? imageUrl; // For image messages
  bool isRead;

  ChatMessageModel({
    required this.id,
    required this.senderEmail,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.timestamp,
    this.receiverEmail,
    this.imageUrl,
    this.isRead = false,
  });

  bool get isImageMessage => imageUrl != null && imageUrl!.isNotEmpty;

  ChatMessageModel copyWith({
    String? id,
    String? senderEmail,
    String? senderName,
    String? senderRole,
    String? message,
    DateTime? timestamp,
    String? receiverEmail,
    String? imageUrl,
    bool? isRead,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      senderEmail: senderEmail ?? this.senderEmail,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      receiverEmail: receiverEmail ?? this.receiverEmail,
      imageUrl: imageUrl ?? this.imageUrl,
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
      receiverEmail: map['receiverEmail'] as String?,
      imageUrl: map['imageUrl'] as String?,
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
      'receiverEmail': receiverEmail,
      'imageUrl': imageUrl,
      'isRead': isRead,
    };
  }
}
