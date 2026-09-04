import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/app_state.dart';
import 'providers/data_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/app_header.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/new_order_toast.dart';
import 'widgets/order_shipped_modal.dart';
import 'screens/login_screen.dart';
import 'screens/email_login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/home_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/growth_screen.dart';
import 'screens/help_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style to match Gramin Modernism Ivory theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surfaceIvory,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Load environment variables (.env)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('⚠️ Warning: .env file not found or could not be loaded: $e');
  }

  // Initialize Supabase
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('⚠️ Supabase init warning: $e');
    }
  }

  runApp(const HandoraApp());
}

class HandoraApp extends StatelessWidget {
  const HandoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final appState = AppState();
          // Restore session: if Supabase has an active session, auto-login
          try {
            final session = Supabase.instance.client.auth.currentSession;
            if (session != null) {
              appState.loginFromSession();
            }
            // Listen to auth state changes and sync AppState
            Supabase.instance.client.auth.onAuthStateChange.listen((data) {
              final event = data.event;
              if (event == AuthChangeEvent.signedIn ||
                  event == AuthChangeEvent.tokenRefreshed) {
                if (!appState.isAuthenticated) {
                  appState.loginFromSession();
                }
              } else if (event == AuthChangeEvent.signedOut) {
                if (appState.isAuthenticated) {
                  appState.logout();
                }
              }
            });
          } catch (_) {
            // Supabase may not be initialized if env keys were missing
          }
          return appState;
        }),
        ChangeNotifierProvider(create: (_) {
          final dp = DataProvider();
          dp.init(); // seeds DB on first launch, loads data
          return dp;
        }),
      ],
      child: const _Root(),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return MaterialApp(
      title: 'Handora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: app.isDark ? ThemeMode.dark : ThemeMode.light,
      initialRoute: app.isAuthenticated ? '/' : LoginScreen.routeName,
      routes: {
        '/': (context) => const _Shell(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        EmailLoginScreen.routeName: (context) => const EmailLoginScreen(),
        SignUpScreen.routeName: (context) => const SignUpScreen(),
        OtpVerificationScreen.routeName: (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final phoneNumber =
              args?['phoneNumber'] as String? ?? '+91 98765 43210';
          return OtpVerificationScreen(phoneNumber: phoneNumber);
        },
      },
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.strings;

    final tabIndex = switch (app.tab) {
      NavTab.home    => 0,
      NavTab.catalog => 1,
      NavTab.growth  => 2,
      NavTab.help    => 3,
    };

    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            AppHeader(
              language: app.language,
              onLanguageChange: app.setLanguage,
            ),
            Expanded(
              child: IndexedStack(
                index: tabIndex,
                children: const [
                  HomeScreen(),
                  CatalogScreen(),
                  GrowthScreen(),
                  HelpScreen(),
                ],
              ),
            ),
            BottomNav(active: app.tab, onChange: app.setTab, labels: s.nav),
          ]),

          // Overlays
          Positioned.fill(
            child: OrderShippedModal(
              visible: app.showShipped,
              strings: s,
              onClose: app.dismissShipped,
            ),
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: NewOrderToast(
              visible: app.showToast,
              strings: s,
              onAccept: app.acceptOrder,
            ),
          ),
        ]),
      ),
    );
  }
}
