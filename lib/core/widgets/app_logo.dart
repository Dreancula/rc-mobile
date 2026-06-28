import 'package:flutter/material.dart';

/// Reusable app logo widget
/// Supports multiple sizes: small (56px), medium (80px), large (120px)
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({
    super.key,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25),
        child: Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to text logo if image not found
            return Container(
              width: size,
              height: size,
              color: Colors.black,
              child: Center(
                child: Text(
                  'RC',
                  style: TextStyle(
                    fontSize: size * 0.37,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
