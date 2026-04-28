
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/locale_state.dart';
import '../../core/strings.dart';

class MatchDetailsScreen extends StatefulWidget {
static const route = '/match-details';

const MatchDetailsScreen({super.key});

@override
State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
String? _selectedArea; // المنطقة/المقعد المحجوز

@override
Widget build(BuildContext context) {
final lang = context.watch<LocaleState>().locale.languageCode;
final l = L(lang);

/// 🟦 مناطق الضغط فوق صورة الملعب
final List<Map<String, dynamic>> hotspots = [
{
'name': 'VIP',
'color': Colors.purple,
'gate': 'Gate 1',
'area': const Rect.fromLTWH(140, 330, 140, 60),
},
{
'name': 'Standard',
'color': Colors.redAccent,
'gate': 'Gate 2',
'area': const Rect.fromLTWH(80, 80, 260, 100),
},
{
'name': 'Category 2',
'color': Colors.blue,
'gate': 'Gate 3',
'area': const Rect.fromLTWH(30, 200, 120, 100),
},
{
'name': 'Family',
'color': Colors.green,
'gate': 'Gate 4',
'area': const Rect.fromLTWH(320, 200, 120, 100),
},
];

final args = ModalRoute.of(context)!.settings.arguments as Map?;
final title = args?['title'] ?? 'Match';
final date = args?['date'] ?? '';
final venue = args?['venue'] ?? '';

return Scaffold(
  backgroundColor: const Color(0xFFF4F6FA),
appBar: AppBar(
title: Text(l.t('match_details')),
),
body: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// 🔹 معلومات المباراة
Padding(
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: const TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
),
),
if (date.isNotEmpty) Text(date),
if (venue.isNotEmpty) Text(venue),
const SizedBox(height: 12),
if (_selectedArea != null)
Text(
'Booked in: $_selectedArea',
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.w600,
color: Colors.green,
),
),
],
),
),

// 🔹 صورة الملعب + الهوت سبوت
Expanded(
child: LayoutBuilder(
builder: (context, constraints) {
// المقاس الأساسي اللي صممتِ عليه الإحداثيات
const double baseWidth = 420;
const double baseHeight = 500;

final double screenWidth = constraints.maxWidth;
final double scaleFactor = screenWidth / baseWidth;
final double scaledHeight = baseHeight * scaleFactor;

return Center(
child: SizedBox(
width: screenWidth,
height: scaledHeight,
child: Stack(
children: [
// صورة الملعب
Positioned.fill(
child: Image.asset(
"assets/stadium.png",
fit: BoxFit.fill,
),
),

// الطبقات التفاعلية (مربعات فوق الصورة)
...hotspots.map((h) {
final Rect r = h['area'] as Rect;
final double left = r.left * scaleFactor;
final double top = r.top * scaleFactor;
final double width = r.width * scaleFactor;
final double height = r.height * scaleFactor;
final String name = h['name'] as String;
final Color color = h['color'] as Color;

final bool isSelected = _selectedArea == name;

return Positioned(
left: left,
top: top,
width: width,
height: height,
child: GestureDetector(
onTap: () {
setState(() {
_selectedArea = name;
});

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'Seat booked in $name',
),
),
);
},
child: Container(
decoration: BoxDecoration(
color: isSelected
? color.withOpacity(0.35)
: Colors.transparent,
border: Border.all(
color: color.withOpacity(0.5),
width: 1,
),
),
),
),
);
}).toList(),
],
),
),
);
},
),
),
],
),
);
}
}
