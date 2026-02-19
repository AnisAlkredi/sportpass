import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AdminState extends Equatable {
  const AdminState();
  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminLoaded extends AdminState {
  final List<Map<String, dynamic>> topupRequests;
  final List<Map<String, dynamic>> qrRegenRequests;
  final List<Map<String, dynamic>> gymOwnerRequests;
  final List<Map<String, dynamic>> partners;
  final List<Map<String, dynamic>> users;
  final Map<String, dynamic> stats;
  const AdminLoaded(
      {this.topupRequests = const [],
      this.qrRegenRequests = const [],
      this.gymOwnerRequests = const [],
      this.partners = const [],
      this.users = const [],
      this.stats = const {}});
  @override
  List<Object?> get props => [
        topupRequests,
        qrRegenRequests,
        gymOwnerRequests,
        partners,
        users,
        stats
      ];
}

class AdminError extends AdminState {
  final String message;
  const AdminError(this.message);
}

class AdminCubit extends Cubit<AdminState> {
  AdminCubit() : super(AdminInitial());

  final _sb = Supabase.instance.client;

  Future<void> loadAdminData() async {
    emit(AdminLoading());
    try {
      final topupRequests = await _sb
          .from('topup_requests')
          .select('*, profiles!topup_requests_user_id_fkey(name, phone)')
          .order('created_at', ascending: false)
          .limit(50);
      final qrRegenRequests = await _sb
          .from('qr_token_regeneration_requests')
          .select(
              '*, partner_locations(name), requester:profiles!qr_token_regeneration_requests_requested_by_fkey(name, phone)')
          .order('created_at', ascending: false)
          .limit(50);
      List<dynamic> gymOwnerRequests = [];
      try {
        gymOwnerRequests = await _sb
            .from('gym_owner_requests')
            .select(
                '*, requester:profiles!gym_owner_requests_user_id_fkey(user_id,name,phone,role)')
            .order('created_at', ascending: false)
            .limit(50);
      } catch (_) {
        gymOwnerRequests = [];
      }
      final partners = await _sb
          .from('partners')
          .select(
            '*, owner:profiles!partners_owner_id_fkey(user_id,name,phone,role), partner_locations(*)',
          )
          .order('name');
      final users = await _sb
          .from('profiles')
          .select('*, wallets(balance)')
          .order('created_at', ascending: false)
          .limit(50);

      // Stats
      final totalUsers = (await _sb.from('profiles').select('user_id')).length;
      final pendingTopups = (await _sb
              .from('topup_requests')
              .select('id')
              .eq('status', 'pending'))
          .length;
      final pendingPartners = (await _sb
              .from('partners')
              .select('id')
              .or('is_active.eq.false,is_active.is.null'))
          .length;
      final pendingLocations = (await _sb
              .from('partner_locations')
              .select('id')
              .or('is_active.eq.false,is_active.is.null'))
          .length;
      final pendingQrRequests = (await _sb
              .from('qr_token_regeneration_requests')
              .select('id')
              .eq('status', 'pending'))
          .length;
      int pendingOwnerRequests = 0;
      try {
        pendingOwnerRequests = (await _sb
                .from('gym_owner_requests')
                .select('id')
                .eq('status', 'pending'))
            .length;
      } catch (_) {
        pendingOwnerRequests = 0;
      }

      emit(AdminLoaded(
        topupRequests: List<Map<String, dynamic>>.from(topupRequests),
        qrRegenRequests: List<Map<String, dynamic>>.from(qrRegenRequests),
        gymOwnerRequests: List<Map<String, dynamic>>.from(gymOwnerRequests),
        partners: List<Map<String, dynamic>>.from(partners),
        users: List<Map<String, dynamic>>.from(users),
        stats: {
          'totalUsers': totalUsers,
          'pendingRequests': pendingTopups +
              pendingPartners +
              pendingLocations +
              pendingQrRequests +
              pendingOwnerRequests,
          'partnersCount': (partners as List).length,
        },
      ));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> approvePayment(
      String requestId, String userId, double amount) async {
    try {
      // Use the new approve_topup RPC (handles everything atomically)
      await _sb.rpc('approve_topup', params: {
        'p_request_id': requestId,
      });

      await loadAdminData();
    } catch (e) {
      emit(AdminError('خطأ في الموافقة: $e'));
    }
  }

  Future<void> rejectPayment(String requestId, String reason) async {
    try {
      // Use the new reject_topup RPC
      await _sb.rpc('reject_topup', params: {
        'p_request_id': requestId,
        'p_admin_notes': reason,
      });
      await loadAdminData();
    } catch (e) {
      emit(AdminError('خطأ في الرفض: $e'));
    }
  }

  Future<void> reviewQrRegeneration(
    String requestId, {
    required bool approve,
    String? adminNotes,
  }) async {
    try {
      await _sb.rpc('review_qr_token_regeneration', params: {
        'p_request_id': requestId,
        'p_approve': approve,
        'p_admin_notes': adminNotes,
      });
      await loadAdminData();
    } catch (e) {
      emit(AdminError('خطأ في مراجعة طلب QR: $e'));
    }
  }

  Future<void> reviewGymOwnerRequest(
    String requestId, {
    required bool approve,
    String? adminNotes,
  }) async {
    try {
      await _sb.rpc('review_gym_owner_request', params: {
        'p_request_id': requestId,
        'p_approve': approve,
        'p_admin_notes': adminNotes,
      });
      await loadAdminData();
    } catch (e) {
      emit(AdminError('خطأ في مراجعة طلب صاحب النادي: $e'));
    }
  }

  Future<void> addPartner(
      String name, String category, String? description) async {
    try {
      await _sb.from('partners').insert({
        'name': name,
        'category': category,
        'description': description ?? '',
        'is_active': true,
      });
      await loadAdminData();
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> addLocation(String partnerId, String name, String? address,
      double lat, double lng, double basePrice, int radiusMeters) async {
    try {
      await _sb.from('partner_locations').insert({
        'partner_id': partnerId,
        'name': name,
        'address_text': address ?? '',
        'lat': lat,
        'lng': lng,
        'base_price': basePrice, // Gym's 80% share
        'radius_m': radiusMeters,
        'is_active': true,
      });
      await loadAdminData();
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> togglePartnerStatus(String partnerId, bool isActive) async {
    try {
      try {
        await _sb.rpc('set_partner_active', params: {
          'p_partner_id': partnerId,
          'p_is_active': isActive,
        });
      } on PostgrestException catch (e) {
        // Fallback for environments where RPC patch is not applied yet.
        if (e.message.contains('Could not find the function')) {
          await _sb
              .from('partners')
              .update({'is_active': isActive}).eq('id', partnerId);
        } else {
          rethrow;
        }
      }
      await loadAdminData();
    } catch (e) {
      emit(AdminError('خطأ في تعديل حالة الشريك: $e'));
    }
  }

  Future<void> toggleLocationStatus(String locationId, bool isActive) async {
    try {
      try {
        await _sb.rpc('set_location_active', params: {
          'p_location_id': locationId,
          'p_is_active': isActive,
        });
      } on PostgrestException catch (e) {
        // Fallback for environments where RPC patch is not applied yet.
        if (e.message.contains('Could not find the function')) {
          await _sb
              .from('partner_locations')
              .update({'is_active': isActive}).eq('id', locationId);
        } else {
          rethrow;
        }
      }
      await loadAdminData(); // Reload to refresh the list
    } catch (e) {
      emit(AdminError('خطأ في تعديل حالة الفرع: $e'));
    }
  }

  Future<void> updateLocationPrice(
      String locationId, double newBasePrice) async {
    try {
      await _sb
          .from('partner_locations')
          .update({'base_price': newBasePrice}).eq('id', locationId);
      await loadAdminData();
    } catch (e) {
      emit(AdminError('خطأ في تعديل السعر: $e'));
    }
  }

  Future<void> assignGymOwnerByPhone({
    required String partnerId,
    required String phone,
  }) async {
    try {
      final normalized = phone.trim();
      if (normalized.isEmpty) {
        throw Exception('رقم الهاتف مطلوب');
      }

      final profile = await _sb
          .from('profiles')
          .select('user_id')
          .eq('phone', normalized)
          .maybeSingle();

      if (profile == null) {
        throw Exception('لا يوجد مستخدم بهذا الرقم');
      }

      await _sb.rpc('assign_gym_owner', params: {
        'p_user_id': profile['user_id'],
        'p_partner_id': partnerId,
      });

      await loadAdminData();
    } catch (e) {
      emit(AdminError('خطأ في تعيين المالك: $e'));
    }
  }
}
