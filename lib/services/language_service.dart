import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  static const String _languageSetKey = 'language_set';

  // Save language preference locally
  static Future<void> saveLanguageLocally(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    await prefs.setBool(_languageSetKey, true);
  }

  // Get language preference locally
  static Future<String?> getLanguageLocally() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey);
  }

  // Check if language has been set before
  static Future<bool> isLanguageSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_languageSetKey) ?? false;
  }

  // Save language preference to Firestore
  static Future<void> saveLanguageToFirestore(String languageCode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'language': languageCode,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error saving language to Firestore: $e');
        rethrow; // Re-throw to handle in UI
      }
    }
  }

  // Get language preference from Firestore
  static Future<String?> getLanguageFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data()?['language'] != null) {
          return doc.data()!['language'] as String;
        }
      } catch (e) {
        print('Error getting language from Firestore: $e');
      }
    }
    return null;
  }

  // Get current language with fallback chain
  static Future<Locale> getCurrentLanguage() async {
    // First check local storage
    String? localLang = await getLanguageLocally();
    if (localLang != null) {
      return Locale(localLang);
    }

    // Then check Firestore
    String? firestoreLang = await getLanguageFromFirestore();
    if (firestoreLang != null) {
      // Save to local storage for faster access
      await saveLanguageLocally(firestoreLang);
      return Locale(firestoreLang);
    }

    // Default to English
    return const Locale('en');
  }

  // Save language (both locally and to Firestore) - Enhanced for profile page
  static Future<void> setLanguage(String languageCode) async {
    // Save locally first for immediate UI update
    await saveLanguageLocally(languageCode);
    
    // Then save to Firestore (can be async)
    try {
      await saveLanguageToFirestore(languageCode);
    } catch (e) {
      // If Firestore save fails, still keep local change but notify user
      print('Warning: Language saved locally but failed to sync to cloud: $e');
      rethrow;
    }
  }

  // Get supported locales
  static List<Locale> getSupportedLocales() {
    return const [
      Locale('en'), // English
      Locale('si'), // Sinhala
    ];
  }

  // Get language name for display
  static String getLanguageName(String code, [String? currentLanguageCode]) {
    switch (code) {
      case 'en':
        return 'English';
      case 'si':
        return 'සිංහල';
      default:
        return 'English'; // Default fallback
    }
  }

  // Get language options map for dropdowns/dialogs
  static Map<String, String> getLanguageOptions() {
    return {
      'en': 'English',
      'si': 'සිංහල',
    };
  }

  // Validate if language code is supported
  static bool isLanguageSupported(String languageCode) {
    return ['en', 'si'].contains(languageCode);
  }

  // Force sync language from Firestore to local storage
  static Future<String?> syncLanguageFromCloud() async {
    try {
      String? cloudLanguage = await getLanguageFromFirestore();
      if (cloudLanguage != null && isLanguageSupported(cloudLanguage)) {
        await saveLanguageLocally(cloudLanguage);
        return cloudLanguage;
      }
    } catch (e) {
      print('Error syncing language from cloud: $e');
    }
    return null;
  }

  static Future<void> changeLanguage(String value) async {}
}