import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/app_state.dart';
import 'providers/data_provider.dart';
import 'theme/handora_theme.dart';
import 'widgets/app_header.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/new_order_toast.dart';
import 'widgets/order_shipped_modal.dart';
import 'screens/home_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/growth_screen.dart';
import 'screens/help_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env)
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  runApp(const HandoraApp());
}

class HandoraApp extends StatelessWidget {
  const HandoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
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
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: app.isDark ? ThemeMode.dark : ThemeMode.light,
      home: const _Shell(),
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
