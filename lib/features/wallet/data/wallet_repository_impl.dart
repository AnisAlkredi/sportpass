import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/wallet_repository.dart';
import '../domain/models/wallet.dart';

class WalletRepositoryImpl implements WalletRepository {
  final SupabaseClient _sb;
  WalletRepositoryImpl(this._sb);

  @override
  Future<Wallet?> getWallet() async {
    try {
      final uid = _sb.auth.currentUser?.id;
      if (uid == null) return null;
      // Get wallet. If not exists, create one with 0 balance.
      final r =
          await _sb.from('wallets').select().eq('user_id', uid).maybeSingle();
      if (r == null) {
        // Attempt to create if missing (though trigger should handle this usually)
        return const Wallet(userId: '', balance: 0);
      }
      return Wallet.fromJson(r);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<WalletTransaction>> getTransactions({int limit = 20}) async {
    try {
      final uid = _sb.auth.currentUser?.id;
      if (uid == null) return [];
      final r = await _sb
          .from('wallet_ledger')
          .select()
          .eq('wallet_type', 'user')
          .eq('wallet_owner_id', uid)
          .order('created_at', ascending: false)
          .limit(limit);
      return (r as List).map((j) => WalletTransaction.fromJson(j)).toList();
    } catch (e) {
      // print('Error fetching transactions: $e');
      return [];
    }
  }

  @override
  Future<bool> requestTopup(double amount,
      {String? proofUrl, String? notes}) async {
    try {
      final uid = _sb.auth.currentUser?.id;
      if (uid == null) return false;
      await _sb.from('topup_requests').insert({
        'user_id': uid,
        'amount': amount,
        'proof_url': proofUrl, // Fixed: was 'proof_image', now matches schema
        'notes':
            notes, // Fixed: was 'admin_notes', now matches user-submitted notes field
        // status defaults to 'pending' on server
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
