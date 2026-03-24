import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/blockchain_provider.dart';
import 'providers/listings_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/balance/balance_screen.dart';
import 'screens/shop/shop_screen.dart';
import 'screens/shop/listing_detail_screen.dart';
import 'screens/create_request/create_request_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BlockchainProvider()),
        ChangeNotifierProvider(create: (_) => ListingsProvider()),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (_) => NotificationProvider(navigatorKey),
          update: (_, auth, notif) {
            final notificationProvider = notif ?? NotificationProvider(navigatorKey);
            if (auth.isAuthenticated && auth.currentUser != null) {
              notificationProvider.startPolling(auth.currentUser!.userId, auth.currentUser!.email);
            } else {
              notificationProvider.stopPolling();
            }
            return notificationProvider;
          },
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'CryptoCampus',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF),
            primary: const Color(0xFF6C63FF),
            secondary: const Color(0xFF4CAF50),
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/balance': (context) => const BalanceScreen(),
          '/shop': (context) => const ShopScreen(),
          '/listing-detail': (context) => const ListingDetailScreen(),
          '/create-request': (context) => const CreateRequestScreen(),
        },
      ),
    );
  }
}
