import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/utils.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/models/wallet.dart';
import '../cubit/wallet_cubit.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});
  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  String _txLabel(String type) {
    return switch (type) {
      'topup' => context.trd('شحن رصيد', 'Top up'),
      'checkin_debit' => context.trd('دخول نادي', 'Gym entry'),
      'checkin_credit_gym' => context.trd('عائد من زيارة', 'Visit revenue'),
      'checkin_credit_platform' => context.trd('عمولة المنصة', 'Platform fee'),
      'refund' => context.trd('استرداد', 'Refund'),
      'refund_debit_gym' => context.trd('استرداد (خصم)', 'Refund (debit)'),
      'refund_debit_platform' => context.trd('استرداد (خصم)', 'Refund (debit)'),
      'adjustment' => context.trd('تعديل إداري', 'Admin adjustment'),
      'settlement' => context.trd('تسوية مالية', 'Settlement'),
      'bonus' => context.trd('مكافأة', 'Bonus'),
      _ => type,
    };
  }

  @override
  void initState() {
    super.initState();
    context.read<WalletCubit>().loadWallet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: Text(context.trd('المحفظة', 'Wallet'),
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700, color: C.textPrimary)),
        backgroundColor: C.bg,
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocBuilder<WalletCubit, WalletState>(
        builder: (ctx, state) {
          if (state is WalletLoading) {
            return const Center(
                child: CircularProgressIndicator(color: C.cyan));
          }
          if (state is WalletLoaded) {
            final authState = context.read<AuthCubit>().state;
            final canTopup = authState is AuthAuthenticated &&
                authState.user.role == 'athlete';
            return RefreshIndicator(
              color: C.cyan,
              onRefresh: () => context.read<WalletCubit>().loadWallet(),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildMainWalletCard(state.wallet)
                      .animate()
                      .fadeIn()
                      .slideY(begin: 0.05),
                  const SizedBox(height: 24),
                  if (canTopup) ...[
                    _buildTopupButton().animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 32),
                  ],
                  Text(context.trd('سجل العمليات', 'Transactions'),
                      style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: C.textPrimary)),
                  const SizedBox(height: 16),
                  if (state.transactions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long,
                                size: 64,
                                color: C.textMuted.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            Text(
                                context.trd('لا توجد عمليات بعد',
                                    'No transactions yet'),
                                style: GoogleFonts.cairo(color: C.textMuted)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...state.transactions.asMap().entries.map(
                          (e) => _buildTransactionTile(e.value)
                              .animate()
                              .fadeIn(
                                  delay:
                                      Duration(milliseconds: 100 + e.key * 50)),
                        ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMainWalletCard(Wallet wallet) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: C.walletGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: C.cyan.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.trd('الرصيد الحالي', 'Current balance'),
                  style:
                      GoogleFonts.cairo(color: Colors.white70, fontSize: 14)),
              const Icon(Icons.account_balance_wallet,
                  color: Colors.white, size: 22),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCurrency(context, wallet.balance, includeCurrency: false),
                style: GoogleFonts.cairo(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.0),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(currencyLabel(context),
                    style: GoogleFonts.cairo(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  context.trd(
                    'يتم خصم الرصيد عند الدخول فقط',
                    'Balance is deducted only after successful check-in',
                  ),
                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopupButton() {
    return ElevatedButton(
      onPressed: () => context.push(AppRouter.topup),
      style: ElevatedButton.styleFrom(
        backgroundColor: C.surface,
        foregroundColor: C.cyan,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: C.cyan.withValues(alpha: 0.3))),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_circle_outline),
          const SizedBox(width: 8),
          Text(context.trd('شحن رصيد', 'Top up wallet'),
              style:
                  GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(WalletTransaction tx) {
    final isCredit = tx.isCredit; // > 0
    // If topup -> Green (+), Checkin -> Red (-)
    final color = isCredit ? C.green : C.red;
    final icon = switch (tx.type) {
      'topup' => Icons.add_card,
      'checkin' => Icons.fitness_center,
      'refund' => Icons.undo,
      'bonus' => Icons.redeem,
      _ => Icons.compare_arrows,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_txLabel(tx.type),
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: C.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  DateFormat(
                    'yyyy/MM/dd HH:mm',
                    AppLocalizations.of(context).isEnglish ? 'en' : 'ar',
                  ).format(tx.createdAt),
                  style: GoogleFonts.cairo(color: C.textMuted, fontSize: 12),
                ),
                if (tx.description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(tx.description!,
                        style: GoogleFonts.cairo(
                            color: C.textSecondary, fontSize: 11)),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : ''}${formatCurrency(context, tx.amount.abs(), includeCurrency: false)}',
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w800, fontSize: 16, color: color),
              ),
              Text(currencyLabel(context),
                  style: GoogleFonts.cairo(color: C.textMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
