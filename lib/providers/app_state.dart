import 'package:flutter/foundation.dart';
import '../l10n/strings.dart';

enum NavTab { home, catalog, growth, help }

/// Handles UI-level state: active tab, language, theme, overlay visibility.
class AppState extends ChangeNotifier {
  Language _language = Language.en;
  NavTab _tab = NavTab.home;
  bool _isDark = false;
  bool _showToast = true;
  bool _showShipped = false;

  Language get language => _language;
  NavTab get tab => _tab;
  bool get isDark => _isDark;
  bool get showToast => _showToast;
  bool get showShipped => _showShipped;

  DashboardStrings get strings => kStrings[_language]!;

  void setLanguage(Language lang) {
    if (_language == lang) return;
    _language = lang;
    notifyListeners();
  }

  void setTab(NavTab t) {
    if (_tab == t) return;
    _tab = t;
    notifyListeners();
  }

  void toggleDark() {
    _isDark = !_isDark;
    notifyListeners();
  }

  void acceptOrder() {
    _showToast = false;
    _showShipped = true;
    notifyListeners();
  }

  void dismissShipped() {
    _showShipped = false;
    notifyListeners();
  }

  void triggerShipped() {
    _showShipped = true;
    notifyListeners();
  }
}
