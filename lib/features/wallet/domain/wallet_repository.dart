import 'models/wallet.dart';

abstract class WalletRepository {
  Future<Wallet?> getWallet();
  Future<List<WalletTransaction>> getTransactions({int limit = 20});
  Future<bool> requestTopup(double amount, {String? proofUrl, String? notes});
}
