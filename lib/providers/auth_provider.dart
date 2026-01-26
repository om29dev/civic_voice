import 'package:flutter/material.dart';

enum AuthStatus { authenticated, unauthenticated, guest }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unauthenticated;
  String? _userName;

  AuthStatus get status => _status;
  String? get userName => _userName;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isGuest => _status == AuthStatus.guest;

  Future<void> login(String email, String password) async {
    // Mock login delay
    await Future.delayed(const Duration(seconds: 1));
    _status = AuthStatus.authenticated;
    _userName = email.split('@')[0];
    notifyListeners();
  }

  Future<void> signup(String name, String email, String password) async {
    // Mock signup delay
    await Future.delayed(const Duration(seconds: 1));
    _status = AuthStatus.authenticated;
    _userName = name;
    notifyListeners();
  }

  void continueAsGuest() {
    _status = AuthStatus.guest;
    _userName = "Guest User";
    notifyListeners();
  }

  void logout() {
    _status = AuthStatus.unauthenticated;
    _userName = null;
    notifyListeners();
  }
}
