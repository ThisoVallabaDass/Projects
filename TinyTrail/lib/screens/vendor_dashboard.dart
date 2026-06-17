import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/theme.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard>
    with TickerProviderStateMixin {
  bool _isLive = false;
  int _currentNavIndex = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Placeholder menu items
  final List<Map<String, dynamic>> _menuItems = [
    {'name': 'Homemade Murukku', 'price': 50, 'inStock': true},
    {'name': 'Crispy Vadai', 'price': 30, 'inStock': true},
    {'name': 'Filter Coffee', 'price': 20, 'inStock': false},
    {'name': 'Samosa (2 pcs)', 'price': 40, 'inStock': true},
  ];

  // Placeholder orders
  final List<Map<String, dynamic>> _activeOrders = [
    {
      'id': '#TT2847',
      'item': 'Homemade Murukku x2',
      'price': 100,
      'customer': 'Rahul K.',
      'time': '2 min ago',
    },
    {
      'id': '#TT2846',
      'item': 'Crispy Vadai x3',
      'price': 90,
      'customer': 'Priya S.',
      'time': '5 min ago',
    },
    {
      'id': '#TT2845',
      'item': 'Samosa (2 pcs) x1',
      'price': 40,
      'customer': 'Ahmed J.',
      'time': '8 min ago',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initPulseAnimation();
  }

  void _initPulseAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startHygieneCheck() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HygieneCheckSheet(
        onComplete: () {
          Navigator.pop(context);
          setState(() {
            _isLive = true;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TinyTrailsColors.white,
      body: Stack(
        children: [
          // Main Dashboard Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildMenuSection(),
                        const SizedBox(height: 28),
                        _buildOrdersSection(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Blur overlay when not live
          if (!_isLive) _buildGoLiveOverlay(),
          // Bottom Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNav(),
          ),
        ],
      ),
      floatingActionButton: _isLive
          ? FloatingActionButton(
              onPressed: () {},
              backgroundColor: TinyTrailsColors.emeraldGreen,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: TinyTrailsColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _isLive
                  ? TinyTrailsColors.emerald50
                  : TinyTrailsColors.gray100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isLive
                    ? TinyTrailsColors.emeraldGreen
                    : TinyTrailsColors.gray300,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isLive
                        ? TinyTrailsColors.emeraldGreen
                        : TinyTrailsColors.gray400,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isLive ? 'LIVE' : 'OFFLINE',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _isLive
                        ? TinyTrailsColors.emeraldGreen
                        : TinyTrailsColors.gray500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Trust Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  TinyTrailsColors.badgeGold.withValues(alpha: 0.15),
                  TinyTrailsColors.badgeGold.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: TinyTrailsColors.badgeGold.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🛡️', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  'Tier 2: Licensed',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: TinyTrailsColors.charcoal,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Settings
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.settings_outlined,
              color: TinyTrailsColors.gray500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Menu',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: TinyTrailsColors.charcoal,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/vendor-menu-manager');
              },
              icon: Icon(
                Icons.edit_outlined,
                size: 18,
                color: TinyTrailsColors.emeraldGreen,
              ),
              label: Text(
                'Edit All',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: TinyTrailsColors.emeraldGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(_menuItems.length, (index) {
          final item = _menuItems[index];
          return _buildMenuItem(item, index);
        }),
      ],
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TinyTrailsColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TinyTrailsColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Item Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: TinyTrailsColors.emerald50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.restaurant_menu,
              color: TinyTrailsColors.emeraldGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: TinyTrailsColors.charcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${item['price']}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: TinyTrailsColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          // Stock Toggle
          Column(
            children: [
              Switch(
                value: item['inStock'],
                onChanged: (value) {
                  setState(() {
                    _menuItems[index]['inStock'] = value;
                  });
                },
                activeThumbColor: TinyTrailsColors.emeraldGreen,
                activeTrackColor: TinyTrailsColors.emerald200,
              ),
              Text(
                item['inStock'] ? 'In Stock' : 'Out',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: item['inStock']
                      ? TinyTrailsColors.emeraldGreen
                      : TinyTrailsColors.gray400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Orders',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: TinyTrailsColors.charcoal,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: TinyTrailsColors.emerald50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_activeOrders.length} pending',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: TinyTrailsColors.emeraldGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(_activeOrders.length, (index) {
          final order = _activeOrders[index];
          return _buildOrderCard(order);
        }),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TinyTrailsColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order['id'],
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: TinyTrailsColors.emeraldGreen,
                ),
              ),
              Text(
                order['time'],
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: TinyTrailsColors.gray400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: TinyTrailsColors.gray100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    order['customer'][0],
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: TinyTrailsColors.charcoal,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['customer'],
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: TinyTrailsColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order['item'],
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: TinyTrailsColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${order['price']}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: TinyTrailsColors.charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TinyTrailsColors.error,
                    side: const BorderSide(color: TinyTrailsColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Decline',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TinyTrailsColors.emeraldGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Accept Order',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoLiveOverlay() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: TinyTrailsColors.white.withValues(alpha: 0.85),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsating button
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: GestureDetector(
                      onTap: _startHygieneCheck,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: TinyTrailsColors.emeraldGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: TinyTrailsColors.emeraldGreen
                                  .withValues(alpha: 0.4),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '🟢',
                              style: TextStyle(fontSize: 36),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start My Shift',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '(Hygiene Check)',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                'Complete hygiene verification to go live',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: TinyTrailsColors.gray500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
            _buildNavItem(1, Icons.inventory_2_outlined, Icons.inventory_2, 'Products'),
            _buildNavItem(2, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Earnings'),
            _buildNavItem(3, Icons.person_outline, Icons.person, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentNavIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
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
              color: isActive
                  ? TinyTrailsColors.emeraldGreen
                  : TinyTrailsColors.gray400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? TinyTrailsColors.emeraldGreen
                    : TinyTrailsColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hygiene Check Bottom Sheet
class _HygieneCheckSheet extends StatefulWidget {
  final VoidCallback onComplete;

  const _HygieneCheckSheet({required this.onComplete});

  @override
  State<_HygieneCheckSheet> createState() => _HygieneCheckSheetState();
}

class _HygieneCheckSheetState extends State<_HygieneCheckSheet> {
  bool _isScanning = true;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _isComplete = true;
        });
        Future.delayed(const Duration(milliseconds: 1500), () {
          widget.onComplete();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: TinyTrailsColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: TinyTrailsColors.gray300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          // AI Camera Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _isComplete
                  ? TinyTrailsColors.emerald50
                  : TinyTrailsColors.gray100,
              shape: BoxShape.circle,
            ),
            child: _isScanning
                ? const Center(
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          TinyTrailsColors.emeraldGreen,
                        ),
                      ),
                    ),
                  )
                : Icon(
                    Icons.check_circle,
                    size: 64,
                    color: TinyTrailsColors.emeraldGreen,
                  ),
          ),
          const SizedBox(height: 28),
          // Status Text
          Text(
            _isScanning ? 'Scanning workspace...' : '96% Hygiene Score',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: TinyTrailsColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isScanning
                ? 'AI is analyzing your cooking area'
                : 'You are LIVE!',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _isComplete
                  ? TinyTrailsColors.emeraldGreen
                  : TinyTrailsColors.gray500,
              fontWeight: _isComplete ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
