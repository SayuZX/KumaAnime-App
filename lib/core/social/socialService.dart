import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive/hive.dart';
import 'package:kumaanime/core/app/logging.dart';
import 'package:kumaanime/core/commons/enums/hiveEnums.dart';
import 'package:kumaanime/core/social/imageCompressor.dart';

class SocialComment {
  final String id;
  final String uid;
  final String nickname;
  final String avatar;
  final String text;
  final DateTime? createdAt;

  SocialComment({
    required this.id,
    required this.uid,
    required this.nickname,
    required this.avatar,
    required this.text,
    this.createdAt,
  });

  factory SocialComment.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return SocialComment(
      id: doc.id,
      uid: (data['uid'] ?? '').toString(),
      nickname: (data['nickname'] ?? 'Anon').toString(),
      avatar: (data['avatar'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class SocialService {
  SocialService._();

  static final SocialService instance = SocialService._();

  static const String _nicknameKey = 'socialNickname';
  static const String _avatarKey = 'socialAvatar';

  bool _ready = false;
  String? _uid;
  String _nickname = "";
  String _avatar = "";
  DateTime? _createdAt;
  int _episodesWatched = 0;
  Set<String> _grantedBadges = {};

  bool get isReady => _ready;
  String? get uid => _uid;
  String get nickname => _nickname.isNotEmpty ? _nickname : _defaultNickname();
  String get avatar => _avatar;
  DateTime? get accountCreatedAt => _createdAt;
  int get episodesWatched => _episodesWatched;
  Set<String> get grantedBadges => _grantedBadges;
  int get accountAgeDays => _createdAt == null ? 0 : DateTime.now().difference(_createdAt!).inDays;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String _defaultNickname() {
    final u = _uid ?? '0000';
    return "Otaku-${u.substring(0, u.length < 4 ? u.length : 4)}";
  }

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      final cred = await FirebaseAuth.instance.signInAnonymously();
      _uid = cred.user?.uid;
      _ready = _uid != null;
      if (_ready) await _loadProfile();
    } catch (err) {
      _ready = false;
      Logs.app.log("[SOCIAL] init failed: ${err.toString()}");
    }
  }

  Future<Box> _box() async {
    final name = HiveBox.kumaanime.boxName;
    return Hive.isBoxOpen(name) ? Hive.box(name) : await Hive.openBox(name);
  }

  Future<void> _loadProfile() async {
    try {
      final box = await _box();
      _nickname = (box.get(_nicknameKey) as String?) ?? "";
      _avatar = (box.get(_avatarKey) as String?) ?? "";
      final ref = _db.collection('social_users').doc(_uid);
      final snap = await ref.get();
      final data = snap.data();
      if (data != null) {
        final remoteName = (data['nickname'] ?? '').toString();
        final remoteAvatar = (data['avatar'] ?? '').toString();
        if (remoteName.isNotEmpty) _nickname = remoteName;
        if (remoteAvatar.isNotEmpty) _avatar = remoteAvatar;
        _episodesWatched = (data['episodesWatched'] ?? 0) as int;
        _createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final badges = data['badges'];
        if (badges is List) _grantedBadges = badges.map((e) => e.toString()).toSet();
        await box.put(_nicknameKey, _nickname);
        await box.put(_avatarKey, _avatar);
      }
      if (_createdAt == null) {
        _createdAt = FirebaseAuth.instance.currentUser?.metadata.creationTime ?? DateTime.now();
        await ref.set({'createdAt': Timestamp.fromDate(_createdAt!)}, SetOptions(merge: true));
      }
    } catch (err) {
      Logs.app.log("[SOCIAL] profile load failed: ${err.toString()}");
    }
  }

  Future<void> recordEpisodeWatched() async {
    if (_uid == null) return;
    _episodesWatched += 1;
    try {
      await _db.collection('social_users').doc(_uid).set(
        {'episodesWatched': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
    } catch (err) {
      Logs.app.log("[SOCIAL] record episode failed: ${err.toString()}");
    }
  }

  Future<void> saveProfile({required String nickname, required String avatar}) async {
    _nickname = nickname.trim();
    _avatar = avatar.trim();
    final box = await _box();
    await box.put(_nicknameKey, _nickname);
    await box.put(_avatarKey, _avatar);
    if (_uid == null) return;
    await _db.collection('social_users').doc(_uid).set({
      'nickname': _nickname,
      'avatar': _avatar,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String?> uploadAvatar(String path) async {
    if (_uid == null) return null;
    final base64Image = await ImageCompressor.compressToBase64(path);
    if (base64Image == null) return null;
    final avatar = "data:image/jpeg;base64,$base64Image";
    await saveProfile(nickname: nickname, avatar: avatar);
    return avatar;
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
      'nickname': nickname,
      'avatar': _avatar.startsWith('data:') ? '' : _avatar,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
