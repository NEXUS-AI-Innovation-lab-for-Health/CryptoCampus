import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/blockchain_provider.dart';
import 'providers/listings_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/messaging_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/balance/balance_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/shop/shop_screen.dart';
import 'screens/shop/listing_detail_screen.dart';
import 'screens/create_request/create_request_screen.dart';
import 'screens/bookings/bookings_screen.dart';
import 'screens/availability/availability_screen.dart';
import 'screens/favorites/favorites_screen.dart';
import 'screens/my_listings/my_listings_screen.dart';
import 'screens/messages/conversations_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('fr_FR', null);
  Intl.defaultLocale = 'fr_FR';
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
        ChangeNotifierProvider(create: (_) => ListingEngagementProvider()),
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
        ChangeNotifierProxyProvider<AuthProvider, MessagingProvider>(
          create: (_) => MessagingProvider(),
          update: (_, auth, messaging) {
            final messagingProvider = messaging ?? MessagingProvider();
            if (auth.isAuthenticated) {
              messagingProvider.connect();
              messagingProvider.loadConversations();
            } else {
              messagingProvider.disconnect();
            }
            return messagingProvider;
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
          '/profile': (context) => const ProfileScreen(),
          '/shop': (context) => const ShopScreen(),
          '/listing-detail': (context) => const ListingDetailScreen(),
          '/create-request': (context) => const CreateRequestScreen(),
          '/bookings': (context) => const BookingsScreen(),
          '/availability': (context) => const AvailabilityScreen(),
          '/favorites': (context) => const FavoritesScreen(),
          '/my-listings': (context) => const MyListingsScreen(),
          '/messages': (context) => const ConversationsScreen(),
        },
      ),
    );
  }
}
