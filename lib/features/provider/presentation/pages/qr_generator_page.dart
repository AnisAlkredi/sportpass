import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/colors.dart';

class QrGeneratorPage extends StatefulWidget {
  final String partnerId;
  const QrGeneratorPage({super.key, required this.partnerId});
  @override
  State<QrGeneratorPage> createState() => _QrGeneratorPageState();
}

class _QrGeneratorPageState extends State<QrGeneratorPage> {
  List<Map<String, dynamic>> _locations = [];
  final Map<String, String> _tokens = {};
  final Set<String> _pendingRequests = {};
  final Map<String, Map<String, dynamic>> _latestReviews = {};
  bool _loading = true;
  bool _isAdmin = false;
  String? _resolvedPartnerId;
  String? _busyLocationId;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final sb = Supabase.instance.client;
      final uid = sb.auth.currentUser?.id;
      if (uid != null) {
        final profile = await sb
            .from('profiles')
            .select('role')
            .eq('user_id', uid)
            .maybeSingle();
        _isAdmin = profile?['role'] == 'admin';
      } else {
        _isAdmin = false;
      }

      _resolvedPartnerId = widget.partnerId.trim();
      if (_resolvedPartnerId == null || _resolvedPartnerId!.isEmpty) {
        final partner = await sb
            .from('partners')
            .select('id')
            .eq('owner_id', uid ?? '')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        _resolvedPartnerId = partner?['id'] as String?;
      }

      if (_resolvedPartnerId == null || _resolvedPartnerId!.isEmpty) {
        setState(() {
          _locations = [];
          _loading = false;
        });
        return;
      }

      final locs = await sb
          .from('partner_locations')
          .select()
          .eq('partner_id', _resolvedPartnerId!)
          .order('created_at', ascending: false);

      _tokens.clear();
      for (final loc in locs) {
        final tokens = await sb
            .from('qr_tokens')
            .select()
            .eq('partner_location_id', loc['id'])
            .eq('is_active', true)
            .order('created_at', ascending: false)
            .limit(1);
        if (tokens.isNotEmpty) {
          _tokens[loc['id']] = tokens.first['token'];
        }
      }

      _pendingRequests.clear();
      _latestReviews.clear();
      if (!_isAdmin && locs.isNotEmpty) {
        try {
          final locationIds = locs
              .map((e) => e['id'])
              .whereType<String>()
              .toList(growable: false);
          if (locationIds.isNotEmpty) {
            final pendingReqs = await sb
                .from('qr_token_regeneration_requests')
                .select('partner_location_id')
                .inFilter('partner_location_id', locationIds)
                .eq('status', 'pending');
            for (final req in pendingReqs) {
              final id = req['partner_location_id'] as String?;
              if (id != null) {
                _pendingRequests.add(id);
              }
            }

            final reviewedReqs = await sb
                .from('qr_token_regeneration_requests')
                .select('partner_location_id,status,admin_notes,updated_at')
                .inFilter('partner_location_id', locationIds)
                .neq('status', 'pending')
                .order('updated_at', ascending: false);
            for (final req in reviewedReqs) {
              final id = req['partner_location_id'] as String?;
              if (id == null || _latestReviews.containsKey(id)) {
                continue;
              }
              _latestReviews[id] = Map<String, dynamic>.from(req);
            }
          }
        } catch (_) {
          // Keep compatibility if DB patch is not applied yet.
        }
      }

