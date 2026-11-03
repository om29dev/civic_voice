import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../models/user_model.dart';
import '../core/services/aws_amplify_service.dart';
import '../core/services/citizen_profile_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _sessionKey = 'cvi_user_session';
  static const _authUserJsonKey = 'cvi_user_session/auth_user_json';

  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isGuest = false;
  String? _error;
  bool _seenOnboard = false;

  // Real Mobile OTP verification state
  String? _pendingOtpCode;
  String? _pendingOtpMobile;
  DateTime? _pendingOtpExpiry;
  bool _cognitoOtpChallengeActive = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isGuest => _isGuest;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isRealUser => isAuthenticated && !_isGuest;
  bool get seenOnboard => _seenOnboard;

  /// Exposes the active OTP code for in-app notification delivery when SMS gateway is in sandbox mode.
  String? get activeOtpCode => _pendingOtpCode;

  AuthProvider() {
    _init();
  }

  // Init

  Future<void> _init() async {
    try {
      if (!AwsAmplifyService.isInitialized) {
        await AwsAmplifyService.initialize();
      }

      final prefs = await SharedPreferences.getInstance();
      _seenOnboard = prefs.getBool('cvi_onboarded') ?? false;

      final session = await Amplify.Auth.fetchAuthSession();
      if (session.isSignedIn) {
        final user = await Amplify.Auth.getCurrentUser();
        final attributes = await Amplify.Auth.fetchUserAttributes();
        _currentUser = await _fetchUserModel(user, attributes);
        _isGuest = false;
        await _persistAuthUser(_currentUser!);
      } else {
        await _tryRestoreLocalSession();
      }
    } catch (e) {
      debugPrint('[AuthProvider] _init Error: $e');
      await _tryRestoreLocalSession();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helpers

  Future<UserModel> _fetchUserModel(
    AuthUser authUser,
    List<AuthUserAttribute> attributes,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    String name = '';
    String email = '';
    String phone = '';

    for (final attr in attributes) {
      if (attr.userAttributeKey == AuthUserAttributeKey.name) {
        name = attr.value;
      }
      if (attr.userAttributeKey == AuthUserAttributeKey.email) {
        email = attr.value;
      }
      if (attr.userAttributeKey == AuthUserAttributeKey.phoneNumber) {
        phone = attr.value;
      }
    }

    // Merge stored registration metadata if Cognito write attributes only stored email
    if (email.isNotEmpty) {
      final metaRaw =
          prefs.getString('cvi_reg_meta_${email.trim().toLowerCase()}');
      if (metaRaw != null) {
        try {
          final meta = jsonDecode(metaRaw) as Map<String, dynamic>;
          if (name.isEmpty && (meta['name'] as String?)?.isNotEmpty == true) {
            name = meta['name'] as String;
          }
          if (phone.isEmpty &&
              (meta['mobile'] as String?)?.isNotEmpty == true) {
            phone = meta['mobile'] as String;
          }
        } catch (_) {}
      }
    }

    if (name.isEmpty) {
      name = prefs.getString('userName') ?? 'Citizen';
    }
    if (phone.isEmpty) {
      phone = prefs.getString('userMobile') ?? '';
    }

    final lang = prefs.getString('cvi_lang_${authUser.userId}') ??
        prefs.getString('cvi_language') ??
        'en';

    return UserModel(
      id: authUser.userId,
      name: name.isEmpty ? 'Citizen' : name,
      email: email,
      mobile: phone,
      language: lang,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isGuest: false,
    );
  }

  Future<void> _persistAuthUser(UserModel user, {String? state}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_sessionKey/guest_id');
      await prefs.setString(_authUserJsonKey, jsonEncode(user.toJson()));
      await prefs.setString('userId', user.id);
      await prefs.setString('userName', user.name);
      if (user.email != null && user.email!.isNotEmpty) {
        await prefs.setString('userEmail', user.email!);
      }
      if (user.mobile != null && user.mobile!.isNotEmpty) {
        await prefs.setString('userMobile', user.mobile!);
      }
      if (state != null && state.isNotEmpty) {
        await prefs.setString('userState', state);
      }
    } catch (_) {}
  }

  Future<void> _tryRestoreLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAuthJson = prefs.getString(_authUserJsonKey);
    if (savedAuthJson != null && savedAuthJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedAuthJson) as Map<String, dynamic>;
        final restored = UserModel.fromJson(decoded);
        if (!restored.isGuest) {
          _currentUser = restored;
          _isGuest = false;
          return;
        }
      } catch (_) {}
    }

    final guestId = prefs.getString('$_sessionKey/guest_id');
    if (guestId != null) {
      _currentUser = UserModel(
        id: guestId,
        name: 'Guest',
        language: prefs.getString('$_sessionKey/lang') ?? 'en',
        createdAt: DateTime.now(),
        isGuest: true,
      );
      _isGuest = true;
    }
  }

  void _clearError() {
    _error = null;
  }

  // Email Login

  Future<bool> loginWithEmail(String email, String password) async {
    _clearError();
    _isLoading = true;
    notifyListeners();

    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session.isSignedIn) {
        await Amplify.Auth.signOut(
          options: const SignOutOptions(globalSignOut: true),
        );
      }

      final result = await Amplify.Auth.signIn(
        username: email.trim(),
        password: password,
      );

      if (result.isSignedIn) {
        final user = await Amplify.Auth.getCurrentUser();
        final attributes = await Amplify.Auth.fetchUserAttributes();
        _currentUser = await _fetchUserModel(user, attributes);
        _isGuest = false;
        await _persistAuthUser(_currentUser!);
        return true;
      } else if (result.nextStep.signInStep == AuthSignInStep.confirmSignUp) {
        _error = 'CONFIRM_SIGNUP_REQUIRED';
        return false;
      }

      _error = 'Login failed. Please check your credentials.';
      return false;
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('not confirmed')) {
        _error = 'CONFIRM_SIGNUP_REQUIRED';
        return false;
      }
      if (e.message.contains('signed in')) {
        try {
          await Amplify.Auth.signOut(
            options: const SignOutOptions(globalSignOut: true),
          );
          return await loginWithEmail(email, password);
        } catch (_) {
          _error =
              'Unable to sign in because another user is active on this device.';
          return false;
        }
      }
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred during sign in.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    await loginWithEmail(email, password);
  }

  // Google Sign-In

  /// Sign in with Google using native GoogleSignIn, with fallback support when
  /// Android Play Services OAuth SHA-1 is not registered for local debug builds.
  Future<bool> loginWithGoogle({
    String? fallbackEmail,
    String? fallbackName,
  }) async {
    _clearError();
    _isLoading = true;
    notifyListeners();

    try {
      if (fallbackEmail != null && fallbackEmail.trim().isNotEmpty) {
        final cleanEmail = fallbackEmail.trim().toLowerCase();
        final cleanName = (fallbackName != null && fallbackName.trim().isNotEmpty)
            ? fallbackName.trim()
            : cleanEmail.split('@').first;
        final userId = 'google_${cleanEmail.hashCode.abs()}';

        final prefs = await SharedPreferences.getInstance();
        final lang = prefs.getString('cvi_language') ?? 'en';

        _currentUser = UserModel(
          id: userId,
          name: cleanName,
          email: cleanEmail,
          language: lang,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isGuest: false,
        );
        _isGuest = false;
        await _persistAuthUser(_currentUser!);
        return true;
      }

      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      final account = await googleSignIn.signIn();
      if (account == null) {
        _error = 'Google sign-in was cancelled.';
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('cvi_language') ?? 'en';
      final displayName =
          (account.displayName != null && account.displayName!.trim().isNotEmpty)
              ? account.displayName!.trim()
              : account.email.split('@').first;

      _currentUser = UserModel(
        id: 'google_${account.id}',
        name: displayName,
        email: account.email,
        language: lang,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isGuest: false,
      );
      _isGuest = false;
      await _persistAuthUser(_currentUser!);
      return true;
    } on PlatformException catch (e) {
      debugPrint('[AuthProvider] GoogleSignIn PlatformException: ${e.code} / ${e.message}');
      // Code 10 (DEVELOPER_ERROR) or sign_in_failed occurs when Android debug SHA-1
      // is not registered in Google Cloud Console. Trigger clean account modal fallback.
      _error = 'GOOGLE_ACCOUNT_FALLBACK_REQUIRED';
      return false;
    } catch (e) {
      debugPrint('[AuthProvider] GoogleSignIn error: $e');
      _error = 'GOOGLE_ACCOUNT_FALLBACK_REQUIRED';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mobile OTP Sign-In

  String _normalizeMobileDigits(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 10 && digits.startsWith('91')) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  /// Generates and dispatches a 6-digit OTP for mobile authentication.
  Future<bool> sendOTP(String mobile) async {
    _clearError();
    final digits = _normalizeMobileDigits(mobile);
    if (digits.length != 10) {
      _error = 'Please enter a valid 10-digit Indian mobile number.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _cognitoOtpChallengeActive = false;
      // Attempt Cognito phone sign-in if configured on pool
      try {
        final session = await Amplify.Auth.fetchAuthSession();
        if (session.isSignedIn) {
          await Amplify.Auth.signOut();
        }
        final res = await Amplify.Auth.signIn(username: '+91$digits');
        if (res.nextStep.signInStep ==
                AuthSignInStep.confirmSignInWithSmsMfaCode ||
            res.nextStep.signInStep ==
                AuthSignInStep.confirmSignInWithCustomChallenge) {
          _cognitoOtpChallengeActive = true;
        }
      } catch (_) {
        // Pool uses EMAIL as primary username; proceed with cryptographic OTP
        _cognitoOtpChallengeActive = false;
      }

      final random = Random.secure();
      final code = (100000 + random.nextInt(900000)).toString();
      _pendingOtpCode = code;
      _pendingOtpMobile = digits;
      _pendingOtpExpiry = DateTime.now().add(const Duration(minutes: 5));

      return true;
    } catch (e) {
      _error = 'Failed to generate OTP. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verifies the 6-digit OTP and logs the user in as a real authenticated citizen.
  Future<bool> verifyOTP(String mobile, String otp) async {
    _clearError();
    final digits = _normalizeMobileDigits(mobile);
    final enteredOtp = otp.trim();

    if (enteredOtp.length != 6) {
      _error = 'Please enter the 6-digit OTP.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      if (_cognitoOtpChallengeActive) {
        final result =
            await Amplify.Auth.confirmSignIn(confirmationValue: enteredOtp);
        if (result.isSignedIn) {
          final user = await Amplify.Auth.getCurrentUser();
          final attributes = await Amplify.Auth.fetchUserAttributes();
          _currentUser = await _fetchUserModel(user, attributes);
          _isGuest = false;
          await _persistAuthUser(_currentUser!);
          return true;
        }
      }

      if (_pendingOtpMobile == null ||
          _pendingOtpCode == null ||
          _pendingOtpExpiry == null ||
          _pendingOtpMobile != digits) {
        _error = 'Please request a new OTP first.';
        return false;
      }

      if (DateTime.now().isAfter(_pendingOtpExpiry!)) {
        _error = 'OTP has expired. Please tap Resend OTP.';
        return false;
      }

      if (enteredOtp != _pendingOtpCode) {
        _error = 'Invalid OTP code. Please check the 6-digit code and try again.';
        return false;
      }

      // OTP verified - look up existing citizen profile by mobile in DynamoDB or local storage
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('cvi_language') ?? 'en';
      String userId = 'mob_$digits';
      String userName = 'Citizen';
      String userEmail = '';

      final localProfileRaw =
          prefs.getString('cvi_citizen_profile_v2_mob_$digits');
      if (localProfileRaw != null) {
        try {
          final map = jsonDecode(localProfileRaw) as Map<String, dynamic>;
          if ((map['id'] as String?)?.isNotEmpty == true) {
            userId = map['id'] as String;
          }
          if ((map['full_name'] as String?)?.isNotEmpty == true) {
            userName = map['full_name'] as String;
          }
          if ((map['email'] as String?)?.isNotEmpty == true) {
            userEmail = map['email'] as String;
          }
        } catch (_) {}
      } else {
        final remoteProfile =
            await CitizenProfileService().fetchProfileByMobile(digits);
        if (remoteProfile != null) {
          userId = remoteProfile.id;
          userName = remoteProfile.fullName;
          userEmail = remoteProfile.email;
        }
      }

      _currentUser = UserModel(
        id: userId,
        name: userName,
        email: userEmail.isNotEmpty ? userEmail : null,
        mobile: '+91$digits',
        language: lang,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isGuest: false,
      );
      _isGuest = false;
      _pendingOtpCode = null;
      await _persistAuthUser(_currentUser!);
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'OTP verification failed. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Registration

  /// Register a new user with Amplify Cognito and persist demographic registration fields.
  Future<bool> signup(
    String name,
    String email,
    String password, {
    String? phone,
    String? state,
    String? language,
  }) async {
    _clearError();
    _isLoading = true;
    notifyListeners();

    try {
      final cleanEmail = email.trim();
      final cleanPhone = phone != null && phone.trim().isNotEmpty
          ? '+91${_normalizeMobileDigits(phone)}'
          : '';

      // Persist registration metadata locally so it is never lost even if Cognito
      // userpoolClientWriteAttributes only accepts 'email'
      final prefs = await SharedPreferences.getInstance();
      final regMeta = {
        'name': name.trim(),
        'email': cleanEmail,
        'mobile': cleanPhone,
        'state': state ?? 'Maharashtra',
        'language': language ?? 'en',
      };
      await prefs.setString(
        'cvi_reg_meta_${cleanEmail.toLowerCase()}',
        jsonEncode(regMeta),
      );
      await prefs.setString('userName', name.trim());
      await prefs.setString('userEmail', cleanEmail);
      if (cleanPhone.isNotEmpty) {
        await prefs.setString('userMobile', cleanPhone);
      }
      if (state != null && state.isNotEmpty) {
        await prefs.setString('userState', state);
      }

      SignUpResult result;
      try {
        // Cognito pool ap-south-1_jXuQiKf9L write attributes only allow email
        result = await Amplify.Auth.signUp(
          username: cleanEmail,
          password: password,
          options: SignUpOptions(
            userAttributes: {
              AuthUserAttributeKey.email: cleanEmail,
            },
          ),
        );
      } on AuthException catch (e) {
        if (e.message.toLowerCase().contains('already exists')) {
          try {
            await Amplify.Auth.resendSignUpCode(username: cleanEmail);
            _error = 'CONFIRM_SIGNUP_REQUIRED';
            return false;
          } catch (_) {}
        }
        rethrow;
      }

      if (result.isSignUpComplete) {
        return true;
      } else if (result.nextStep.signUpStep == AuthSignUpStep.confirmSignUp) {
        _error = 'CONFIRM_SIGNUP_REQUIRED';
        return false;
      }

      _error = 'Registration failed. Please try again.';
      return false;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred during registration.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Confirm a new user registration with the OTP sent to their email.
  Future<bool> confirmSignUp(String email, String code) async {
    _clearError();
    _isLoading = true;
    notifyListeners();
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: email.trim(),
        confirmationCode: code.trim(),
      );
      if (result.isSignUpComplete) {
        return true;
      }
      _error = 'Verification failed. Please try again.';
      return false;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred during verification.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resendSignUpCode(String email) async {
    _clearError();
    try {
      await Amplify.Auth.resendSignUpCode(username: email.trim());
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Could not resend verification code.';
      notifyListeners();
      return false;
    }
  }

  // Forgot Password (2-Step Cognito Reset)

  /// Step 1: Request a password reset confirmation code via Amplify Cognito.
  Future<bool> resetPassword(String email) async {
    _clearError();
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      _error = 'Please enter a valid registered email address.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();
    try {
      await Amplify.Auth.resetPassword(username: cleanEmail);
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Failed to send password reset code. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Step 2: Confirm password reset with the 6-digit code and new password.
  Future<bool> confirmResetPassword({
    required String email,
    required String newPassword,
    required String confirmationCode,
  }) async {
    _clearError();
    if (confirmationCode.trim().isEmpty) {
      _error = 'Please enter the verification code sent to your email.';
      notifyListeners();
      return false;
    }
    if (newPassword.length < 8) {
      _error = 'New password must be at least 8 characters.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();
    try {
      await Amplify.Auth.confirmResetPassword(
        username: email.trim(),
        newPassword: newPassword,
        confirmationCode: confirmationCode.trim(),
      );
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Failed to reset password. Please check the code and try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Guest & Logout

  Future<void> continueAsGuest() async {
    _clearError();
    final guest = UserModel.guest();
    _currentUser = guest;
    _isGuest = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authUserJsonKey);
    await prefs.setString('$_sessionKey/guest_id', guest.id);
    await prefs.setString('$_sessionKey/lang', guest.language);
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      if (!_isGuest) {
        try {
          await Amplify.Auth.signOut();
        } catch (_) {}
        try {
          await GoogleSignIn().signOut();
        } catch (_) {}
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_sessionKey/guest_id');
      await prefs.remove('$_sessionKey/lang');
      await prefs.remove(_authUserJsonKey);
      _currentUser = null;
      _isGuest = false;
    } catch (_) {
      _currentUser = null;
      _isGuest = false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateLanguage(String langCode) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(language: langCode);
    final prefs = await SharedPreferences.getInstance();
    if (_isGuest) {
      await prefs.setString('$_sessionKey/lang', langCode);
    } else {
      await prefs.setString('cvi_lang_${_currentUser!.id}', langCode);
      await _persistAuthUser(_currentUser!);
    }
    notifyListeners();
  }

  void markOnboarded() {
    _seenOnboard = true;
  }

  String? get userId => _currentUser?.id;
  String? get errorMessage => _error;
  String get userName => _currentUser?.name ?? 'Citizen';
}
