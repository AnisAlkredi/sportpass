import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/checkin_repository.dart';

class CheckinRepositoryImpl implements CheckinRepository {
  final SupabaseClient _sb;
  CheckinRepositoryImpl(this._sb);

  @override
  Future<Map<String, dynamic>> performCheckin(
    String qrToken,
    double lat,
    double lng,
  ) async {
    try {
      final date = DateTime.now().toIso8601String().split('T')[0];
      final nonce = DateTime.now().millisecondsSinceEpoch;
      final userId = _sb.auth.currentUser?.id;
      final deviceHash = 'DEVICE-$nonce';
      final idempotencyKey = 'checkin:$userId:${qrToken.trim()}:$date:$nonce';

      final rpcResult = await _sb.rpc(
        'perform_checkin',
        params: {
          'p_qr_token': qrToken.trim(),
          'p_lat': lat,
          'p_lng': lng,
          'p_device_hash': deviceHash,
          'p_idempotency_key': idempotencyKey,
        },
      );

      final result = Map<String, dynamic>.from(rpcResult as Map);
      if (result['success'] != true) {
        return result;
      }

      final checkinId = result['checkin_id']?.toString();
      if (checkinId == null || checkinId.isEmpty) {
        return result;
      }

      final merged = <String, dynamic>{...result};

      try {
        // Fetch snapshot fields for a complete receipt (base/platform/final).
        final snapshot = await _sb
            .from('checkins')
            .select(
              'id, base_price, platform_fee, final_price, created_at,'
              'partner_locations(name, partners(name))',
            )
            .eq('id', checkinId)
            .maybeSingle();

        if (snapshot != null) {
          merged['base_price'] = snapshot['base_price'];
          merged['platform_fee'] = snapshot['platform_fee'];
          merged['price_paid'] =
              snapshot['final_price'] ?? result['price_paid'];
          merged['created_at'] = snapshot['created_at'];

          final location = snapshot['partner_locations'];
          if (location is Map<String, dynamic>) {
            merged['location_name'] =
                location['name'] ?? result['location_name'];
            final partner = location['partners'];
            if (partner is Map<String, dynamic>) {
              merged['gym_name'] = partner['name'] ?? result['gym_name'];
            }
          }
        }
      } catch (_) {
        // Keep RPC result if detail expansion fails.
      }

      return merged;
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ غير متوقع: ${e.toString()}',
      };
    }
  }
}
