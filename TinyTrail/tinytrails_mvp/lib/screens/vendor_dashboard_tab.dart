import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/theme.dart';
import '../services/firebase_service.dart';
import 'vendor_daily_shift_camera.dart';

class VendorDashboardTab extends StatefulWidget {
  const VendorDashboardTab({super.key});

  @override
  State<VendorDashboardTab> createState() => _VendorDashboardTabState();
}

class _VendorDashboardTabState extends State<VendorDashboardTab> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isOnline = false;
  String _vendorCategory = 'non-food';
  String _shopName = 'My Shop';
  bool _isLoading = true;

  // Chennai coordinates
  final LatLng _vendorLocation = const LatLng(13.0827, 80.2707);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVendorData();
  }

  Future<void> _loadVendorData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    final userData = await firebaseService.getUserData(uid);
    if (userData != null && mounted) {
      setState(() {
        _shopName = userData.businessName ?? 'My Shop';
        _vendorCategory = userData.vendorCategory;
        _isOnline = userData.isLive ?? false;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  final Map<String, bool> _inventoryStock = {
    'Paneer Wrap': true,
    'Masala Tea': true,
    'Samosa': false,
    'Lemon Soda': true,
  };

  // Dummy orders for New Requests
  final List<_DummyOrder> _newOrders = [
    _DummyOrder(
      id: 'ORD102',
      items: '2x Mysore Pak, 1x Filter Coffee',
      customerName: 'Priya S.',
      amount: 115.0,
      distance: 1.2,
      customerLocation: const LatLng(13.0900, 80.2750),
    ),
    _DummyOrder(
      id: 'ORD103',
      items: '1x Chicken Biryani',
      customerName: 'Karthik R.',
      amount: 180.0,
      distance: 2.5,
      customerLocation: const LatLng(13.0750, 80.2600),
    ),
    _DummyOrder(
      id: 'ORD104',
      items: '3x Masala Dosa, 2x Idli',
      customerName: 'Ananya M.',
      amount: 220.0,
      distance: 0.8,
      customerLocation: const LatLng(13.0850, 80.2800),
    ),
  ];

  // Dummy orders for Preparing
  final List<_DummyOrder> _preparingOrders = [
    _DummyOrder(
      id: 'ORD099',
      items: '1x Paneer Wrap, 2x Samosa',
      customerName: 'Ravi K.',
      amount: 150.0,
      distance: 1.8,
      customerLocation: const LatLng(13.0780, 80.2650),
      status: 'preparing',
    ),
    _DummyOrder(
      id: 'ORD100',
      items: '4x Masala Tea',
      customerName: 'Deepa V.',
      amount: 80.0,
      distance: 0.5,
      customerLocation: const LatLng(13.0860, 80.2720),
      status: 'ready',
    ),
  ];

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onToggleOnline() async {
    if (_isOnline) {
      // Going offline
      setState(() => _isOnline = false);
      _showSnack('You are now offline', isOnline: false);
      return;
    }

    // Going online - food vendors need hygiene check
    if (_vendorCategory == 'food') {
      print('🍽️ Food vendor going online - hygiene check required');
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VendorDailyShiftCameraScreen()),
      );
      if (result == true && mounted) {
        setState(() => _isOnline = true);
        _showSnack('You are now visible to customers!', isOnline: true);
      }
      return;
    }

    // Non-food vendors (crafts, etc.) go online directly - NO HYGIENE CHECK
    print('🛍️ Non-food vendor going online - skipping hygiene check');
    setState(() => _isOnline = true);
    _showSnack('You are now visible to customers!', isOnline: true);
  }

  void _showSnack(String message, {bool isOnline = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isOnline ? Icons.wifi : Icons.wifi_off,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: isOnline ? TinyTrailsColors.emeraldGreen : TinyTrailsColors.slateGray,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _acceptOrder(_DummyOrder order) {
    setState(() {
      _newOrders.removeWhere((o) => o.id == order.id);
      _preparingOrders.add(order.copyWith(status: 'preparing'));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order #${order.id} accepted! Moved to Preparing.'),
        backgroundColor: TinyTrailsColors.emeraldGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _declineOrder(_DummyOrder order) {
    setState(() {
      _newOrders.removeWhere((o) => o.id == order.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order #${order.id} declined'),
        backgroundColor: TinyTrailsColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _markReady(_DummyOrder order) {
    setState(() {
      final index = _preparingOrders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        _preparingOrders[index] = order.copyWith(status: 'ready');
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order #${order.id} marked as ready!'),
        backgroundColor: TinyTrailsColors.royalBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _markPicked(_DummyOrder order) {
    setState(() {
      _preparingOrders.removeWhere((o) => o.id == order.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order #${order.id} picked up! Customer notified.'),
        backgroundColor: TinyTrailsColors.emeraldGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TinyTrailsColors.gray100,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStatsRow(),
            _buildOrderTrackingMap(),
            _buildOrderTabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNewRequestsList(),
                  _buildPreparingList(),
                ],
              ),
            ),
            _buildInventoryStrip(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TinyTrailsColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: TinyTrailsColors.charcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: TinyTrailsColors.gray400),
                    const SizedBox(width: 3),
                    Text(
                      'Chennai, TN',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: TinyTrailsColors.gray500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _onToggleOnline,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isOnline ? TinyTrailsColors.emeraldGreen : TinyTrailsColors.gray200,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isOnline ? '🟢' : '📴',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isOnline ? 'Online' : 'Go Online',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _isOnline ? Colors.white : TinyTrailsColors.slateGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return SizedBox(
      height: 82,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatCard("Today's Earnings", 'Rs. 2,450', Icons.currency_rupee),
          const SizedBox(width: 10),
          _buildStatCard('Active Orders', '${_newOrders.length + _preparingOrders.length}', Icons.receipt_long_outlined),
          const SizedBox(width: 10),
          _buildStatCard('Profile Views', '47', Icons.visibility_outlined),
        ],
      ),
    );
  }

  // FIXED: Removed hardcoded height, using flexible content sizing
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TinyTrailsColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: TinyTrailsColors.emerald50,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: TinyTrailsColors.emeraldGreen),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: TinyTrailsColors.gray500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              // FIXED: Using FittedBox to prevent overflow
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: TinyTrailsColors.charcoal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      decoration: BoxDecoration(
        color: TinyTrailsColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: TinyTrailsColors.emeraldGreen,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: TinyTrailsColors.emeraldGreen,
        unselectedLabelColor: TinyTrailsColors.gray500,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: [
          Tab(text: 'New (${_newOrders.length})'),
          Tab(text: 'Preparing (${_preparingOrders.length})'),
        ],
      ),
    );
  }

  Widget _buildOrderTrackingMap() {
    final allOrders = [..._newOrders, ..._preparingOrders];

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      height: 140,
      decoration: BoxDecoration(
        color: TinyTrailsColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: _vendorLocation,
                initialZoom: 13.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.tinytrails.mvp',
                ),
                PolylineLayer(
                  polylines: allOrders.map((order) {
                    return Polyline(
                      points: [_vendorLocation, order.customerLocation],
                      strokeWidth: 2,
                      color: TinyTrailsColors.emeraldGreen.withAlpha(150),
                    );
                  }).toList(),
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _vendorLocation,
                      width: 32,
                      height: 32,
                      child: Container(
                        decoration: BoxDecoration(
                          color: TinyTrailsColors.emeraldGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: TinyTrailsColors.emeraldGreen.withAlpha(80),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.storefront, color: Colors.white, size: 16),
                      ),
                    ),
                    ...allOrders.map((order) {
                      return Marker(
                        point: order.customerLocation,
                        width: 26,
                        height: 26,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: TinyTrailsColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on, color: Colors.white, size: 14),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
            // Map label
            Positioned(
              left: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.route, size: 14, color: TinyTrailsColors.emeraldGreen),
                    const SizedBox(width: 4),
                    Text(
                      '${allOrders.length} orders nearby',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: TinyTrailsColors.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewRequestsList() {
    if (_newOrders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No new orders',
        subtitle: 'Take a breather! New orders will appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      itemCount: _newOrders.length,
      itemBuilder: (context, i) => _buildNewOrderCard(_newOrders[i]),
    );
  }

  Widget _buildPreparingList() {
    if (_preparingOrders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.soup_kitchen_outlined,
        title: 'Nothing cooking',
        subtitle: 'Accepted orders will appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      itemCount: _preparingOrders.length,
      itemBuilder: (context, i) => _buildPreparingOrderCard(_preparingOrders[i]),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: TinyTrailsColors.gray300),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: TinyTrailsColors.gray400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: TinyTrailsColors.gray400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewOrderCard(_DummyOrder order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TinyTrailsColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TinyTrailsColors.emerald100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: TinyTrailsColors.warning.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'NEW',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: TinyTrailsColors.warning,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Order #${order.id}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: TinyTrailsColors.charcoal,
                ),
              ),
              const Spacer(),
              Text(
                '${order.distance.toStringAsFixed(1)} km',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: TinyTrailsColors.gray500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.items,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: TinyTrailsColors.slateGray,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Rs. ${order.amount.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: TinyTrailsColors.emerald700,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 38,
                child: OutlinedButton(
                  onPressed: () => _declineOrder(order),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TinyTrailsColors.error,
                    side: const BorderSide(color: TinyTrailsColors.error, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Text('Decline', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: () => _acceptOrder(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TinyTrailsColors.emeraldGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text('Accept', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreparingOrderCard(_DummyOrder order) {
    final isReady = order.status == 'ready';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TinyTrailsColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isReady ? TinyTrailsColors.royalBlue100 : TinyTrailsColors.gray200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isReady ? TinyTrailsColors.royalBlue.withAlpha(25) : TinyTrailsColors.emerald50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isReady ? 'READY' : 'PREPARING',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isReady ? TinyTrailsColors.royalBlue : TinyTrailsColors.emeraldGreen,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Order #${order.id}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: TinyTrailsColors.charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.items,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: TinyTrailsColors.slateGray,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Rs. ${order.amount.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: TinyTrailsColors.emerald700,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: () => isReady ? _markPicked(order) : _markReady(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isReady ? TinyTrailsColors.royalBlue : TinyTrailsColors.emeraldGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(
                    isReady ? 'Picked Up' : 'Mark Ready',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryStrip() {
    return Container(
      decoration: const BoxDecoration(color: TinyTrailsColors.white),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Quick Inventory',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: TinyTrailsColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _inventoryStock.entries.map<Widget>((entry) {
                final item = entry.key;
                final inStock = entry.value;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: TinyTrailsColors.gray100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: TinyTrailsColors.charcoal,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Transform.scale(
                        scale: 0.75,
                        child: Switch(
                          value: inStock,
                          activeColor: TinyTrailsColors.emeraldGreen,
                          onChanged: (value) {
                            setState(() => _inventoryStock[item] = value);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DummyOrder {
  final String id;
  final String items;
  final String customerName;
  final double amount;
  final double distance;
  final LatLng customerLocation;
  final String status;

  _DummyOrder({
    required this.id,
    required this.items,
    required this.customerName,
    required this.amount,
    required this.distance,
    required this.customerLocation,
    this.status = 'pending',
  });

  _DummyOrder copyWith({String? status}) {
    return _DummyOrder(
      id: id,
      items: items,
      customerName: customerName,
      amount: amount,
      distance: distance,
      customerLocation: customerLocation,
      status: status ?? this.status,
    );
  }
}
