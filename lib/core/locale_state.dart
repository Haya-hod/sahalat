import 'package:flutter/material.dart';

class LocaleState extends ChangeNotifier {
Locale _locale = const Locale('en');
Locale get locale => _locale;

void setLocale(Locale l) {
if (!['en','ar','fr'].contains(l.languageCode)) return;
_locale = l;
notifyListeners();
}
}