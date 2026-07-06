import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../services/auth0_service.dart';
import '../services/account_linking_service.dart';
import 'auth_repository.dart';
import 'user_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final Auth0Service _auth0Service;
  final UserRepository _userRepository;

  final StreamController<AppUser?> _authStateController = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;
  
  AuthRepositoryImpl(this._auth0Service, this._userRepository) {
    _init();
  }

  void _init() {
    _firebaseAuth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser == null) {
        _updateUser(null);
        return;
      }

      final userDoc = await _userRepository.getUser(firebaseUser.uid);
      if (userDoc != null) {
        _updateUser(userDoc);
      } else {
        // Doc doesn't exist yet, we'll create it during sign in
      }
    });
  }

  void _updateUser(AppUser? user) {
    _currentUser = user;
    _authStateController.add(user);
  }

  @override
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<AppUser> signInAnonymously() async {
    final cred = await _firebaseAuth.signInAnonymously();
    final uid = cred.user!.uid;

    var appUser = await _userRepository.getUser(uid);
    if (appUser == null) {
      appUser = AppUser(
        uid: uid,
        anonymous: true,
        nickname: 'Otaku-${uid.substring(0, 4)}',
        role: UserRole.guest,
        badges: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _userRepository.createUser(appUser);
    }
    
    _updateUser(appUser);
    return appUser;
  }

  @override
  Future<AppUser> signInWithAuth0() async {
    final auth0Creds = await _auth0Service.login();
    final profile = auth0Creds.user;
    
    // Auth0 successfully logged in. 
    // We need to create a custom token to sign in to Firebase with this identity, 
    // but since we are using Firebase Anonymous + Auth0, we can just use the Auth0 sub as the UID.
    // However, Firebase doesn't allow setting arbitrary UIDs without a custom token backend.
    // In a purely serverless setup without cloud functions, we can continue using the Firebase Anonymous UID
    // but update the Firestore doc to indicate they are no longer anonymous.
    
    final currentUid = _firebaseAuth.currentUser?.uid;
    if (currentUid == null) {
      throw Exception("Must be signed in anonymously first to upgrade account.");
    }
    
    // Store old UID in case we need to link later if they are signing into a different Auth0 account
    // For simplicity, we just upgrade the current anonymous account in place
    
    // Provider parsing from Auth0 'sub' (e.g., github|123456)
    final subParts = profile.sub.split('|');
    final provider = subParts.length > 1 ? subParts[0] : null;
    
    final updatedUser = AppUser(
      uid: currentUid,
      anonymous: false,
      nickname: profile.nickname ?? profile.name ?? 'Contributor',
      avatar: profile.pictureUrl?.toString(),
      email: profile.email,
      provider: provider,
      role: UserRole.contributor, // Default role for new contributors. Firestore rules prevent client override of existing role.
      badges: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // This will merge with existing data, preserving server-assigned roles/badges
    await _userRepository.createUser(updatedUser);
    
    final finalUser = await _userRepository.getUser(currentUid);
    _updateUser(finalUser);
    return finalUser!;
  }

  @override
  Future<void> signOut() async {
    if (_currentUser?.anonymous == false) {
      await _auth0Service.logout();
    }
    await _firebaseAuth.signOut();
    // Re-authenticate anonymously so the app always has a user context
    await signInAnonymously();
  }

  @override
  Future<AppUser> linkAnonymousToAuth0(LinkStrategy strategy) async {
    // Implement complex linking if using Custom Tokens and changing UIDs.
    // For now, since we upgraded in-place during signInWithAuth0, this is a no-op placeholder.
    return _currentUser!;
  }
}
