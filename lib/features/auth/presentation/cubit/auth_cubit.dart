import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/auth_repository.dart';
import '../../domain/models/user_profile.dart';

// States
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpSent extends AuthState {
  final String phone;
  const AuthOtpSent(this.phone);
  @override
  List<Object?> get props => [phone];
}

class AuthAuthenticated extends AuthState {
  final UserProfile user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthRoleSelectionRequired extends AuthState {
  final UserProfile user;
  const AuthRoleSelectionRequired(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthUnauthenticated extends AuthState {}

// Cubit
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repo;
  AuthCubit(this._repo) : super(AuthInitial());

  Future<void> checkAuth() async {
    if (_repo.isLoggedIn) {
      final user = await _repo.getCurrentUser();
      if (user != null) {
        _emitPostAuth(user);
        return;
      }
    }
    emit(AuthUnauthenticated());
  }

  Future<void> sendOtp(String phone) async {
    emit(AuthLoading());
    try {
      await _repo.sendOtp(phone);
      emit(AuthOtpSent(phone));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> loginWithPassword(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await _repo.loginWithPassword(email, password);
      if (user != null) {
        _emitPostAuth(user);
      } else {
        emit(const AuthError('فشل تسجيل الدخول. تأكد من صحة البيانات.'));
      }
    } catch (e) {
      emit(AuthError('فشل تسجيل الدخول: ${e.toString()}'));
    }
  }

  Future<void> signUpWithPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    emit(AuthLoading());
    try {
      final user = await _repo.signUpWithPassword(
        email: email,
        password: password,
        name: name,
      );
      if (user != null) {
        _emitPostAuth(user);
      } else {
        emit(const AuthError('تعذر إنشاء الحساب.'));
      }
    } catch (e) {
      emit(AuthError('تعذر إنشاء الحساب: ${e.toString()}'));
    }
  }

  Future<void> verifyOtp(String phone, String otp) async {
    emit(AuthLoading());
    try {
      final user = await _repo.verifyOtp(phone, otp);
      if (user != null) {
        _emitPostAuth(user);
      } else {
        emit(const AuthError('فشل التحقق'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> submitRoleSelection({
    required String name,
    required String selectedRole,
    Map<String, dynamic>? gymOwnerDetails,
  }) async {
    emit(AuthLoading());
    try {
      final ok = await _repo.submitRoleSelection(
        name: name,
        selectedRole: selectedRole,
        gymOwnerDetails: gymOwnerDetails,
      );
      if (!ok) {
        emit(const AuthError('تعذر حفظ الدور.'));
        return;
      }
      final user = await _repo.getCurrentUser();
      if (user == null) {
        emit(const AuthError('تعذر تحديث الملف.'));
        return;
      }
      _emitPostAuth(user);
    } catch (e) {
      emit(AuthError('تعذر حفظ الدور: ${e.toString()}'));
    }
  }

  Future<void> refreshProfile() async {
    final user = await _repo.getCurrentUser();
    if (user != null) _emitPostAuth(user);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _repo.sendPasswordResetEmail(email);
  }

  Future<void> signOut() async {
    await _repo.signOut();
    emit(AuthUnauthenticated());
  }

  void _emitPostAuth(UserProfile user) {
    if (user.needsRoleSelection) {
      emit(AuthRoleSelectionRequired(user));
      return;
    }
    emit(AuthAuthenticated(user));
  }
}
