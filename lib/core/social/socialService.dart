import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive/hive.dart';
import 'package:kumaanime/core/app/logging.dart';
import 'package:kumaanime/core/commons/enums/hiveEnums.dart';

class SocialComment {
  final String id;
  final String uid;
  final String nickname;
  final String text;
  final DateTime? createdAt;

  SocialComment({
    required this.id,
    required this.uid,
    required this.nickname,
    required this.text,
    this.createdAt,
  });

  factory SocialComment.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return SocialComment(
      id: doc.id,
      uid: (data['uid'] ?? '').toString(),
      nickname: (data['nickname'] ?? 'Anon').toString(),
      text: (data['text'] ?? '').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class SocialService {
  SocialService._();

  static final SocialService instance = SocialService._();

  static const String _nicknameKey = 'socialNickname';

  bool _ready = false;
  String? _uid;

  bool get isReady => _ready;
  String? get uid => _uid;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      final cred = await FirebaseAuth.instance.signInAnonymously();
      _uid = cred.user?.uid;
      _ready = _uid != null;
    } catch (err) {
      _ready = false;
      Logs.app.log("[SOCIAL] init failed: ${err.toString()}");
    }
  }

  Future<Box> _box() async {
    final name = HiveBox.kumaanime.boxName;
    return Hive.isBoxOpen(name) ? Hive.box(name) : await Hive.openBox(name);
  }

  Future<String> getNickname() async {
    final box = await _box();
    final stored = box.get(_nicknameKey);
    if (stored is String && stored.trim().isNotEmpty) return stored;
    final fallback = "Otaku-${(_uid ?? '0000').substring(0, (_uid ?? '0000').length < 4 ? (_uid ?? '0000').length : 4)}";
    return fallback;
  }

  Future<void> setNickname(String nickname) async {
    final box = await _box();
    await box.put(_nicknameKey, nickname.trim());
  }

  DocumentReference<Map<String, dynamic>> _animeDoc(String key) => _db.collection('anime_social').doc(key);

  Stream<Map<String, int>> watchCounts(String key) {
    return _animeDoc(key).snapshots().map((snap) {
      final data = snap.data() ?? {};
      return {
        'likes': (data['likes'] ?? 0) as int,
        'dislikes': (data['dislikes'] ?? 0) as int,
      };
    });
  }

  Future<int> getMyVote(String key) async {
    if (_uid == null) return 0;
    final snap = await _animeDoc(key).collection('votes').doc(_uid).get();
    return (snap.data()?['value'] ?? 0) as int;
  }

  Future<int> setVote(String key, int value) async {
    if (_uid == null) return 0;
    final animeRef = _animeDoc(key);
    final voteRef = animeRef.collection('votes').doc(_uid);
    int applied = value;
    await _db.runTransaction((tx) async {
      final voteSnap = await tx.get(voteRef);
      final prev = (voteSnap.data()?['value'] ?? 0) as int;
      if (prev == value) applied = 0;

      int likeDelta = 0;
      int dislikeDelta = 0;
      if (prev == 1) likeDelta -= 1;
      if (prev == -1) dislikeDelta -= 1;
      if (applied == 1) likeDelta += 1;
      if (applied == -1) dislikeDelta += 1;

      tx.set(
        animeRef,
        {'likes': FieldValue.increment(likeDelta), 'dislikes': FieldValue.increment(dislikeDelta)},
        SetOptions(merge: true),
      );
      if (applied == 0) {
        tx.delete(voteRef);
      } else {
        tx.set(voteRef, {'value': applied});
      }
    });
    return applied;
  }

  Stream<List<SocialComment>> watchComments(String key) {
    return _animeDoc(key)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs.map(SocialComment.fromDoc).toList());
  }

  Future<void> addComment(String key, String text) async {
    if (_uid == null || text.trim().isEmpty) return;
    await _animeDoc(key).collection('comments').add({
      'uid': _uid,
      'nickname': await getNickname(),
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
