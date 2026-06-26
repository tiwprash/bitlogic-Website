import '../services/access_config.dart';
class UserModel {
  final String id;
  final String email;
  final bool isPremium;
  final UserRole role;
  UserModel({required this.id, required this.email, required this.isPremium, this.role = UserRole.premium});
}
