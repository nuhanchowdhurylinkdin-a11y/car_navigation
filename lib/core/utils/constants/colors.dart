import 'package:flutter/material.dart';

/// NavTest design system colors (from the Stitch style guide).
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF3D5AFE); // Deep Indigo: main actions, route line
  static const Color accent = Color(0xFF00BFA5); // Vivid Teal: "Go" actions (Start, Resume)

  // Status
  static const Color error = Color(0xFFE53935); // Traffic / Stop, destination pin
  static const Color warning = Color(0xFFFFA000); // Congestion, timeouts
  static const Color success = Color(0xFF43A047); // Arrived

  // Surfaces
  static const Color white = Color(0xFFFFFFFF);
  static const Color tint = Color(0xFFF5F7FB); // App background tint

  // Text
  static const Color textPrimary = Color(0xFF1A1C29);
  static const Color textSecondary = Color(0xFF6B7085);
}
