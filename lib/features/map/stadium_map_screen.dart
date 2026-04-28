import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../colors.dart';
import '../../core/locale_state.dart';

class StadiumMapScreen extends StatefulWidget {
  static const route = '/stadium-map';
  const StadiumMapScreen({super.key});

  @override
  State<StadiumMapScreen> createState() => _StadiumMapScreenState();
}

class _StadiumMapScreenState extends State<StadiumMapScreen>
    with TickerProviderStateMixin {
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset _lastFocalPoint = Offset.zero;
  double _lastScale = 1.0;

  String? _selectedPoi;
  String _filterCategory = 'all';

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late Map<String, int> _crowdData;

  // POI data — descriptions stored per locale key
  final List<_Poi> _pois = [
    _Poi('gate_a',   'gate',     const Offset(0.5,  0.05), Icons.door_sliding_outlined,
        en: 'Gate A', ar: 'البوابة أ', fr: 'Porte A',
        descEn: 'North entrance – 83% full', descAr: 'المدخل الشمالي – 83% ممتلئ', descFr: 'Entrée Nord – 83% occupée'),
    _Poi('gate_b',   'gate',     const Offset(0.95, 0.5),  Icons.door_sliding_outlined,
        en: 'Gate B', ar: 'البوابة ب', fr: 'Porte B',
        descEn: 'East entrance – 45% full', descAr: 'المدخل الشرقي – 45% ممتلئ', descFr: 'Entrée Est – 45% occupée'),
    _Poi('gate_c',   'gate',     const Offset(0.5,  0.95), Icons.door_sliding_outlined,
        en: 'Gate C', ar: 'البوابة ج', fr: 'Porte C',
        descEn: 'South entrance – 19% full', descAr: 'المدخل الجنوبي – 19% ممتلئ', descFr: 'Entrée Sud – 19% occupée'),
    _Poi('gate_d',   'gate',     const Offset(0.05, 0.5),  Icons.door_sliding_outlined,
        en: 'Gate D', ar: 'البوابة د', fr: 'Porte D',
        descEn: 'West entrance – 14% full', descAr: 'المدخل الغربي – 14% ممتلئ', descFr: 'Entrée Ouest – 14% occupée'),

    _Poi('wc_1', 'restroom', const Offset(0.25, 0.2),  Icons.wc_rounded,
        en: 'Restroom 1', ar: 'دورة المياه 1', fr: 'Toilettes 1',
        descEn: 'Level 1 – Near Gate A', descAr: 'الطابق 1 – بالقرب من البوابة أ', descFr: 'Niveau 1 – Près de la Porte A'),
    _Poi('wc_2', 'restroom', const Offset(0.75, 0.2),  Icons.wc_rounded,
        en: 'Restroom 2', ar: 'دورة المياه 2', fr: 'Toilettes 2',
        descEn: 'Level 1 – East corridor', descAr: 'الطابق 1 – الممر الشرقي', descFr: 'Niveau 1 – Couloir Est'),
    _Poi('wc_3', 'restroom', const Offset(0.25, 0.8),  Icons.wc_rounded,
        en: 'Restroom 3', ar: 'دورة المياه 3', fr: 'Toilettes 3',
        descEn: 'Level 1 – West corridor', descAr: 'الطابق 1 – الممر الغربي', descFr: 'Niveau 1 – Couloir Ouest'),
    _Poi('wc_4', 'restroom', const Offset(0.75, 0.8),  Icons.wc_rounded,
        en: 'Restroom 4', ar: 'دورة المياه 4', fr: 'Toilettes 4',
        descEn: 'Level 1 – Near Gate C', descAr: 'الطابق 1 – بالقرب من البوابة ج', descFr: 'Niveau 1 – Près de la Porte C'),

    _Poi('food_1', 'food', const Offset(0.5,  0.3),  Icons.restaurant_rounded,
        en: 'Food Court', ar: 'منطقة الطعام', fr: 'Aire de restauration',
        descEn: 'Main food court – 3-min walk', descAr: 'منطقة الطعام الرئيسية – 3 دقائق', descFr: 'Restauration principale – 3 min'),
    _Poi('food_2', 'food', const Offset(0.8,  0.7),  Icons.fastfood_rounded,
        en: 'Snack Bar', ar: 'بار الوجبات الخفيفة', fr: 'Snack Bar',
        descEn: 'Quick snacks & beverages', descAr: 'وجبات خفيفة ومشروبات', descFr: 'Snacks et boissons rapides'),

    _Poi('vip_1', 'vip', const Offset(0.5, 0.5), Icons.star_rounded,
        en: 'VIP Lounge', ar: 'صالة VIP', fr: 'Salon VIP',
        descEn: 'Centre VIP section', descAr: 'القسم المركزي VIP', descFr: 'Section VIP centrale'),

    _Poi('aid_1', 'aid', const Offset(0.15, 0.35), Icons.local_hospital_rounded,
        en: 'First Aid', ar: 'الإسعافات الأولية', fr: 'Premiers secours',
        descEn: 'Medical assistance – 24/7', descAr: 'مساعدة طبية – 24/7', descFr: 'Assistance médicale – 24h/24'),
    _Poi('aid_2', 'aid', const Offset(0.85, 0.35), Icons.info_outline_rounded,
        en: 'Info Desk', ar: 'مكتب المعلومات', fr: 'Bureau d\'information',
        descEn: 'Stadium information & support', descAr: 'معلومات ودعم الملعب', descFr: 'Informations et assistance'),

    _Poi('park_a', 'parking', const Offset(0.2, 0.0), Icons.local_parking_rounded,
        en: 'Parking A', ar: 'موقف A', fr: 'Parking A',
        descEn: 'North parking – 200 spots', descAr: 'موقف شمالي – 200 مقعد', descFr: 'Parking Nord – 200 places'),
    _Poi('park_b', 'parking', const Offset(0.8, 0.0), Icons.local_parking_rounded,
        en: 'Parking B', ar: 'موقف B', fr: 'Parking B',
        descEn: 'North-East parking', descAr: 'موقف شمال شرقي', descFr: 'Parking Nord-Est'),
  ];

  // Crowd data keyed by POI id
  late Map<String, int> _crowdById;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _crowdData = {'Gate A': 83, 'Gate B': 45, 'Gate C': 19, 'Gate D': 14};
    _crowdById  = {'gate_a': 83, 'gate_b': 45, 'gate_c': 19, 'gate_d': 14};
    _simulateCrowd();
  }

  void _simulateCrowd() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        _crowdById['gate_a'] = (_crowdById['gate_a']! + Random().nextInt(5) - 2).clamp(0, 100);
        _crowdById['gate_b'] = (_crowdById['gate_b']! + Random().nextInt(5) - 2).clamp(0, 100);
      });
      _simulateCrowd();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  List<_Poi> get _filtered =>
      _filterCategory == 'all' ? _pois : _pois.where((p) => p.category == _filterCategory).toList();

  Color _poiColor(String cat) {
    switch (cat) {
      case 'gate':     return const Color(0xFF7C3AED);
      case 'restroom': return const Color(0xFF0891B2);
      case 'food':     return AppColors.warning;
      case 'vip':      return const Color(0xFFD97706);
      case 'aid':      return AppColors.error;
      case 'parking':  return AppColors.green;
      default:         return AppColors.primary;
    }
  }

  // Returns [label, color] for each category key in the current language
  Map<String, Map<String, dynamic>> _categoryMeta(String lang) {
    final isAr = lang == 'ar';
    final isFr = lang == 'fr';
    return {
      'all':      {'label': isAr ? 'الكل'           : (isFr ? 'Tout'         : 'All'),       'color': AppColors.primary},
      'parking':  {'label': isAr ? 'مواقف'          : (isFr ? 'Parking'      : 'Parking'),   'color': AppColors.green},
      'aid':      {'label': isAr ? 'إسعاف'          : (isFr ? 'Secours'      : 'Aid'),       'color': AppColors.error},
      'vip':      {'label': 'VIP',                                                             'color': const Color(0xFFD97706)},
      'food':     {'label': isAr ? 'طعام'           : (isFr ? 'Restauration' : 'Food'),      'color': AppColors.warning},
      'restroom': {'label': isAr ? 'دورات المياه'   : (isFr ? 'Toilettes'    : 'Restrooms'), 'color': const Color(0xFF0891B2)},
      'gate':     {'label': isAr ? 'بوابات'         : (isFr ? 'Portes'       : 'Gates'),     'color': const Color(0xFF7C3AED)},
    };
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleState>().locale.languageCode;
    final isAr = lang == 'ar';
    final isFr = lang == 'fr';
    final meta = _categoryMeta(lang);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isAr ? 'خريطة الملعب' : (isFr ? 'Plan du stade' : 'Stadium Map')),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: isAr ? 'توسيط الخريطة' : (isFr ? 'Centrer la carte' : 'Centre map'),
            onPressed: () => setState(() { _scale = 1.0; _offset = Offset.zero; _selectedPoi = null; }),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            height: 48,
            color: AppColors.surface,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: meta.entries.map((entry) {
                final isSelected = _filterCategory == entry.key;
                final color = entry.value['color'] as Color;
                final label = entry.value['label'] as String;
                return GestureDetector(
                  onTap: () => setState(() => _filterCategory = entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? color : color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.3)),
                    ),
                    child: Text(label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : color,
                        )),
                  ),
                );
              }).toList(),
            ),
          ),

          // Map
          Expanded(
            child: Stack(children: [
              _buildMap(),
              if (_selectedPoi != null) _buildPoiPopup(lang),
            ]),
          ),

          // Legend
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _legendItem(AppColors.success, isAr ? 'خفيف' : (isFr ? 'Faible'  : 'Low')),
                _legendItem(AppColors.warning, isAr ? 'متوسط': (isFr ? 'Moyen'   : 'Medium')),
                _legendItem(AppColors.error,   isAr ? 'مرتفع': (isFr ? 'Élevé'   : 'High')),
                Row(children: [
                  Container(width: 6, height: 6,
                      decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(isAr ? 'مباشر' : (isFr ? 'Direct' : 'Live'),
                      style: const TextStyle(fontSize: 11, color: AppColors.green, fontWeight: FontWeight.w600)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return GestureDetector(
      onTap: () => setState(() => _selectedPoi = null),
      onScaleStart: (d) { _lastFocalPoint = d.focalPoint; _lastScale = _scale; },
      onScaleUpdate: (d) {
        setState(() {
          _scale = (_lastScale * d.scale).clamp(0.8, 3.5);
          _offset += d.focalPoint - _lastFocalPoint;
          _lastFocalPoint = d.focalPoint;
        });
      },
      child: ClipRect(
        child: CustomPaint(
          painter: _StadiumPainter(
            pois: _filtered,
            selectedPoi: _selectedPoi,
            crowdById: _crowdById,
            poiColor: _poiColor,
            scale: _scale,
            offset: _offset,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: _filtered.map((poi) {
                  final x = poi.position.dx * constraints.maxWidth * _scale + _offset.dx;
                  final y = poi.position.dy * constraints.maxHeight * _scale + _offset.dy;
                  final color = _poiColor(poi.category);
                  final isSelected = _selectedPoi == poi.id;
                  return Positioned(
                    left: x - 20,
                    top: y - 20,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPoi = _selectedPoi == poi.id ? null : poi.id),
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, child) => Transform.scale(
                          scale: isSelected ? _pulseAnim.value : 1.0,
                          child: child,
                        ),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: isSelected ? color : color.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: isSelected ? 3 : 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: isSelected ? 12 : 4,
                                spreadRadius: isSelected ? 3 : 0,
                              ),
                            ],
                          ),
                          child: Icon(poi.icon, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPoiPopup(String lang) {
    final isAr = lang == 'ar';
    final isFr = lang == 'fr';
    final poi = _pois.firstWhere((p) => p.id == _selectedPoi, orElse: () => _pois.first);
    final color = _poiColor(poi.category);
    final name = isAr ? poi.ar : (isFr ? poi.fr : poi.en);
    final desc = isAr ? poi.descAr : (isFr ? poi.descFr : poi.descEn);
    final crowdPct = _crowdById[poi.id];

    return Positioned(
      bottom: 16, left: 16, right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: AppColors.shadowSmall,
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(poi.icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(desc,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  if (crowdPct != null) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: crowdPct / 100,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.directions_walk_rounded, color: AppColors.primary),
              tooltip: isAr ? 'التنقل هنا' : (isFr ? 'Naviguer ici' : 'Navigate here'),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) => Row(
    children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ],
  );
}

// ---------------------------------------------------------------------------
// POI model
// ---------------------------------------------------------------------------

class _Poi {
  final String id;
  final String category;
  final Offset position;
  final IconData icon;
  final String en, ar, fr;
  final String descEn, descAr, descFr;

  const _Poi(this.id, this.category, this.position, this.icon, {
    required this.en, required this.ar, required this.fr,
    required this.descEn, required this.descAr, required this.descFr,
  });
}

// ---------------------------------------------------------------------------
// Stadium painter
// ---------------------------------------------------------------------------

class _StadiumPainter extends CustomPainter {
  final List<_Poi> pois;
  final String? selectedPoi;
  final Map<String, int> crowdById;
  final Color Function(String) poiColor;
  final double scale;
  final Offset offset;

  _StadiumPainter({
    required this.pois, required this.selectedPoi, required this.crowdById,
    required this.poiColor, required this.scale, required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final cx = size.width / 2 * scale + offset.dx;
    final cy = size.height / 2 * scale + offset.dy;
    final pw = size.width * scale;
    final ph = size.height * scale;

    // Background
    paint..style = PaintingStyle.fill..color = const Color(0xFFE8F5E9);
    canvas.drawRect(Offset.zero & size, paint);

    paint..color = const Color(0xFF000000).withValues(alpha: 0.03)..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 20) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += 20) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 8 * scale), width: pw * 0.92, height: ph * 0.78),
      Paint()..maskFilter = MaskFilter.blur(BlurStyle.normal, 18 * scale)
             ..color = const Color(0xFF1A3A5C).withValues(alpha: 0.18),
    );

    // Outer ring
    paint..style = PaintingStyle.fill..color = const Color(0xFF0D2137);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: pw * 0.90, height: ph * 0.75), paint);

    _drawArcSection(canvas, cx, cy, pw * 0.86, ph * 0.71, pw * 0.64, ph * 0.53,
        const Color(0xFF1565C0), paint, topBottom: true);
    _drawArcSection(canvas, cx, cy, pw * 0.86, ph * 0.71, pw * 0.64, ph * 0.53,
        const Color(0xFF00695C), paint, topBottom: false);

    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy), width: pw * 0.75, height: ph * 0.62),
      0.35, 0.6, false,
      Paint()..style = PaintingStyle.stroke..strokeWidth = pw * 0.04..color = const Color(0xFFD97706),
    );

    paint..style = PaintingStyle.stroke..color = const Color(0xFF37474F)..strokeWidth = pw * 0.025;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: pw * 0.64, height: ph * 0.53), paint);

    paint..color = const Color(0xFFB84315).withValues(alpha: 0.7)..strokeWidth = pw * 0.018;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: pw * 0.60, height: ph * 0.49), paint);

    paint..style = PaintingStyle.fill..color = const Color(0xFF2E7D32);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: pw * 0.54, height: ph * 0.43), paint);

    _drawGrassStripes(canvas, cx, cy, pw * 0.54, ph * 0.43);

    final lp = Paint()..color = Colors.white.withValues(alpha: 0.85)..style = PaintingStyle.stroke..strokeWidth = 1.5 * scale;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: pw * 0.54, height: ph * 0.43), lp);
    canvas.drawLine(Offset(cx - pw * 0.27, cy), Offset(cx + pw * 0.27, cy), lp);
    canvas.drawCircle(Offset(cx, cy), 28 * scale, lp);
    paint..style = PaintingStyle.fill..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawCircle(Offset(cx, cy), 3 * scale, paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - ph * 0.16), width: pw * 0.22, height: ph * 0.12), lp);
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy + ph * 0.16), width: pw * 0.22, height: ph * 0.12), lp);
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - ph * 0.195), width: pw * 0.10, height: ph * 0.055), lp);
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy + ph * 0.195), width: pw * 0.10, height: ph * 0.055), lp);

    final cp = Paint()..color = Colors.white.withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 2.5 * scale;
    canvas.drawLine(Offset(cx, cy - ph * 0.375), Offset(cx, cy - ph * 0.265), cp);
    canvas.drawLine(Offset(cx, cy + ph * 0.375), Offset(cx, cy + ph * 0.265), cp);
    canvas.drawLine(Offset(cx + pw * 0.45, cy), Offset(cx + pw * 0.32, cy), cp);
    canvas.drawLine(Offset(cx - pw * 0.45, cy), Offset(cx - pw * 0.32, cy), cp);

    for (final e in [['N', cx, cy - ph * 0.27], ['S', cx, cy + ph * 0.27],
                     ['E', cx + pw * 0.34, cy], ['W', cx - pw * 0.34, cy]]) {
      _drawLabel(canvas, e[1] as double, e[2] as double, e[0] as String, scale);
    }

    final gatePos = {
      'gate_a': Offset(cx, size.height * 0.05 * scale + offset.dy),
      'gate_b': Offset(size.width * 0.95 * scale + offset.dx, cy),
      'gate_c': Offset(cx, size.height * 0.95 * scale + offset.dy),
      'gate_d': Offset(size.width * 0.05 * scale + offset.dx, cy),
    };
    crowdById.forEach((id, pct) {
      final pos = gatePos[id]; if (pos == null) return;
      final c = AppColors.getCrowdColor(pct.toDouble());
      canvas.drawCircle(pos, 40 * scale, Paint()..style = PaintingStyle.fill..color = c.withValues(alpha: 0.30));
      canvas.drawCircle(pos, 60 * scale, Paint()..style = PaintingStyle.fill..color = c.withValues(alpha: 0.12));
    });
  }

  void _drawArcSection(Canvas canvas, double cx, double cy,
      double outerW, double outerH, double innerW, double innerH,
      Color color, Paint paint, {required bool topBottom}) {
    final outer = Rect.fromCenter(center: Offset(cx, cy), width: outerW, height: outerH);
    final inner = Rect.fromCenter(center: Offset(cx, cy), width: innerW, height: innerH);
    paint..style = PaintingStyle.fill..color = color;
    if (topBottom) {
      for (final start in [3.14 + 0.3, 0.3]) {
        final p = Path()..addArc(outer, start, 2.54 - 0.6);
        p.arcTo(inner, start + (2.54 - 0.6), -(2.54 - 0.6), false);
        p.close(); canvas.drawPath(p, paint);
      }
    } else {
      for (final pair in [[1.87, 1.8], [-0.07 + 3.14, -1.8]]) {
        final s = pair[0]; final sw = pair[1];
        final p = Path()..addArc(outer, s, sw);
        p.arcTo(inner, s + sw, -sw, false);
        p.close(); canvas.drawPath(p, paint);
      }
    }
  }

  void _drawGrassStripes(Canvas canvas, double cx, double cy, double w, double h) {
    final clip = Path()..addOval(Rect.fromCenter(center: Offset(cx, cy), width: w, height: h));
    canvas.save(); canvas.clipPath(clip);
    final sp = Paint()..style = PaintingStyle.fill;
    final sw = w / 10;
    for (int i = 0; i < 10; i++) {
      sp.color = i.isEven ? const Color(0xFF2E7D32) : const Color(0xFF388E3C);
      canvas.drawRect(Rect.fromLTWH(cx - w / 2 + i * sw, cy - h / 2, sw, h), sp);
    }
    canvas.restore();
  }

  void _drawLabel(Canvas canvas, double x, double y, String letter, double scale) {
    final tp = TextPainter(
      text: TextSpan(text: letter, style: TextStyle(
        color: Colors.white.withValues(alpha: 0.6), fontSize: 11 * scale, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(_StadiumPainter o) =>
      o.scale != scale || o.offset != offset || o.crowdById != crowdById || o.selectedPoi != selectedPoi;
}
