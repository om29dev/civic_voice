import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

/// Bilingual label widget — English text on top, Hindi (Devanagari) below.
/// Used throughout the app for culturally authentic, accessible labeling.
class BilingualLabel extends StatelessWidget {
  final String englishText;
  final String hindiText;
  /// Scale multiplier applied to default font sizes.
  final double scale;
  final TextAlign align;
  final Color? englishColor;
  final Color? hindiColor;
  final FontWeight englishWeight;

  const BilingualLabel({
    super.key,
    required this.englishText,
    required this.hindiText,
    this.scale = 1.0,
    this.align = TextAlign.start,
    this.englishColor,
    this.hindiColor,
    this.englishWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align == TextAlign.center
          ? CrossAxisAlignment.center
          : align == TextAlign.end
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          englishText,
          textAlign: align,
          style: GoogleFonts.poppins(
            fontSize: 14 * scale,
            fontWeight: englishWeight,
            color: englishColor ?? AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          hindiText,
          textAlign: align,
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 11 * scale,
            fontWeight: FontWeight.w400,
            color: hindiColor ?? AppColors.textMuted,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
