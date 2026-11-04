import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/profile_constants.dart';
import '../../core/utils/helpers.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/citizen_profile_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/neon_button.dart';
import '../../widgets/particle_background.dart';
import '../../widgets/t_text.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ParticleBackground(
        child: Column(
          children: [
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: _AuthHeader(),
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0x14FFFFFF),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(
                    top: BorderSide(color: Color(0x1A00F5FF), width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 4),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    _AnimatedTabBar(controller: _tabCtrl),
                    Expanded(
                      child: TabBarView(
                        controller: _tabCtrl,
                        children: const [_LoginTab(), _RegisterTab()],
                      ),
                    ),
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

Future<void> _hydrateSessionProfiles({
  required AuthProvider auth,
  required CitizenProfileProvider citizenProfileProvider,
  required UserProvider userProvider,
  String? overrideName,
  String? overrideEmail,
  String? overrideMobile,
  String? overrideState,
  String? overrideLanguage,
}) async {
  final current = auth.currentUser;
  if (current == null || auth.userId == null) return;

  final fullName = (overrideName != null && overrideName.trim().isNotEmpty)
      ? overrideName.trim()
      : current.name;
  final email = (overrideEmail != null && overrideEmail.trim().isNotEmpty)
      ? overrideEmail.trim()
      : (current.email ?? '');
  final mobile = (overrideMobile != null && overrideMobile.trim().isNotEmpty)
      ? overrideMobile.trim()
      : (current.mobile ?? '');
  final stateName = (overrideState != null && overrideState.trim().isNotEmpty)
      ? ProfileConstants.normalizeState(overrideState)
      : ProfileConstants.normalizeState(current.state?.label);

  await citizenProfileProvider.bootstrapFromAuth(
    id: current.id,
    fullName: fullName,
    email: email,
    mobile: mobile,
    state: stateName,
  );

  userProvider.login(
    name: fullName,
    email: email,
    phone: mobile,
    location: stateName,
  );
  if (citizenProfileProvider.profile != null) {
    userProvider.syncFromCitizenProfile(citizenProfileProvider.profile!);
  }
  unawaited(userProvider.fetchUserProfile(current.id));
}

void _showEmailVerificationDialog({
  required BuildContext hostContext,
  required String email,
  required String password,
  required AuthProvider auth,
  required CitizenProfileProvider citizenProfileProvider,
  required UserProvider userProvider,
  String? registeredName,
  String? registeredMobile,
  String? registeredState,
  String? registeredLanguage,
}) {
  final otpCtrl = TextEditingController();
  bool isVerifying = false;
  bool isResending = false;

  showDialog(
    context: hostContext,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundLight,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const TText(
            'Verify Email',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Rajdhani',
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TText(
                'Enter the 6-digit verification code sent to $email:',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              _NeonTextField(
                controller: otpCtrl,
                label: 'Verification Code',
                icon: Icons.password_rounded,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: (isVerifying || isResending)
                      ? null
                      : () async {
                          setDialogState(() => isResending = true);
                          final resent = await auth.resendSignUpCode(email);
                          if (!dialogContext.mounted) return;
                          setDialogState(() => isResending = false);
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: TText(
                                resent
                                    ? 'Verification code resent to $email'
                                    : (auth.error ?? 'Failed to resend code'),
                              ),
                              backgroundColor:
                                  resent ? AppColors.success : AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  icon: isResending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        )
                      : const Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: AppColors.accent,
                        ),
                  label: const TText(
                    'Resend Code',
                    style: TextStyle(color: AppColors.accent, fontSize: 13),
                  ),
                ),
              ),
              if (isVerifying) ...[
                const SizedBox(height: 12),
                const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  isVerifying ? null : () => Navigator.pop(dialogContext),
              child: const TText(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: isVerifying
                  ? null
                  : () async {
                      final code = otpCtrl.text.trim();
                      if (code.isEmpty) return;

                      setDialogState(() => isVerifying = true);
                      final success = await auth.confirmSignUp(email, code);

                      if (!hostContext.mounted) return;

                      if (success) {
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }

                        final loginSuccess =
                            await auth.loginWithEmail(email, password);

                        if (loginSuccess && auth.userId != null) {
                          await _hydrateSessionProfiles(
                            auth: auth,
                            citizenProfileProvider: citizenProfileProvider,
                            userProvider: userProvider,
                            overrideName: registeredName,
                            overrideEmail: email,
                            overrideMobile: registeredMobile,
                            overrideState: registeredState,
                            overrideLanguage: registeredLanguage,
                          );
                        } else if (hostContext.mounted) {
                          ScaffoldMessenger.of(hostContext).showSnackBar(
                            const SnackBar(
                              content: TText(
                                'Email verified! You can now log in.',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } else {
                        setDialogState(() => isVerifying = false);
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content:
                                  Text(auth.error ?? 'Verification failed'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: const TText(
                'Verify & Login',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.record_voice_over_rounded,
              color: AppColors.accent,
              size: 28,
            ),
          ).animate().fadeIn(duration: 500.ms).scale(
                begin: const Offset(0.8, 0.8),
                duration: 600.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 12),
          const Text(
            'CIVIC VOICE',
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 4,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const TText(
            'Your gateway to government services',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

class _AnimatedTabBar extends StatelessWidget {
  final TabController controller;
  const _AnimatedTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: TabBar(
          controller: controller,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: -4,
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: [
            Tab(text: lang.translateSync('Login')),
            Tab(text: lang.translateSync('Register')),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LOGIN TAB
// ═════════════════════════════════════════════════════════════════════════════

class _LoginTab extends StatefulWidget {
  const _LoginTab();

  @override
  State<_LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends State<_LoginTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _passVisible = false;
  bool _showOTP = false;
  bool _otpSent = false;
  final List<TextEditingController> _otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _mobileCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _mobileCtrl.dispose();
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final auth = context.read<AuthProvider>();
    final citizenProfileProvider = context.read<CitizenProfileProvider>();
    final userProvider = context.read<UserProvider>();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    final success = await auth.loginWithEmail(email, password);

    if (success && auth.userId != null) {
      await _hydrateSessionProfiles(
        auth: auth,
        citizenProfileProvider: citizenProfileProvider,
        userProvider: userProvider,
        overrideEmail: email,
      );
      return;
    }

    if (!mounted) return;

    if (auth.error == 'CONFIRM_SIGNUP_REQUIRED') {
      _showEmailVerificationDialog(
        hostContext: context,
        email: email,
        password: password,
        auth: auth,
        citizenProfileProvider: citizenProfileProvider,
        userProvider: userProvider,
      );
    } else if (auth.error != null) {
      _showError(auth.error!);
    }
  }

  Future<void> _loginGoogle() async {
    final auth = context.read<AuthProvider>();
    final citizenProfileProvider = context.read<CitizenProfileProvider>();
    final userProvider = context.read<UserProvider>();

    final success = await auth.loginWithGoogle();
    if (success && auth.userId != null) {
      await _hydrateSessionProfiles(
        auth: auth,
        citizenProfileProvider: citizenProfileProvider,
        userProvider: userProvider,
      );
      return;
    }

    if (!mounted) return;

    if (auth.error == 'GOOGLE_ACCOUNT_FALLBACK_REQUIRED') {
      _showGoogleAccountFallbackDialog(
        auth: auth,
        citizenProfileProvider: citizenProfileProvider,
        userProvider: userProvider,
      );
      return;
    }

    if (auth.error != null) {
      _showError(auth.error!);
    }
  }

  void _showGoogleAccountFallbackDialog({
    required AuthProvider auth,
    required CitizenProfileProvider citizenProfileProvider,
    required UserProvider userProvider,
  }) {
    final googleEmailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    final googleNameCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.backgroundLight,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    'G',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: TText(
                    'Continue with Google',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: 'Rajdhani',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TText(
                    'Enter your Google account details to sign in and sync your citizen profile:',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  _NeonTextField(
                    controller: googleNameCtrl,
                    label: 'Full Name',
                    icon: Icons.person_outline_rounded,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _NeonTextField(
                    controller: googleEmailCtrl,
                    label: 'Google Email Address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!isValidEmail(v.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    isSubmitting ? null : () => Navigator.pop(dialogContext),
                child: const TText(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSubmitting = true);
                        final email = googleEmailCtrl.text.trim();
                        final name = googleNameCtrl.text.trim();

                        Navigator.pop(dialogContext);
                        final ok = await auth.loginWithGoogle(
                          fallbackEmail: email,
                          fallbackName: name,
                        );
                        if (ok && auth.userId != null) {
                          await _hydrateSessionProfiles(
                            auth: auth,
                            citizenProfileProvider: citizenProfileProvider,
                            userProvider: userProvider,
                            overrideName: name,
                            overrideEmail: email,
                          );
                        } else if (mounted && auth.error != null) {
                          _showError(auth.error!);
                        }
                      },
                child: const TText(
                  'Continue',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sendOTP() async {
    final mobile = _mobileCtrl.text.trim();
    if (mobile.length != 10) {
      _showError('Enter a valid 10-digit mobile number.');
      return;
    }
    final auth = context.read<AuthProvider>();
    final sent = await auth.sendOTP(mobile);
    if (!mounted) return;

    if (!sent) {
      if (auth.error != null) _showError(auth.error!);
      return;
    }

    setState(() {
      _otpSent = true;
      for (final c in _otpCtrls) {
        c.clear();
      }
    });

    final code = auth.activeOtpCode ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'OTP sent to +91 $mobile. Verification Code: $code',
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Future.delayed(50.ms, () {
      if (mounted) _otpFocusNodes[0].requestFocus();
    });
  }

  void _autoFillOtp(String code) {
    if (code.length != 6) return;
    for (int i = 0; i < 6; i++) {
      _otpCtrls[i].text = code[i];
    }
    setState(() {});
  }

  Future<void> _verifyOTP() async {
    final otp = _otpCtrls.map((c) => c.text).join();
    if (otp.length < 6) {
      _showError('Enter all 6 OTP digits.');
      return;
    }
    final auth = context.read<AuthProvider>();
    final citizenProfileProvider = context.read<CitizenProfileProvider>();
    final userProvider = context.read<UserProvider>();
    final mobile = _mobileCtrl.text.trim();

    final verified = await auth.verifyOTP(mobile, otp);
    if (!mounted) return;

    if (!verified) {
      _showError(auth.error ?? 'Incorrect OTP code. Please try again.');
      return;
    }

    if (auth.userId != null) {
      await _hydrateSessionProfiles(
        auth: auth,
        citizenProfileProvider: citizenProfileProvider,
        userProvider: userProvider,
        overrideMobile: mobile,
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TText(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showForgotDialog() {
    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    final codeCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final step1Key = GlobalKey<FormState>();
    final step2Key = GlobalKey<FormState>();

    int step = 1;
    bool isSubmitting = false;
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final auth = this.context.read<AuthProvider>();

          return AlertDialog(
            backgroundColor: AppColors.backgroundLight,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: TText(
              step == 1 ? 'Reset Password' : 'Enter Reset Code',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Rajdhani',
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: SingleChildScrollView(
              child: step == 1
                  ? Form(
                      key: step1Key,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const TText(
                            'Enter your registered email address to receive a 6-digit password reset code.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _NeonTextField(
                            controller: emailCtrl,
                            label: 'Email address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!isValidEmail(v.trim())) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          if (dialogError != null) ...[
                            const SizedBox(height: 12),
                            TText(
                              dialogError!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : Form(
                      key: step2Key,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TText(
                            'We sent a 6-digit verification code to ${emailCtrl.text.trim()}. Enter it below with your new password.',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _NeonTextField(
                            controller: codeCtrl,
                            label: '6-Digit Verification Code',
                            icon: Icons.pin_outlined,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: (v) =>
                                (v == null || v.trim().length < 6)
                                    ? 'Enter the 6-digit code'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          _NeonTextField(
                            controller: newPassCtrl,
                            label: 'New Password',
                            icon: Icons.lock_outline_rounded,
                            obscure: obscureNew,
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureNew
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              onPressed: () => setDialogState(
                                () => obscureNew = !obscureNew,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'New password is required';
                              }
                              if (v.length < 8) {
                                return 'Minimum 8 characters required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _NeonTextField(
                            controller: confirmPassCtrl,
                            label: 'Confirm New Password',
                            icon: Icons.lock_reset_rounded,
                            obscure: obscureConfirm,
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              onPressed: () => setDialogState(
                                () => obscureConfirm = !obscureConfirm,
                              ),
                            ),
                            validator: (v) {
                              if (v != newPassCtrl.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          if (dialogError != null) ...[
                            const SizedBox(height: 12),
                            TText(
                              dialogError!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
            actions: [
              TextButton(
                onPressed:
                    isSubmitting ? null : () => Navigator.pop(dialogContext),
                child: const TText(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              if (step == 2)
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() {
                            isSubmitting = true;
                            dialogError = null;
                          });
                          final ok = await auth.resetPassword(
                            emailCtrl.text.trim(),
                          );
                          if (!dialogContext.mounted) return;
                          setDialogState(() {
                            isSubmitting = false;
                            if (!ok) {
                              dialogError =
                                  auth.error ?? 'Could not resend code';
                            }
                          });
                        },
                  child: const TText(
                    'Resend Code',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (step == 1) {
                          if (!step1Key.currentState!.validate()) return;
                          setDialogState(() {
                            isSubmitting = true;
                            dialogError = null;
                          });
                          final sent = await auth.resetPassword(
                            emailCtrl.text.trim(),
                          );
                          if (!dialogContext.mounted) return;
                          setDialogState(() {
                            isSubmitting = false;
                            if (sent) {
                              step = 2;
                            } else {
                              dialogError = auth.error ??
                                  'Failed to send password reset code.';
                            }
                          });
                        } else {
                          if (!step2Key.currentState!.validate()) return;
                          setDialogState(() {
                            isSubmitting = true;
                            dialogError = null;
                          });
                          final resetOk = await auth.confirmResetPassword(
                            email: emailCtrl.text.trim(),
                            newPassword: newPassCtrl.text,
                            confirmationCode: codeCtrl.text.trim(),
                          );
                          if (!dialogContext.mounted) return;
                          setDialogState(() => isSubmitting = false);

                          if (resetOk) {
                            final updatedEmail = emailCtrl.text.trim();
                            final updatedPass = newPassCtrl.text;
                            Navigator.pop(dialogContext);
                            if (mounted) {
                              setState(() {
                                _emailCtrl.text = updatedEmail;
                                _passCtrl.text = updatedPass;
                              });
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: TText(
                                    'Password reset successful! You can now log in.',
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } else {
                            setDialogState(() {
                              dialogError = auth.error ??
                                  'Could not reset password. Check your code.';
                            });
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      )
                    : TText(
                        step == 1 ? 'Send Code' : 'Update Password',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GoogleButton(onTap: _loginGoogle, isLoading: auth.isLoading),
            const SizedBox(height: 20),
            const _Divider(label: '- or login with email -'),
            const SizedBox(height: 16),
            _NeonTextField(
              controller: _emailCtrl,
              label: 'Email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!isValidEmail(v)) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _NeonTextField(
              controller: _passCtrl,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              obscure: !_passVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _passVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () => setState(() => _passVisible = !_passVisible),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotDialog,
                child: const TText(
                  'Forgot Password?',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontFamily: 'Rajdhani',
                  ),
                ),
              ),
            ),
            NeonButton(
              label: 'Login',
              icon: Icons.login_rounded,
              isLoading: auth.isLoading,
              onTap: auth.isLoading ? null : _loginWithEmail,
            ),
            const SizedBox(height: 20),
            const _Divider(label: '- or use mobile OTP -'),
            const SizedBox(height: 12),
            _OTPSection(
              showOTP: _showOTP,
              otpSent: _otpSent,
              activeOtpCode: auth.activeOtpCode,
              mobileCtrl: _mobileCtrl,
              otpCtrls: _otpCtrls,
              otpFocusNodes: _otpFocusNodes,
              onToggle: () => setState(() {
                _showOTP = !_showOTP;
                if (!_showOTP) {
                  _otpSent = false;
                  _mobileCtrl.clear();
                  for (final c in _otpCtrls) {
                    c.clear();
                  }
                }
              }),
              onSendOTP: _sendOTP,
              onVerifyOTP: _verifyOTP,
              onAutoFillOTP: _autoFillOtp,
              isLoading: auth.isLoading,
            ),
            const SizedBox(height: 24),
            _GuestSection(
              onGuest: () async {
                await context.read<AuthProvider>().continueAsGuest();
              },
              isLoading: auth.isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;
  const _GoogleButton({required this.onTap, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: isLoading ? null : onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      backgroundColor: Colors.white.withValues(alpha: 0.06),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              children: [
                TextSpan(text: 'G', style: TextStyle(color: Color(0xFF4285F4))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const TText(
            'Continue with Google',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'Rajdhani',
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _OTPSection extends StatelessWidget {
  final bool showOTP;
  final bool otpSent;
  final String? activeOtpCode;
  final TextEditingController mobileCtrl;
  final List<TextEditingController> otpCtrls;
  final List<FocusNode> otpFocusNodes;
  final VoidCallback onToggle;
  final VoidCallback onSendOTP;
  final VoidCallback onVerifyOTP;
  final ValueChanged<String> onAutoFillOTP;
  final bool isLoading;

  const _OTPSection({
    required this.showOTP,
    required this.otpSent,
    required this.activeOtpCode,
    required this.mobileCtrl,
    required this.otpCtrls,
    required this.otpFocusNodes,
    required this.onToggle,
    required this.onSendOTP,
    required this.onVerifyOTP,
    required this.onAutoFillOTP,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton.icon(
          onPressed: onToggle,
          icon: Icon(
            showOTP ? Icons.keyboard_arrow_up : Icons.phone_android_rounded,
            color: AppColors.accent,
            size: 18,
          ),
          label: TText(
            showOTP ? 'Hide OTP Login' : 'Login with Mobile OTP',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 14,
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          child: showOTP
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    _NeonTextField(
                      controller: mobileCtrl,
                      label: 'Mobile Number',
                      icon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                      prefixText: '+91 ',
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                    if (!otpSent)
                      NeonButton(
                        label: 'Send OTP',
                        icon: Icons.send_rounded,
                        height: 46,
                        isLoading: isLoading,
                        onTap: onSendOTP,
                      ),
                    if (otpSent) ...[
                      if (activeOtpCode != null &&
                          activeOtpCode!.length == 6) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.sms_outlined,
                                color: AppColors.accent,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const TText(
                                      'Civic Voice SMS Gateway Code',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      activeOtpCode!,
                                      style: const TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'SpaceMono',
                                        letterSpacing: 3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => onAutoFillOTP(activeOtpCode!),
                                child: const TText(
                                  'Auto-fill',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const TText(
                        'Enter 6-digit OTP',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontFamily: 'Rajdhani',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      _OTPBoxes(
                        controllers: otpCtrls,
                        focusNodes: otpFocusNodes,
                      ),
                      const SizedBox(height: 16),
                      NeonButton(
                        label: 'Verify OTP',
                        icon: Icons.verified_outlined,
                        height: 46,
                        isLoading: isLoading,
                        onTap: onVerifyOTP,
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: isLoading ? null : onSendOTP,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            size: 16,
                            color: AppColors.accent,
                          ),
                          label: const TText(
                            'Resend OTP',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _OTPBoxes extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;

  const _OTPBoxes({required this.controllers, required this.focusNodes});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 44,
          height: 52,
          child: TextField(
            controller: controllers[i],
            focusNode: focusNodes[i],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFamily: 'SpaceMono',
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: AppColors.surface.withValues(alpha: 0.6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.accent, width: 1.5),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (val) {
              if (val.isNotEmpty && i < 5) {
                focusNodes[i + 1].requestFocus();
              } else if (val.isEmpty && i > 0) {
                focusNodes[i - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }
}

class _GuestSection extends StatelessWidget {
  final VoidCallback onGuest;
  final bool isLoading;
  const _GuestSection({required this.onGuest, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: AppColors.border, thickness: 1),
        const SizedBox(height: 12),
        NeonButton.outlined(
          label: 'Continue as Guest',
          icon: Icons.person_outline_rounded,
          onTap: isLoading ? null : onGuest,
          height: 48,
        ),
        const SizedBox(height: 8),
        const TText(
          'Limited features - No data saved',
          style: TextStyle(
            color: AppColors.textDisabled,
            fontSize: 11,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// REGISTER TAB
// ═════════════════════════════════════════════════════════════════════════════

class _RegisterTab extends StatefulWidget {
  const _RegisterTab();

  @override
  State<_RegisterTab> createState() => _RegisterTabState();
}

class _RegisterTabState extends State<_RegisterTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _passVisible = false;
  bool _confirmVisible = false;
  String _selectedLang = 'en';
  String _selectedState = 'Maharashtra';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _selectedLang = context.read<LanguageProvider>().currentLanguage;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final auth = context.read<AuthProvider>();
    final citizenProfileProvider = context.read<CitizenProfileProvider>();
    final userProvider = context.read<UserProvider>();

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final mobile = _mobileCtrl.text.trim();
    final password = _passCtrl.text;

    final success = await auth.signup(
      name,
      email,
      password,
      phone: mobile,
      state: _selectedState,
      language: _selectedLang,
    );

    if (success && auth.userId != null) {
      await _hydrateSessionProfiles(
        auth: auth,
        citizenProfileProvider: citizenProfileProvider,
        userProvider: userProvider,
        overrideName: name,
        overrideEmail: email,
        overrideMobile: mobile,
        overrideState: _selectedState,
        overrideLanguage: _selectedLang,
      );
      return;
    }

    if (!mounted) return;

    if (auth.error == 'CONFIRM_SIGNUP_REQUIRED') {
      _showEmailVerificationDialog(
        hostContext: context,
        email: email,
        password: password,
        auth: auth,
        citizenProfileProvider: citizenProfileProvider,
        userProvider: userProvider,
        registeredName: name,
        registeredMobile: mobile,
        registeredState: _selectedState,
        registeredLanguage: _selectedLang,
      );
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TText(auth.error!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NeonTextField(
              controller: _nameCtrl,
              label: 'Full Name',
              icon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            _NeonTextField(
              controller: _emailCtrl,
              label: 'Email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!isValidEmail(v)) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _NeonTextField(
              controller: _mobileCtrl,
              label: 'Mobile Number',
              icon: Icons.phone_android_rounded,
              prefixText: '+91 ',
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Mobile number is required';
                if (!isValidIndianPhone(v) && v.length != 10) {
                  return 'Enter a valid 10-digit number';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _NeonTextField(
              controller: _passCtrl,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              obscure: !_passVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _passVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () => setState(() => _passVisible = !_passVisible),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _NeonTextField(
              controller: _confirmPassCtrl,
              label: 'Confirm Password',
              icon: Icons.lock_outline_rounded,
              obscure: !_confirmVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _confirmVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _confirmVisible = !_confirmVisible),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Please confirm your password';
                }
                if (v != _passCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 20),
            const TText(
              'Preferred Language',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontFamily: 'Rajdhani',
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            _LangChipSelector(
              selected: _selectedLang,
              onChanged: (l) {
                setState(() => _selectedLang = l);
                context.read<LanguageProvider>().switchLanguage(l);
              },
            ),
            const SizedBox(height: 20),
            const TText(
              'State / Union Territory',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontFamily: 'Rajdhani',
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            _StateDropdown(
              selected: _selectedState,
              onChanged: (s) {
                if (s != null) {
                  setState(() => _selectedState = s);
                }
              },
            ),
            const SizedBox(height: 24),
            NeonButton(
              label: 'Create Account',
              icon: Icons.app_registration_rounded,
              isLoading: auth.isLoading,
              onTap: auth.isLoading ? null : _register,
            ),
          ],
        ),
      ),
    );
  }
}

class _LangChipSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  static const _langs = [
    ('en', 'EN', 'English'),
    ('hi', 'HI', 'Hindi'),
    ('mr', 'MR', 'Marathi'),
    ('ta', 'TA', 'Tamil'),
  ];

  const _LangChipSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _langs.map((l) {
        final (code, badge, label) = l;
        final isSelected = selected == code;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(code),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    badge,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color:
                          isSelected ? AppColors.accent : AppColors.textPrimary,
                      fontFamily: 'SpaceMono',
                    ),
                  ),
                  const SizedBox(height: 2),
                  TText(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Rajdhani',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StateDropdown extends StatelessWidget {
  final String selected;
  final ValueChanged<String?> onChanged;

  const _StateDropdown({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final normalizedSelected = ProfileConstants.normalizeState(selected);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: normalizedSelected,
          isExpanded: true,
          dropdownColor: AppColors.backgroundLight,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontFamily: 'Rajdhani',
          ),
          items: ProfileConstants.statesAndUTs.map((s) {
            return DropdownMenuItem<String>(
              value: s,
              child: Text(
                lang.translateSync(s),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _NeonTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final String? prefixText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  const _NeonTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.suffixIcon,
    this.validator,
    this.prefixText,
    this.maxLength,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<_NeonTextField> createState() => _NeonTextFieldState();
}

class _NeonTextFieldState extends State<_NeonTextField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeOut);
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!mounted) return;
    if (_focusNode.hasFocus) {
      _glowCtrl.forward();
    } else {
      _glowCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _glowCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.15 * _glowAnim.value),
              blurRadius: 12 * _glowAnim.value,
              spreadRadius: -2,
            ),
          ],
        ),
        child: child,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscure,
        maxLength: widget.maxLength,
        inputFormatters: widget.inputFormatters,
        textCapitalization: widget.textCapitalization,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontFamily: 'Rajdhani',
        ),
        validator: widget.validator != null
            ? (v) {
                final err = widget.validator!(v);
                return err != null ? lang.translateSync(err) : null;
              }
            : null,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: lang.translateSync(widget.label),
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontFamily: 'Rajdhani',
          ),
          counterText: '',
          prefixIcon: Icon(widget.icon, color: AppColors.accent, size: 20),
          prefixText: widget.prefixText,
          prefixStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontFamily: 'SpaceMono',
            fontSize: 13,
          ),
          suffixIcon: widget.suffixIcon,
          filled: true,
          fillColor: AppColors.surface.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          errorStyle: const TextStyle(color: AppColors.error, fontSize: 11),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final String label;
  const _Divider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TText(
            label,
            style: const TextStyle(
              color: AppColors.textDisabled,
              fontSize: 11,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
      ],
    );
  }
}
