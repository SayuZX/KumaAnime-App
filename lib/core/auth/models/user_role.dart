enum UserRole {
  guest(0),
  contributor(1),
  moderator(2),
  developer(3),
  owner(4);

  final int level;
  const UserRole(this.level);

  bool hasAtLeast(UserRole requiredRole) => level >= requiredRole.level;

  static UserRole fromString(String? roleStr) {
    if (roleStr == null) return UserRole.guest;
    return UserRole.values.firstWhere(
      (e) => e.name.toLowerCase() == roleStr.toLowerCase(),
      orElse: () => UserRole.guest,
    );
  }
}
