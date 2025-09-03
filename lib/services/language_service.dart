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
          'preferredLanguage': languageCode,
          'languageUpdatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error saving language to Firestore: $e');
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
        
        if (doc.exists && doc.data()?['preferredLanguage'] != null) {
          return doc.data()!['preferredLanguage'] as String;
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

  // Save language (both locally and to Firestore)
  static Future<void> setLanguage(String languageCode) async {
    await saveLanguageLocally(languageCode);
    await saveLanguageToFirestore(languageCode);
  }

  // Get supported locales
  static List<Locale> getSupportedLocales() {
    return const [
      Locale('en'), // English
      Locale('si'), // Sinhala
    ];
  }

  // Get language name for display
  static String getLanguageName(String code, String currentLanguageCode) {
    switch (code) {
      case 'en':
        return currentLanguageCode == 'si' ? 'English' : 'English';
      case 'si':
        return currentLanguageCode == 'si' ? 'සිංහල' : 'Sinhala';
      default:
        return 'Unknown';
    }
  }
}