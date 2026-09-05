import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/strings.dart';

enum NavTab { home, catalog, growth, help }

/// Handles UI-level state: active tab, language, theme, auth, overlay visibility.
class AppState extends ChangeNotifier {
  Language _language = Language.en;
  NavTab _tab = NavTab.home;
  bool _isDark = false;
  bool _showToast = true;
  bool _showShipped = false;
  bool _isAuthenticated = false;

  // User profile (populated from Supabase session)
  String? _userDisplayName;
  String? _userEmail;

  bool get isAuthenticated => _isAuthenticated;
  String? get userDisplayName => _userDisplayName;
  String? get userEmail => _userEmail;

  /// Current Supabase auth user id (null for mock-OTP or unauthenticated).
  String? get currentUserId {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }
  Language get language => _language;
  NavTab get tab => _tab;
  bool get isDark => _isDark;
  bool get showToast => _showToast;
  bool get showShipped => _showShipped;

  DashboardStrings get strings => kStrings[_language]!;

  /// Call after Supabase auth succeeds or on session restore.
  /// Reads display name and email from the current Supabase user.
  void loginFromSession() {
    _isAuthenticated = true;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _userEmail = user.email;
        final meta = user.userMetadata;
        final name = meta?['full_name'] as String?;
        _userDisplayName = (name != null && name.isNotEmpty) ? name : _userEmail;
      }
    } catch (_) {
      // Supabase may not be initialized
    }
    notifyListeners();
  }

  /// Legacy login (used by OTP flow which has no Supabase session)
  void login() {
    _isAuthenticated = true;
    notifyListeners();
  }

  /// Sign out: clears Supabase session and resets local state.
  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    _isAuthenticated = false;
    _userDisplayName = null;
    _userEmail = null;
    _tab = NavTab.home;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _userDisplayName = null;
    _userEmail = null;
    notifyListeners();
  }

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
