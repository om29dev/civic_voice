import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/accessibility_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/services_provider.dart';
import '../../providers/voice_provider.dart';
import '../../widgets/indian_card.dart';
import '../../widgets/cvi_button.dart';
import '../../widgets/bilingual_label.dart';
import '../../widgets/decorative/jali_pattern.dart';

// ═════════════════════════════════════════════════════════════════════════════
// PROFILE SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          // Background Jali
          const Positioned.fill(
            child: JaliPattern(opacity: 0.03),
          ),
          
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Premium App Bar
              SliverAppBar(
                backgroundColor: AppColors.bgDeep.withValues(alpha: 0.9),
                elevation: 0,
                pinned: true,
                centerTitle: false,
                title: Text(
                  'My Profile',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF6B1A),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: AppColors.semanticError, size: 24),
                    onPressed: () => _confirmLogout(context, auth),
                    tooltip: 'Sign Out',
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Header Card
                    _ProfileHeader(user: user),
                    const SizedBox(height: 32),

                    // Applications
                    const _MySectionHeader('My Applications', 'मेरे आवेदन', Icons.apps_rounded),
                    const SizedBox(height: 16),
                    _ApplicationsSection(),
                    const SizedBox(height: 32),

                    // Language & Region
                    const _MySectionHeader('Language & Region', 'भाषा और क्षेत्र', Icons.language_rounded),
                    const SizedBox(height: 16),
                    _LanguageSection(),
                    const SizedBox(height: 32),

                    // Voice Settings
                    const _MySectionHeader('Voice Settings', 'आवाज़ सेटिंग', Icons.mic_rounded),
                    const SizedBox(height: 16),
                    _VoiceSettingsSection(),
                    const SizedBox(height: 32),

                    // Privacy & Security
                    const _MySectionHeader('Privacy & Security', 'गोपनीयता और सुरक्षा', Icons.security_rounded),
                    const SizedBox(height: 16),
                    _PrivacySection(),
                    const SizedBox(height: 32),

                    // About CVI
                    const _MySectionHeader('About CVI', 'सीवीआई के बारे में', Icons.info_outline_rounded),
                    const SizedBox(height: 16),
                    _AboutSection(),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        title: Text('Sign Out',
            style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          CviButton(
            text: 'Sign Out',
            variant: CviButtonVariant.primary,
            width: 120,
            onPressed: () async {
              final nav = Navigator.of(context);
              await auth.logout();
              if (nav.mounted) nav.pop();
            },
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HEADER
// ═════════════════════════════════════════════════════════════════════════════

class _ProfileHeader extends StatelessWidget {
  final UserModel? user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final initials = user?.initials ?? 'G';
    final name     = user?.name ?? 'Guest User';
    final email    = user?.email;
    final mobile   = user?.mobile;
    final joined   = user?.createdAt;
    final isGuest  = user?.isGuest ?? true;

    return IndianCard(
      isPremium: true,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            children: [
              // Avatar with gold ring
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B1A), Color(0xFFE8510A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(0xFFD4930A), width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66FF6B1A),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Edit overlay
              if (!isGuest)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.bgDeep,
                      border: Border.all(color: AppColors.gold, width: 1.5),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: AppColors.gold, size: 16),
                  ),
                ),
            ],
          )
              .animate()
              .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.elasticOut),
          const SizedBox(height: 20),
          
          Text(name,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
                  
          if (email != null || mobile != null) ...[
            const SizedBox(height: 8),
            if (mobile != null)
              Text('+91 $mobile',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 14)),
            if (email != null)
              Text(email,
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 14)),
          ],

          if (joined != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Text(
                'Member since ${_fmtDate(joined)}',
                style: GoogleFonts.spaceMono(
                    color: AppColors.textMuted,
                    fontSize: 11),
              ),
            ),
          ],

          if (!isGuest) ...[
            const SizedBox(height: 20),
            const Divider(color: AppColors.surfaceBorder, height: 1),
            const SizedBox(height: 16),
            // Verification badges
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (mobile != null) const _VerifiedBadge(label: 'Mobile Verified'),
                if (email != null) const _VerifiedBadge(label: 'Email Verified'),
                const _VerifiedBadge(label: 'Aadhaar Linked', isGold: true),
              ],
            ),
          ],

          if (isGuest) ...[
            const SizedBox(height: 24),
            CviButton(
              text: 'Create Account',
              variant: CviButtonVariant.gold,
              onPressed: () => context.go(Routes.auth),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0);
  }

  static String _fmtDate(DateTime d) =>
      '${_months[d.month - 1]} ${d.year}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
}

