import 'package:flutter/material.dart';

class AppColors {
  // PRIMARY - Deep Space Silicon Valley Palette
  static const Color background = Color(0xFF0A192F); // Deep Space Blue
  static const Color primary = Color(0xFF00D4FF);    // Electric Blue
  static const Color accent = Color(0xFF00FFE0);     // Neon Cyan
  static const Color white = Colors.white;

  // SECONDARY - Premium Gradients
  static const Color gradStart = Color(0xFF667EEA);
  static const Color gradEnd = Color(0xFF764BA2);
  
  // SEMANTIC
  static const Color success = Color(0xFF00FF9D);
  static const Color warning = Color(0xFFFFD166);
  static const Color error = Color(0xFFFF6B6B);

  // DEPTH
  static const Color surface = Color(0x0DFFFFFF); // rgba(255, 255, 255, 0.05)
  static final Color glow = const Color(0xFF00D4FF).withOpacity(0.3);

  // LEGACY (for backward compatibility during migration)
  static const Color deepBlue = Color(0xFF0A192F);
  static const Color secondary = Color(0xFF00FFE0);
  static const Color textBody = Colors.white70;
}
