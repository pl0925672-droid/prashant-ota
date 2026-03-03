import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    // 15 seconds ka timeout add kiya hai
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    ).timeout(const Duration(seconds: 15), onTimeout: () {
      throw 'Server response nahi de raha hai. Shayad maintenance chal rahi hai. Baad mein try karein!';
    });
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    ).timeout(const Duration(seconds: 15), onTimeout: () {
      throw 'Connection slow hai ya server down hai. Kripya thodi der baad koshish karein.';
    });
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
