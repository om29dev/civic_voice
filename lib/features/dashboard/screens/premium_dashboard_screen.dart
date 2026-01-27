import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/glass/glass_card.dart';
import '../../../widgets/animated/particle_background.dart';
import '../../../widgets/animated/voice_waveform.dart';
import '../../../widgets/animated/animated_hero_greeting.dart';
import '../../../providers/voice_provider.dart';
import '../../../providers/conversation_provider.dart';
import '../../../providers/language_provider.dart';
import 'package:civic_voice_interface/providers/theme_provider.dart';
import '../../../models/service_model_new.dart';
import '../../voice_interface/screens/voice_dashboard_screen.dart';
import '../../services/screens/service_detail_screen_new.dart';
import '../../services/screens/all_services_screen.dart';
import '../../services/screens/schemes_screen.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../../profile/screens/user_onboarding_screen.dart';
import '../../../providers/user_provider.dart';
import '../../services/screens/virtual_queue_screen.dart';
import '../../profile/screens/family_dashboard_screen.dart';
import '../../services/screens/track_application_screen.dart';
import '../../services/screens/emergency_screen.dart';
import '../../community/screens/community_verification_screen.dart';
import 'package:civic_voice_interface/models/application_model.dart';
import 'package:civic_voice_interface/core/services/scheme_knowledge_base.dart';
import 'package:intl/intl.dart';

class PremiumDashboardScreen extends StatefulWidget {
  const PremiumDashboardScreen({super.key});

  @override
  State<PremiumDashboardScreen> createState() => _PremiumDashboardScreenState();
}

