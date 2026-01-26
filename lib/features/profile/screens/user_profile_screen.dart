import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/glass/glass_card.dart';
import '../../../widgets/animated/particle_background.dart';
import '../../../providers/language_provider.dart';
import '../../voice_interface/screens/voice_dashboard_screen.dart';
import 'user_onboarding_screen.dart';
import 'personal_information_screen.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/accessibility_provider.dart';
import 'notes_screen.dart';
import 'family_dashboard_screen.dart';
import '../../services/screens/virtual_queue_screen.dart';
import '../../gamification/screens/gamification_screen.dart';
import '../../community/screens/community_verification_screen.dart';
import '../../services/screens/emergency_screen.dart';
import '../../documents/screens/ar_guidance_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;
    final langProvider = Provider.of<LanguageProvider>(context);
    
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
          'Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.pureWhite,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.electricBlue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserOnboardingScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: ParticleBackground(
              numberOfParticles: 40,
              particleColor: AppTheme.electricBlue,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(user),
                  const SizedBox(height: 32),
                  
                  // Demographic Info (If complete)
                  if (user.isProfileComplete) ...[
                    _buildSection('Demographic Information', [
                      _buildInfoItem(Icons.cake, 'Age', '${user.age} years'),
                      _buildInfoItem(Icons.currency_rupee, 'Annual Income', '₹${user.annualIncome?.toStringAsFixed(0)}'),
                      _buildInfoItem(Icons.work, 'Occupation', user.occupation ?? 'Not specified'),
                      _buildInfoItem(Icons.location_on, 'Location', user.location ?? 'Not specified'),
                      _buildInfoItem(Icons.landscape, 'Land Ownership', user.ownsLand ? 'Yes' : 'No'),
                    ]),
                    const SizedBox(height: 24),
                  ] else ...[
                    _buildIncompleteProfileBanner(context),
                    const SizedBox(height: 24),
                  ],
                  
                  // Stats Cards
                  _buildStatsRow(user),
                  const SizedBox(height: 32),
                  
                  // Settings Section
                  _buildSection('Account Settings', [
                    _buildMenuItem(Icons.person, 'Personal Information', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PersonalInformationScreen()),
                      );
                    }),
                    _buildMenuItem(Icons.security, 'Security & Privacy', () {}),
                    _buildMenuItem(Icons.notifications, 'Notifications', () {}, trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) => setState(() => _notificationsEnabled = value),
                      activeColor: AppTheme.electricBlue,
                    )),
                    _buildMenuItem(Icons.mic, 'Voice Notes (Feature 9)', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotesScreen()),
                      );
                    }),
                    _buildMenuItem(Icons.people, 'Family Members (Feature 4)', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FamilyDashboardScreen()),
                      );
                    }),
                    _buildMenuItem(Icons.confirmation_number, 'Smart Queue (Feature 13)', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const VirtualQueueScreen()),
                      );
                    }),
                    _buildMenuItem(Icons.emoji_events, 'Civic Progress (Feature 7)', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GamificationScreen()),
                      );
                    }),
                    _buildMenuItem(Icons.verified, 'Community Trust (Feature 10)', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CommunityVerificationScreen()),
                      );
                    }),
                    _buildMenuItem(Icons.sos, 'Emergency Mode (Feature 6)', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EmergencyScreen()),
                      );
                    }, trailing: const Icon(Icons.arrow_forward_ios, color: AppTheme.error, size: 16)),
                    _buildMenuItem(Icons.view_in_ar, 'AR Document Guidance (F12)', () {
                       // Warning: This requires a valid file path to work perfectly.
                       // For demo, we might need to pick a file first or use a placeholder asset if available.
                       // I'll launch a picker or just show a dialog explanation for the prototype.
                       // Actually, let's just push screen with a dummy path and let it fail gracefully or show black.
                       // Better: Show a picker dialog.
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Select a document to scan...')),
                       );
                       // Quick mock: We will just push it with a placeholder that won't load image but shows UI.
                       Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ARGuidanceScreen(imagePath: '')),
                      );
                    }),
                  ]),
                  const SizedBox(height: 24),
                  
                  // Preferences Section
                  _buildSection('Preferences', [
                    _buildLanguageMenuItem(context, langProvider),
                    _buildMenuItem(Icons.dark_mode, 'Dark Mode', () {}, trailing: Switch(
                      value: _darkModeEnabled,
                      onChanged: (value) => setState(() => _darkModeEnabled = value),
                      activeColor: AppTheme.electricBlue,
                    )),
                  ]),
                  const SizedBox(height: 24),
                  
                  // Accessibility Section (Feature 11)
                  Consumer<AccessibilityProvider>(
                    builder: (context, acc, _) => _buildSection('Accessibility (Feature 11)', [
                      _buildMenuItem(Icons.contrast, 'High Contrast Mode', () {}, trailing: Switch(
                        value: acc.isHighContrast,
                        onChanged: (value) => acc.toggleHighContrast(value),
                        activeColor: AppTheme.electricBlue,
                      )),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Text Size: ${(acc.textScaleFactor * 100).toInt()}%',
                              style: GoogleFonts.inter(color: AppTheme.pureWhite),
                            ),
                            Slider(
                              value: acc.textScaleFactor,
                              min: 0.8,
                              max: 1.5,
                              divisions: 7,
                              activeColor: AppTheme.electricBlue,
                              inactiveColor: AppTheme.glassBorder,
                              onChanged: (val) => acc.setTextScale(val),
                            ),
                          ],
                        ),
                      ),
                      _buildMenuItem(Icons.palette, 'Color Blindness', () {
                         _showColorBlindDialog(context, acc);
                      }, trailing: Text(
                        acc.colorBlindMode.toString().split('.').last.toUpperCase(),
                        style: GoogleFonts.inter(color: AppTheme.neonCyan, fontSize: 12),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // Support Section
                  _buildSection('Support', [
                    _buildMenuItem(Icons.help, 'Help & FAQ', () {}),
                    _buildMenuItem(Icons.feedback, 'Send Feedback', () {}),
                    _buildMenuItem(Icons.info, 'About CVI', () {}),
                  ]),
                  const SizedBox(height: 32),
                  
                  // Logout Button
                  _buildLogoutButton(context, userProvider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile user) {
    return GlassCard(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.electricBlue.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.glassBackground,
              child: Text(
                user.name.substring(0, user.name.contains(' ') ? 2 : 1).toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.electricBlue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.pureWhite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.pureWhite.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (user.isVerified ? AppTheme.success : AppTheme.warning).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  user.isVerified ? Icons.verified : Icons.warning_amber_rounded,
                  size: 16,
                  color: user.isVerified ? AppTheme.success : AppTheme.warning,
                ),
                const SizedBox(width: 6),
                Text(
                  user.isVerified ? 'Verified User' : 'Unverified Account',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: user.isVerified ? AppTheme.success : AppTheme.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncompleteProfileBanner(BuildContext context) {
    return GlassCard(
      gradientColors: [AppTheme.warning.withOpacity(0.1), AppTheme.warning.withOpacity(0.05)],
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.warning, size: 32),
          const SizedBox(height: 12),
          Text(
            'Incomplete Profile',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.pureWhite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add your details to get personalized scheme recommendations.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.pureWhite.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserOnboardingScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              foregroundColor: AppTheme.deepSpaceBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Complete Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(UserProfile user) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('${user.applicationsCount}', 'Applications', Icons.assignment),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('${user.completedCount}', 'Completed', Icons.check_circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('${user.pendingCount}', 'Pending', Icons.pending),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.electricBlue, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.pureWhite,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppTheme.pureWhite.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.pureWhite.withOpacity(0.7),
            ),
          ),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {Widget? trailing}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.electricBlue, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppTheme.pureWhite,
                  ),
                ),
              ),
              trailing ?? const Icon(Icons.chevron_right, color: AppTheme.pureWhite),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.neonCyan, size: 20),
          const SizedBox(width: 16),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.pureWhite.withOpacity(0.6),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.pureWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageMenuItem(BuildContext context, LanguageProvider langProvider) {
    return _buildMenuItem(
      Icons.language,
      'Language',
      () => _showLanguageDialog(context, langProvider),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            langProvider.languageName,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.neonCyan,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppTheme.pureWhite),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LanguageProvider langProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.deepSpaceBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Select Language',
          style: GoogleFonts.poppins(color: AppTheme.pureWhite),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.values.map((lang) {
            return RadioListTile<AppLanguage>(
              title: Text(
                _getLanguageName(lang),
                style: GoogleFonts.inter(color: AppTheme.pureWhite),
              ),
              value: lang,
              groupValue: langProvider.currentLanguage,
              activeColor: AppTheme.electricBlue,
              onChanged: (value) {
                if (value != null) {
                  langProvider.setLanguage(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getLanguageName(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.english: return 'English';
      case AppLanguage.hindi: return 'हिन्दी (Hindi)';
      case AppLanguage.marathi: return 'मराठी (Marathi)';
      case AppLanguage.tamil: return 'தமிழ் (Tamil)';
    }
  }

  Widget _buildLogoutButton(BuildContext context, UserProvider userProvider) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          userProvider.logout();
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        },
        icon: const Icon(Icons.logout, size: 20),
        label: Text(
          'Logout',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.error,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: AppTheme.error, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _showColorBlindDialog(BuildContext context, AccessibilityProvider acc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.deepSpaceBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Select Filter',
          style: GoogleFonts.poppins(color: AppTheme.pureWhite),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ColorBlindMode.values.map((mode) {
             final name = mode.toString().split('.').last.toUpperCase();
             return RadioListTile<ColorBlindMode>(
               title: Text(
                 name == 'NONE' ? 'None (Normal Vision)' : name,
                 style: GoogleFonts.inter(color: AppTheme.pureWhite),
               ),
               value: mode,
               groupValue: acc.colorBlindMode,
               activeColor: AppTheme.electricBlue,
               onChanged: (val) {
                 if (val != null) {
                   acc.setColorBlindMode(val);
                   Navigator.pop(context);
                 }
               },
             );
          }).toList(),
        ),
      ),
    );
  }
}
