import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
  final FlutterTts _tts = FlutterTts();
  bool _showBrandNote = false;
  bool _isNavigated = false;
  Timer? _nuclearTimer;

  @override
  void initState() {
    super.initState();
    debugPrint('[CVI_SPLASH] 0ms: Nuclear Sequence Initialized');
    
    _loadingCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000));

    // 1. ABSOLUTE FAIL-SAFE (Triggered at 5.0s no matter what)
    _nuclearTimer = Timer(const Duration(milliseconds: 5000), () {
      debugPrint('[CVI_SPLASH] 5000ms: NUCLEAR FAIL-SAFE TRIGGERED');
      _navigate();
    });

    // 2. RUN SEQUENCES INDEPENDENTLY (No mutual blocking)
    _runVisualSequence();
    _runAudioSequence();
    
    // 3. TARGETED NAVIGATION (Triggered at 4.7s)
    Future.delayed(const Duration(milliseconds: 4700), () {
      debugPrint('[CVI_SPLASH] 4700ms: Targeted Navigation Trigger');
      _navigate();
    });
  }

  void _runVisualSequence() {
    debugPrint('[CVI_SPLASH] Logic: Visual Sequence Started');
    _loadingCtrl.forward();
    
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _showBrandNote = true);
        debugPrint('[CVI_SPLASH] 1200ms: Brand Note Displayed');
      }
    });
  }

  void _runAudioSequence() async {
    try {
      debugPrint('[CVI_SPLASH] TTS: Warming up engine...');
      await _tts.setLanguage("hi-IN");
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.4);
      await _tts.setVolume(1.0);
      
      // Sync with visual reveal
      await Future.delayed(const Duration(milliseconds: 1500));
      
      debugPrint('[CVI_SPLASH] 1500ms: TTS Speak Attempt');
      await _tts.speak("जागो भारत जागो");
      debugPrint('[CVI_SPLASH] TTS: Speak call return');
    } catch (e) {
      debugPrint('[CVI_SPLASH] TTS ERROR (Ignored): $e');
    }
  }

  @override
  void dispose() {
    _nuclearTimer?.cancel();
    _loadingCtrl.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _navigate() async {
    if (!mounted || _isNavigated) return;
    
    // Guard against rapid multi-nav
    _isNavigated = true;
    
    debugPrint('[CVI_SPLASH] Nav: Starting transition flow...');

    final auth = context.read<AuthProvider>();
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('cvi_onboarded') ?? false;

    // Final safety check for context
    if (!mounted) return;
    
    String target;
    if (auth.isAuthenticated) {
      target = Routes.dashboard;
    } else if (!seen) {
      target = Routes.onboarding;
    } else {
      target = Routes.auth;
    }
    
    debugPrint('[CVI_SPLASH] Nav: Target resolved to -> $target');
    
    // Extra safety: Delay slightly to ensure any pending frames are clear
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    // FORCE LOCAL SYSTEM FONTS FOR SPLASH
    return Theme(
      data: ThemeData.dark().copyWith(
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'serif', color: AppColors.textPrimary),
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.bgDeep,
        body: Stack(
          children: [
            const Positioned.fill(child: ParticleBackground()),
            const Center(
              child: ChakraPainterWidget(
                size: 280,
                opacity: 0.03,
                color: AppColors.gold,
                rotationSeconds: 20,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    
                    // Branded CVI Header
                    Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppColors.saffron, AppColors.gold],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).createShader(bounds),
                        child: const Text(
                          'CVI',
                          style: TextStyle(
                            fontSize: 100,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -4,
                            fontFamily: 'serif',
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.9, 0.9)),

                    const SizedBox(height: 8),

                    const Text(
                      'CIVIC VOICE INTERFACE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 6,
                        fontFamily: 'sans-serif',
                      ),
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 60),

                    // Welcome Note
                    if (_showBrandNote)
                      const Text(
                        'जागो भारत जागो',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: AppColors.saffron,
                          letterSpacing: 2,
                          fontFamily: 'serif',
                          shadows: [
                            Shadow(
                              color: Color(0xAAFF6B1A),
                              blurRadius: 25,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),

                    const Spacer(flex: 4),

                    // Bottom Attribution
                    const Text(
                      'भारत सरकार की सेवा में',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                        letterSpacing: 2,
                        fontFamily: 'serif',
                      ),
                    ).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: 24),
                    
                    // Loading Indicator
                    AnimatedBuilder(
                      animation: _loadingCtrl,
                      builder: (context, child) {
                        return Container(
                          height: 2,
                          width: 180,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(1),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _loadingCtrl.value,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [AppColors.saffron, Colors.white, AppColors.emerald],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
