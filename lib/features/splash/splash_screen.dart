import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/decorative/chakra_painter.dart';
import '../../widgets/decorative/tricolor_bar.dart';
import '../../widgets/particle_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _loadingCtrl;

  @override
  void initState() {
    super.initState();
    _loadingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..forward();
    Future.delayed(const Duration(milliseconds: 3200), _navigate);
  }

  @override
  void dispose() {
    _loadingCtrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('cvi_onboarded') ?? false;

    if (!mounted) return;
    if (auth.isAuthenticated) {
      context.go(Routes.dashboard);
    } else if (!seen) {
      context.go(Routes.onboarding);
    } else {
      context.go(Routes.auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          const Positioned.fill(
            child: ParticleBackground(),
          ),
          
          // ── Centered Ashoka Chakra watermark ──────────────────────────────
          const Center(
            child: ChakraPainterWidget(
              size: 280,
              opacity: 0.05,
              color: AppColors.gold,
              rotationSeconds: 16,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // ── CVI Hero Logo ────────────────────────────────────────────
                Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.saffron, AppColors.gold],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: Text(
                      'CVI',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 72,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -2,
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 700.ms).slideY(
                      begin: 0.15,
                      end: 0,
                      curve: Curves.easeOut,
                      duration: 700.ms,
                    ),

                const SizedBox(height: 10),

                // ── Civic Voice Interface subtitle ───────────────────────────
                Text(
                  'Civic Voice Interface',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    letterSpacing: 3,
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

                const SizedBox(height: 6),

                // ── Hindi tagline ────────────────────────────────────────────
                Text(
                  'सेवा · सुलभ · स्मार्ट',
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.gold.withValues(alpha: 0.55),
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 600.ms),

                const Spacer(flex: 4),

                // ── Bottom section ───────────────────────────────────────────
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'भारत सरकार की सेवा में',
                      style: GoogleFonts.notoSansDevanagari(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ).animate().fadeIn(delay: 800.ms),

                    const SizedBox(height: 14),

                    // Saffron loading line sweeping across
                    AnimatedBuilder(
                      animation: _loadingCtrl,
                      builder: (context, child) {
                        return Stack(
                          children: [
                            const TricolorBar(height: 2),
                            Positioned.fill(
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _loadingCtrl.value,
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.saffron.withValues(alpha: 0),
                                        AppColors.saffron,
                                        Colors.white.withValues(alpha: 0.8),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
