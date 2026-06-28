import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Custom Squircle Icon Widget
/// Used for navigation icons and category icons
class SquircleIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final double size;
  final bool useGradient;

  const SquircleIcon({
    super.key,
    required this.icon,
    this.isActive = false,
    this.size = 24,
    this.useGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: isActive && useGradient ? AppColors.blackGradient : null,
        color: isActive ? null : AppColors.lightGrey,
      ),
      child: Icon(
        icon,
        size: size,
        color: isActive ? AppColors.pureWhite : AppColors.charcoal,
      ),
    );
  }
}

/// Squircle Icon Button with badge support
class SquircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final int? badgeCount;
  final double iconSize;

  const SquircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.badgeCount,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.borderGrey,
            width: 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                icon,
                size: iconSize,
                color: AppColors.pitchBlack,
              ),
            ),
            if (badgeCount != null && badgeCount! > 0)
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
                    badgeCount! > 9 ? '9+' : '$badgeCount',
                    style: const TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 10,
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

/// Category Icon with squircle background
class CategorySquircleIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategorySquircleIcon({
    super.key,
    required this.icon,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.pitchBlack : AppColors.pureWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.pitchBlack : AppColors.borderGrey,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.pitchBlack.withValues(alpha: 0.2)
                      : AppColors.shadowColorLight,
                  blurRadius: isSelected ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 28,
              color: isSelected ? AppColors.pureWhite : AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient Status Badge
class GradientStatusBadge extends StatelessWidget {
  final String text;
  final LinearGradient? gradient;

  const GradientStatusBadge({
    super.key,
    required this.text,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.pureWhite,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Outlined Button Style
class OutlinedSquircleButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final IconData? icon;

  const OutlinedSquircleButton({
    super.key,
    required this.text,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.pitchBlack,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: AppColors.pitchBlack,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.pitchBlack,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}