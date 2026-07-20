import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  factory SocialComment.fromMap(Map<String, dynamic> data, String id) {
    return SocialComment(
      id: id,
      uid: (data['uid'] ?? '').toString(),
      nickname: (data['nickname'] ?? 'Anon').toString(),
      avatar: (data['avatar'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nickname': nickname,
      'avatar': avatar,
      'text': text,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class SocialService {
  SocialService._();

  static final SocialService instance = SocialService._();

  static const String _nicknameKey = 'socialNickname';
  static const String _avatarKey = 'socialAvatar';
  static const String _localUidKey = 'socialLocalUid';

  bool _ready = false;
  bool _useFirebase = false;
  String? _uid;
  String _nickname = "";
  String _avatar = "";
  DateTime? _createdAt;
  int _episodesWatched = 0;
  Set<String> _grantedBadges = {};

  final Map<String, StreamController<List<SocialComment>>> _commentControllers = {};
  final Map<String, StreamController<Map<String, int>>> _countsControllers = {};

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
    _ready = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _uid = user.uid;
        _useFirebase = true;
        await _migrateIfNecessary();
        await _loadProfile();
      } else {
        await _loadLocalProfile();
      }
    } catch (err) {
      _useFirebase = false;
      await _loadLocalProfile();
      Logs.app.log("[SOCIAL] Firebase unavailable, using local social mode: ${err.toString()}");
    }
  }

  Future<Box> _box() async {
    final name = HiveBox.kumaanime.boxName;
    return Hive.isBoxOpen(name) ? Hive.box(name) : await Hive.openBox(name);
  }

  Future<void> _loadLocalProfile() async {
    final box = await _box();
    var storedUid = box.get(_localUidKey) as String?;
    if (storedUid == null || storedUid.isEmpty) {
      storedUid = "local_${DateTime.now().millisecondsSinceEpoch}";
      await box.put(_localUidKey, storedUid);
    }
    _uid = storedUid;
    _nickname = (box.get(_nicknameKey) as String?) ?? "";
    _avatar = (box.get(_avatarKey) as String?) ?? "";
    _createdAt ??= DateTime.now();
  }

  Future<void> _migrateIfNecessary() async {
    if (_uid == null || !_useFirebase) return;
    try {
      final oldRef = _db.collection('social_users').doc(_uid);
      final newRef = _db.collection('users').doc(_uid);
      final oldSnap = await oldRef.get();
      final newSnap = await newRef.get();

      if (oldSnap.exists && !newSnap.exists) {
        final data = oldSnap.data()!;
        data['role'] = 'guest';
        await newRef.set(data, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  Future<void> _loadProfile() async {
    try {
      final box = await _box();
      _nickname = (box.get(_nicknameKey) as String?) ?? "";
      _avatar = (box.get(_avatarKey) as String?) ?? "";
      if (_useFirebase && _uid != null) {
        final ref = _db.collection('users').doc(_uid);
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
      }
    } catch (err) {
      Logs.app.log("[SOCIAL] profile load failed: ${err.toString()}");
      await _loadLocalProfile();
    }
  }

  Future<void> recordEpisodeWatched() async {
    _episodesWatched += 1;
    if (_useFirebase && _uid != null) {
      try {
        await _db.collection('users').doc(_uid).set(
          {'episodesWatched': FieldValue.increment(1)},
          SetOptions(merge: true),
        );
      } catch (err) {
        Logs.app.log("[SOCIAL] record episode failed: ${err.toString()}");
      }
    }
  }

  Future<void> saveProfile({required String nickname, required String avatar}) async {
    _nickname = nickname.trim();
    _avatar = avatar.trim();
    final box = await _box();
    await box.put(_nicknameKey, _nickname);
    await box.put(_avatarKey, _avatar);

    if (_useFirebase && _uid != null) {
      try {
        await _db.collection('users').doc(_uid).set({
          'nickname': _nickname,
          'avatar': _avatar,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  Future<String?> uploadAvatar(String path) async {
    final base64Image = await ImageCompressor.compressToBase64(path);
    if (base64Image == null) return null;
    final avatarStr = "data:image/jpeg;base64,$base64Image";
    await saveProfile(nickname: nickname, avatar: avatarStr);
    return avatarStr;
  }

  DocumentReference<Map<String, dynamic>> _animeDoc(String key) => _db.collection('anime_social').doc(key);

  Stream<Map<String, int>> watchCounts(String key) {
    if (_useFirebase) {
      try {
        return _animeDoc(key).snapshots().map((snap) {
          final data = snap.data() ?? {};
          return {
            'likes': (data['likes'] ?? 0) as int,
            'dislikes': (data['dislikes'] ?? 0) as int,
          };
        });
      } catch (_) {}
    }

    _countsControllers[key] ??= StreamController<Map<String, int>>.broadcast();
    Future.microtask(() async {
      final counts = await _getLocalCounts(key);
      if (!_countsControllers[key]!.isClosed) {
        _countsControllers[key]!.add(counts);
      }
    });
    return _countsControllers[key]!.stream;
  }

  Future<Map<String, int>> _getLocalCounts(String key) async {
    final box = await _box();
    final likes = (box.get("social_likes_$key") ?? 0) as int;
    final dislikes = (box.get("social_dislikes_$key") ?? 0) as int;
    return {'likes': likes, 'dislikes': dislikes};
  }

  Future<int> getMyVote(String key) async {
    if (_useFirebase && _uid != null) {
      try {
        final snap = await _animeDoc(key).collection('votes').doc(_uid).get();
        return (snap.data()?['value'] ?? 0) as int;
      } catch (_) {}
    }
    final box = await _box();
    return (box.get("social_my_vote_${key}_$_uid") ?? 0) as int;
  }

  Future<int> setVote(String key, int value) async {
    if (_useFirebase && _uid != null) {
      try {
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
      } catch (_) {}
    }

    final box = await _box();
    final prev = (box.get("social_my_vote_${key}_$_uid") ?? 0) as int;
    int applied = value;
    if (prev == value) applied = 0;

    int likes = (box.get("social_likes_$key") ?? 0) as int;
    int dislikes = (box.get("social_dislikes_$key") ?? 0) as int;

    if (prev == 1) likes = (likes - 1).clamp(0, 999999);
    if (prev == -1) dislikes = (dislikes - 1).clamp(0, 999999);
    if (applied == 1) likes += 1;
    if (applied == -1) dislikes += 1;

    await box.put("social_my_vote_${key}_$_uid", applied);
    await box.put("social_likes_$key", likes);
    await box.put("social_dislikes_$key", dislikes);

    if (_countsControllers.containsKey(key)) {
      _countsControllers[key]!.add({'likes': likes, 'dislikes': dislikes});
    }

    return applied;
  }

  Stream<List<SocialComment>> watchComments(String key) {
    if (_useFirebase) {
      try {
        return _animeDoc(key)
            .collection('comments')
            .orderBy('createdAt', descending: true)
            .limit(200)
            .snapshots()
            .map((snap) => snap.docs.map(SocialComment.fromDoc).toList());
      } catch (_) {}
    }

    _commentControllers[key] ??= StreamController<List<SocialComment>>.broadcast();
    Future.microtask(() async {
      final comments = await _getLocalComments(key);
      if (!_commentControllers[key]!.isClosed) {
        _commentControllers[key]!.add(comments);
      }
    });
    return _commentControllers[key]!.stream;
  }

  Future<List<SocialComment>> _getLocalComments(String key) async {
    final box = await _box();
    final rawList = box.get("social_comments_$key") as List?;
    if (rawList == null) return [];
    return rawList
        .map((e) => SocialComment.fromMap(Map<String, dynamic>.from(e as Map), (e['id'] ?? '').toString()))
        .toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
  }

  Future<void> addComment(String key, String text) async {
    if (text.trim().isEmpty) return;

    if (_useFirebase && _uid != null) {
      try {
        await _animeDoc(key).collection('comments').add({
          'uid': _uid,
          'nickname': nickname,
          'avatar': _avatar.startsWith('data:') ? '' : _avatar,
          'text': text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        return;
      } catch (_) {}
    }

    final box = await _box();
    final rawList = (box.get("social_comments_$key") as List?) ?? [];
    final newList = List<Map<String, dynamic>>.from(rawList.map((e) => Map<String, dynamic>.from(e as Map)));

    final newComment = SocialComment(
      id: "comment_${DateTime.now().millisecondsSinceEpoch}",
      uid: _uid ?? "local",
      nickname: nickname,
      avatar: _avatar.startsWith('data:') ? '' : _avatar,
      text: text.trim(),
      createdAt: DateTime.now(),
    );

    newList.add(newComment.toMap()..['id'] = newComment.id);
    await box.put("social_comments_$key", newList);

    if (_commentControllers.containsKey(key)) {
      final comments = newList
          .map((e) => SocialComment.fromMap(e, (e['id'] ?? '').toString()))
          .toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      _commentControllers[key]!.add(comments);
    }
  }
}
