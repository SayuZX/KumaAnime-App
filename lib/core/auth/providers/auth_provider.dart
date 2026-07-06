import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/user_badge.dart';
import '../models/user_role.dart';
import '../repositories/auth_repository.dart';
import '../services/account_linking_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  
  AppUser? _user;
  StreamSubscription? _authSubscription;
  bool _isInitialized = false;

  AuthProvider(this._authRepository);

  AppUser? get user => _user;
  bool get isAnonymous => _user?.anonymous ?? true;
  bool get isContributor => !isAnonymous;
  UserRole get role => _user?.role ?? UserRole.guest;
  List<UserBadge> get badges => _user?.badges ?? [];
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });

    // Attempt anonymous sign in if not already signed in
    if (_authRepository.currentUser == null) {
      await _authRepository.signInAnonymously();
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> loginWithAuth0() async {
    try {
      await _authRepository.signInWithAuth0();
    } catch (e) {
      debugPrint('Failed to login with Auth0: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.signOut();
    } catch (e) {
      debugPrint('Failed to logout: $e');
      rethrow;
    }
  }

  Future<void> linkAccount(LinkStrategy strategy) async {
    try {
      await _authRepository.linkAnonymousToAuth0(strategy);
    } catch (e) {
      debugPrint('Failed to link account: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
