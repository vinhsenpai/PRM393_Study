import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'theme/app_theme.dart';
import 'providers/account_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/auth_provider.dart';

import 'screens/login_screen.dart';
import 'screens/buyer_home_screen.dart';
import 'screens/seller_home_screen.dart';
import 'screens/admin_home_screen.dart';

import 'models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
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
          if (!auth.isAuthenticated) {
            return const LoginScreen();
          }

          switch (auth.currentUser?.role) {
            case UserRole.admin:
              return const AdminHomeScreen();

            case UserRole.seller:
              return const SellerHomeScreen();

            case UserRole.buyer:
            default:
              return const BuyerHomeScreen();
          }
        },
      ),
    );
  }
}