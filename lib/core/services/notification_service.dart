import 'dart:math';
import 'package:flutter/material.dart';
import '../database/hive_db.dart';
import '../models/notification_model.dart';
import 'sound_helper.dart';

class NotificationService extends ChangeNotifier {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final HiveDb _db = HiveDb.instance;
  int _unreadCount = 0;
  int _unreadUserCount = 0;
  int _unreadAdminCount = 0;

  int get unreadCount => _unreadCount;
  int get unreadUserCount => _unreadUserCount;
  int get unreadAdminCount => _unreadAdminCount;

  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _unreadCount = _db.getUnreadNotificationCount();
    _unreadUserCount = _db.getUnreadNotificationCount(recipient: 'user');
    _unreadAdminCount = _db.getUnreadNotificationCount(recipient: 'admin');
    _initialized = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> createNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? orderId,
    required String recipient,
  }) async {
    final notif = NotificationModel(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      title: title,
      body: body,
      type: type,
      orderId: orderId,
      createdAt: DateTime.now(),
      recipient: recipient,
    );

    await _db.saveNotification(notif);
    _refreshUnreadCount();
    notifyListeners();
    _playSound();
  }

  void _refreshUnreadCount() {
    _unreadCount = _db.getUnreadNotificationCount();
    _unreadUserCount = _db.getUnreadNotificationCount(recipient: 'user');
    _unreadAdminCount = _db.getUnreadNotificationCount(recipient: 'admin');
  }

  Future<void> markAsRead(String id) async {
    await _db.markNotificationAsRead(id);
    _refreshUnreadCount();
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    await _db.markAllNotificationsAsRead();
    _refreshUnreadCount();
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    await _db.deleteNotification(id);
    _refreshUnreadCount();
    notifyListeners();
  }

  void _playSound() {
    SoundHelper.playNotificationSound();
  }

  List<NotificationModel> getNotifications({String? recipient}) {
    var list = _db.getNotifications();
    if (recipient != null) {
      list = list.where((n) => n.recipient == recipient || n.recipient == 'both').toList();
    }
    return list;
  }
}
