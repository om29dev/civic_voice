import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/glass/glass_card.dart';
import '../../../widgets/animated/voice_waveform.dart';
import '../../../widgets/animated/particle_background.dart';

class VoiceInterfaceScreen extends StatefulWidget {
  const VoiceInterfaceScreen({super.key});

  @override
  State<VoiceInterfaceScreen> createState() => _VoiceInterfaceScreenState();
}

class _VoiceInterfaceScreenState extends State<VoiceInterfaceScreen>
    with TickerProviderStateMixin {
  bool _isListening = false;
  late AnimationController _avatarController;
  late AnimationController _gridController;
  late Animation<double> _avatarAnimation;

  final List<Map<String, dynamic>> _messages = [
    {'text': 'How do I apply for a ration card?', 'isUser': true},
    {'text': 'I can help you with that! You\'ll need your Aadhaar card, address proof, and income certificate. Would you like me to guide you through the process?', 'isUser': false},
  ];

  final List<String> _quickResponses = [
    'Yes, please',
    'What documents?',
    'Show offices',
    'Start over',
  ];

  @override
  void initState() {
    super.initState();
    
    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _avatarAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _avatarController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _avatarController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepSpaceBlue,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.pureWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Voice Assistant',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.pureWhite,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.pureWhite),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Animated grid background
          Positioned.fill(
            child: CustomPaint(
              painter: _AnimatedGridPainter(
                animation: _gridController,
                color: AppTheme.electricBlue,
              ),
            ),
          ),
          
          // Particle effects
          const Positioned.fill(
            child: ParticleBackground(
              numberOfParticles: 40,
              particleColor: AppTheme.neonCyan,
              connectParticles: false,
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Animated Avatar
                _buildAnimatedAvatar(),
                
                const SizedBox(height: 30),
                
                // Voice Waveform Visualizer
                _buildWaveformVisualizer(),
                
                const SizedBox(height: 30),
                
                // Conversation Bubbles
                Expanded(
                  child: _buildConversationList(),
                ),
                
                // Quick Responses
                _buildQuickResponses(),
                
                const SizedBox(height: 20),
                
                // Voice Control Button
                _buildVoiceControlButton(),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedAvatar() {
    return AnimatedBuilder(
      animation: _avatarAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _avatarAnimation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.electricBlue.withOpacity(0.8),
                  AppTheme.neonCyan.withOpacity(0.6),
                  AppTheme.gradientStart.withOpacity(0.4),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.electricBlue.withOpacity(0.6),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: AppTheme.neonCyan.withOpacity(0.4),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Rotating rings
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RotatingRingsPainter(
                      animation: _avatarController,
                      isActive: _isListening,
                    ),
                  ),
                ),
                
                // Center icon
                Center(
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    size: 50,
                    color: AppTheme.pureWhite,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveformVisualizer() {
    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: _isListening
          ? VoiceWaveform(
              isListening: _isListening,
              size: 200,
              color: AppTheme.electricBlue,
            )
          : CircularWaveform(
              isActive: _isListening,
              size: 200,
              color: AppTheme.electricBlue,
            ),
    );
  }

  Widget _buildConversationList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      reverse: true,
      physics: const BouncingScrollPhysics(),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final reversedIndex = _messages.length - 1 - index;
        final message = _messages[reversedIndex];
        return _AnimatedMessageBubble(
          message: message['text'] as String,
          isUser: message['isUser'] as bool,
          delay: Duration(milliseconds: index * 100),
        );
      },
    );
  }

  Widget _buildQuickResponses() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _quickResponses.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _QuickResponseChip(
              label: _quickResponses[index],
              onTap: () {},
            ),
          );
        },
      ),
    );
  }

  Widget _buildVoiceControlButton() {
    return GestureDetector(
      onTap: _toggleListening,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: _isListening ? 200 : 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: _isListening ? AppTheme.primaryGradient : AppTheme.accentGradient,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: (_isListening ? AppTheme.gradientStart : AppTheme.electricBlue).withOpacity(0.6),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isListening ? Icons.stop : Icons.mic,
              color: AppTheme.pureWhite,
              size: 32,
            ),
            if (_isListening) ...[
              const SizedBox(width: 12),
              Text(
                'Listening...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.pureWhite,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnimatedMessageBubble extends StatefulWidget {
  final String message;
  final bool isUser;
  final Duration delay;

  const _AnimatedMessageBubble({
    required this.message,
    required this.isUser,
    required this.delay,
  });

  @override
  State<_AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<_AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.isUser ? 1 : -1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Align(
            alignment: widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isUser
                      ? [AppTheme.electricBlue.withOpacity(0.4), AppTheme.electricBlue.withOpacity(0.2)]
                      : [AppTheme.gradientStart.withOpacity(0.4), AppTheme.gradientEnd.withOpacity(0.2)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(widget.isUser ? 20 : 4),
                  bottomRight: Radius.circular(widget.isUser ? 4 : 20),
                ),
                border: Border.all(
                  color: widget.isUser
                      ? AppTheme.electricBlue.withOpacity(0.4)
                      : AppTheme.gradientStart.withOpacity(0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isUser ? AppTheme.electricBlue : AppTheme.gradientStart).withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                widget.message,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppTheme.pureWhite,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickResponseChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickResponseChip({
    required this.label,
    required this.onTap,
  });

  @override
  State<_QuickResponseChip> createState() => _QuickResponseChipState();
}

class _QuickResponseChipState extends State<_QuickResponseChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: _isPressed
              ? AppTheme.accentGradient
              : LinearGradient(
                  colors: [
                    AppTheme.glassBackground,
                    AppTheme.glassBackground,
                  ],
                ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _isPressed ? AppTheme.electricBlue : AppTheme.glassBorder,
            width: 1,
          ),
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: AppTheme.electricBlue.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.pureWhite,
          ),
        ),
      ),
    );
  }
}

class _AnimatedGridPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _AnimatedGridPainter({
    required this.animation,
    required this.color,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.05)
      ..strokeWidth = 1;

    final spacing = 40.0;
    final offset = (animation.value * spacing) % spacing;

    // Vertical lines
    for (double x = -spacing + offset; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (double y = -spacing + offset; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_AnimatedGridPainter oldDelegate) => true;
}

class _RotatingRingsPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isActive;

  _RotatingRingsPainter({
    required this.animation,
    required this.isActive,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (!isActive) return;

    for (int i = 0; i < 3; i++) {
      final ringRadius = radius * (0.7 + i * 0.15);
      final rotation = animation.value * 2 * 3.14159 * (i.isEven ? 1 : -1);

      final paint = Paint()
        ..color = AppTheme.pureWhite.withOpacity(0.2 - i * 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);
      canvas.translate(-center.dx, -center.dy);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        0,
        3.14159,
        false,
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_RotatingRingsPainter oldDelegate) => true;
}
