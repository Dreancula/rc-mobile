import 'package:flutter/material.dart';
import '../database/hive_db.dart';
import 'translations.dart';

class LanguageProvider extends ChangeNotifier {
  AppLocale _locale = AppLocale.en;

  AppLocale get locale => _locale;
  Locale get flutterLocale => Locale(_locale.name);

  LanguageProvider() {
    _loadSavedLanguage();
  }

  void _loadSavedLanguage() {
    final saved = HiveDb.instance.getLanguage();
    _locale = saved == 'id' ? AppLocale.id : AppLocale.en;
  }

  void setLocale(AppLocale newLocale) {
    if (_locale == newLocale) return;
    _locale = newLocale;
    HiveDb.instance.saveLanguage(newLocale.name);
    notifyListeners();
  }

  void toggleLanguage() {
    setLocale(_locale == AppLocale.en ? AppLocale.id : AppLocale.en);
  }
}
