enum NotificationType {
  newOrder,
  paymentConfirmed,
  orderProcessing,
  orderShipped,
  orderDelivered,
  orderCancelled,
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String? orderId;
  bool isRead;
  final DateTime createdAt;
  final String recipient;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.orderId,
    this.isRead = false,
    required this.createdAt,
    required this.recipient,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type.name,
    'orderId': orderId,
    'isRead': isRead,
    'createdAt': createdAt.toIso8601String(),
    'recipient': recipient,
  };

  factory NotificationModel.fromMap(Map<String, dynamic> map) => NotificationModel(
    id: map['id'] as String,
    title: map['title'] as String,
    body: map['body'] as String,
    type: NotificationType.values.byName(map['type'] as String),
    orderId: map['orderId'] as String?,
    isRead: map['isRead'] as bool? ?? false,
    createdAt: DateTime.parse(map['createdAt'] as String),
    recipient: map['recipient'] as String,
  );
}
