import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../colors.dart';
import '../../core/ticket_store.dart';
import '../../core/locale_state.dart';

class PaymentScreen extends StatefulWidget {
  static const route = '/payment';
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  bool _isProcessing = false;
  bool _showCvv = false;
  String _selectedMethod = 'card';
  int _currentStep = 0;

  final List<Map<String, dynamic>> _methods = [
    {'id': 'card', 'label': 'Credit / Debit Card', 'icon': Icons.credit_card_rounded},
    {'id': 'apple', 'label': 'Apple Pay', 'icon': Icons.apple_rounded},
    {'id': 'stcpay', 'label': 'STC Pay', 'icon': Icons.account_balance_wallet_rounded},
  ];

  String _formatCardNumber(String value) {
    value = value.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < value.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(value[i]);
    }
    return buffer.toString();
  }

  String _formatExpiry(String value) {
    value = value.replaceAll('/', '');
    if (value.length >= 2) {
      return '${value.substring(0, 2)}/${value.substring(2)}';
    }
    return value;
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == 'card' && !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _currentStep = 1;
    });

    await Future.delayed(const Duration(milliseconds: 2500));

    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final matchTitle = args?['title'] ?? 'Match';
    final section = args?['section'] ?? 'Standard';
    final lang = context.read<LocaleState>().locale.languageCode;
    final newTicketLabel = lang == 'ar' ? 'تذكرة جديدة' : (lang == 'fr' ? 'Nouveau billet' : 'New ticket');

    final gateMap = {
      'VIP': 'Gate 1', 'Standard': 'Gate 2',
      'Premium': 'Gate 3', 'Family': 'Gate 4',
    };
    final seatMap = {
      'VIP': 'VIP-01', 'Standard': 'STD-01',
      'Premium': 'PRE-01', 'Family': 'FAM-01',
    };
    if (mounted) {
      context.read<TicketStore>().addTicket(
        match: matchTitle,
        category: section,
        gate: gateMap[section] ?? 'Gate 1',
        section: section[0],
        seat: seatMap[section] ?? 'A-01',
        date: newTicketLabel,
      );
    }

    setState(() {
      _isProcessing = false;
      _currentStep = 2;
    });
  }

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _nameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleState>().locale.languageCode;
    final isAr = lang == 'ar';
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final matchTitle = args?['title'] ?? 'Spain vs Brazil';
    final section = args?['section'] ?? 'VIP';
    final price = args?['price'] ?? 'SAR 850';

    if (_currentStep == 2) return _buildSuccessScreen(context, lang, matchTitle, section);
    if (_currentStep == 1) return _buildProcessingScreen(isAr);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isAr ? 'إتمام الدفع' : 'Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderSummary(matchTitle, section, price, isAr),
            const SizedBox(height: 24),
            _buildSectionTitle(isAr ? 'طريقة الدفع' : 'Payment Method'),
            const SizedBox(height: 12),
            _buildMethodSelector(),
            const SizedBox(height: 24),
            if (_selectedMethod == 'card') ...[
              _buildSectionTitle(isAr ? 'تفاصيل البطاقة' : 'Card Details'),
              const SizedBox(height: 12),
              _buildCardForm(isAr),
              const SizedBox(height: 24),
            ],
            if (_selectedMethod != 'card') ...[
              _buildWalletInfo(_selectedMethod, isAr),
              const SizedBox(height: 24),
            ],
            _buildSecurityBadge(isAr),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      isAr ? 'ادفع $price الآن' : 'Pay $price Now',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(String title, String section, String price, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isAr ? 'ملخص الطلب' : 'Order Summary',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.event_seat_outlined, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(section, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
              Text(price, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Row(
      children: _methods.map((m) {
        final isSelected = _selectedMethod == m['id'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedMethod = m['id'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(m['icon'] as IconData,
                      size: 22,
                      color: isSelected ? Colors.white : AppColors.textSecondary),
                  const SizedBox(height: 4),
                  Text(
                    (m['label'] as String).split(' ').first,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCardForm(bool isAr) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _cardNumberCtrl,
            keyboardType: TextInputType.number,
            maxLength: 19,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) {
              final formatted = _formatCardNumber(v);
              if (formatted != v) {
                _cardNumberCtrl.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }
            },
            decoration: InputDecoration(
              labelText: isAr ? 'رقم البطاقة' : 'Card Number',
              hintText: '1234 5678 9012 3456',
              prefixIcon: const Icon(Icons.credit_card_rounded),
              counterText: '',
            ),
            validator: (v) {
              if (v == null || v.replaceAll(' ', '').length < 16) {
                return isAr ? 'رقم البطاقة غير صحيح' : 'Invalid card number';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: isAr ? 'الاسم على البطاقة' : 'Cardholder Name',
              hintText: 'JOHN DOE',
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
            validator: (v) {
              if (v == null || v.trim().length < 3) {
                return isAr ? 'أدخل الاسم' : 'Enter cardholder name';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) {
                    final formatted = _formatExpiry(v);
                    if (formatted != v) {
                      _expiryCtrl.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  },
                  decoration: InputDecoration(
                    labelText: isAr ? 'تاريخ الانتهاء' : 'Expiry',
                    hintText: 'MM/YY',
                    prefixIcon: const Icon(Icons.calendar_today_rounded),
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.length < 5) {
                      return isAr ? 'غير صحيح' : 'Invalid';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _cvvCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: !_showCvv,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    hintText: '***',
                    counterText: '',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_showCvv ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _showCvv = !_showCvv),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 3) {
                      return isAr ? 'غير صحيح' : 'Invalid';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletInfo(String method, bool isAr) {
    final isApple = method == 'apple';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isApple ? Colors.black : const Color(0xFF6B2FA0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isApple ? Icons.apple_rounded : Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isApple ? 'Apple Pay' : 'STC Pay',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr
                      ? 'سيتم تأكيد الدفع بـ Face ID / Touch ID'
                      : 'Payment will be confirmed via Face ID / Touch ID',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityBadge(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.greenPale,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: AppColors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isAr
                  ? 'دفع آمن ومشفر بتقنية SSL 256-bit. بياناتك محمية تماماً.'
                  : '256-bit SSL encrypted payment. Your data is fully protected.',
              style: const TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
      );

  Widget _buildProcessingScreen(bool isAr) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isAr ? 'جاري معالجة الدفع...' : 'Processing payment...',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              isAr ? 'لا تغلق التطبيق' : 'Please do not close the app',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessScreen(BuildContext context, String lang, String title, String section) {
    final isAr = lang == 'ar';
    final isFr = lang == 'fr';
    final ticketId = '#TKT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(width: 140, height: 140, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.green.withValues(alpha: 0.08))),
                    Container(width: 110, height: 110, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.green.withValues(alpha: 0.15))),
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF16A34A), Color(0xFF22C55E)]),
                        boxShadow: [BoxShadow(color: AppColors.green.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 4)],
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(isAr ? 'تم الدفع بنجاح! 🎉' : 'Payment Successful! 🎉', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(isAr ? 'تذكرتك جاهزة وتجدها في قسم "تذاكري"' : (isFr ? 'Votre billet est prêt dans "Mes billets"' : 'Your ticket is ready in "My Tickets"'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0, 4))]),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: const BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        child: Row(
                          children: [
                            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.sports_soccer_rounded, color: Colors.white, size: 22)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                                Text(ticketId, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ]),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(20)),
                              child: Text(isAr ? 'صالحة' : (isFr ? 'VALIDE' : 'VALID'), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(children: List.generate(30, (i) => Expanded(child: Container(height: 1, color: i.isEven ? AppColors.border : Colors.transparent)))),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(children: [
                          _successRow(Icons.event_seat_outlined, isAr ? 'القسم' : (isFr ? 'Section' : 'Section'), section),
                          const SizedBox(height: 14),
                          _successRow(Icons.confirmation_number_outlined, isAr ? 'رقم التذكرة' : (isFr ? 'N° billet' : 'Ticket ID'), ticketId),
                          const SizedBox(height: 14),
                          _successRow(Icons.payment_rounded, isAr ? 'حالة الدفع' : (isFr ? 'Paiement' : 'Payment'), isAr ? '✅ مدفوع' : (isFr ? '✅ Payé' : '✅ Paid')),
                        ]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/tickets', (r) => r.isFirst),
                    icon: const Icon(Icons.confirmation_number_outlined, size: 20),
                    label: Text(isAr ? 'عرض تذاكري' : (isFr ? 'Voir mes billets' : 'View My Tickets')),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    icon: const Icon(Icons.home_rounded, size: 18),
                    label: Text(isAr ? 'العودة للرئيسية' : (isFr ? 'Retour à l\'accueil' : 'Back to Home')),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.border, width: 1.5), foregroundColor: AppColors.textSecondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _successRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      const Spacer(),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    ]);
  }
}
