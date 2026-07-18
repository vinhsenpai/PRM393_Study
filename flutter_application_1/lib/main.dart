import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';

import 'theme/app_theme.dart';
import 'providers/account_provider.dart';
import 'providers/cart_provider.dart';

import 'package:hive_flutter/hive_flutter.dart';

import 'hive/cart_item_adapter.dart';

import 'providers/auth_provider.dart';

import 'screens/login_screen.dart';
import 'navigation/buyer_navigation_shell.dart';
import 'navigation/seller_navigation_shell.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/email_verification_required_screen.dart';
import 'services/notification_service.dart';

import 'models/user.dart';

// Global navigation key for navigating from FCM notification clicks without context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // IMPORTANT: Register Hive adapters before using Hive boxes.
  // Using handwritten adapter (no Hive code generation).
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(CartItemAdapter());
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    // Set the background messaging handler early on, as a top-level function
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // Khởi tạo Firebase Storage rõ ràng
  try {
    final storage = FirebaseStorage.instance;
    debugPrint('Firebase Storage initialized: ${storage.bucket}');
  } catch (e) {
    debugPrint('Error initializing Firebase Storage: $e');
  }

  // Initialize notification service and request permission
  if (!kIsWeb) {
    try {
      await NotificationService().initNotifications();
      debugPrint('Notification Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Notification Service: $e');
    }
  }

  runApp(const GameAcctHubApp());
}

class GameAcctHubApp extends StatelessWidget {
  const GameAcctHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (context) => CartProvider()..loadCart()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'GameAcctHub',
        theme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        debugShowCheckedModeBanner: false,
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (!auth.isAuthenticated || auth.currentUser == null) {
              return const LoginScreen();
            }

            // Always check/reload before deciding access
            return FutureBuilder<bool>(
              future: auth.isEmailVerified(),

              builder: (context, snapshot) {
                // While checking, show loading indicator
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                // If there was an error checking verification status
                if (snapshot.hasError) {
                  return Scaffold(
                    body: Center(
                      child: Text(
                        'Error checking verification status: ${snapshot.error}',
                      ),
                    ),
                  );
                }

                // If email is verified, proceed to home screen
                if (snapshot.data == true) {
                  switch (auth.currentUser?.role) {
                    case UserRole.admin:
                      return const AdminDashboardScreen();

                    case UserRole.seller:
                      return SellerNavigationShell(key: SellerNavigationShell.navKey);

                    case UserRole.buyer:
                    default:
                      return BuyerNavigationShell(key: BuyerNavigationShell.navKey);
                  }
                }

                // If email is not verified, show verification required screen
                return const EmailVerificationRequiredScreen();
              },
            );
          },
        ),
      ),
    );
  }
}
