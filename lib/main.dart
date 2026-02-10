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
        title: 'Oil Manager',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1976D2),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: const CardThemeData(
            elevation: 2,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
