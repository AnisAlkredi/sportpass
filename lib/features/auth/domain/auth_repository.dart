import 'models/user_profile.dart';

abstract class AuthRepository {
  Future<void> sendOtp(String phone);
  Future<UserProfile?> verifyOtp(String phone, String otp);
  Future<UserProfile?> loginWithPassword(String email, String password);
  Future<UserProfile?> signUpWithPassword({
    required String email,
    required String password,
    required String name,
  });
  Future<void> sendPasswordResetEmail(String email);
  Future<bool> submitRoleSelection({
    required String name,
    required String selectedRole, // athlete | gym_owner
    Map<String, dynamic>? gymOwnerDetails,
  });
  Future<void> signOut();
  Future<UserProfile?> getCurrentUser();
  bool get isLoggedIn;
  Stream<bool> get authStateChanges;
}
