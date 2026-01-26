import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/glass/glass_card.dart';
import '../../../widgets/animated/particle_background.dart';
import '../../../providers/language_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _particleController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _glowAnimation;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _logoController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _particleController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    });
  }

  void _handleGuestLogin() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepSpaceBlue,
      body: Stack(
        children: [
          // Animated gradient background
          const Positioned.fill(
            child: AnimatedGradientBackground(),
          ),
          
          // Particle field
          const Positioned.fill(
            child: ParticleBackground(
              numberOfParticles: 80,
              particleColor: AppTheme.electricBlue,
              connectParticles: true,
            ),
          ),
          
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    
                    // Animated Logo
                    _buildAnimatedLogo(),
                    
                    const SizedBox(height: 60),
                    
                    // Login Card
                    _buildLoginCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Register Link
                    _buildRegisterLink(),
                    
                    const SizedBox(height: 24),
                    
                    // Guest Login
                    _buildGuestLogin(),
                    
                    const SizedBox(height: 30),
                    
                    // Language Selector
                    _buildLanguageSelector(),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value,
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
                  color: AppTheme.electricBlue.withOpacity(0.6 * _glowAnimation.value),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.account_balance,
                size: 50,
                color: AppTheme.pureWhite,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginCard() {
    return AnimatedGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          ShaderMask(
            shaderCallback: (bounds) => AppTheme.accentGradient.createShader(bounds),
            child: Text(
              'Welcome Back',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.pureWhite,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Login to access your civic services',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.pureWhite.withOpacity(0.7),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Email Input
          _buildInputField(
            controller: _emailController,
            hint: 'Email or Phone',
            icon: Icons.person_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          
          const SizedBox(height: 16),
          
          // Password Input
          _buildInputField(
            controller: _passwordController,
            hint: 'Password',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.electricBlue,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Forgot Password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text(
                'Forgot Password?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.electricBlue,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Login Button
          _buildGlowingButton(
            onPressed: _handleLogin,
            isLoading: _isLoading,
            text: 'Login',
          ),
          
          const SizedBox(height: 16),
          
          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: AppTheme.pureWhite.withOpacity(0.2))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.pureWhite.withOpacity(0.5),
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppTheme.pureWhite.withOpacity(0.2))),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Social Login Buttons
          Row(
            children: [
              Expanded(
                child: _buildSocialButton(
                  icon: Icons.g_mobiledata,
                  label: 'Google',
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSocialButton(
                  icon: Icons.phone_android,
                  label: 'OTP',
                  onPressed: () {
                    Navigator.pushNamed(context, '/otp-auth');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.glassGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.glassBorder,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: GoogleFonts.inter(
              color: AppTheme.pureWhite,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: AppTheme.pureWhite.withOpacity(0.5),
              ),
              prefixIcon: Icon(icon, color: AppTheme.electricBlue),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.pureWhite,
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: AppTheme.glassBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.pureWhite.withOpacity(0.7),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/register');
          },
          child: Text(
            'Register',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.electricBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestLogin() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            color: AppTheme.neonCyan,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue as Guest',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.pureWhite,
                  ),
                ),
                Text(
                  'Limited features available',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.pureWhite.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _handleGuestLogin,
            icon: const Icon(
              Icons.arrow_forward,
              color: AppTheme.neonCyan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    final langProvider = Provider.of<LanguageProvider>(context);
    
    final languages = [
      {'name': 'English', 'flag': '🇬🇧', 'lang': AppLanguage.english},
      {'name': 'हिंदी', 'flag': '🇮🇳', 'lang': AppLanguage.hindi},
      {'name': 'मराठी', 'flag': '🇮🇳', 'lang': AppLanguage.marathi},
      {'name': 'தமிழ்', 'flag': '🇮🇳', 'lang': AppLanguage.tamil},
    ];

    return Column(
      children: [
        Text(
          'Select Language',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.pureWhite.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: languages.map((lang) {
            final isSelected = langProvider.currentLanguage == lang['lang'];
            return _LanguageChip(
              flag: lang['flag']! as String,
              name: lang['name']! as String,
              isSelected: isSelected,
              onTap: () {
                langProvider.setLanguage(lang['lang']! as AppLanguage);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGlowingButton({
    required VoidCallback onPressed,
    required bool isLoading,
    required String text,
  }) {
    return _GlowingButton(
      onPressed: onPressed,
      isLoading: isLoading,
      child: Text(
        isLoading ? 'Logging in...' : text,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.deepSpaceBlue,
        ),
      ),
    );
  }
}

class _GlowingButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool isLoading;

  const _GlowingButton({
    required this.onPressed,
    required this.child,
    this.isLoading = false,
  });

  @override
  State<_GlowingButton> createState() => _GlowingButtonState();
}

class _GlowingButtonState extends State<_GlowingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
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
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.electricBlue.withOpacity(0.5 * _glowAnimation.value),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : widget.onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricBlue,
                foregroundColor: AppTheme.deepSpaceBlue,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppTheme.deepSpaceBlue),
                      ),
                    )
                  : widget.child,
            ),
          ),
        );
      },
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String flag;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageChip({
    required this.flag,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? AppTheme.accentGradient
              : LinearGradient(
                  colors: [
                    AppTheme.glassBackground,
                    AppTheme.glassBackground,
                  ],
                ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppTheme.electricBlue : AppTheme.glassBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.electricBlue.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: AppTheme.pureWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
