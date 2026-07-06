import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/user_repository.dart';

enum LinkStrategy { continueAsGuest, mergeData, startFresh }

class AccountLinkingService {
  final UserRepository _userRepository;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AccountLinkingService(this._userRepository);

  Future<void> mergeAnonymousData(String oldUid, String newUid) async {
    // 1. Copy old user data
    final oldUser = await _userRepository.getUser(oldUid);
    if (oldUser != null) {
      // Merge badges, keep new user's role if it's already higher
      await _userRepository.updateUser(newUid, {
        if (oldUser.badges.isNotEmpty) 'badges': FieldValue.arrayUnion(oldUser.badges.map((b) => b.firestoreKey).toList()),
      });
    }

    // 2. Migrate bookmarks
    final bookmarksSnapshot = await _db.collection('users').doc(oldUid).collection('bookmarks').get();
    for (var doc in bookmarksSnapshot.docs) {
      await _db.collection('users').doc(newUid).collection('bookmarks').doc(doc.id).set(doc.data());
    }

    // 3. Migrate history
    final historySnapshot = await _db.collection('users').doc(oldUid).collection('history').get();
    for (var doc in historySnapshot.docs) {
      await _db.collection('users').doc(newUid).collection('history').doc(doc.id).set(doc.data());
    }

    // 4. Clear old data
    await clearAnonymousData(oldUid);
  }

  Future<void> clearAnonymousData(String oldUid) async {
    // Delete subcollections first (simplified for client-side, ideally done via Cloud Functions)
    final bookmarksSnapshot = await _db.collection('users').doc(oldUid).collection('bookmarks').get();
    for (var doc in bookmarksSnapshot.docs) {
      await doc.reference.delete();
    }
    
    final historySnapshot = await _db.collection('users').doc(oldUid).collection('history').get();
    for (var doc in historySnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete main doc
    await _userRepository.deleteUser(oldUid);
  }
}
