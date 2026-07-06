import 'dart:async';
import '../models/app_user.dart';
import '../services/account_linking_service.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;
  
  Future<AppUser> signInAnonymously();
  Future<AppUser> signInWithAuth0();
  Future<void> signOut();
  Future<AppUser> linkAnonymousToAuth0(LinkStrategy strategy);
}
