import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';

class NotificationScreen extends StatelessWidget {
  final String? recipient;
  const NotificationScreen({super.key, this.recipient});

  @override
  Widget build(BuildContext context) {
    final service = NotificationService();
    service.initialize();

    return Consumer<NotificationService>(
      builder: (context, notifService, _) {
        final notifications = notifService.getNotifications(recipient: recipient);
        final unreadCount = notifications.where((n) => !n.isRead).length;

        return Scaffold(
          backgroundColor: AppColors.offWhite,
          appBar: AppBar(
            backgroundColor: AppColors.pureWhite,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              color: AppColors.pitchBlack,
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Notifikasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.pitchBlack,
              ),
            ),
            actions: [
              if (unreadCount > 0)
                TextButton(
                  onPressed: () => notifService.markAllAsRead(),
                  child: const Text(
                    'Tandai Dibaca',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pitchBlack,
                    ),
                  ),
                ),
            ],
          ),
          body: notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 64,
                        color: AppColors.softGrey.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada notifikasi',
                        style: AppTextStyles.heading4.copyWith(
                          color: AppColors.softGrey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    return _buildNotificationCard(context, notif, notifService);
                  },
                ),
        );
      },
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel notif,
    NotificationService service,
  ) {
    final iconData = _iconForType(notif.type);
    final iconColor = _colorForType(notif.type);

    return GestureDetector(
      onTap: () {
        if (!notif.isRead) service.markAsRead(notif.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppConstants.spacingM),
        decoration: BoxDecoration(
          color: notif.isRead ? AppColors.pureWhite : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notif.isRead
                ? AppColors.borderGrey
                : AppColors.pitchBlack.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight:
                                notif.isRead ? FontWeight.w500 : FontWeight.w700,
                            color: AppColors.pitchBlack,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notif.createdAt),
                    style: AppTextStyles.bodyXSmall.copyWith(
                      color: AppColors.softGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return Icons.shopping_bag_rounded;
      case NotificationType.paymentConfirmed:
        return Icons.payment_rounded;
      case NotificationType.orderProcessing:
        return Icons.inventory_2_rounded;
      case NotificationType.orderShipped:
        return Icons.local_shipping_rounded;
      case NotificationType.orderDelivered:
        return Icons.check_circle_rounded;
      case NotificationType.orderCancelled:
        return Icons.cancel_rounded;
    }
  }

  Color _colorForType(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return AppColors.info;
      case NotificationType.paymentConfirmed:
        return AppColors.success;
      case NotificationType.orderProcessing:
        return AppColors.charcoal;
      case NotificationType.orderShipped:
        return AppColors.warning;
      case NotificationType.orderDelivered:
        return AppColors.success;
      case NotificationType.orderCancelled:
        return AppColors.error;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
