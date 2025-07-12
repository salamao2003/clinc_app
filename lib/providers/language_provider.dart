import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  bool _isArabic = false; // Default to English

  bool get isArabic => _isArabic;
  String get languageCode => _isArabic ? 'ar' : 'en';
  
  void toggleLanguage() {
    _isArabic = !_isArabic;
    notifyListeners();
  }
  
  void setLanguage(bool isArabic) {
    if (_isArabic != isArabic) {
      _isArabic = isArabic;
      notifyListeners();
    }
  }
}