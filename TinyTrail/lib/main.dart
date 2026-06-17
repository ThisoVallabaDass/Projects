import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

import 'theme/theme.dart';
import 'screens/login_screen.dart';
import 'screens/customer_home.dart';
import 'screens/vendor_dashboard.dart';
import 'screens/vendor_menu_manager.dart';
import 'screens/customer_vendor_view.dart';
import 'services/demo_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Create demo accounts (only on first run or if they don't exist)
  try {
    await DemoDataService.createDemoAccounts();
    // Also refresh existing demo accounts to ensure correct categories
    await DemoDataService.refreshDemoAccounts();
    // Specifically fix the craft demo account category issue
    await DemoDataService.fixCraftDemoAccount();
  } catch (e) {
    print('Demo account creation/refresh error (ignored): $e');
  }

  // Set system UI overlay style for a clean white status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: TinyTrailsColors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const TinyTrailsApp());
}

class TinyTrailsApp extends StatelessWidget {
  const TinyTrailsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TinyTrails',
      debugShowCheckedModeBanner: false,
      theme: TinyTrailsTheme.consumerTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/customer-home': (context) => const CustomerHome(),
        '/vendor-dashboard': (context) => const VendorDashboard(),
        '/vendor-menu-manager': (context) => const VendorMenuManager(),
      },
      onGenerateRoute: (settings) {
        // Handle vendor view with arguments
        if (settings.name == '/customer-vendor-view') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => CustomerVendorView(
              vendorId: args?['vendorId'] ?? '',
              vendorName: args?['vendorName'] ?? 'Vendor',
              businessType: args?['businessType'],
              hygieneScore: args?['hygieneScore'] ?? 95,
              trustTier: args?['trustTier'] ?? 'blue',
            ),
          );
        }
        return null;
      },
    );
  }
}
