import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  final String userId;
  final double balance;
  final String currency;

  const Wallet({
    required this.userId,
    this.balance = 0,
    this.currency = 'SYP',
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      userId: json['user_id'] as String,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'SYP',
    );
  }

  @override
  List<Object?> get props => [userId, balance, currency];
}

class WalletTransaction extends Equatable {
  final String id;
  final String walletType; // 'user', 'gym', 'platform'
  final String?
      walletOwnerId; // user_id for user wallets, partner_id for gym, null for platform
  final String type; // ledger_entry_type enum
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String? description;
  final String? referenceId;
  final String? referenceType; // 'checkin', 'topup', 'settlement', etc.
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.walletType,
    this.walletOwnerId,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.description,
    this.referenceId,
    this.referenceType,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String,
      walletType: json['wallet_type'] as String,
      walletOwnerId: json['wallet_owner_id'] as String?,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      balanceBefore: (json['balance_before'] as num).toDouble(),
      balanceAfter: (json['balance_after'] as num).toDouble(),
      description: json['description'] as String?,
      referenceId: json['reference_id'] as String?,
      referenceType: json['reference_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isCredit => amount > 0;
  bool get isDebit => amount < 0;

  String get typeLabel => switch (type) {
        'topup' => 'شحن رصيد',
        'checkin_debit' => 'دخول نادي',
        'checkin_credit_gym' => 'عائد من زيارة',
        'checkin_credit_platform' => 'عمولة المنصة',
        'refund' => 'استرداد',
        'refund_debit_gym' => 'استرداد (خصم)',
        'refund_debit_platform' => 'استرداد (خصم)',
        'adjustment' => 'تعديل إداري',
        'settlement' => 'تسوية مالية',
        'bonus' => 'مكافأة',
        _ => type,
      };

  @override
  List<Object?> get props =>
      [id, walletType, type, amount, balanceAfter, createdAt];
}
