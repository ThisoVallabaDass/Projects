import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/theme.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _pastOrders = [
    {
      'id': 'ORD-2024-001',
      'vendorName': 'Lakshmi Sweets',
      'items': ['Mysore Pak x2', 'Kaju Katli x1'],
      'total': 300.0,
      'status': 'Delivered',
      'date': '22 Mar 2024',
      'time': '7:30 PM',
    },
    {
      'id': 'ORD-2024-002',
      'vendorName': "Raju's Pushcart",
      'items': ['Samosa x4', 'Pani Puri x2'],
      'total': 280.0,
      'status': 'Delivered',
      'date': '20 Mar 2024',
      'time': '1:15 PM',
    },
    {
      'id': 'ORD-2024-003',
      'vendorName': 'Spice Garden',
      'items': ['Butter Chicken x1', 'Biryani x1'],
      'total': 530.0,
      'status': 'Cancelled',
      'date': '18 Mar 2024',
      'time': '8:00 PM',
    },
  ];

  final List<Map<String, dynamic>> _activeOrders = [
    {
      'id': 'ORD-2024-004',
      'vendorName': 'Green Basket',
      'items': ['Tomato Basket x2', 'Potato Sack x1'],
      'total': 130.0,
      'status': 'Preparing',
      'date': 'Today',
      'time': '2:30 PM',
      'eta': '15 mins',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TinyTrailsColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Your Orders',
          style: GoogleFonts.inter(
            color: TinyTrailsColors.charcoal,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: TinyTrailsColors.royalBlue,
          unselectedLabelColor: TinyTrailsColors.gray400,
          indicatorColor: TinyTrailsColors.royalBlue,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Past Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveOrders(),
          _buildPastOrders(),
        ],
      ),
    );
  }

  Widget _buildActiveOrders() {
    if (_activeOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: TinyTrailsColors.gray300),
            const SizedBox(height: 16),
            Text(
              'No active orders',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: TinyTrailsColors.gray500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your ongoing orders will appear here',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: TinyTrailsColors.gray400,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeOrders.length,
      itemBuilder: (context, index) => _buildActiveOrderCard(_activeOrders[index]),
    );
  }

  Widget _buildActiveOrderCard(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TinyTrailsColors.emeraldGreen, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: TinyTrailsColors.emerald50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(TinyTrailsColors.emeraldGreen),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order['status'],
                      style: GoogleFonts.inter(
                        color: TinyTrailsColors.emeraldGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'ETA: ${order['eta']}',
                style: GoogleFonts.inter(
                  color: TinyTrailsColors.emeraldGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order['vendorName'],
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: TinyTrailsColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            (order['items'] as List).join(', '),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: TinyTrailsColors.gray500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Rs. ${order['total'].toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: TinyTrailsColors.charcoal,
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening live tracking...')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: TinyTrailsColors.royalBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Track Order',
                  style: GoogleFonts.inter(
                    color: TinyTrailsColors.royalBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPastOrders() {
    if (_pastOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: TinyTrailsColors.gray300),
            const SizedBox(height: 16),
            Text(
              'No past orders',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: TinyTrailsColors.gray500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pastOrders.length,
      itemBuilder: (context, index) => _buildPastOrderCard(_pastOrders[index]),
    );
  }

  Widget _buildPastOrderCard(Map<String, dynamic> order) {
    final isDelivered = order['status'] == 'Delivered';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order['vendorName'],
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: TinyTrailsColors.charcoal,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDelivered ? TinyTrailsColors.emerald50 : TinyTrailsColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order['status'],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDelivered ? TinyTrailsColors.emeraldGreen : TinyTrailsColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            (order['items'] as List).join(', '),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: TinyTrailsColors.gray500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: TinyTrailsColors.gray400),
              const SizedBox(width: 4),
              Text(
                '${order['date']} at ${order['time']}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: TinyTrailsColors.gray400,
                ),
              ),
              const Spacer(),
              Text(
                'Rs. ${order['total'].toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: TinyTrailsColors.charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reordering items...')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: TinyTrailsColors.royalBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Reorder',
                    style: GoogleFonts.inter(
                      color: TinyTrailsColors.royalBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening order details...')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: TinyTrailsColors.gray300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'View Details',
                    style: GoogleFonts.inter(
                      color: TinyTrailsColors.gray500,
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
}
