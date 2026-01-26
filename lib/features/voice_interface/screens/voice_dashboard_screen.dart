import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:civic_voice_interface/core/constants/app_colors.dart';
import 'package:civic_voice_interface/providers/voice_provider.dart';
import 'package:civic_voice_interface/providers/conversation_provider.dart';
import 'package:civic_voice_interface/providers/language_provider.dart';

class VoiceDashboardScreen extends StatelessWidget {
  const VoiceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final voice = Provider.of<VoiceProvider>(context);
    final convo = Provider.of<ConversationProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);

    // Sync language choice
    WidgetsBinding.instance.addPostFrameCallback((_) {
      voice.setLocale(lang.fullLocaleId);
      convo.setLanguage(lang.currentLanguage == AppLanguage.hindi ? 'hi' : 'en');
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Animated Sci-Fi Grid Background
          const Positioned.fill(child: _SciFiGrid()),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                
                // 2. Abstract Morphing AI Core
                Expanded(
                  flex: 2,
                  child: _AICoreVisualizer(state: voice.state),
                ),

                // 3. Shimmering Conversation Hub
                Expanded(
                  flex: 3,
                  child: _ConversationConsole(convo: convo),
                ),

                // 4. Interaction Controls (Glass FAB Overlay)
                _buildInteractionDeck(context, voice, convo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NEURAL LINK ACTIVE',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              Text(
                lang.translate('voice_assistant'),
                style: GoogleFonts.poppins(
                  color: AppColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close_fullscreen_rounded, color: AppColors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionDeck(BuildContext context, VoiceProvider voice, ConversationProvider convo) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [AppColors.background, AppColors.background.withOpacity(0)],
        ),
      ),
      child: Column(
        children: [
          if (voice.errorMessage.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Text(
                voice.errorMessage,
                style: GoogleFonts.inter(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ).animate().shake(),
          if (voice.lastWords.isNotEmpty && voice.errorMessage.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                voice.lastWords,
                style: GoogleFonts.inter(color: AppColors.white.withOpacity(0.7), fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn().slideY(begin: 0.5, end: 0),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              if (voice.state == VoiceState.error) {
                await voice.initVoice();
              } else if (voice.isListening) {
                voice.stopSilently();
              } else {
                await voice.startListening(onFinalResult: (text) => convo.sendMessage(text));
              }
            },
            child: _buildOrbButton(voice.isListening, voice.state == VoiceState.error),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbButton(bool active, bool isError) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: isError 
            ? [AppColors.error, AppColors.error.withOpacity(0.5), AppColors.error]
            : (active 
              ? [AppColors.primary, AppColors.accent, AppColors.primary]
              : [AppColors.white.withOpacity(0.1), AppColors.white.withOpacity(0.2), AppColors.white.withOpacity(0.1)]),
        ),
        boxShadow: [
          BoxShadow(
            color: (isError ? AppColors.error : (active ? AppColors.primary : AppColors.white)).withOpacity(0.3),
            blurRadius: active || isError ? 30 : 10,
            spreadRadius: active || isError ? 5 : 0,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
          child: Icon(
            isError ? Icons.refresh_rounded : (active ? Icons.stop_rounded : Icons.mic_rounded),
            color: isError ? AppColors.error : (active ? AppColors.primary : AppColors.white),
            size: 40,
          ),
        ),
      ),
    ).animate(onPlay: (c) => active ? c.repeat() : c.stop())
     .rotate(duration: 3.seconds);
  }
}

class _AICoreVisualizer extends StatefulWidget {
  final VoiceState state;
  const _AICoreVisualizer({required this.state});

  @override
  State<_AICoreVisualizer> createState() => _AICoreVisualizerState();
}

class _AICoreVisualizerState extends State<_AICoreVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color coreColor;
    double scale = 1.0;
    
    switch (widget.state) {
      case VoiceState.listening: coreColor = AppColors.primary; scale = 1.2; break;
      case VoiceState.processing: coreColor = AppColors.warning; scale = 1.1; break;
      case VoiceState.responding: coreColor = AppColors.accent; scale = 1.3; break;
      case VoiceState.error: coreColor = AppColors.error; scale = 1.0; break;
      default: coreColor = AppColors.white.withOpacity(0.2);
    }

    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _CorePainter(_controller.value, coreColor, widget.state),
            child: SizedBox(width: 200, height: 200),
          );
        },
      ),
    ).animate(target: scale).scale(duration: 500.ms, curve: Curves.easeOutBack);
  }
}

class _CorePainter extends CustomPainter {
  final double progress;
  final Color color;
  final VoiceState state;
  _CorePainter(this.progress, this.color, this.state);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Outer spinning rings
    for (int i = 0; i < 3; i++) {
      double radius = 60.0 + (i * 20);
      double rotation = progress * math.pi * 2 * (i % 2 == 0 ? 1 : -1);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        rotation,
        math.pi / 2,
        false,
        paint..color = color.withOpacity(0.3 / (i + 1)),
      );
    }

    // Inner morphing core
    if (state != VoiceState.idle) {
      final corePaint = Paint()..color = color.withOpacity(0.4)..style = PaintingStyle.fill;
      final path = Path();
      for (int i = 0; i < 8; i++) {
        double angle = (i * 45) * math.pi / 180;
        double r = 40 + math.sin(progress * math.pi * 2 + i) * 10;
        Offset p = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
        if (i == 0) path.moveTo(p.dx, p.dy); else path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, corePaint);
      canvas.drawShadow(path, color, 10, true);
    } else {
      canvas.drawCircle(center, 40, paint..color = color..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SciFiGrid extends StatelessWidget {
  const _SciFiGrid();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primary.withOpacity(0.05)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ConversationConsole extends StatelessWidget {
  final ConversationProvider convo;
  const _ConversationConsole({required this.convo});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(30),
      reverse: true,
      physics: const BouncingScrollPhysics(),
      itemCount: convo.messages.length,
      itemBuilder: (context, index) {
        final msg = convo.messages.reversed.toList()[index];
        return _buildMessageBubble(msg);
      },
    );
  }

  Widget _buildMessageBubble(dynamic msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isUser 
              ? [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0.05)]
              : [AppColors.gradEnd.withOpacity(0.2), AppColors.gradEnd.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(isUser ? 24 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 24),
          ),
          border: Border.all(
            color: (isUser ? AppColors.primary : AppColors.gradEnd).withOpacity(0.2),
          ),
        ),
        child: Text(
          msg.text,
          style: GoogleFonts.inter(color: AppColors.white, fontSize: 13, height: 1.5),
        ),
      ).animate().slideX(begin: isUser ? 0.3 : -0.3, end: 0, duration: 400.ms, curve: Curves.easeOut).fadeIn(),
    );
  }
}
