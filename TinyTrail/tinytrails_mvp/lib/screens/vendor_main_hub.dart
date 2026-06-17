import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/theme.dart';
import '../services/firebase_service.dart';
import '../widgets/vendor_ai_chat.dart';
import 'vendor_menu_tab.dart';
import 'vendor_orders_tab.dart';
import 'vendor_dashboard_tab.dart';
import 'vendor_profile_tab.dart';
import 'vendor_offers_screen.dart';

class VendorMainHub extends StatefulWidget {
  const VendorMainHub({super.key});

  @override
  State<VendorMainHub> createState() => _VendorMainHubState();
}

class _VendorMainHubState extends State<VendorMainHub> {
  int _currentIndex = 0;
  String? _vendorId;
  String _vendorCategory = 'non-food';

  @override
  void initState() {
    super.initState();
    _loadVendorData();
  }

  Future<void> _loadVendorData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await firebaseService.getUserData(user.uid);
      if (userData != null && mounted) {
        setState(() {
          _vendorId = user.uid;
          _vendorCategory = userData.vendorCategory;
        });
      }
    }
  }

  List<Widget> get _screens => [
    const VendorDashboardTab(),
    const VendorMenuTab(),
    const VendorOrdersTab(),
    const VendorOffersScreen(),
    const VendorProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TinyTrailsColors.white,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          // Trail AI Chat Widget
          if (_vendorId != null)
            VendorAIChatWidget(
              vendorId: _vendorId!,
              vendorCategory: _vendorCategory,
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: TinyTrailsColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
                _buildNavItem(1, Icons.restaurant_menu_outlined, Icons.restaurant_menu, 'Menu'),
                _buildNavItem(2, Icons.receipt_long_outlined, Icons.receipt_long, 'Orders'),
                _buildNavItem(3, Icons.local_offer_outlined, Icons.local_offer, 'Offers'),
                _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? TinyTrailsColors.emerald50 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? TinyTrailsColors.emeraldGreen : TinyTrailsColors.gray400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? TinyTrailsColors.emeraldGreen : TinyTrailsColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
