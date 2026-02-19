import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/partners_repository.dart';
import '../domain/models/partner.dart';

class PartnersRepositoryImpl implements PartnersRepository {
  final SupabaseClient _sb;
  PartnersRepositoryImpl(this._sb);

  @override
  Future<List<Partner>> getPartners() async {
    try {
      final r = await _sb
          .from('partners')
          .select('*, partner_locations(*)')
          .eq('is_active', true)
          .order('name');
      return (r as List).map((j) => Partner.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Partner?> getPartnerById(String id) async {
    try {
      final r = await _sb
          .from('partners')
          .select('*, partner_locations(*)')
          .eq('id', id)
          .single();
      return Partner.fromJson(r);
    } catch (_) {
      return null;
    }
  }
}
