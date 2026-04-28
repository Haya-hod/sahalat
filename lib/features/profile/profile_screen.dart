
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/locale_state.dart';
import '../../core/strings.dart';
import '../../core/auth_state.dart';

class ProfileScreen extends StatelessWidget {
static const route = '/profile';
const ProfileScreen({super.key});

@override
Widget build(BuildContext context) {
final localeState = context.watch<LocaleState>();
final lang = localeState.locale.languageCode;
final l = L(lang);
final auth = context.watch<AuthState>();
final user = auth.user;

// مثال ثابت (إلى أن يتم ربط البيانات)
const firstName = "Ahmed";
const lastName = "Mohammad";
const nationality = "Saudi";

return Scaffold(
  backgroundColor: const Color(0xFFF4F6FA),
appBar: AppBar(
title: Text(l.t('my_profile')),
),
body: Padding(
padding: const EdgeInsets.all(16),
child: SingleChildScrollView(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
/// 🔥 الشعار أكبر وفي المنتصف
Center(
child: Image.asset(
'assets/logo.png',
height: 180,
width: 180,
fit: BoxFit.contain,
errorBuilder: (_, __, ___) => const Icon(
Icons.sports_soccer,
size: 90,
color: Colors.deepPurple,
),
),
),

const SizedBox(height: 30),

/// عنوان البريد الإلكتروني
Text(
l.t('email'),
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 8),

/// البريد الإلكتروني
Text(
user?.email ?? '',
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.w600,
),
),

const SizedBox(height: 30),

/// 🔵 FIRST NAME
const Text(
'First Name',
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 6),
const ListTile(
contentPadding: EdgeInsets.zero,
leading: Icon(Icons.person),
title: Text(
firstName, // Ahmed
style: TextStyle(fontSize: 16),
),
),

const SizedBox(height: 12),

/// 🔵 LAST NAME
const Text(
'Last Name',
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 6),
const ListTile(
contentPadding: EdgeInsets.zero,
leading: Icon(Icons.person_outline),
title: Text(
lastName, // Mohammad
style: TextStyle(fontSize: 16),
),
),

const SizedBox(height: 12),

/// 🔵 NATIONALITY
const Text(
'Nationality',
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 6),
const ListTile(
contentPadding: EdgeInsets.zero,
leading: Icon(Icons.flag),
title: Text(
nationality, // Saudi
style: TextStyle(fontSize: 16),
),
),

const SizedBox(height: 24),

/// اختيار اللغة
Text(
l.t('language'),
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 8),

Row(
children: [
const Icon(Icons.language, color: Colors.deepPurple),
const SizedBox(width: 8),
DropdownButton<String>(
value: lang,
items: const [
DropdownMenuItem(value: 'ar', child: Text('العربية')),
DropdownMenuItem(value: 'en', child: Text('English')),
DropdownMenuItem(value: 'fr', child: Text('Français')),
],
onChanged: (v) {
if (v == null) return;
localeState.setLocale(Locale(v));
},
),
],
),

const SizedBox(height: 30),

/// حالة الحساب
ListTile(
contentPadding: EdgeInsets.zero,
leading: const Icon(Icons.verified_user),
title: Text(auth.isAdmin ? 'Admin' : 'Visitor'),
subtitle: Text(
auth.isAdmin
? 'You have access to the crowd dashboard.'
: 'Standard visitor account.',
),
),
],
),
),
),
);
}
}
