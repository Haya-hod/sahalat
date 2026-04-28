
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_state.dart';
import '../profile/profile_screen.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
static const route = '/admin-dashboard';
const AdminDashboardScreen({super.key});

@override
Widget build(BuildContext context) {
// ألوان من الشعار
const logoBlue = Color(0xFF0066CC);
const logoOrange = Color(0xFFF57C00);
const logoGreen = Color(0xFF43A047);
const logoYellow = Color(0xFFFFC107);
const logoBg = Color(0xFFF5F5F7);

final auth = context.read<AuthState>();

return Scaffold(
backgroundColor: logoBg,

// ---------- APPBAR ----------
appBar: AppBar(
backgroundColor: logoBlue,
elevation: 0,
title: const Text(
'Dashboard', // ✅ يذكر مرة واحدة فقط
style: TextStyle(color: Colors.white),
),
iconTheme: const IconThemeData(color: Colors.white),
actions: [
// زر My Profile
IconButton(
icon: const Icon(Icons.person),
onPressed: () {
Navigator.pushNamed(context, ProfileScreen.route);
},
),
// زر Logout
IconButton(
icon: const Icon(Icons.logout),
onPressed: () async {
await auth.signOut();
if (context.mounted) {
Navigator.pushNamedAndRemoveUntil(
context,
LoginScreen.route,
(r) => false,
);
}
},
),
],
),

// ---------- BODY ----------
body: ListView(
padding: const EdgeInsets.all(16),
children: [
const SizedBox(height: 8),

// كروت الإحصائيات
Row(
children: const [
Expanded(
child: _StatBox(
label: 'Total Visitors',
value: '18,500',
icon: Icons.groups,
color: logoBlue,
),
),
SizedBox(width: 8),
Expanded(
child: _StatBox(
label: 'Inside Now',
value: '13,240',
icon: Icons.meeting_room,
color: logoGreen,
),
),
SizedBox(width: 8),
Expanded(
child: _StatBox(
label: 'Avg Wait',
value: '7 min',
icon: Icons.timer,
color: logoOrange,
),
),
],
),

const SizedBox(height: 28),

// Crowd by Gate
const Text(
'Crowd by Gate',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: logoBlue,
),
),
const SizedBox(height: 12),

Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(12),
),
child: Column(
children: const [
_GateBar(
name: 'North',
count: 4200,
max: 4200,
color: logoBlue,
),
_GateBar(
name: 'East',
count: 3800,
max: 4200,
color: logoGreen,
),
_GateBar(
name: 'South',
count: 2600,
max: 4200,
color: logoOrange,
),
_GateBar(
name: 'West',
count: 1900,
max: 4200,
color: logoYellow,
),
],
),
),

const SizedBox(height: 24),

// Alerts
const Text(
'Alerts',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: logoBlue,
),
),
const SizedBox(height: 8),

Card(
elevation: 2,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
child: Column(
children: const [
_AlertTile(
level: 'HIGH',
message: 'High congestion at North Gate',
color: Colors.red,
icon: Icons.error,
),
Divider(height: 1),
_AlertTile(
level: 'MED',
message: 'Queue increasing at East Gate',
color: Colors.orange,
icon: Icons.warning,
),
Divider(height: 1),
_AlertTile(
level: 'OK',
message: 'South & West gates are normal',
color: Colors.green,
icon: Icons.check_circle,
),
],
),
),
],
),
);
}
}

class _StatBox extends StatelessWidget {
final String label;
final String value;
final IconData icon;
final Color color;

const _StatBox({
required this.label,
required this.value,
required this.icon,
required this.color,
});

@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(14),
border: Border.all(color: color.withOpacity(0.2)),
boxShadow: [
BoxShadow(
color: color.withOpacity(0.08),
blurRadius: 8,
offset: const Offset(0, 3),
),
],
),
child: Column(
children: [
Icon(icon, size: 26, color: color),
const SizedBox(height: 6),
Text(
value,
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: color,
),
),
const SizedBox(height: 2),
Text(
label,
textAlign: TextAlign.center,
style: const TextStyle(fontSize: 12, color: Colors.black54),
),
],
),
);
}
}

class _GateBar extends StatelessWidget {
final String name;
final int count;
final int max;
final Color color;

const _GateBar({
required this.name,
required this.count,
required this.max,
required this.color,
});

@override
Widget build(BuildContext context) {
final ratio = count / max;

return Padding(
padding: const EdgeInsets.symmetric(vertical: 6),
child: Row(
children: [
SizedBox(
width: 70,
child: Text(
name,
style: const TextStyle(fontSize: 13),
),
),
Expanded(
child: Stack(
children: [
Container(
height: 12,
decoration: BoxDecoration(
color: color.withOpacity(0.12),
borderRadius: BorderRadius.circular(10),
),
),
FractionallySizedBox(
widthFactor: ratio,
child: Container(
height: 12,
decoration: BoxDecoration(
color: color,
borderRadius: BorderRadius.circular(10),
),
),
),
],
),
),
const SizedBox(width: 8),
Text(
'$count',
style: const TextStyle(fontSize: 12),
),
],
),
);
}
}

class _AlertTile extends StatelessWidget {
final String level;
final String message;
final Color color;
final IconData icon;

const _AlertTile({
required this.level,
required this.message,
required this.color,
required this.icon,
});

@override
Widget build(BuildContext context) {
return ListTile(
leading: Icon(icon, color: color),
title: Text(message),
subtitle: Text('Level: $level'),
);
}
}
