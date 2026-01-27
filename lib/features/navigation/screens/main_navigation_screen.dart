import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../dashboard/screens/premium_dashboard_screen.dart';
import '../../services/screens/all_services_screen.dart';
import '../../documents/screens/documents_screen.dart';
import '../../voice_interface/screens/voice_dashboard_screen.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../../profile/screens/family_dashboard_screen.dart';


class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late List<Animation<double>> _iconAnimations;

  final List<Widget> _pages = [
    const PremiumDashboardScreen(),
    const AllServicesScreen(),
    const FamilyDashboardScreen(),
    const VoiceDashboardScreen(),
    const UserProfileScreen(),
  ];

  List<NavItem> _getNavItems(LanguageProvider lang) {
    return [
      NavItem(
        icon: Icons.home_rounded,
        label: lang.translate('home'),
        activeColor: AppTheme.electricBlue,
      ),
      NavItem(
        icon: Icons.apps_rounded,
        label: lang.translate('services'),
        activeColor: AppTheme.neonCyan,
      ),
      NavItem(
        icon: Icons.people_rounded,
        label: lang.translate('family') ?? 'Family',
        activeColor: AppTheme.success,
      ),
      NavItem(
        icon: Icons.mic_rounded,
        label: lang.translate('voice_ai'),
        activeColor: AppTheme.gradientStart,
      ),
      NavItem(
        icon: Icons.person_rounded,
        label: lang.translate('profile'),
        activeColor: AppTheme.warning,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _iconAnimations = List.generate(
      5, // 5 navigation items
      (index) => Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        ),
      ),
    );

    // Fetch user profile if logged in but data is missing (e.g. app restart)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      if (authProvider.isAuthenticated && userProvider.isGuest && authProvider.userId != null) {
        userProvider.fetchUserProfile(authProvider.userId!);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _animationController.forward().then((_) => _animationController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    final lang = Provider.of<LanguageProvider>(context);
    final navItems = _getNavItems(lang);
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.deepSpaceBlue,
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                navItems.length,
                (index) => _buildNavItem(index, navItems[index]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, NavItem item) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          item.activeColor.withOpacity(0.2),
                          item.activeColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? item.activeColor.withOpacity(0.2)
                          : Colors.transparent,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: item.activeColor.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: Transform.scale(
                      scale: isSelected && _animationController.isAnimating
                          ? _iconAnimations[index].value
                          : 1.0,
                      child: Icon(
                        item.icon,
                        size: 22,
                        color: isSelected
                            ? item.activeColor
                            : AppTheme.pureWhite.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? item.activeColor
                          : AppTheme.pureWhite.withOpacity(0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final String label;
  final Color activeColor;

  NavItem({
    required this.icon,
    required this.label,
    required this.activeColor,
  });
}
