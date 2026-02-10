import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/role_selector_screen.dart';
import 'screens/auth/access_pending_page.dart';
import 'screens/customer/customer_home_screen.dart';
import 'screens/driver/driver_home_screen.dart';
import 'screens/dispatcher/dispatcher_home_screen.dart';
import 'screens/backoffice/backoffice_shell.dart';
import 'screens/backoffice/admin/administration_hub.dart';
import 'screens/backoffice/admin/admin_products_page.dart';
import 'screens/backoffice/admin/admin_uco_grades_page.dart';
import 'screens/backoffice/admin/admin_payment_methods_page.dart';
import 'screens/backoffice/admin/admin_order_statuses_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'Oil Manager - Enterprise Cooking Oil Management',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Professional cooking oil industry color scheme
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFF59E0B), // Amber/Golden - represents cooking oil
            primary: const Color(0xFFF59E0B),    // Amber 500
            secondary: const Color(0xFF059669),  // Emerald 600 - eco-friendly/UCO
            tertiary: const Color(0xFF7C3AED),   // Violet 600 - premium
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          
          // AppBar styling
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Color(0xFFF59E0B), // Amber primary
            foregroundColor: Colors.white,
          ),
          
          // Card styling
          cardTheme: CardThemeData(
            elevation: 2,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          
          // Input styling
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          
          // Button styling
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          
          // FloatingActionButton styling
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFFF59E0B),
            foregroundColor: Colors.white,
          ),
        ),
        home: const SplashScreen(),
        routes: {
          '/role-selector': (context) => const RoleSelectorScreen(),
          '/auth/landing': (context) => const LoginScreen(),
          '/auth/access-pending': (context) => const AccessPendingPage(),
          '/login': (context) => const LoginScreen(),
          '/customer/home': (context) => const CustomerHomeScreen(),
          '/driver/home': (context) => const DriverHomeScreen(),
          '/dispatcher/home': (context) => const DispatcherHomeScreen(),
          '/backoffice/dashboard': (context) => const BackofficeShell(),
          '/backoffice/admin/hub': (context) => const AdministrationHub(),
          '/backoffice/admin/products': (context) => const AdminProductsPage(),
          '/backoffice/admin/uco-grades': (context) => const AdminUCOGradesPage(),
          '/backoffice/admin/payment-methods': (context) => const AdminPaymentMethodsPage(),
          '/backoffice/admin/order-statuses': (context) => const AdminOrderStatusesPage(),
        },
      ),
    );
  }
}
