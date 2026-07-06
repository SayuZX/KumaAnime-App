import '../models/user_badge.dart';
import '../repositories/user_repository.dart';

class BadgeService {
  final UserRepository _userRepository;

  BadgeService(this._userRepository);

  Future<List<UserBadge>> getBadges(String uid) async {
    final user = await _userRepository.getUser(uid);
    return user?.badges ?? [];
  }

  Stream<List<UserBadge>> watchBadges(String uid) {
    return _userRepository.watchUser(uid).map((user) => user?.badges ?? []);
  }
}
