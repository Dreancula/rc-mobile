import 'package:flutter/material.dart';

/// App Color Palette - Clean Modern & Elegant Monochrome Theme
/// Based on #0A0A0A (Pitch Black) and #FFFFFF (Pure White)
class AppColors {
  AppColors._();

  // ===== PRIMARY COLORS =====
  // Pitch Black - Main dark color
  static const Color pitchBlack = Color(0xFF0A0A0A);
  // Pure White - Main light color
  static const Color pureWhite = Color(0xFFFFFFFF);

  // For backwards compatibility
  static const Color primaryBlack = pitchBlack;
  static const Color primaryWhite = pureWhite;

  // ===== MONOCHROME GRADIENT PALETTE =====
  // Dark shades
  static const Color deepBlack = Color(0xFF050505);
  static const Color softBlack = Color(0xFF1A1A1A);
  static const Color charcoal = Color(0xFF2D2D2D);
  static const Color darkCharcoal = Color(0xFF3D3D3D);

  // Light shades
  static const Color offWhite = Color(0xFFFAFAFA);
  static const Color lightGrey = Color(0xFFF0F0F0);
  static const Color mediumGrey = Color(0xFFBDBDBD);
  static const Color softGrey = Color(0xFF9E9E9E);

  // For backwards compatibility
  static const Color darkGrey = charcoal;
  static const Color accentGrey = softGrey;
  static const Color borderGrey = Color(0xFFE5E5E5);
  static const Color dividerColor = Color(0xFFF0F0F0);

  // ===== SEMANTIC COLORS =====
  // Status colors (keeping minimal)
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // ===== GRADIENTS =====
  // Only used as accents, not backgrounds

  // Black gradient - for CTA buttons, active elements
  static const LinearGradient blackGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D2D2D), Color(0xFF0A0A0A)],
  );

  // Soft black gradient - for subtle accents
  static const LinearGradient softBlackGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF1A1A1A), Color(0xFF333333)],
  );

  // White gradient - for light backgrounds
  static const LinearGradient whiteGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF5F5F5)],
  );

  // Card gradient - for status badges, active cards
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
  );

  // Splash screen gradient
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
  );

  static const Gradient buttonGradient = LinearGradient(
    colors: [Color(0xFF2D2D2D), Color(0xFF0A0A0A)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ===== SHADOWS =====
  static const Color shadowColor = Color(0x0D000000);
  static const Color shadowColorLight = Color(0x08000000);
  static const Color shadowColorMedium = Color(0x14000000);

  // ===== GLASSMORPHISM =====
  static const Color glassBackground = Color(0xF0FFFFFF);
  static const Color glassBorder = Color(0x1A000000);
}
