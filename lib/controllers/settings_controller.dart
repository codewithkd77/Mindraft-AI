import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class SettingsController extends ChangeNotifier {
  final SharedPreferences _prefs;

  // Constructor
  SettingsController(this._prefs);

  // Language settings
  String get currentLanguage => _prefs.getString('language') ?? 'en';
  Future<void> setLanguage(String languageCode) async {
    await _prefs.setString('language', languageCode);
    notifyListeners();
  }

  // Theme settings
  bool get isDarkMode => _prefs.getBool('isDarkMode') ?? false;
  Future<void> toggleTheme() async {
    await _prefs.setBool('isDarkMode', !isDarkMode);
    notifyListeners();
  }

  // App version
  String get appVersion => '1.0.0';

  // Share app
  Future<void> shareApp() async {
    await Share.share('Check out this amazing app!', subject: 'App Invitation');
  }

  // Rate app
  Future<void> rateApp() async {
    final Uri url =
        Uri.parse('https://play.google.com/store/apps/details?id=your.app.id');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // Open privacy policy
  Future<void> openPrivacyPolicy() async {
    final Uri url = Uri.parse('https://your-privacy-policy-url.com');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // Open terms of service
  Future<void> openTermsOfService() async {
    final Uri url = Uri.parse('https://your-terms-of-service-url.com');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // Open help center
  Future<void> openHelpCenter() async {
    final Uri url = Uri.parse('https://your-help-center-url.com');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // Logout
  Future<void> logout() async {
    await _prefs.clear();
    notifyListeners();
  }
}
