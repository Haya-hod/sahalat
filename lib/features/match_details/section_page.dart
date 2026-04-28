import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/locale_state.dart';
import '../../core/strings.dart';

import '../../core/ticket_payload.dart';
import '../../core/ticket_repo.dart';

import '../tickets/ticket_qr_screen.dart';

class SectionPage extends StatefulWidget {
  final String match;
  final String category;
  final String gate;
  final Color color;
  final List<String> sections;

  const SectionPage({
    super.key,
    required this.match,
    required this.category,
    required this.gate,
    required this.color,
    required this.sections,
  });

  @override
  State<SectionPage> createState() => _SectionPageState();
}

class _SectionPageState extends State<SectionPage> {
  String? _selectedSection;
  bool _saving = false;

  /// نولّد مقاعد لهذا السيكشن
  List<String> get _seats {
    if (_selectedSection == null) return [];
    return List.generate(24, (i) {
      final seatNo = i + 1;
      return '$_selectedSection-$seatNo';
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleState>().locale.languageCode;
    final l = L(lang);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        backgroundColor: widget.color,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات عامة عن المباراة / البوابة
            Text(
              widget.match,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Gate: ${widget.gate}'),
            Text('Category: ${widget.category}'),
            const SizedBox(height: 16),

            // اختيار الـ Section
            Text(
              l.t('select_section'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.sections.map((s) {
                final selected = _selectedSection == s;
                return ChoiceChip(
                  label: Text(s),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedSection = s;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            Text(
              l.t('select_seat'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            if (_selectedSection == null)
              Text(
                l.t('please_select_section_first'),
                style: const TextStyle(color: Colors.grey),
              )
            else
              Expanded(
                child: Stack(
                  children: [
                    GridView.builder(
                      itemCount: _seats.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemBuilder: (context, index) {
                        final seatId = _seats[index];

                        return GestureDetector(
                          onTap: _saving
                              ? null
                              : () async {
                                  await _bookSeatAndOpenQr(
                                    context: context,
                                    l: l,
                                    seatId: seatId,
                                  );
                                },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              seatId,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Loading overlay
                    if (_saving)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.15),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _bookSeatAndOpenQr({
    required BuildContext context,
    required L l,
    required String seatId,
  }) async {
    if (_selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.t('please_select_section_first'))),
      );
      return;
    }

    setState(() => _saving = true);

    final payload = TicketPayload(
      matchTitle: widget.match,
      matchDate: 'TBD', // مؤقت (بعدها نمرره من MatchDetails)
      venue: 'Stadium', // مؤقت
      category: widget.category,
      gate: widget.gate,
      section: _selectedSection ?? '',
      seat: seatId,
    );

    try {
      final repo = TicketRepo();

      // ✅ حفظ في Firestore ويرجع ticketId
      final ticketId = await repo.createTicket(payload);

      if (!context.mounted) return;

      final withId = payload.copyWith(ticketId: ticketId);

      // ✅ فتح QR
      Navigator.pushNamed(
        context,
        TicketQrScreen.route,
        arguments: withId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ticket created: $ticketId')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
