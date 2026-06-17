import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/theme.dart';
import '../services/firebase_service.dart';

class VendorOrdersTab extends StatefulWidget {
  const VendorOrdersTab({super.key});

  @override
  State<VendorOrdersTab> createState() => _VendorOrdersTabState();
}

class _VendorOrdersTabState extends State<VendorOrdersTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _vendorId;
  String _vendorCategory = 'food';  // Default to food, will be updated

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVendorId();
  }

  void _loadVendorId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _vendorId = user.uid;
      });

      // Load vendor category
      try {
        final userData = await firebaseService.getUserData(user.uid);
        if (userData != null && mounted) {
          setState(() {
            _vendorCategory = userData.vendorCategory;
          });
        }
      } catch (e) {
        // Keep default category if loading fails
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _acceptOrder(String orderId) async {
    final success = await firebaseService.updateOrderStatus(orderId, 'accepted');

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order accepted. Moved to Preparing!'),
          backgroundColor: TinyTrailsColors.emeraldGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _declineOrder(String orderId) async {
    final success = await firebaseService.updateOrderStatus(orderId, 'cancelled');

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order declined'),
          backgroundColor: TinyTrailsColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _markAsReady(String orderId) async {
    final success = await firebaseService.updateOrderStatus(orderId, 'ready');

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order marked as ready! Customer notified.'),
          backgroundColor: TinyTrailsColors.royalBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_vendorId == null) {
      return Scaffold(
        backgroundColor: TinyTrailsColors.gray100,
        appBar: AppBar(
          backgroundColor: TinyTrailsColors.white,
          title: Text(
            'Orders',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: TinyTrailsColors.charcoal,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: TinyTrailsColors.gray100,
      appBar: AppBar(
        backgroundColor: TinyTrailsColors.white,
        elevation: 0,
        title: Text(
          'Orders',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: TinyTrailsColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('vendorId', isEqualTo: _vendorId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Try fallback method without ordering for non-food vendors
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('vendorId', isEqualTo: _vendorId)
                  .snapshots(),
              builder: (context, fallbackSnapshot) {
                if (fallbackSnapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: TinyTrailsColors.error),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading orders',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: TinyTrailsColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please try again later',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: TinyTrailsColors.gray500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TinyTrailsColors.emeraldGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (fallbackSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(TinyTrailsColors.emeraldGreen),
                    ),
                  );
                }

                final docs = fallbackSnapshot.data?.docs ?? [];

                // Sort manually by timestamp if available
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['createdAt'] as Timestamp?;
                  final bTime = bData['createdAt'] as Timestamp?;

                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;

                  return bTime.compareTo(aTime);
                });

                // Filter orders by status
                final pendingOrders = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] == 'pending';
                }).toList();

                final preparingOrders = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'];
                  return status == 'accepted' || status == 'preparing';
                }).toList();

                return Column(
                  children: [
                    // Tab Bar
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      decoration: BoxDecoration(
                        color: TinyTrailsColors.gray100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: TinyTrailsColors.emeraldGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: TinyTrailsColors.gray500,
                        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(text: 'New Requests (${pendingOrders.length})'),
                          Tab(text: 'Preparing (${preparingOrders.length})'),
                        ],
                      ),
                    ),
                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildNewRequestsTab(pendingOrders),
                          _buildPreparingTab(preparingOrders),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(TinyTrailsColors.emeraldGreen),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          // Filter orders by status
          final pendingOrders = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'pending';
          }).toList();

          final preparingOrders = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'];
            return status == 'accepted' || status == 'preparing';
          }).toList();

          return Column(
            children: [
              // Tab Bar
              Container(
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: BoxDecoration(
                  color: TinyTrailsColors.gray100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: TinyTrailsColors.emeraldGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: TinyTrailsColors.gray500,
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: 'New Requests (${pendingOrders.length})'),
                    Tab(text: 'Preparing (${preparingOrders.length})'),
                  ],
                ),
              ),
              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNewRequestsTab(pendingOrders),
                    _buildPreparingTab(preparingOrders),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNewRequestsTab(List<QueryDocumentSnapshot> orders) {
    if (orders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No new requests right now',
        subtitle: 'Take a breather! New orders will appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final doc = orders[index];
        final data = doc.data() as Map<String, dynamic>;
        return _buildNewRequestCard(doc.id, data);
      },
    );
  }

  Widget _buildPreparingTab(List<QueryDocumentSnapshot> orders) {
    if (orders.isEmpty) {
      return _buildEmptyState(
        icon: _vendorCategory == 'food' ? Icons.soup_kitchen_outlined : Icons.inventory_outlined,
        title: _vendorCategory == 'food' ? 'Nothing cooking yet' : 'Nothing in progress yet',
        subtitle: _vendorCategory == 'food'
            ? 'Accepted orders will appear here for preparation.'
            : 'Accepted orders will appear here for processing.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final doc = orders[index];
        final data = doc.data() as Map<String, dynamic>;
        return _buildPreparingCard(doc.id, data);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: TinyTrailsColors.emerald50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: TinyTrailsColors.emeraldGreen),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: TinyTrailsColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: TinyTrailsColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getItemsSummary(List<dynamic> items) {
    if (items.isEmpty) return 'No items';
    if (items.length == 1) {
      final item = items[0] as Map<String, dynamic>;
      final qty = item['quantity'] ?? 1;
      return '${qty}x ${item['name']}';
    }
    return items.map((item) {
      final itemData = item as Map<String, dynamic>;
      final qty = itemData['quantity'] ?? 1;
      return '${qty}x ${itemData['name']}';
    }).join(', ');
  }

  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final date = timestamp.toDate();
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} days ago';
  }

  Widget _buildNewRequestCard(String orderId, Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>? ?? [];
    final itemsSummary = _getItemsSummary(items);
    final customerName = order['customerName'] as String? ?? 'Customer';
    final amount = (order['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final timestamp = order['createdAt'] as Timestamp?;
    final timeAgo = _getTimeAgo(timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: TinyTrailsColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TinyTrailsColors.emerald200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TinyTrailsColors.emerald50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: TinyTrailsColors.warning,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'NEW',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Order #${orderId.substring(0, 8)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: TinyTrailsColors.charcoal,
                    ),
                  ),
                ),
                Text(
                  timeAgo,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: TinyTrailsColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemsSummary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: TinyTrailsColors.charcoal,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: TinyTrailsColors.gray500),
                    const SizedBox(width: 6),
                    Text(
                      customerName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: TinyTrailsColors.gray500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Rs. ${amount.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: TinyTrailsColors.emeraldGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _declineOrder(orderId),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: TinyTrailsColors.error, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Decline',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: TinyTrailsColors.error,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _acceptOrder(orderId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TinyTrailsColors.emeraldGreen,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Accept',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreparingCard(String orderId, Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>? ?? [];
    final itemsSummary = _getItemsSummary(items);
    final customerName = order['customerName'] as String? ?? 'Customer';
    final amount = (order['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final timestamp = order['createdAt'] as Timestamp?;
    final timeAgo = _getTimeAgo(timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: TinyTrailsColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TinyTrailsColors.royalBlue200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TinyTrailsColors.royalBlue50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: TinyTrailsColors.royalBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.restaurant, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Order #${orderId.substring(0, 8)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: TinyTrailsColors.charcoal,
                    ),
                  ),
                ),
                Text(
                  timeAgo,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: TinyTrailsColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemsSummary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: TinyTrailsColors.charcoal,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: TinyTrailsColors.gray500),
                    const SizedBox(width: 6),
                    Text(
                      customerName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: TinyTrailsColors.gray500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Rs. ${amount.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: TinyTrailsColors.royalBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Mark as Ready Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _markAsReady(orderId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TinyTrailsColors.royalBlue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
                    label: Text(
                      'Mark as Ready',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
