import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/theme.dart';
import 'package:tinytrails_mvp/screens/customer_cart_tab.dart';
import 'package:tinytrails_mvp/screens/customer_home_tab.dart';
import 'package:tinytrails_mvp/screens/customer_map_tab.dart';
import 'package:tinytrails_mvp/screens/customer_profile_tab.dart';

class CustomerMainHub extends StatefulWidget {
  const CustomerMainHub({super.key});

  @override
  State<CustomerMainHub> createState() => _CustomerMainHubState();
}

class _CustomerMainHubState extends State<CustomerMainHub> {
  int _currentIndex = 0;

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const CustomerHomeTab();
      case 1:
        return const CustomerMapTab();
      case 2:
        return const CustomerCartTab();
      case 3:
        return const CustomerProfileTab();
      default:
        return const CustomerHomeTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TinyTrailsColors.white,
      body: _buildCurrentScreen(),
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
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                _buildNavItem(1, Icons.map_outlined, Icons.map, 'Live Map'),
                _buildNavItem(2, Icons.shopping_cart_outlined, Icons.shopping_cart, 'Cart'),
                _buildNavItem(3, Icons.person_outline, Icons.person, 'Profile'),
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
          color: isActive ? TinyTrailsColors.royalBlue50 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? TinyTrailsColors.royalBlue : TinyTrailsColors.gray400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? TinyTrailsColors.royalBlue : TinyTrailsColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


