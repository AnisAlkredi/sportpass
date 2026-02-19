import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/utils.dart';
import '../cubit/activity_cubit.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});
  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  @override
  void initState() {
    super.initState();
    context.read<ActivityCubit>().loadActivity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: Text('سجل النشاط',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        backgroundColor: C.bg,
      ),
      body: BlocBuilder<ActivityCubit, ActivityState>(
        builder: (ctx, state) {
          if (state is ActivityLoading) {
            return const Center(
                child: CircularProgressIndicator(color: C.cyan));
          }
          if (state is ActivityLoaded) {
            if (state.checkins.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history,
                        size: 64, color: C.textMuted.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text('لا توجد سجلات بعد',
                        style: GoogleFonts.cairo(color: C.textMuted)),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.checkins.length,
              itemBuilder: (ctx, i) => _buildItem(state.checkins[i])
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: i * 50)),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> c) {
    final approved = c['status'] == 'approved';
    final locationName = (c['partner_locations'] as Map?)?['name'] ?? 'نادي';
    final ts = DateTime.tryParse(c['created_at'] ?? '') ?? DateTime.now();
    final amountCharged = (c['final_price'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (approved ? C.green : C.red).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(approved ? Icons.check : Icons.close,
                color: approved ? C.green : C.red, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locationName,
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w600,
                        color: C.textPrimary,
                        fontSize: 14)),
                Text(DateFormat('yyyy/MM/dd - HH:mm').format(ts),
                    style: GoogleFonts.cairo(color: C.textMuted, fontSize: 11)),
              ],
            ),
          ),
          if (approved && amountCharged > 0)
            Text('-${formatSYP(amountCharged)}',
                style: GoogleFonts.cairo(
                    color: C.red, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
