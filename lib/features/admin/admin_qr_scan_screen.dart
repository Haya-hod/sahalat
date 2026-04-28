
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/locale_state.dart';
import '../../core/strings.dart';
import 'admin_dashboard_screen.dart';

class AdminQrScanScreen extends StatefulWidget {
static const route = '/admin-scan';
const AdminQrScanScreen({super.key});

@override
State<AdminQrScanScreen> createState() => _AdminQrScanScreenState();
}

class _AdminQrScanScreenState extends State<AdminQrScanScreen> {
bool _handled = false;

void _onDetect(BarcodeCapture capture) {
if (_handled) return;
final barcodes = capture.barcodes;
if (barcodes.isEmpty) return;
final value = barcodes.first.rawValue;
if (value == null) return;

_handled = true;

Navigator.pushReplacementNamed(
context,
AdminDashboardScreen.route,
arguments: value,
);
}

@override
Widget build(BuildContext context) {
final lang = context.watch<LocaleState>().locale.languageCode;
final l = L(lang);

return Scaffold(
appBar: AppBar(
title: Text(l.t('scan_qr')),
),
body: Stack(
children: [
MobileScanner(
onDetect: _onDetect,
),
// إطار بسيط في المنتصف (UI جميل لعلامة المسح)
Align(
alignment: Alignment.center,
child: Container(
width: 260,
height: 260,
decoration: BoxDecoration(
border: Border.all(color: Colors.white, width: 2),
borderRadius: BorderRadius.circular(16),
),
),
),
],
),
);
}
}