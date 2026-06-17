import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VendorDashboardTab extends StatefulWidget {
  const VendorDashboardTab({super.key});

  @override
  State<VendorDashboardTab> createState() => _VendorDashboardTabState();
}

class _VendorDashboardTabState extends State<VendorDashboardTab>
    with SingleTickerProviderStateMixin {
  bool _isOnline = false;
  late TabController _tabController;
  String? _vendorBusinessType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVendorData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVendorData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('vendors')
            .doc(user.uid)
            .get();
        if (mounted && doc.exists) {
          setState(() {
            _vendorBusinessType = doc['businessType'];
          });
        }
      }
    } catch (e) {
      print('Error loading vendor data: $e');
    }
  }

  Future<void> _toggleOnlineStatus() async {
    // For food vendors, open camera screen before toggling online
    if (_vendorBusinessType == 'food' && !_isOnline) {
      Navigator.of(context).pushNamed('/vendor-daily-shift-camera');
      return;
    }

    // Update Firestore
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('vendors').doc(user.uid).update({
          'isOnline': !_isOnline,
        });
        setState(() {
          _isOnline = !_isOnline;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const emeraldGreen = Color(0xFF10B981);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Header with Go Online/Offline toggle
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: Colors.white,
            expandedHeight: 180,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Shop name and toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('vendors')
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .get(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    final shopName = snapshot.data!['shopName'] ?? 'Your Shop';
                                    return Text(
                                      shopName,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF111827),
                                      ),
                                    );
                                  }
                                  return const Text(
                                    'Your Shop',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF111827),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isOnline ? 'Online' : 'Offline',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _isOnline ? emeraldGreen : const Color(0xFF667085),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Toggle switch
                        Container(
                          decoration: BoxDecoration(
                            color: _isOnline
                                ? emeraldGreen.withValues(alpha: 0.1)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: _isOnline ? emeraldGreen : const Color(0xFFE5E7EB),
                              width: 2,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _toggleOnlineStatus,
                              borderRadius: BorderRadius.circular(50),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isOnline ? Icons.power_settings_new : Icons.power_off,
                                      color: _isOnline ? emeraldGreen : const Color(0xFF667085),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isOnline ? 'Online' : 'Offline',
                                      style: TextStyle(
                                        color:
                                            _isOnline ? emeraldGreen : const Color(0xFF667085),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Quick Stats Row
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  _StatCard(
                    title: 'Today\'s Earnings',
                    value: 'Rs. 0',
                    icon: Icons.trending_up,
                  ),
                  const SizedBox(width: 16),
                  _StatCard(
                    title: 'Active Orders',
                    value: '0',
                    icon: Icons.shopping_bag_outlined,
                  ),
                  const SizedBox(width: 16),
                  _StatCard(
                    title: 'Profile Views',
                    value: '12',
                    icon: Icons.visibility_outlined,
                  ),
                ],
              ),
            ),
          ),

          // Orders TabBar
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            toolbarHeight: 0,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: emeraldGreen,
              labelColor: emeraldGreen,
              unselectedLabelColor: const Color(0xFF667085),
              tabs: const [
                Tab(
                  child: Text(
                    'New Requests',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Tab(
                  child: Text(
                    'Preparing',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          // TabBarView content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                // New Requests Tab
                _buildOrderList(
                  title: 'New Requests',
                  isEmpty: true,
                  emeraldGreen: emeraldGreen,
                ),
                // Preparing Tab
                _buildOrderList(
                  title: 'Preparing',
                  isEmpty: true,
                  emeraldGreen: emeraldGreen,
                ),
              ],
            ),
          ),
        ],
      ),
      // Quick Inventory Toggle at bottom
      bottomNavigationBar: Container(
        height: 120,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: Text(
                'Inventory',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _InventoryItem(
                      name: 'Biryani',
                      inStock: true,
                    ),
                    const SizedBox(width: 16),
                    _InventoryItem(
                      name: 'Tandoori Chicken',
                      inStock: true,
                    ),
                    const SizedBox(width: 16),
                    _InventoryItem(
                      name: 'Naan',
                      inStock: false,
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

  Widget _buildOrderList({
    required String title,
    required bool isEmpty,
    required Color emeraldGreen,
  }) {
    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: emeraldGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                color: emeraldGreen,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No orders yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When orders come in, they\'ll appear here',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF667085),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return _OrderCard(
          orderNumber: '12345',
          items: 'Biryani x2, Naan x3',
          total: 599.0,
          emeraldGreen: emeraldGreen,
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF667085),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                icon,
                color: const Color(0xFF10B981),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String orderNumber;
  final String items;
  final double total;
  final Color emeraldGreen;

  const _OrderCard({
    required this.orderNumber,
    required this.items,
    required this.total,
    required this.emeraldGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order number
          Text(
            'Order #$orderNumber',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          // Items
          Text(
            items,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF667085),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Total and buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rs. ${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              Row(
                children: [
                  // Decline button
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () {},
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        color: Color(0xFFEF5350),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Accept button
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: emeraldGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () {},
                    child: const Text(
                      'Accept',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InventoryItem extends StatefulWidget {
  final String name;
  final bool inStock;

  const _InventoryItem({
    required this.name,
    required this.inStock,
  });

  @override
  State<_InventoryItem> createState() => _InventoryItemState();
}

class _InventoryItemState extends State<_InventoryItem> {
  late bool _inStock;

  @override
  void initState() {
    super.initState();
    _inStock = widget.inStock;
  }

  @override
  Widget build(BuildContext context) {
    const emeraldGreen = Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _inStock ? emeraldGreen : const Color(0xFFEF5350),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _inStock = !_inStock;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _inStock
                    ? emeraldGreen.withValues(alpha: 0.1)
                    : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _inStock ? 'In Stock' : 'Out of Stock',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _inStock ? emeraldGreen : const Color(0xFFEF5350),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
