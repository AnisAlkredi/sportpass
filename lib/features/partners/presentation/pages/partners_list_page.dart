import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/router/app_router.dart';

import '../../../../core/widgets/utils.dart';
import '../../domain/models/partner.dart';
import '../cubit/partners_cubit.dart';

class PartnersListPage extends StatefulWidget {
  const PartnersListPage({super.key});
  @override
  State<PartnersListPage> createState() => _PartnersListPageState();
}

class _PartnersListPageState extends State<PartnersListPage> {
  @override
  void initState() {
    super.initState();
    context.read<PartnersCubit>().loadPartners();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: Text(context.trd('المراكز الرياضية', 'Fitness centers'),
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        backgroundColor: C.bg,
      ),
      body: BlocBuilder<PartnersCubit, PartnersState>(
        builder: (ctx, state) {
          if (state is PartnersLoading) {
            return const Center(
                child: CircularProgressIndicator(color: C.cyan));
          }
          if (state is PartnersLoaded) {
            if (state.partners.isEmpty) {
              return Center(
                  child: Text(
                      context.trd('لا توجد مراكز متاحة حالياً',
                          'No centers available right now'),
                      style: GoogleFonts.cairo(color: C.textMuted)));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.partners.length,
              itemBuilder: (ctx, i) => _buildPartnerCard(state.partners[i])
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: i * 80))
                  .slideX(begin: 0.03),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPartnerCard(Partner partner) {
    final loc = partner.locations.firstOrNull;
    return GestureDetector(
      onTap: () => context
          .push(AppRouter.partnerDetails.replaceFirst(':id', partner.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: C.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(
                  colors: [C.navyLight, C.navy.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                      child: Text(partner.categoryIcon,
                          style: const TextStyle(fontSize: 52))),
                  if (loc != null && loc.isActive)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: C.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              context.trd('نشط', 'Active'),
                              style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(partner.name,
                      style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: C.textPrimary)),
                  if (partner.description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(partner.description!,
                          style: GoogleFonts.cairo(
                              color: C.textMuted, fontSize: 12),
                          maxLines: 2),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (loc != null) ...[
                        _tag(
                          Icons.location_on,
                          loc.addressText ?? context.trd('دمشق', 'Damascus'),
                          C.textMuted,
                        ),
                        const Spacer(),
                        _tag(
                          Icons.monetization_on,
                          formatCurrency(context, loc.userPrice),
                          C.gold,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(
                            AppRouter.partnerDetails
                                .replaceFirst(':id', partner.id),
                          ),
                          icon:
                              const Icon(Icons.info_outline_rounded, size: 18),
                          label: Text(
                            context.trd('التفاصيل', 'Details'),
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push(AppRouter.scanner),
                          icon: const Icon(Icons.qr_code_scanner_rounded,
                              size: 18),
                          label: Text(
                            context.trd('شيك إن', 'Check-in'),
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text,
            style: GoogleFonts.cairo(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
