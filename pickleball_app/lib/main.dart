import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_colors.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/main_layout.dart';
import 'screens/booking/booking_screen.dart';
import 'screens/tournament/tournament_screen.dart';
import 'screens/wallet/wallet_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/notification/notification_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..checkAuthStatus(),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final GoRouter _router;
  bool _routerInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Only initialize router once
    if (!_routerInitialized) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      _router = GoRouter(
        refreshListenable: authProvider,
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/register',
            builder: (context, state) => const RegisterScreen(),
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          ShellRoute(
            builder: (context, state, child) {
              return MainLayout(child: child);
            },
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
              GoRoute(
                path: '/booking',
                builder: (context, state) => const BookingScreen(),
              ),
              GoRoute(
                path: '/tournaments',
                builder: (context, state) => const TournamentScreen(),
              ),
              GoRoute(
                path: '/wallet',
                builder: (context, state) => const WalletScreen(),
              ),
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
              GoRoute(
                path: '/notifications',
                builder: (context, state) => const NotificationScreen(),
              ),
            ],
          ),
        ],
        redirect: (context, state) {
          final isAuthenticated = authProvider.isAuthenticated;
          final isLoggingIn = state.matchedLocation == '/login';
          final isRegistering = state.matchedLocation == '/register';
          final isAdminRoute = state.matchedLocation.startsWith('/admin');
          final isAdminUser = authProvider.user?.role == 'Admin';

          if (!isAuthenticated && !isLoggingIn && !isRegistering) {
            return '/login';
          }

          if (isAuthenticated && (isLoggingIn || isRegistering)) {
            return '/home';
          }

          if (isAdminRoute && !isAdminUser) {
            return '/home';
          }

          return null;
        },
      );
      
      _routerInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Show loading indicator while checking auth status
    if (authProvider.isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Pickleball Club',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
