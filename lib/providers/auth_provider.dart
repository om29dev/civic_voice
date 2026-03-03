import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  static const _sessionKey = 'cvi_user_session';

  final SupabaseClient _client = Supabase.instance.client;

  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isGuest = false;
  String? _error;

  UserModel? get currentUser    => _currentUser;
  bool get isLoading            => _isLoading;
  bool get isGuest              => _isGuest;
  String? get error             => _error;
  bool get isAuthenticated      => _currentUser != null;
  bool get isRealUser           => isAuthenticated && !_isGuest;

  AuthProvider() {
    _init();
  }

  // ─── Init ──────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final session = _client.auth.currentSession;
      if (session != null) {
        _currentUser = await _fetchUserModel(session.user);
      } else {
        await _tryRestoreGuestSession();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Listen for Supabase auth changes
    _client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _currentUser = await _fetchUserModel(session.user);
        _isGuest = false;
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        _isGuest = false;
      }
      notifyListeners();
    });
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Future<UserModel> _fetchUserModel(User supabaseUser) async {
    final prefs = await SharedPreferences.getInstance();
    final name  = prefs.getString('cvi_name_${supabaseUser.id}') ?? 'User';
    final lang  = prefs.getString('cvi_lang_${supabaseUser.id}') ?? 'en';
    return UserModel(
      id: supabaseUser.id,
      name: name,
      email: supabaseUser.email,
      mobile: supabaseUser.phone,
      language: lang,
      createdAt: DateTime.tryParse(supabaseUser.createdAt) ?? DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
  }

  Future<void> _tryRestoreGuestSession() async {
    final prefs = await SharedPreferences.getInstance();
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

  // ─── Public Methods ────────────────────────────────────────────────────────

  /// Sign in with email and password via Supabase.
  Future<bool> loginWithEmail(String email, String password) async {
    _clearError();
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.session != null) {
        _currentUser = await _fetchUserModel(response.user!);
        _isGuest = false;
        return true;
      }
      _error = 'Login failed. Please check your credentials.';
      return false;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    await loginWithEmail(email, password);
  }

  /// Mock Google Sign-In (wire up google_sign_in later).
  Future<bool> loginWithGoogle() async {
    _clearError();
    _isLoading = true;
    notifyListeners();
    try {
      // TODO: Replace with real Google OAuth when configured in Supabase dashboard.
      await Future.delayed(const Duration(seconds: 1));
      _error = 'Google Sign-In is not yet configured. Please use email or guest login.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mock OTP-based sign-in (wire up Supabase phone auth later).
  Future<bool> sendOTP(String mobile) async {
    _clearError();
    _isLoading = true;
    notifyListeners();
    try {
      await _client.auth.signInWithOtp(phone: mobile.trim());
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Failed to send OTP. Check your number and try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOTP(String mobile, String otp) async {
    _clearError();
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _client.auth.verifyOTP(
        phone: mobile.trim(),
        token: otp.trim(),
        type: OtpType.sms,
      );
      if (response.session != null) {
        _currentUser = await _fetchUserModel(response.user!);
        _isGuest = false;
        return true;
      }
      _error = 'Invalid OTP. Please try again.';
      return false;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'OTP verification failed.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register a new user with Supabase.
  Future<bool> signup(
    String name,
    String email,
    String password, {
    String? phone,
    String? language,
  }) async {
    _clearError();
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'name': name,
          'mobile': phone ?? '',
          'language': language ?? 'en'
        },
      );
      if (response.session != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cvi_name_${response.user!.id}', name);
        await prefs.setString('cvi_lang_${response.user!.id}', language ?? 'en');
        _currentUser = UserModel(
          id: response.user!.id,
          name: name,
          email: email,
          mobile: phone ?? '',
          language: language ?? 'en',
          createdAt: DateTime.now(),
        );
        _isGuest = false;
        return true;
      } else if (response.user != null) {
        _error = 'Please check your email to verify your account before logging in.';
        return false;
      }
      _error = 'Registration failed. Please try again.';
      return false;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Let the user browse without signing in.
  Future<void> continueAsGuest() async {
    _clearError();
    final guest = UserModel.guest();
    _currentUser = guest;
    _isGuest = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_sessionKey/guest_id', guest.id);
    await prefs.setString('$_sessionKey/lang', guest.language);

    notifyListeners();
  }

  /// Sign out and clear stored session.
  Future<void> logout() async {
    try {
      if (!_isGuest) {
        await _client.auth.signOut();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_sessionKey/guest_id');
      await prefs.remove('$_sessionKey/lang');
      _currentUser = null;
      _isGuest = false;
    } catch (_) {
      // Always clear local state even if network call fails
      _currentUser = null;
      _isGuest = false;
    } finally {
      notifyListeners();
    }
  }

  /// Persist and apply a new language for the current user.
  Future<void> updateLanguage(String langCode) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(language: langCode);
    final prefs = await SharedPreferences.getInstance();
    if (_isGuest) {
      await prefs.setString('$_sessionKey/lang', langCode);
    } else {
      await prefs.setString('cvi_lang_${_currentUser!.id}', langCode);
    }
    notifyListeners();
  }

  /// Sends a password reset email via Supabase.
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } catch (_) {
      // Silently fail — success message is always shown for security
    }
  }

  // ─── Legacy API Stubs ───────────────────────────────────────────────────────

  /// Alias for currentUser?.id used by legacy screens.
  String? get userId => _currentUser?.id;

  /// Alias for [error] used by legacy screens.
  String? get errorMessage => _error;

  /// Display name of the current user.
  String get userName => _currentUser?.name ?? 'User';
}
