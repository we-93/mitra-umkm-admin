import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mitra_umkm_admin/theme/admin_theme.dart';
import 'package:mitra_umkm_admin/screens/login_screen.dart';
import 'package:mitra_umkm_admin/screens/admin_dashboard.dart';
import 'package:mitra_umkm_admin/screens/users_screen.dart';
import 'package:mitra_umkm_admin/screens/lms_screen.dart';
import 'package:mitra_umkm_admin/screens/ai_config_screen.dart';
import 'package:mitra_umkm_admin/screens/products_config_screen.dart';
import 'package:mitra_umkm_admin/screens/settings_screen.dart';
import 'package:mitra_umkm_admin/screens/notification_screen.dart';
import 'package:mitra_umkm_admin/screens/invoices_screen.dart';
import 'package:mitra_umkm_admin/layout/admin_layout.dart';
import 'package:mitra_umkm_admin/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.red,
          child: SingleChildScrollView(
            child: Text(
              'ERROR TERJADI:\n${details.exceptionAsString()}\n\nSTACK TRACE:\n${details.stack.toString()}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  };

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MitraUmkmAdminApp());
}

class MitraUmkmAdminApp extends StatefulWidget {
  const MitraUmkmAdminApp({Key? key}) : super(key: key);

  static _MitraUmkmAdminAppState of(BuildContext context) => 
      context.findAncestorStateOfType<_MitraUmkmAdminAppState>()!;

  @override
  State<MitraUmkmAdminApp> createState() => _MitraUmkmAdminAppState();
}

class _MitraUmkmAdminAppState extends State<MitraUmkmAdminApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MITRA UMKM Admin Panel',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AdminTheme.themeData.copyWith(
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.light().textTheme,
        ),
      ),
      darkTheme: AdminTheme.darkThemeData.copyWith(
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          final bool isLoggedIn = snapshot.hasData;

          if (!isLoggedIn) {
            return LoginScreen();
          }

          // If logged in, we show a nested Navigator to handle the admin routing properly
          // without conflicting with the root MaterialApp.
          return Navigator(
            initialRoute: '/',
            onGenerateRoute: (settings) {
              Widget page;
              switch (settings.name) {
                case '/users':
                  page = UsersScreen();
                  break;
                case '/invoices':
                  page = InvoicesScreen();
                  break;
                case '/lms':
                  page = LmsScreen();
                  break;
                case '/ai':
                  page = AiConfigScreen();
                  break;
                case '/products_config':
                  page = ProductsConfigScreen();
                  break;
                case '/settings':
                  page = SettingsScreen();
                  break;
                case '/notifications':
                  page = NotificationScreen();
                  break;
                case '/':
                case '/dashboard':
                default:
                  page = AdminDashboard();
                  break;
              }

              return PageRouteBuilder(
                settings: settings,
                pageBuilder: (context, animation, secondaryAnimation) => AdminLayout(
                  currentRoute: settings.name ?? '/',
                  child: page,
                ),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              );
            },
          );
        },
      ),
    );
  }
}
