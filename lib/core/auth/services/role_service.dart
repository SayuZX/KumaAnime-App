import '../models/user_role.dart';
import '../repositories/user_repository.dart';

class RoleService {
  final UserRepository _userRepository;

  RoleService(this._userRepository);

  Future<UserRole> getRole(String uid) async {
    final user = await _userRepository.getUser(uid);
    return user?.role ?? UserRole.guest;
  }

  Stream<UserRole> watchRole(String uid) {
    return _userRepository.watchUser(uid).map((user) => user?.role ?? UserRole.guest);
  }
}
