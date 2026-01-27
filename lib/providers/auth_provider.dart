import 'package:flutter/material.dart';
import '../core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { authenticated, unauthenticated, guest, loading }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unauthenticated;
  String? _userName;
  String? _userId;
  String? _email;
  String? _errorMessage;

  AuthProvider() {
    _checkCurrentSession();
    _listenToAuthChanges();
  }

  AuthStatus get status => _status;
  String? get userName => _userName;
  String? get userId => _userId;
  String? get email => _email;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isGuest => _status == AuthStatus.guest;
  bool get isLoading => _status == AuthStatus.loading;

  void _checkCurrentSession() {
    if (SupabaseService.isInitialized && SupabaseService.isLoggedIn) {
      final user = SupabaseService.currentUser!;
      _status = AuthStatus.authenticated;
      _userId = user.id;
      _email = user.email;
      _userName = user.userMetadata?['name'] ?? user.email?.split('@')[0];
      notifyListeners();
    }
  }

  void _listenToAuthChanges() {
    if (!SupabaseService.isInitialized) return;
    
    SupabaseService.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      
      if (event == AuthChangeEvent.signedIn && session != null) {
        _status = AuthStatus.authenticated;
        _userId = session.user.id;
        _email = session.user.email;
        _userName = session.user.userMetadata?['name'] ?? session.user.email?.split('@')[0];
        _errorMessage = null;
        notifyListeners();
      } else if (event == AuthChangeEvent.signedOut) {
        _status = AuthStatus.unauthenticated;
        _userId = null;
        _email = null;
        _userName = null;
        notifyListeners();
      }
    });
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await SupabaseService.signInWithEmail(email, password);
      if (response.user != null) {
        _status = AuthStatus.authenticated;
        _userId = response.user!.id;
        _email = response.user!.email;
        _userName = response.user!.userMetadata?['name'] ?? email.split('@')[0];
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Login failed';
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup(String name, String email, String password, {String? phone}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await SupabaseService.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'phone': phone},
      );
      
      if (response.user != null) {
        _status = AuthStatus.authenticated;
        _userId = response.user!.id;
        _email = response.user!.email;
        _userName = name;
        notifyListeners();
        
        // Create profile in database
        await _createUserProfile(response.user!.id, name, email, phone);
        return true;
      } else {
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Signup failed';
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  Future<void> _createUserProfile(String id, String name, String email, String? phone) async {
    try {
      await SupabaseService.from('profiles').upsert({
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error creating profile: $e');
    }
  }

  void continueAsGuest() {
    _status = AuthStatus.guest;
    _userName = "Guest User";
    _userId = null;
    _email = null;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await SupabaseService.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
    _status = AuthStatus.unauthenticated;
    _userName = null;
    _userId = null;
    _email = null;
    notifyListeners();
  }
}
