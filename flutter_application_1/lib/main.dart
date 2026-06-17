import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'theme/app_theme.dart';
import 'providers/account_provider.dart';
import 'providers/cart_provider.dart';

import 'models/cart_item.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'hive/cart_item_adapter.dart';

import 'providers/auth_provider.dart';

import 'screens/login_screen.dart';
import 'navigation/buyer_navigation_shell.dart';
import 'navigation/seller_navigation_shell.dart';
import 'screens/admin_home_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/email_verification_required_screen.dart';




import 'models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // IMPORTANT: Register Hive adapters before using Hive boxes.
  // Using handwritten adapter (no Hive code generation).
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(CartItemAdapter());
  }




  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(

    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(
          create: (context) => CartProvider()..loadCart(),
        ),

      ],
      child: const GameAcctHubApp(),
    ),
  );
}

class GameAcctHubApp extends StatelessWidget {
  const GameAcctHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GameAcctHub',
      theme: AppTheme.lightTheme,
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
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // If there was an error checking verification status
              if (snapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Text('Error checking verification status: ${snapshot.error}'),
                  ),
                );
              }

              // If email is verified, proceed to home screen
  if (snapshot.data == true) {
  switch (auth.currentUser?.role) {
    case UserRole.admin:
      return const AdminHomeScreen();

    case UserRole.seller:
      return const SellerNavigationShell();

    case UserRole.buyer:
    default:
      return const BuyerNavigationShell();
  }
}

              // If email is not verified, show verification required screen
              return const EmailVerificationRequiredScreen();
            },
          );
        },
      ),
    );
  }
}