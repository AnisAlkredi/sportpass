import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final SupabaseClient _sb;
  HomeRepositoryImpl(this._sb);

  @override
  Future<int> getTodayCheckinCount(String userId) async {
    try {
      final today = DateTime.now();
      final start = DateTime(today.year, today.month, today.day);
      final r = await _sb
          .from('checkins')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'approved')
          .gte('ts', start.toIso8601String())
          .lt('ts', start.add(const Duration(days: 1)).toIso8601String());
      return (r as List).length;
    } catch (_) {
      return 0;
    }
  }
}
