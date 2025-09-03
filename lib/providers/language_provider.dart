import 'package:flutter/material.dart';
import '../services/language_service.dart';

class LanguageProvider with ChangeNotifier {
  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  Future<void> loadLanguage() async {
    _currentLocale = await LanguageService.getCurrentLanguage();
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    await LanguageService.setLanguage(languageCode);
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }

  bool get isEnglish => _currentLocale.languageCode == 'en';
  bool get isSinhala => _currentLocale.languageCode == 'si';
}