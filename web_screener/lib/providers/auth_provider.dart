import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel _user = UserModel(id: 'mock_user', email: 'mock@example.com', isPremium: true);
  UserModel get user => _user;
  bool get isAuthenticated => true;

  Future<void> login(String email, String password) async {}
  Future<void> logout() async {}
}