class _PremiumDashboardScreenState extends State<PremiumDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late List<Animation<Offset>> _cardSlideAnimations;
  late List<Animation<double>> _cardFadeAnimations;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Staggered animations for cards
    _cardSlideAnimations = List.generate(
      4,
      (index) => Tween<Offset>(
        begin: Offset(index.isEven ? -1 : 1, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _slideController,
          curve: Interval(
            index * 0.15,
            0.6 + (index * 0.15),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _cardFadeAnimations = List.generate(
      4,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(
            index * 0.15,
            0.6 + (index * 0.15),
            curve: Curves.easeIn,
          ),
        ),
      ),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepSpaceBlue,
      body: SafeArea(
        child: Stack(
          children: [
            // Backgrounds - Fill entire screen
            Positioned.fill(
              child: Stack(
                children: [
                  const AnimatedGradientBackground(),
                  const ParticleBackground(
                    numberOfParticles: 60,
                    particleColor: AppTheme.electricBlue,
                  ),
                ],
              ),
            ),
            
            // Main content - SCROLLABLE
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100), // Space for FAB
              child: Column(
                children: [
                  // Animated Hero Greeting
                  const AnimatedHeroGreeting(),
                  const SizedBox(height: 10),
                  _buildHeader(),
                  const SizedBox(height: 20),
                  
                  // Recommended section - Only if profile is semi-complete
                  _buildRecommendations(),
                  
                  const SizedBox(height: 20),
                  _buildStatsGrid(),
                  const SizedBox(height: 32),
                  _buildFeaturedActions(),
                  const SizedBox(height: 32),
                  _buildSchemesButton(),
                  const SizedBox(height: 32),
                  _buildConversationPreview(),
                  const SizedBox(height: 32),
                  _buildRecentActivity(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            
            // Floating Voice Assistant FAB
            _buildVoiceFAB(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;
    final convoProvider = Provider.of<ConversationProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Avatar with subtle halo
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(),
                ),
              );
            },
            child: CircleAvatar(
              radius: 30,
              backgroundColor: theme.colorScheme.surface,
              child: Text(
                user.name.isNotEmpty 
                    ? user.name.substring(0, user.name.contains(' ') ? 2 : 1).toUpperCase()
                    : 'U',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${langProvider.translate('welcome_back')},',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.name.split(' ')[0],
                  style: theme.textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          
          // Theme Toggle
          IconButton(
            onPressed: () => themeProvider.toggleTheme(),
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: theme.colorScheme.onSurface,
            ),
          ),
          
          // Notification bell
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.notifications_outlined, color: theme.colorScheme.onSurface),
              ),
              if (convoProvider.messages.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;
    final convoProvider = Provider.of<ConversationProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final totalMessages = convoProvider.messages.length;
    final userMessages = convoProvider.messages.where((m) => m.isUser).length;
    
    final theme = Theme.of(context);
    final stats = [
      {
        'icon': Icons.assignment_outlined,
        'value': '${user.applicationsCount}',
        'label': lang.translate('queries'),
        'color': theme.colorScheme.primary
      },
      {
        'icon': Icons.check_circle_outline,
        'value': '${user.completedCount}',
        'label': lang.translate('success'),
        'color': AppTheme.success
      },
      {
        'icon': Icons.pending_outlined,
        'value': '${user.pendingCount}',
        'label': lang.translate('pending'),
        'color': AppTheme.warning
      },
      {
        'icon': Icons.trending_up,
        'value': '${totalMessages > 0 ? 95 : 0}%',
        'label': lang.translate('avg_time'),
        'color': theme.colorScheme.secondary
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          mainAxisExtent: 160, // Increased to 160 to prevent overflow
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return SlideTransition(
            position: _cardSlideAnimations[index],
            child: FadeTransition(
              opacity: _cardFadeAnimations[index],
              child: _StatCard(
                icon: stat['icon'] as IconData,
                value: stat['value'] as String,
                label: stat['label'] as String,
                color: stat['color'] as Color,
                delay: Duration(milliseconds: index * 100),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Consumer<LanguageProvider>(
            builder: (context, lang, _) => Text(
              lang.translate('high_priority_schemes'),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.pureWhite,
              ),
            ),
          ),
        ),
        Consumer<LanguageProvider>(
          builder: (context, lang, _) => GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildActionItem(
                lang.translate('smart_queue'),
                Icons.confirmation_number,
                AppTheme.electricBlue,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VirtualQueueScreen())),
              ),
               _buildActionItem(
                lang.translate('family_hub'),
                Icons.people,
                AppTheme.success,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyDashboardScreen())),
              ),
              _buildActionItem(
                lang.translate('sos_emergency'),
                Icons.sos,
                AppTheme.error,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyScreen())),
              ),
              _buildActionItem(
                lang.translate('trust_score'),
                Icons.verified,
                AppTheme.neonCyan,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityVerificationScreen())),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem(String label, IconData icon, Color color, VoidCallback onTap) {
    final theme = Theme.of(context);
    return AnimatedGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickServices() {
    final theme = Theme.of(context);
// ... existing _buildQuickServices code ...
    final allServices = ServiceModel.getAllServices();
    final quickServices = allServices.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Consumer<LanguageProvider>(
            builder: (context, lang, _) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang.translate('quick_services'),
                  style: theme.textTheme.headlineSmall,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllServicesScreen(),
                      ),
                    );
                  },
                  child: Text(
                    lang.translate('view_all'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: quickServices.length,
            itemBuilder: (context, index) {
              final service = quickServices[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _ServiceCard(
                  title: service.title,
                  icon: service.icon,
                  color: service.color,
                  description: service.category,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceDetailScreen(service: service),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSchemesButton() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedGlassCard(
        padding: const EdgeInsets.all(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SchemesScreen(),
            ),
          );
        },
        child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.account_balance,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Consumer<LanguageProvider>(
                  builder: (context, lang, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.translate('government_schemes'),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.pureWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lang.translate('browse_schemes'),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.pureWhite.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.pureWhite.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildConversationPreview() {
    final theme = Theme.of(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final convoProvider = Provider.of<ConversationProvider>(context);
    final recentMessages = convoProvider.messages.take(2).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: AnimatedGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  color: AppTheme.electricBlue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Consumer<LanguageProvider>(
                  builder: (context, lang, _) => Text(
                    lang.translate('recent_conversation'),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const Spacer(),
                if (recentMessages.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${convoProvider.messages.length} ${langProvider.translate('messages')}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 12,
                        color: AppTheme.success,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (recentMessages.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      Provider.of<LanguageProvider>(context).translate('no_conversations_yet'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.pureWhite.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Provider.of<LanguageProvider>(context).translate('start_asking'),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.pureWhite.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...recentMessages.map((msg) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MessageBubble(
                      message: msg.text,
                      isUser: msg.isUser,
                    ),
                  )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VoiceDashboardScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricBlue,
                  foregroundColor: AppTheme.deepSpaceBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Consumer<LanguageProvider>(
                  builder: (context, lang, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mic, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        recentMessages.isEmpty 
                            ? lang.translate('start_conversation') 
                            : lang.translate('continue_conversation'),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final userProvider = Provider.of<UserProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final apps = userProvider.currentUser.applications.reversed.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.translate('recent_activity'),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.pureWhite,
                ),
              ),
              TextButton(
                onPressed: () {}, // View all applications
                child: Text(
                  lang.translate('view_all'),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.electricBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (apps.isEmpty)
             _buildEmptyActivity(lang)
          else
            ...apps.take(3).map((app) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AnimatedGlassCard(
                padding: const EdgeInsets.all(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrackApplicationScreen(application: app),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(context, app.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getStatusIcon(context, app.status),
                        color: _getStatusColor(context, app.status),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.schemeName,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.pureWhite,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(app.submissionDate),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.pureWhite.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(context, app.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        lang.translate(app.status.name),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(context, app.status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildEmptyActivity(LanguageProvider lang) {
     return Center(
       child: Padding(
         padding: const EdgeInsets.symmetric(vertical: 20),
         child: Column(
           children: [
             Icon(Icons.history, color: AppTheme.pureWhite.withOpacity(0.3), size: 40),
             const SizedBox(height: 10),
             Text(
               lang.translate('no_activity_yet'),
               style: GoogleFonts.inter(color: AppTheme.pureWhite.withOpacity(0.5)),
             ),
           ],
         ),
       ),
     );
  }

  Color _getStatusColor(BuildContext context, ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.approved: return AppTheme.success;
      case ApplicationStatus.rejected: return AppTheme.error;
      case ApplicationStatus.submitted: return AppTheme.warning;
      case ApplicationStatus.verified: return Theme.of(context).colorScheme.primary;
      default: return Theme.of(context).colorScheme.onSurface;
    }
  }

  IconData _getStatusIcon(BuildContext context, ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.approved: return Icons.check_circle_rounded;
      case ApplicationStatus.rejected: return Icons.cancel_rounded;
      case ApplicationStatus.submitted: return Icons.send_rounded;
      case ApplicationStatus.verified: return Icons.verified_user_rounded;
      default: return Icons.info_rounded;
    }
  }

  Widget _buildRecommendations() {
    final userProvider = Provider.of<UserProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final user = userProvider.currentUser;
    
    if (!user.isProfileComplete) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: AnimatedGlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                   const Icon(Icons.tips_and_updates_outlined, color: AppTheme.neonCyan),
                   const SizedBox(width: 12),
                   Text(
                     lang.translate('personalization_tip'),
                     style: GoogleFonts.poppins(
                       fontWeight: FontWeight.bold,
                       color: AppTheme.pureWhite,
                     ),
                   ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                lang.translate('complete_profile_tip'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.pureWhite.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserOnboardingScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.neonCyan,
                  side: const BorderSide(color: AppTheme.neonCyan),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(lang.translate('setup_my_profile')),
              ),
            ],
          ),
        ),
      );
    }

    final allServices = ServiceModel.getAllServices();
    final List<ServiceModel> recommended = [];

    // Simple Recommendation Logic
    for (var service in allServices) {
      bool isRelevant = false;
      
      if (service.id == 'pension' && (user.age ?? 0) >= 60) isRelevant = true;
      if (service.id == 'ration' && (user.annualIncome ?? 0) <= 100000) isRelevant = true;
      if (service.id == 'land' && (user.ownsLand || user.occupation == 'Farmer')) isRelevant = true;
      if (service.id == 'driving' && (user.age ?? 0) >= 18) isRelevant = true;

      if (isRelevant) recommended.add(service);
    }

    if (recommended.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Consumer<LanguageProvider>(
            builder: (context, lang, _) => Text(
              lang.translate('recommended_for_you'),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.pureWhite,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: recommended.length,
            itemBuilder: (context, index) {
              final service = recommended[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _ServiceCard(
                  title: service.title,
                  icon: service.icon,
                  color: service.color,
                  description: service.description,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceDetailScreen(service: service),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceFAB() {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Center(
        child: _PulsingVoiceFAB(),
      ),
    );
  }
}

class _StatCard extends StatefulWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Duration delay;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.delay,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: AnimatedGlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.value,
                  style: theme.textTheme.displaySmall?.copyWith(fontSize: 24, color: widget.color),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final VoidCallback? onTap;

  const _ServiceCard({
    required this.title,
    required this.icon,
    required this.color,
    this.description = '',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedGlassCard(
      padding: const EdgeInsets.all(20),
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.labelLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const _MessageBubble({
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary.withOpacity(0.15)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser
                ? theme.colorScheme.primary.withOpacity(0.3)
                : theme.dividerColor,
          ),
        ),
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isUser ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            fontWeight: isUser ? FontWeight.w600 : FontWeight.normal,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _PulsingVoiceFAB extends StatefulWidget {
  @override
  State<_PulsingVoiceFAB> createState() => _PulsingVoiceFABState();
}

class _PulsingVoiceFABState extends State<_PulsingVoiceFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3 * _glowAnimation.value),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VoiceDashboardScreen(),
                  ),
                );
              },
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 4,
              icon: const Icon(Icons.mic, size: 28),
              label: Consumer<LanguageProvider>(
                builder: (context, lang, _) => Text(
                  lang.translate('ask_cvi'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
