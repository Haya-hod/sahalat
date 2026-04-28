
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/locale_state.dart';
import '../../core/strings.dart';
import '../profile/profile_screen.dart';

class AdminDashboardSection extends StatelessWidget {
const AdminDashboardSection({super.key});

@override
Widget build(BuildContext context) {
final lang = context.watch<LocaleState>().locale.languageCode;
final l = L(lang);

final totalVisitors = 18500;
final currentInside = 13240;
final avgWait = 7;

final gates = [
{'name': 'North', 'count': 4200},
{'name': 'East', 'count': 3800},
{'name': 'South', 'count': 2600},
{'name': 'West', 'count': 1900},
];
final maxGateCount = gates
.map((g) => g['count'] as int)
.reduce((a, b) => a > b ? a : b);

final alerts = [
{'level': 'HIGH', 'message': 'High congestion at North Gate'},
{'level': 'MED', 'message': 'Queue increasing at East Gate'},
{'level': 'OK', 'message': 'South & West gates are normal'},
];

return Card(
elevation: 3,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
child: Padding(
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [

/// 🔥 حذف الشعار — والاكتفاء بالعنوان فقط
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(
l.t('admin_dashboard'),
style: const TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
),
),

/// 🔥 زر My Profile على الجانب (يمين أو يسار حسب اللغة)
IconButton(
icon: const Icon(Icons.person, color: Colors.deepPurple),
onPressed: () {
Navigator.pushNamed(context, ProfileScreen.route);
},
),
],
),

const SizedBox(height: 16),

/// إحصائيات عامة
Row(
children: [
_StatCard(
label: 'Total Visitors',
value: totalVisitors.toString(),
icon: Icons.groups,
),
const SizedBox(width: 8),
_StatCard(
label: 'Inside Now',
value: currentInside.toString(),
icon: Icons.meeting_room,
),
const SizedBox(width: 8),
_StatCard(
label: 'Avg Wait (min)',
value: avgWait.toString(),
icon: Icons.timer,
),
],
),

const SizedBox(height: 24),

const Text(
'Crowd by Gate',
style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
),

const SizedBox(height: 12),

SizedBox(
height: 150,
child: Row(
crossAxisAlignment: CrossAxisAlignment.end,
children: gates.map((g) {
final count = g['count'] as int;
final ratio = count / maxGateCount;
final barHeight = 20 + 100 * ratio;

return Expanded(
child: Column(
mainAxisAlignment: MainAxisAlignment.end,
children: [
Container(
height: barHeight,
width: 20,
decoration: BoxDecoration(
color: Colors.deepPurple.shade300,
borderRadius: BorderRadius.circular(6),
),
),
const SizedBox(height: 6),
Text(
g['name'] as String,
style: const TextStyle(fontSize: 12),
),
Text(
count.toString(),
style: const TextStyle(
fontSize: 10, color: Colors.grey),
),
],
),
);
}).toList(),
),
),

const SizedBox(height: 24),

const Text(
'Alerts',
style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
),

const SizedBox(height: 8),

Column(
children: alerts.map((a) {
final level = a['level'] as String;
final msg = a['message'] as String;
Color color;
IconData icon;

if (level == 'HIGH') {
color = Colors.red;
icon = Icons.error;
} else if (level == 'MED') {
color = Colors.orange;
icon = Icons.warning;
} else {
color = Colors.green;
icon = Icons.check_circle;
}

return ListTile(
dense: true,
leading: Icon(icon, color: color),
title: Text(msg),
);
}).toList(),
),
],
),
),
);
}
}

class _StatCard extends StatelessWidget {
final String label;
final String value;
final IconData icon;

const _StatCard({
required this.label,
required this.value,
required this.icon,
});

@override
Widget build(BuildContext context) {
return Expanded(
child: Container(
padding: const EdgeInsets.all(10),
decoration: BoxDecoration(
color: Colors.deepPurple.shade50,
borderRadius: BorderRadius.circular(10),
),
child: Column(
children: [
Icon(icon, size: 22, color: Colors.deepPurple),
const SizedBox(height: 4),
Text(
value,
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 2),
Text(
label,
style: const TextStyle(
fontSize: 11,
color: Colors.grey,
),
textAlign: TextAlign.center,
),
],
),
),
);
}
}
