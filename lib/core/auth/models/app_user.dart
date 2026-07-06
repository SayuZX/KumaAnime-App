import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_badge.dart';
import 'user_role.dart';

class AppUser {
  final String uid;
  final bool anonymous;
  final String nickname;
  final String? avatar;
  final String? email;
  final String? provider;
  final UserRole role;
  final List<UserBadge> badges;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppUser({
    required this.uid,
    required this.anonymous,
    required this.nickname,
    this.avatar,
    this.email,
    this.provider,
    required this.role,
    required this.badges,
    required this.createdAt,
    required this.updatedAt,
  });

  AppUser copyWith({
    String? uid,
    bool? anonymous,
    String? nickname,
    String? avatar,
    String? email,
    String? provider,
    UserRole? role,
    List<UserBadge>? badges,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      anonymous: anonymous ?? this.anonymous,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      email: email ?? this.email,
      provider: provider ?? this.provider,
      role: role ?? this.role,
      badges: badges ?? this.badges,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppUser(
      uid: doc.id,
      anonymous: data['anonymous'] as bool? ?? true,
      nickname: data['nickname'] as String? ?? 'Otaku',
      avatar: data['avatar'] as String?,
      email: data['email'] as String?,
      provider: data['provider'] as String?,
      role: UserRole.fromString(data['role'] as String?),
      badges: UserBadge.fromList(data['badges'] as List<dynamic>?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'anonymous': anonymous,
      'nickname': nickname,
      if (avatar != null) 'avatar': avatar,
      if (email != null) 'email': email,
      if (provider != null) 'provider': provider,
      // role and badges are generally not written by the client after creation
      // but included for initial creation payload
      'role': role.name.toLowerCase(),
      'badges': badges.map((b) => b.firestoreKey).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
