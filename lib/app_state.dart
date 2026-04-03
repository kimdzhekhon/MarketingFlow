import 'package:flutter/material.dart';
import 'l10n/app_locale.dart';

class AppState extends ChangeNotifier {
  AppLocale _locale = AppLocale.ko;
  String? _apiKey;

  AppLocale get locale => _locale;
  String? get apiKey => _apiKey;

  void setLocale(AppLocale locale) {
    _locale = locale;
    notifyListeners();
  }

  void setApiKey(String key) {
    _apiKey = key;
    notifyListeners();
  }
}
