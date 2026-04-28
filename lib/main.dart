
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(
options: DefaultFirebaseOptions.currentPlatform,
);

runApp(const _Boot());
}

class _Boot extends StatelessWidget {
const _Boot({super.key});

@override
Widget build(BuildContext context) {
final app = const SahalatApp();

// 🔥 في وضع التطوير: اعرض التطبيق داخل مستطيل مثل شاشة الجوال
if (kDebugMode) {
return MaterialApp(
debugShowCheckedModeBanner: false,
home: Scaffold(
backgroundColor: Colors.black,
body: Center(
child: AspectRatio(
aspectRatio: 390 / 844, // 📱 أبعاد شاشة iPhone 13 (تستطيعين تغييرها)
child: ClipRRect(
borderRadius: BorderRadius.circular(22), // شكل الشاشة اختياري
child: Container(
color: Colors.white,
child: app,
),
),
),
),
),
);
}

// 🔥 في الإصدار النهائي (على الجوال): التطبيق كامل الشاشة
return app;
}
}

