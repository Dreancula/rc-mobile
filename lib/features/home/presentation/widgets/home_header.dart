import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';

/// Home Header Widget with Greeting and Action Icons
class HomeHeader extends StatelessWidget {
  final String userName;
  final VoidCallback? onSearchTap;
  final VoidCallback? onCartTap;
  final VoidCallback? onNotificationTap;
  final int cartItemCount;

  const HomeHeader({
    super.key,
    this.userName = 'Pengguna',
    this.onSearchTap,
    this.onCartTap,
    this.onNotificationTap,
    this.cartItemCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
        vertical: AppConstants.spacingS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hey, ${userName}!',
                  style: AppTextStyles.heading3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppConstants.spacingXS),
                Text(
                  'Temukan gaya casual favoritmu',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.softGrey,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildIconButton(
                icon: Icons.search,
                onTap: onSearchTap ?? () {},
              ),
              const SizedBox(width: AppConstants.spacingS),
              _buildIconButton(
                icon: Icons.notifications_outlined,
                onTap: onNotificationTap ?? () {},
              ),
              const SizedBox(width: AppConstants.spacingS),
              _buildCartButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        child: Icon(
          icon,
          color: AppColors.primaryBlack,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildCartButton() {
    return GestureDetector(
      onTap: onCartTap ?? () {},
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.primaryBlack,
                size: 22,
              ),
            ),
            if (cartItemCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    cartItemCount > 9 ? '9+' : '$cartItemCount',
                    style: AppTextStyles.bodyXSmall.copyWith(
                      color: AppColors.primaryWhite,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