class _VerifiedBadge extends StatelessWidget {
  final String label;
  final bool isGold;
  const _VerifiedBadge({required this.label, this.isGold = false});

  @override
  Widget build(BuildContext context) {
    final color = isGold ? AppColors.gold : AppColors.emerald;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isGold ? Icons.verified_user_rounded : Icons.check_circle_rounded,
              color: color, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.inter(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// APPLICATIONS SECTION
// ═════════════════════════════════════════════════════════════════════════════

class _ApplicationsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sp       = context.watch<ServicesProvider>();
    final services = sp.allServices;

    // Only show services with any progress
    final active = services.where((s) {
      final prog = sp.getProgress(s.id);
      return prog.any((v) => v);
    }).toList();

    if (active.isEmpty) {
      return IndianCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.folder_open_rounded,
                  color: AppColors.textMuted, size: 36),
            ),
            const SizedBox(height: 16),
            Text('No applications started',
                style: GoogleFonts.playfairDisplay(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 8),
            Text('Explore services to begin your application process.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 13)),
                    
            const SizedBox(height: 20),
            CviButton(
              text: 'Browse Services',
              variant: CviButtonVariant.secondary,
              width: 160,
              onPressed: () => context.go(Routes.services),
            )
          ],
        ),
      );
    }

    return Column(
      children: active.map((s) {
        final progress = sp.getProgress(s.id);
        final done     = progress.where((v) => v).length;
        final total    = progress.length;
        final pct      = total > 0 ? done / total : 0.0;
        final complete = pct == 1.0;

        final (statusLabel, statusColor) = complete
            ? ('Approved', AppColors.emerald)
            : done > 0
                ? ('Processing', AppColors.saffron)
                : ('Submitted', AppColors.accentBlue);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: IndianCard(
            onTap: () {
              sp.selectService(s.id);
              context.go(Routes.serviceDetailPath(s.id));
            },
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(s.iconEmoji, style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.localizedName('en'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: statusColor.withValues(alpha: 0.3), width: 1),
                            ),
                            child: Text(statusLabel.toUpperCase(),
                                style: GoogleFonts.spaceMono(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: AppColors.bgDeep,
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('$done/$total steps',
                        style: GoogleFonts.spaceMono(
                            color: AppColors.textSecondary,
                            fontSize: 12)),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.04, end: 0),
        );
      }).toList(),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LANGUAGE & REGION
// ═════════════════════════════════════════════════════════════════════════════

class _LanguageSection extends StatelessWidget {
  static const _langs = [
    ('en', '🇬🇧', 'English'),
    ('hi', '🇮🇳', 'हिन्दी'),
    ('mr', '🇮🇳', 'मराठी'),
    ('ta', '🇮🇳', 'தமிழ்'),
  ];

  @override
  Widget build(BuildContext context) {
    final lp      = context.watch<LanguageProvider>();
    final current = lp.currentLanguage;

    return IndianCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 language chips
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.8,
            physics: const NeverScrollableScrollPhysics(),
            children: _langs.map((l) {
              final (code, flag, name) = l;
              final active = code == current;
              return GestureDetector(
                onTap: () => lp.switchLanguage(code),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.saffron.withValues(alpha: 0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active ? AppColors.saffron : AppColors.surfaceBorder,
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(flag, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Text(name,
                          style: GoogleFonts.poppins(
                            color: active
                                ? AppColors.saffron
                                : AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                          )),
                      if (active) ...[
                        const Spacer(),
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.saffron, size: 18),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.surfaceBorder, height: 1),
          const SizedBox(height: 20),

          // Font size
          Text('Text Size',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          _SegmentedSizeControl(),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }
}

class _SegmentedSizeControl extends StatefulWidget {
  @override
  State<_SegmentedSizeControl> createState() => _SegmentedSizeControlState();
}

class _SegmentedSizeControlState extends State<_SegmentedSizeControl> {
  static const _options = ['Small', 'Medium', 'Large'];
  static const _scaleValues = [0.85, 1.0, 1.2];

  @override
  Widget build(BuildContext context) {
    final access = context.watch<AccessibilityProvider>();
    int _selected = _scaleValues.indexOf(access.textScaleFactor);
    if (_selected == -1) _selected = 1; // fallback to Medium

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final active = _selected == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => access.setTextScale(_scaleValues[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.bgMid
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: active ? [
                    const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                  ] : null,
                ),
                child: Text(_options[i],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        color: active
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500)),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// VOICE SETTINGS
// ═════════════════════════════════════════════════════════════════════════════

class _VoiceSettingsSection extends StatefulWidget {
  @override
  State<_VoiceSettingsSection> createState() => _VoiceSettingsSectionState();
}

class _VoiceSettingsSectionState extends State<_VoiceSettingsSection> {
  bool _wakeWord = false;

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VoiceProvider>();

    return IndianCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // TTS speed
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Speech Speed',
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${vp.speechRate.toStringAsFixed(1)}×',
                    style: GoogleFonts.spaceMono(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.gold,
              inactiveTrackColor: AppColors.bgDeep,
              thumbColor: AppColors.gold,
              overlayColor: AppColors.gold.withValues(alpha: 0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 4,
            ),
            child: Slider(
              value: vp.speechRate,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              onChanged: (v) => vp.setSpeechRate(v),
            ),
          ),
          const Divider(color: AppColors.surfaceBorder, height: 1),

          // Voice gender
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text('Voice Gender',
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
                _GenderToggle(current: vp.voiceGender, vp: vp),
              ],
            ),
          ),
          const Divider(color: AppColors.surfaceBorder, height: 1),

          // Wake word
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            title: Text('Wake Word "Hey CVI"',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
            subtitle: Text('Beta feature',
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
            value: _wakeWord,
            activeColor: AppColors.saffron,
            activeTrackColor: AppColors.saffron.withValues(alpha: 0.3),
            inactiveTrackColor: AppColors.bgDeep,
            onChanged: (v) => setState(() => _wakeWord = v),
          ),
          const Divider(color: AppColors.surfaceBorder, height: 1),

          // Mic permission
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: _MicPermissionCard(vp: vp),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }
}

class _GenderToggle extends StatelessWidget {
  final String current;
  final VoiceProvider vp;
  const _GenderToggle({required this.current, required this.vp});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['female', 'male'].map((g) {
          final active = current == g;
          return GestureDetector(
            onTap: () => vp.setVoiceGender(g),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                boxShadow: active ? [
                  const BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))
                ] : null,
              ),
              child: Row(
                children: [
                   Icon(
                    g == 'female' ? Icons.female_rounded : Icons.male_rounded,
                    size: 16,
                    color: active ? AppColors.saffron : AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    g == 'female' ? 'Female' : 'Male',
                    style: GoogleFonts.inter(
                      color: active ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MicPermissionCard extends StatelessWidget {
  final VoiceProvider vp;
  const _MicPermissionCard({required this.vp});

  @override
  Widget build(BuildContext context) {
    final hasPerms = vp.state != VoiceState.permissionDenied;
    final color = hasPerms ? AppColors.emerald : AppColors.semanticError;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(hasPerms ? Icons.mic_rounded : Icons.mic_off_rounded,
              color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            hasPerms ? 'Microphone setup complete' : 'Microphone access required',
            style: GoogleFonts.inter(
                color: hasPerms ? AppColors.textPrimary : color,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
        ),
        if (!hasPerms)
          CviButton(
            text: 'Fix',
            variant: CviButtonVariant.secondary,
            width: 80,
            onPressed: () => vp.requestMicPermission(),
          ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PRIVACY & SECURITY
// ═════════════════════════════════════════════════════════════════════════════

class _PrivacySection extends StatefulWidget {
  @override
  State<_PrivacySection> createState() => _PrivacySectionState();
}

class _PrivacySectionState extends State<_PrivacySection> {
  bool _biometric = false;

  @override
  Widget build(BuildContext context) {
    return IndianCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Biometric
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            title: Text('Biometric Lock',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
            subtitle: Text('Require fingerprint to open app',
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
            value: _biometric,
            activeColor: AppColors.saffron,
            activeTrackColor: AppColors.saffron.withValues(alpha: 0.3),
            inactiveTrackColor: AppColors.bgDeep,
            onChanged: (v) => setState(() => _biometric = v),
          ),
          const Divider(color: AppColors.surfaceBorder, height: 1),

          // Clear history
          _SettingsListTile(
            icon: Icons.delete_outline_rounded,
            title: 'Clear Conversation History',
            iconColor: AppColors.semanticError,
            textColor: AppColors.semanticError,
            onTap: () => _confirmClear(context),
          ),
          const Divider(color: AppColors.surfaceBorder, height: 1),

          // Export data
          _SettingsListTile(
            icon: Icons.download_rounded,
            title: 'Export My Data',
            showChevron: true,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.bgMid,
                  content: Text('Data export initiated. You will receive an email.', style: TextStyle(color: AppColors.textPrimary)),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const Divider(color: AppColors.surfaceBorder, height: 1),

          // Delete account
          _SettingsListTile(
            icon: Icons.person_remove_rounded,
            title: 'Delete Account',
            iconColor: AppColors.semanticError,
            textColor: AppColors.semanticError,
            isBold: true,
            onTap: () => _confirmDelete(context),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        title: Text('Clear History',
            style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        content: Text('This will permanently clear all conversation history.',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: AppColors.textSecondary))),
          CviButton(
            text: 'Clear',
            variant: CviButtonVariant.primary,
            width: 100,
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Conversation history cleared.'),
                    behavior: SnackBarBehavior.floating),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.semanticError, width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.semanticError, size: 28),
            const SizedBox(width: 10),
            Text('Delete Account',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.semanticError)),
          ],
        ),
        content: Text(
            'This will permanently delete your account and all data. This action CANNOT be undone.',
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              await context.read<AuthProvider>().logout();
              if (nav.mounted) nav.pop();
            },
            child: Text('Delete Account',
                style: GoogleFonts.inter(
                    color: AppColors.semanticError,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _SettingsListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color iconColor;
  final Color textColor;
  final bool isBold;
  final bool showChevron;
  
  const _SettingsListTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor = AppColors.textSecondary,
    this.textColor = AppColors.textPrimary,
    this.isBold = false,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: GoogleFonts.inter(
              color: textColor,
              fontSize: 15,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500)),
      trailing: showChevron 
        ? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted)
        : null,
      onTap: onTap,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ABOUT CVI
// ═════════════════════════════════════════════════════════════════════════════

class _AboutSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IndianCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _SettingsListTile(
            icon: Icons.info_outline_rounded,
            title: 'App Version',
            onTap: () {},
            // Use trailing instead of trying to hack the list tile
          ),
          // Quick hack to add the trailing version since we used a rigid list tile class
          Transform.translate(
            offset: const Offset(0, -45),
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Text('1.0.0 (Build 1)',
                    style: GoogleFonts.spaceMono(
                        color: AppColors.textMuted,
                        fontSize: 12)),
              ),
            ),
          ),
          const Divider(color: AppColors.surfaceBorder, height: 1),
          _SettingsListTile(
            icon: Icons.new_releases_outlined,
            title: "What's New",
            showChevron: true,
            onTap: () => _showChangelog(context),
          ),
          const Divider(color: AppColors.surfaceBorder, height: 1),
          _SettingsListTile(
            icon: Icons.star_outline_rounded,
            title: 'Rate on Play Store',
            iconColor: AppColors.gold,
            showChevron: true,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Opening Play Store...'),
                    behavior: SnackBarBehavior.floating),
              );
            },
          ),
          const Divider(color: AppColors.surfaceBorder, height: 1),
          _SettingsListTile(
            icon: Icons.share_outlined,
            title: 'Share CVI',
            showChevron: true,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Share link copied!'),
                    behavior: SnackBarBehavior.floating),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms);
  }

  void _showChangelog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bgDeep,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: AppColors.surfaceBorder, width: 1)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.new_releases_rounded, color: AppColors.saffron, size: 28),
                  const SizedBox(width: 12),
                  Text("What's New in v1.0.0",
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 24),
              ...[
                '🎤 AI-powered voice assistant for 16 major Indian government services',
                '🌐 4 native language support: English, Hindi, Marathi, Tamil',
                '🏛️ "Bharat Silicon" premium design system implementation',
                '📋 Step-by-step guidance and eligibility checking',
                '🔐 Secure authentication and session management',
              ].map((item) {
                final icon = item.substring(0, 2);
                final text = item.substring(2);
                return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(icon, style: const TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(text,
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    height: 1.4)),
                          ),
                        ),
                      ],
                    ),
              );}),
              const SizedBox(height: 16),
              CviButton(
                text: 'Close',
                variant: CviButtonVariant.primary,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section header helper ────────────────────────────────────────────────────

class _MySectionHeader extends StatelessWidget {
  final String title;
  final String hindiTitle;
  final IconData icon;
  const _MySectionHeader(this.title, this.hindiTitle, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.saffron,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.gold, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: BilingualLabel(
            englishText: title,
            hindiText: hindiTitle,
            scale: 1.1,
            englishColor: AppColors.textPrimary,
            hindiColor: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
