import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice_interface/core/constants/app_colors.dart';

void main() {
  group('AppColors design token tests', () {
    test('brand colors define expected values', () {
      expect(AppColors.saffron, equals(const Color(0xFFFF6B1A)));
      expect(AppColors.saffronDeep, equals(const Color(0xFFE8510A)));
      expect(AppColors.gold, equals(const Color(0xFFD4930A)));
      expect(AppColors.emerald, equals(const Color(0xFF0A7A3E)));
    });

    test('background and surface colors are differentiated for contrast', () {
      expect(AppColors.bgDeep, isNot(equals(AppColors.surface)));
      expect(AppColors.textPrimary, isNot(equals(AppColors.textSecondary)));
      expect(AppColors.textPrimary, equals(const Color(0xFFFFF8F0)));
    });

    test('gradients contain appropriate color stops', () {
      expect(AppColors.primaryGradient.colors, contains(AppColors.saffron));
      expect(AppColors.primaryGradient.colors, contains(AppColors.saffronDeep));
      expect(AppColors.goldGradient.colors, contains(AppColors.gold));
    });
  });
}

