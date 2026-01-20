import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:mehran_football_academy/auth_screens/password_recovery/enter_email.dart';
import 'package:mehran_football_academy/auth_screens/password_recovery/new_password.dart';
import 'package:mehran_football_academy/auth_screens/splash_screen.dart';
import 'package:mehran_football_academy/players_screens/player_profile.dart';
import 'package:mehran_football_academy/players_screens/fee_related_screens/fee_section_screen.dart';
import 'package:mehran_football_academy/auth_screens/login_screen.dart';
import 'package:mehran_football_academy/utils/local_storage.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:mehran_football_academy/chat_module/chat_home_screen.dart';
import 'package:mehran_football_academy/chat_module/models/profile.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mehran_football_academy/my_components/admin_nav_bar.dart';
import 'package:mehran_football_academy/my_media/notifications.dart';
import 'chat_module/private_chat_page.dart';
import 'my_components/player_nav_bar.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (required for OneSignal and other services)
  await Firebase.initializeApp();

  // Defer other initializations to avoid blocking the main thread
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri?>? _linkSubscription;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _handleDeepLinks();
    _setupOneSignal();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Initialize OneSignal
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize("23241790-a833-4f2e-ae6e-a9c24d7d002e");
    OneSignal.consentRequired(false);
    OneSignal.Notifications.requestPermission(true);

    // Initialize Supabase
    await supabase.Supabase.initialize(
      url: "https://muxyklfwehoeifagwmzg.supabase.co",
      anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im11eHlrbGZ3ZWhvZWlmYWd3bXpnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA0OTY1MzksImV4cCI6MjA1NjA3MjUzOX0.6uGCn6jvHmIXbwKXt9_RcZE4hNKJ5yAZFPByHj1reLg",
    );

    // Initialize LocalStorage and Connectivity
    await LocalStorage.init();
    final connectivity = Connectivity();
    await connectivity.checkConnectivity();
  }

  void _setupOneSignal() {
    // Handle notification received in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.notification.display();
    });

    // Handle notification click
    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      if (data != null && data['screen'] != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigatorKey.currentState?.pushNamed('/notifications');
        });
      }
    });

    // Handle permission changes
    OneSignal.Notifications.addPermissionObserver((state) {
      print("Notification permission state: $state");
    });
  }

  void _handleDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null &&
          initialUri.scheme == 'com.mehranfootballacademy' &&
          initialUri.host == 'reset-password') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigatorKey.currentState?.pushNamed('/newPassword');
        });
      }
    } catch (e) {
      print('Error handling initial deep link: $e');
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null &&
          uri.scheme == 'com.mehranfootballacademy' &&
          uri.host == 'reset-password') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigatorKey.currentState?.pushNamed('/newPassword');
        });
      }
    }, onError: (err) {
      print('Error handling deep link stream: $err');
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mehran Football Academy',
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Rubik',
        appBarTheme: const AppBarTheme(
          color: Colors.blue,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/adminHome': (context) => const AdminNavBar(),
        '/playerHome': (context) => const PlayerNavBar(),
        '/feeSection': (context) => const FeeSectionScreen(),
        '/chatHome': (context) => const ChatHomeScreen(),
        '/enterEmail': (context) => const EnterEmail(),
        '/newPassword': (context) => const NewPassword(),
        '/notifications': (context) => const Notifications(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/playerProfile') {
          return MaterialPageRoute(builder: (context) => const PlayerProfile());
        }
        if (settings.name == '/privateChat') {
          final args = settings.arguments as Profile?;
          if (args != null) {
            return MaterialPageRoute(
              builder: (context) => PrivateChatPage(receiverProfile: args),
            );
          }
        }
        return null;
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) =>
          const Scaffold(body: Center(child: Text('Page Not Found'))),
        );
      },
    );
  }
}