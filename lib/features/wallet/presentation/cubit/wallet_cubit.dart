import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/wallet_repository.dart';
import '../../domain/models/wallet.dart';

// States
abstract class WalletState extends Equatable {
  const WalletState();
  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {}

class WalletLoading extends WalletState {}

class WalletLoaded extends WalletState {
  final Wallet wallet;
  final List<WalletTransaction> transactions;
  const WalletLoaded({required this.wallet, this.transactions = const []});
  @override
  List<Object?> get props => [wallet, transactions];
}

class WalletError extends WalletState {
  final String message;
  const WalletError(this.message);
  @override
  List<Object?> get props => [message];
}

class TopupSubmitted extends WalletState {
  final bool success;
  const TopupSubmitted(this.success);
}

// Cubit
class WalletCubit extends Cubit<WalletState> {
  final WalletRepository _repo;
  WalletCubit(this._repo) : super(WalletInitial());

  Future<void> loadWallet() async {
    emit(WalletLoading());
    try {
      final wallet = await _repo.getWallet();
      if (wallet == null) {
        emit(const WalletLoaded(wallet: Wallet(userId: '', balance: 0)));
        return;
      }
      final txs = await _repo.getTransactions();
      emit(WalletLoaded(wallet: wallet, transactions: txs));
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }

  Future<void> submitTopup(double amount,
      {String? proofUrl, String? notes}) async {
    try {
      final success =
          await _repo.requestTopup(amount, proofUrl: proofUrl, notes: notes);
      emit(TopupSubmitted(success));
      if (success) await loadWallet();
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }
}
