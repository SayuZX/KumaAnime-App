import '../models/user_role.dart';

class PermissionService {
  bool canWatch(UserRole role) => true; 
  bool canBookmark(UserRole role) => true; 
  
  bool canUpload(UserRole role) => role.hasAtLeast(UserRole.contributor);
  bool canReport(UserRole role) => role.hasAtLeast(UserRole.contributor);
  
  bool canModerate(UserRole role) => role.hasAtLeast(UserRole.moderator);
  bool canAdmin(UserRole role) => role.hasAtLeast(UserRole.developer);
}