      setState(() {
        _locations = List<Map<String, dynamic>>.from(locs);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _generateToken(String locationId) async {
    try {
      final token = await Supabase.instance.client.rpc(
        'generate_qr_token',
        params: {'p_location_id': locationId},
      );

      setState(() {
        _tokens[locationId] = token.toString();
        _pendingRequests.remove(locationId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('تم إنشاء رمز QR جديد بموافقة المدير',
                  style: GoogleFonts.cairo()),
              backgroundColor: C.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('خطأ: $e', style: GoogleFonts.cairo()),
              backgroundColor: C.red),
        );
      }
    }
  }

  Future<void> _requestRegeneration(String locationId) async {
    try {
      setState(() => _busyLocationId = locationId);
      final res = await Supabase.instance.client.rpc(
        'request_qr_token_regeneration',
        params: {'p_location_id': locationId},
      );
      final success = res is Map && res['success'] == true;
      final message = res is Map && res['message'] != null
          ? res['message'].toString()
          : success
              ? 'تم إرسال طلب التجديد إلى المدير'
              : 'تعذر إرسال الطلب';

      if (success) {
        setState(() {
          _pendingRequests.add(locationId);
          _latestReviews.remove(locationId);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: GoogleFonts.cairo()),
            backgroundColor: success ? C.green : C.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('تعذر إرسال طلب التجديد: $e', style: GoogleFonts.cairo()),
            backgroundColor: C.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyLocationId = null);
      }
    }
  }

  Future<bool> _confirmQrAction({
    required bool isAdmin,
    required bool hasToken,
  }) async {
    final title = isAdmin
        ? (hasToken ? 'تأكيد إعادة إنشاء QR' : 'تأكيد إنشاء QR')
        : (hasToken ? 'تأكيد طلب تجديد QR' : 'تأكيد طلب إنشاء QR');
    final body = isAdmin
        ? 'سيتم تعطيل الرمز الحالي وإنشاء رمز فعال جديد لهذا الفرع.'
        : 'سيتم إرسال الطلب إلى مدير النظام للمراجعة قبل إصدار الرمز الجديد.';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.surface,
        title: Text(
          title,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w700,
            color: C.textPrimary,
          ),
        ),
        content: Text(
          body,
          style: GoogleFonts.cairo(color: C.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: C.cyan),
            child: Text('تأكيد',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<Uint8List> _buildQrPdf({
    required String token,
    required String locationName,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Center(
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                'SportPass QR',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Location: $locationName'),
              pw.SizedBox(height: 24),
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: token,
                width: 260,
                height: 260,
              ),
              pw.SizedBox(height: 16),
              pw.Text(token, style: const pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 24),
              pw.Text('Print and place this code at gym entrance.'),
            ],
          ),
        ),
      ),
    );

    return doc.save();
  }

