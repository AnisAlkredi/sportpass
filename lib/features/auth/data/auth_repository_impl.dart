import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_repository.dart';
import '../domain/models/user_profile.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _sb;
  final _ctrl = StreamController<bool>.broadcast();

  AuthRepositoryImpl(this._sb) {
    _sb.auth.onAuthStateChange.listen((d) => _ctrl.add(d.session != null));
  }

  @override
  Future<void> sendOtp(String phone) async {
    await _sb.auth.signInWithOtp(phone: phone);
  }

  @override
  Future<UserProfile?> verifyOtp(String phone, String otp) async {
    final r =
        await _sb.auth.verifyOTP(phone: phone, token: otp, type: OtpType.sms);
    return r.user != null ? getCurrentUser() : null;
  }

  @override
  Future<UserProfile?> loginWithPassword(String email, String password) async {
    final cleanEmail = _normalizeEmail(email);
    if (cleanEmail == null || password.trim().isEmpty) {
      throw Exception('البيانات غير مكتملة');
    }

    final r = await _sb.auth
        .signInWithPassword(email: cleanEmail, password: password);
    return r.user != null ? getCurrentUser() : null;
  }

  @override
  Future<UserProfile?> signUpWithPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    final cleanEmail = _normalizeEmail(email);
    if (cleanEmail == null ||
        password.trim().length < 6 ||
        name.trim().length < 2) {
      throw Exception('تحقق من الاسم والبريد الإلكتروني وكلمة المرور');
    }

    final signup = await _sb.auth.signUp(
      email: cleanEmail,
      password: password,
      data: {
        'name': name.trim(),
      },
    );

    if (signup.user == null && signup.session == null) {
      return null;
    }

    if (signup.session == null) {
      try {
        await _sb.auth
            .signInWithPassword(email: cleanEmail, password: password);
      } on AuthException catch (e) {
        if (e.message.toLowerCase().contains('email not confirmed')) {
          throw Exception(
            'تم إنشاء الحساب. فعّل البريد الإلكتروني أولاً ثم سجّل الدخول.',
          );
        }
        rethrow;
      }
    }

    return getCurrentUser();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = _normalizeEmail(email);
    if (cleanEmail == null) {
      throw Exception('أدخل بريد إلكتروني صالح');
    }
    await _sb.auth.resetPasswordForEmail(cleanEmail);
  }

  @override
  Future<bool> submitRoleSelection({
    required String name,
    required String selectedRole,
    Map<String, dynamic>? gymOwnerDetails,
  }) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) {
      return false;
    }

    try {
      final res = await _sb.rpc('submit_role_selection', params: {
        'p_name': name.trim(),
        'p_selected_role': selectedRole,
      });
      if (selectedRole == 'gym_owner') {
        await _saveGymOwnerDetails(uid, gymOwnerDetails);
      }
      if (res is Map) {
        return res['success'] == true;
      }
      return false;
    } on PostgrestException catch (e) {
      // Backward-compatible fallback if patch is not applied yet.
      if (!e.message.contains('Could not find the function')) {
        rethrow;
      }
      final normalizedRole =
          selectedRole == 'gym_owner' ? 'gym_owner_pending' : 'athlete';
      await _sb.from('profiles').update({
        'name': name.trim(),
        'role': normalizedRole,
        'metadata': {'role_selected': true},
      }).eq('user_id', uid);
      if (selectedRole == 'gym_owner') {
        await _saveGymOwnerDetails(uid, gymOwnerDetails);
      }
      return true;
    }
  }

  @override
  Future<void> signOut() => _sb.auth.signOut();

  @override
  Future<UserProfile?> getCurrentUser() async {
    final u = _sb.auth.currentUser;
    if (u == null) {
      return null;
    }

    final data =
        await _sb.from('profiles').select().eq('user_id', u.id).maybeSingle();

    if (data != null) {
      return UserProfile.fromJson(data);
    }

    // Fallback: profile trigger should normally create this row.
    await _sb.from('profiles').insert({
      'user_id': u.id,
      'phone': u.phone,
      'name': u.userMetadata?['name'] ?? 'مستخدم جديد',
      'status': 'active',
      'role': 'athlete',
      'metadata': {'role_selected': false},
    });

    final retry =
        await _sb.from('profiles').select().eq('user_id', u.id).maybeSingle();
    if (retry != null) {
      return UserProfile.fromJson(retry);
    }

    return null;
  }

  @override
  bool get isLoggedIn => _sb.auth.currentUser != null;

  @override
  Stream<bool> get authStateChanges => _ctrl.stream;

  Future<void> _saveGymOwnerDetails(
    String uid,
    Map<String, dynamic>? details,
  ) async {
    final normalized = _normalizeGymOwnerDetails(details);
    try {
      await _sb.rpc('upsert_gym_owner_request_details', params: {
        'p_gym_name': normalized['gym_name'],
        'p_gym_city': normalized['gym_city'],
        'p_gym_address': normalized['gym_address'],
        'p_branches_count': normalized['branches_count'],
        'p_gym_category': normalized['gym_category'],
        'p_business_description': normalized['business_description'],
      });
    } on PostgrestException catch (e) {
      if (!e.message.contains('Could not find the function')) {
        rethrow;
      }
      try {
        await _sb.from('gym_owner_requests').upsert({
          'user_id': uid,
          'status': 'pending',
          ...normalized,
        }, onConflict: 'user_id');
      } on PostgrestException {
        final summary = [
          if (normalized['gym_name'] != null) 'gym:${normalized['gym_name']}',
          if (normalized['gym_city'] != null) 'city:${normalized['gym_city']}',
          if (normalized['gym_address'] != null)
            'address:${normalized['gym_address']}',
          'branches:${normalized['branches_count']}',
        ].join(' | ');
        await _sb.from('gym_owner_requests').upsert({
          'user_id': uid,
          'status': 'pending',
          'notes': summary,
        }, onConflict: 'user_id');
      }
    }
  }

  Map<String, dynamic> _normalizeGymOwnerDetails(Map<String, dynamic>? raw) {
    final gymName = (raw?['gym_name'] as String?)?.trim();
    final gymCity = (raw?['gym_city'] as String?)?.trim();
    final gymAddress = (raw?['gym_address'] as String?)?.trim();
    final gymCategory = (raw?['gym_category'] as String?)?.trim();
    final businessDescription =
        (raw?['business_description'] as String?)?.trim();

    int branchesCount = 1;
    final rawBranches = raw?['branches_count'];
    if (rawBranches is int) {
      branchesCount = rawBranches;
    } else if (rawBranches is String) {
      branchesCount = int.tryParse(rawBranches) ?? 1;
    } else if (rawBranches is num) {
      branchesCount = rawBranches.toInt();
    }

    return {
      'gym_name': (gymName == null || gymName.isEmpty) ? null : gymName,
      'gym_city': (gymCity == null || gymCity.isEmpty) ? null : gymCity,
      'gym_address':
          (gymAddress == null || gymAddress.isEmpty) ? null : gymAddress,
      'branches_count': branchesCount < 1 ? 1 : branchesCount,
      'gym_category':
          (gymCategory == null || gymCategory.isEmpty) ? null : gymCategory,
      'business_description':
          (businessDescription == null || businessDescription.isEmpty)
              ? null
              : businessDescription,
    };
  }

  String? _normalizeEmail(String value) {
    final clean = value.trim().toLowerCase();
    if (clean.isEmpty) {
      return null;
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(clean)) {
      return null;
    }
    return clean;
  }
}
