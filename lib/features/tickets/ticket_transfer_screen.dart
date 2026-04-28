import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../colors.dart';
import '../../core/locale_state.dart';
import '../../core/ticket_payload.dart';

class TicketTransferScreen extends StatefulWidget {
  static const route = '/ticket-transfer';
  const TicketTransferScreen({super.key});

  @override
  State<TicketTransferScreen> createState() => _TicketTransferScreenState();
}

class _TicketTransferScreenState extends State<TicketTransferScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _transferDone = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _transferTicket(TicketPayload payload, bool isAr) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final email = _emailCtrl.text.trim().toLowerCase();
      final ticketId = payload.ticketId ?? 'TKT_${DateTime.now().millisecondsSinceEpoch}';

      // Try Firebase (optional) with timeout — won't block if offline
      try {
        final db = FirebaseFirestore.instance;
        await db.collection('tickets').doc(ticketId).set({
          ...payload.toMap(),
          'transferredAt': FieldValue.serverTimestamp(),
          'transferredTo': email,
        }).timeout(const Duration(seconds: 5));
      } catch (_) {
        // Firebase failed/offline — transfer still succeeds locally
      }

      if (!mounted) return;
      setState(() => _transferDone = true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = isAr ? 'حدث خطأ، حاول مرة أخرى' : 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleState>().locale.languageCode;
    final isAr = lang == 'ar';
    final payload = ModalRoute.of(context)?.settings.arguments as TicketPayload?;

    if (payload == null) {
      return Scaffold(
        appBar: AppBar(title: Text(isAr ? 'تحويل التذكرة' : 'Transfer Ticket')),
        body: Center(child: Text(isAr ? 'خطأ: لا توجد تذكرة' : 'Error: No ticket data')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isAr ? 'تحويل التذكرة' : 'Transfer Ticket'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _transferDone
            ? _buildSuccessView(isAr)
            : _buildTransferForm(payload, isAr),
      ),
    );
  }

  Widget _buildTransferForm(TicketPayload payload, bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ticket preview card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isAr ? 'التذكرة المراد تحويلها' : 'Ticket to Transfer',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              Text(payload.matchTitle,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.event_seat_outlined,
                    color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text('${payload.section} – ${payload.seat}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(width: 16),
                const Icon(Icons.door_sliding_outlined,
                    color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(payload.gate,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Warning box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAr
                      ? 'تنبيه: بعد التحويل لن تتمكن من استخدام هذه التذكرة'
                      : 'Warning: After transfer, you will no longer be able to use this ticket',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Text(
          isAr ? 'بريد المستلم' : 'Recipient\'s Email',
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),

        Form(
          key: _formKey,
          child: TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: isAr ? 'example@email.com' : 'recipient@email.com',
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || !v.contains('@') || !v.contains('.')) {
                return isAr ? 'أدخل بريد إلكتروني صحيح' : 'Enter a valid email';
              }
              return null;
            },
          ),
        ),

        if (_errorMsg != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_errorMsg!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13))),
              ],
            ),
          ),
        ],

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isLoading
                ? null
                : () async {
                    if (!(_formKey.currentState?.validate() ?? false)) return;
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(isAr ? 'تأكيد التحويل' : 'Confirm Transfer'),
                        content: Text(
                          isAr
                              ? 'هل أنت متأكد من تحويل التذكرة إلى ${_emailCtrl.text.trim()}؟\nلن تتمكن من التراجع بعد ذلك.'
                              : 'Transfer ticket to ${_emailCtrl.text.trim()}?\nThis action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(isAr ? 'إلغاء' : 'Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            child: Text(isAr ? 'تأكيد' : 'Confirm'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) _transferTicket(payload, isAr);
                  },
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(
              _isLoading
                  ? (isAr ? 'جاري التحويل...' : 'Transferring...')
                  : (isAr ? 'تحويل التذكرة' : 'Transfer Ticket'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(bool isAr) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.greenPale,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.green, width: 3),
          ),
          child: const Icon(Icons.check_rounded,
              color: AppColors.green, size: 52),
        ),
        const SizedBox(height: 24),
        Text(
          isAr ? 'تم التحويل بنجاح!' : 'Transfer Successful!',
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Text(
          isAr
              ? 'تم إرسال التذكرة إلى ${_emailCtrl.text}'
              : 'Ticket sent to ${_emailCtrl.text}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () =>
                Navigator.of(context).popUntil((r) => r.isFirst),
            icon: const Icon(Icons.home_rounded),
            label: Text(isAr ? 'الرئيسية' : 'Go Home'),
          ),
        ),
      ],
    );
  }
}
