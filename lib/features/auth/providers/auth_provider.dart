import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _repository = AuthRepository();
  bool _isLoading = false;
  User? _user;

  AuthProvider() {
    _user = _repository.currentUser;
    _listenToAuthChanges();
  }

  bool get isLoading => _isLoading;
  User? get user => _user;

  void _listenToAuthChanges() {
    _repository.authStateChanges.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      _user = session?.user;
      notifyListeners();
    });
  }

  Future<void> signUp(String email, String password, String username) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.signUp(email: email, password: password, username: username);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _repository.signIn(email: email, password: password);
      _user = response.user;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _user = null;
    notifyListeners();
  }
}
