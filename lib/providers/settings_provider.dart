import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  // ── Keys ──────────────────────────────────────────────────────────────────
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyNotifications = 'notifications';
  static const String _keyOrderUpdates = 'order_updates';
  static const String _keyPromoAlerts = 'promo_alerts';
  static const String _keyEmailNotifs = 'email_notifs';
  static const String _keyFontSize = 'font_size'; // 0=Small 1=Medium 2=Large
  static const String _keyCurrency = 'currency'; // "Rs" / "USD"
  static const String _keyLanguage = 'language'; // "English" / "Urdu"
  static const String _keyBiometric = 'biometric';
  static const String _keySaveAddress = 'save_address';
  static const String _keyNewsletterSub = 'newsletter';

  // ── State ─────────────────────────────────────────────────────────────────
  bool _darkMode = false;
  bool _notifications = true;
  bool _orderUpdates = true;
  bool _promoAlerts = true;
  bool _emailNotifs = false;
  int _fontSizeIndex = 1; // Medium
  String _currency = 'Rs';
  String _language = 'English';
  bool _biometric = false;
  bool _saveAddress = true;
  bool _newsletter = false;

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get darkMode => _darkMode;
  bool get notifications => _notifications;
  bool get orderUpdates => _orderUpdates;
  bool get promoAlerts => _promoAlerts;
  bool get emailNotifs => _emailNotifs;
  int get fontSizeIndex => _fontSizeIndex;
  String get currency => _currency;
  String get language => _language;
  bool get biometric => _biometric;
  bool get saveAddress => _saveAddress;
  bool get newsletter => _newsletter;

  ThemeMode get themeMode => _darkMode ? ThemeMode.dark : ThemeMode.light;

  // ── Load from SharedPreferences ───────────────────────────────────────────
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool(_keyDarkMode) ?? false;
    _notifications = prefs.getBool(_keyNotifications) ?? true;
    _orderUpdates = prefs.getBool(_keyOrderUpdates) ?? true;
    _promoAlerts = prefs.getBool(_keyPromoAlerts) ?? true;
    _emailNotifs = prefs.getBool(_keyEmailNotifs) ?? false;
    _fontSizeIndex = prefs.getInt(_keyFontSize) ?? 1;
    _currency = prefs.getString(_keyCurrency) ?? 'Rs';
    _language = prefs.getString(_keyLanguage) ?? 'English';
    _biometric = prefs.getBool(_keyBiometric) ?? false;
    _saveAddress = prefs.getBool(_keySaveAddress) ?? true;
    _newsletter = prefs.getBool(_keyNewsletterSub) ?? false;
    notifyListeners();
  }

  // ── Setters ───────────────────────────────────────────────────────────────
  Future<void> setDarkMode(bool val) async {
    _darkMode = val;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, val);
  }

  Future<void> setNotifications(bool val) async {
    _notifications = val;
    // when master toggle off → turn sub-options off too
    if (!val) {
      _orderUpdates = false;
      _promoAlerts = false;
    }
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, val);
    await prefs.setBool(_keyOrderUpdates, _orderUpdates);
    await prefs.setBool(_keyPromoAlerts, _promoAlerts);
  }

  Future<void> setOrderUpdates(bool val) async {
    _orderUpdates = val;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOrderUpdates, val);
  }

  Future<void> setPromoAlerts(bool val) async {
    _promoAlerts = val;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPromoAlerts, val);
  }

  Future<void> setEmailNotifs(bool val) async {
    _emailNotifs = val;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEmailNotifs, val);
  }

  Future<void> setFontSize(int index) async {
    _fontSizeIndex = index;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFontSize, index);
  }

  Future<void> setCurrency(String val) async {
    _currency = val;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, val);
  }

  Future<void> setLanguage(String val) async {
    _language = val;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, val);
  }

  Future<void> setBiometric(bool val) async {
    _biometric = val;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometric, val);
  }

  Future<void> setSaveAddress(bool val) async {
    _saveAddress = val;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySaveAddress, val);
  }

  Future<void> setNewsletter(bool val) async {
    _newsletter = val;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNewsletterSub, val);
  }

  Future<void> resetAll() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.clear();

    _darkMode = false;
    _notifications = true;
    _orderUpdates = true;
    _promoAlerts = true;
    _emailNotifs = false;
    _fontSizeIndex = 1;
    _currency = 'Rs';
    _language = 'English';
    _biometric = false;
    _saveAddress = true;
    _newsletter = false;

    notifyListeners();
  }
}