  Future<void> _printQr({
    required String locationId,
    required String locationName,
    required String token,
  }) async {
    try {
      setState(() => _busyLocationId = locationId);
      final bytes = await _buildQrPdf(token: token, locationName: locationName);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر الطباعة: $e', style: GoogleFonts.cairo()),
            backgroundColor: C.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyLocationId = null);
      }
    }
  }

  Future<void> _exportQrPdf({
    required String locationId,
    required String locationName,
    required String token,
  }) async {
    try {
      setState(() => _busyLocationId = locationId);
      final bytes = await _buildQrPdf(token: token, locationName: locationName);
      final filename =
          'sportpass_qr_${locationName.replaceAll(RegExp(r"\\s+"), "_")}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر التصدير: $e', style: GoogleFonts.cairo()),
            backgroundColor: C.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyLocationId = null);
      }
    }
  }

  Future<void> _copyToken(String token) async {
    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ التوكن', style: GoogleFonts.cairo()),
        backgroundColor: C.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: Text('رموز QR',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        backgroundColor: C.bg,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: C.cyan))
          : _locations.isEmpty
              ? Center(
                  child: Text('لا توجد فروع مرتبطة بهذا النادي',
                      style: GoogleFonts.cairo(color: C.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _locations.length,
                  itemBuilder: (ctx, i) => _buildLocationQR(_locations[i])
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: i * 150)),
                ),
    );
  }

  Widget _buildLocationQR(Map<String, dynamic> loc) {
    final token = _tokens[loc['id']];
    final hasToken = token != null && token.isNotEmpty;
    final isActive = loc['is_active'] == true;
    final hasPendingRequest = _pendingRequests.contains(loc['id']);
    final review = _latestReviews[loc['id']];
    final reviewStatus = review?['status']?.toString();
    final reviewNotes = review?['admin_notes']?.toString().trim();
    final hasReview = reviewStatus != null &&
        (reviewStatus == 'approved' || reviewStatus == 'rejected');
    final isBusy = _busyLocationId == loc['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: C.border),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: C.cyanGradient,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc['name'] ?? '',
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      if (loc['address_text'] != null)
                        Text(loc['address_text'],
                            style: GoogleFonts.cairo(
                                color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? C.green.withValues(alpha: 0.2)
                        : C.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'نشط' : 'قيد المراجعة',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: hasToken
                ? Column(
                    children: [
                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: QrImageView(
                          data: token,
                          version: QrVersions.auto,
                          size: 200,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Token display
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: C.surfaceAlt,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                token,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                    color: C.cyan,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _copyToken(token),
                              child: const Icon(Icons.copy_rounded,
                                  size: 16, color: C.cyan),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('اطبع هذا الرمز وضعه عند مدخل النادي',
                          style: GoogleFonts.cairo(
                              color: C.textMuted, fontSize: 12)),
                      if (!_isAdmin && hasReview) ...[
                        const SizedBox(height: 10),
                        _buildReviewNotice(
                          status: reviewStatus,
                          notes: (reviewNotes == null || reviewNotes.isEmpty)
                              ? null
                              : reviewNotes,
                        ),
                      ],
                      if (!_isAdmin && hasPendingRequest) ...[
                        const SizedBox(height: 8),
                        Text(
                          'طلب التجديد قيد مراجعة مدير النظام',
                          style: GoogleFonts.cairo(
                            color: C.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Tooltip(
                              message: _isAdmin ? 'إعادة إنشاء' : 'طلب تجديد',
                              child: OutlinedButton(
                                onPressed: isBusy ||
                                        (!_isAdmin && hasPendingRequest)
                                    ? null
                                    : () async {
                                        final confirmed =
                                            await _confirmQrAction(
                                          isAdmin: _isAdmin,
                                          hasToken: hasToken,
                                        );
                                        if (!confirmed) {
                                          return;
                                        }
                                        if (_isAdmin) {
                                          await _generateToken(loc['id']);
                                        } else {
                                          await _requestRegeneration(loc['id']);
                                        }
                                      },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: C.gold,
                                  minimumSize: const Size.fromHeight(54),
                                ),
                                child: !_isAdmin && hasPendingRequest
                                    ? const Icon(Icons.hourglass_top_rounded,
                                        size: 20)
                                    : Icon(
                                        _isAdmin
                                            ? Icons.refresh
                                            : Icons.send_rounded,
                                        size: 20,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Tooltip(
                              message: 'طباعة',
                              child: OutlinedButton(
                                onPressed: isBusy
                                    ? null
                                    : () => _printQr(
                                          locationId: loc['id'],
                                          locationName:
                                              loc['name'] ?? 'Location',
                                          token: token,
                                        ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: C.cyan,
                                  minimumSize: const Size.fromHeight(54),
                                ),
                                child:
                                    const Icon(Icons.print_rounded, size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Tooltip(
                              message: 'تصدير',
                              child: OutlinedButton(
                                onPressed: isBusy
                                    ? null
                                    : () => _exportQrPdf(
                                          locationId: loc['id'],
                                          locationName:
                                              loc['name'] ?? 'Location',
                                          token: token,
                                        ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: C.green,
                                  minimumSize: const Size.fromHeight(54),
                                ),
                                child: isBusy
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: C.green,
                                        ),
                                      )
                                    : const Icon(Icons.ios_share_rounded,
                                        size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    children: [
                      const Icon(Icons.qr_code_2, size: 64, color: C.textMuted),
                      const SizedBox(height: 12),
                      Text(
                          _isAdmin
                              ? 'لم يُنشأ رمز QR بعد'
                              : 'لا يوجد QR فعال بعد',
                          style: GoogleFonts.cairo(color: C.textMuted)),
                      if (!_isAdmin) ...[
                        const SizedBox(height: 8),
                        Text(
                          hasPendingRequest
                              ? 'تم إرسال طلب الإنشاء وبانتظار الموافقة'
                              : 'إنشاء/تجديد QR يتطلب موافقة مدير النظام',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                              color: hasPendingRequest ? C.gold : C.textMuted,
                              fontSize: 12),
                        ),
                        if (hasReview) ...[
                          const SizedBox(height: 10),
                          _buildReviewNotice(
                            status: reviewStatus,
                            notes: (reviewNotes == null || reviewNotes.isEmpty)
                                ? null
                                : reviewNotes,
                          ),
                        ],
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isBusy || (!_isAdmin && hasPendingRequest)
                              ? null
                              : () async {
                                  final confirmed = await _confirmQrAction(
                                    isAdmin: _isAdmin,
                                    hasToken: hasToken,
                                  );
                                  if (!confirmed) {
                                    return;
                                  }
                                  if (_isAdmin) {
                                    await _generateToken(loc['id']);
                                  } else {
                                    await _requestRegeneration(loc['id']);
                                  }
                                },
                          icon: Icon(_isAdmin
                              ? Icons.qr_code
                              : Icons.mark_email_read_rounded),
                          label: Text(
                            _isAdmin
                                ? 'إنشاء رمز QR'
                                : (hasPendingRequest
                                    ? 'طلب قيد المراجعة'
                                    : 'طلب إنشاء QR'),
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: C.cyan,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewNotice({
    required String status,
    String? notes,
  }) {
    final approved = status == 'approved';
    final color = approved ? C.green : C.red;
    final title = approved ? 'تمت الموافقة على طلب QR' : 'تم رفض طلب تجديد QR';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                approved ? Icons.notifications_active : Icons.error_outline,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'ملاحظة الإدارة: $notes',
              style: GoogleFonts.cairo(
                color: C.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
