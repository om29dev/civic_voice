import 'dart:math' as math;
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:civic_voice_interface/core/theme/app_theme.dart';
import 'package:civic_voice_interface/providers/voice_provider.dart';
import 'package:civic_voice_interface/providers/conversation_provider.dart';
import 'package:civic_voice_interface/providers/language_provider.dart';
import 'package:civic_voice_interface/models/conversation_model.dart';
import 'package:url_launcher/url_launcher.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: _buildHistoryDrawer(context, convo),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            
            // 2. Minimalistic AI Indicator
            Expanded(
              flex: 2,
              child: _AICoreVisualizer(state: voice.state),
            ),

            // 3. Conversation List
            Expanded(
              flex: 3,
              child: _ConversationConsole(convo: convo),
            ),

            // 4. Input Area
            _buildInteractionDeck(context, voice, convo),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.history, color: theme.colorScheme.onSurface),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          Text(
            lang.translate('voice_assistant'),
            style: theme.textTheme.headlineSmall,
          ),
          IconButton(
            icon: Icon(Icons.close_fullscreen_rounded, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionDeck(BuildContext context, VoiceProvider voice, ConversationProvider convo) {
    final theme = Theme.of(context);
    final textController = TextEditingController();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (voice.errorMessage.isNotEmpty)
            _buildErrorTip(voice.errorMessage),
          
          Row(
            children: [
              IconButton(
                onPressed: () => convo.clearMessages(),
                icon: Icon(Icons.add, color: theme.colorScheme.primary),
                tooltip: 'New Chat',
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      hintText: 'Type or ask...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (text) {
                      if (text.trim().isNotEmpty) {
                        convo.sendMessage(text.trim());
                        textController.clear();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                child: _buildOrbButton(context, voice.isListening, voice.state == VoiceState.error),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorTip(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        error,
        style: const TextStyle(color: AppTheme.error, fontSize: 12),
      ),
    ).animate().shake();
  }

  Widget _buildOrbButton(BuildContext context, bool active, bool isError) {
    final theme = Theme.of(context);
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isError 
            ? AppTheme.error 
            : (active ? theme.colorScheme.primary : theme.colorScheme.surface),
        boxShadow: [
          BoxShadow(
            color: (isError ? AppTheme.error : (active ? theme.colorScheme.primary : theme.colorScheme.onSurface)).withOpacity(0.2),
            blurRadius: active || isError ? 30 : 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          isError ? Icons.refresh_rounded : (active ? Icons.stop_rounded : Icons.mic_rounded),
          color: isError || active ? Colors.white : theme.colorScheme.onSurface,
          size: 32,
        ),
      ),
    ).animate(onPlay: (c) => active ? c.repeat() : c.stop())
     .shimmer(duration: 2.seconds);
  }

  Widget _buildHistoryDrawer(BuildContext context, ConversationProvider convo) {
    final theme = Theme.of(context);
    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(Icons.history, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text('Chat History', style: theme.textTheme.titleLarge),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: convo.messages.length,
                itemBuilder: (context, index) {
                   final msg = convo.messages[index];
                   return ListTile(
                     leading: Icon(msg.isUser ? Icons.person_outline : Icons.smart_toy_outlined),
                     title: Text(msg.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                     subtitle: Text(DateFormat('HH:mm').format(msg.timestamp)),
                     onLongPress: () {
                        convo.deleteMessage(index);
                     },
                     onTap: () {
                       // Scroll to message or just highlight?
                       Navigator.pop(context);
                     },
                   );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton.icon(
                onPressed: () => convo.clearMessages(),
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Clear All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error.withOpacity(0.1),
                  foregroundColor: AppTheme.error,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    final theme = Theme.of(context);
    Color coreColor;
    double scale = 1.0;
    
    switch (widget.state) {
      case VoiceState.listening: coreColor = theme.colorScheme.primary; scale = 1.1; break;
      case VoiceState.processing: coreColor = theme.colorScheme.tertiary; scale = 1.05; break; // Use tertiary if available, or secondary
      case VoiceState.responding: coreColor = theme.colorScheme.secondary; scale = 1.2; break;
      case VoiceState.error: coreColor = theme.colorScheme.error; scale = 1.0; break;
      default: coreColor = theme.colorScheme.onSurface.withOpacity(0.1);
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



// Minimalistic Conversation Console
class _ConversationConsole extends StatelessWidget {
  final ConversationProvider convo;
  const _ConversationConsole({required this.convo});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      reverse: true,
      physics: const BouncingScrollPhysics(),
      itemCount: convo.messages.length,
      itemBuilder: (context, index) {
        final msg = convo.messages.reversed.toList()[index];
        return _buildMessageBubble(context, msg);
      },
    );
  }

  Widget _buildMessageBubble(BuildContext context, Message msg) {
    final isUser = msg.isUser;
    final theme = Theme.of(context);
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(
              color: isUser 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              msg.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
          
          if (msg.action != null)
            _buildActionCard(context, msg.action!),
            
          const SizedBox(height: 8),
        ],
      ),
    );
  }


  Widget _buildActionCard(BuildContext context, Map<String, dynamic> action) {
    final theme = Theme.of(context);
    final String type = action['type'] ?? '';
    
    IconData icon;
    String label;
    VoidCallback onTap;
    
    switch (type) {
      case 'link':
        icon = Icons.open_in_new_rounded;
        label = action['text'] ?? 'Open Link';
        onTap = () async {
          final url = Uri.parse(action['url'] ?? '');
          if (await canLaunchUrl(url)) await launchUrl(url);
        };
        break;
      case 'navigate':
        icon = Icons.directions_rounded;
        label = 'Launch Application';
        onTap = () {
          // Navigation logic would go here
          debugPrint("Navigating to: ${action['screen']}");
        };
        break;
      case 'guide':
        icon = Icons.auto_stories_rounded;
        label = action['title'] ?? 'Review Guide';
        onTap = () {
          debugPrint("Showing guide steps: ${action['steps']}");
        };
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }
}
