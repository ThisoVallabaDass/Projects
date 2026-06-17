import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/offers_service.dart';
import '../services/firebase_service.dart';
import '../theme/theme.dart';
import 'create_offer_screen.dart';

class VendorOffersScreen extends StatefulWidget {
  const VendorOffersScreen({super.key});

  @override
  State<VendorOffersScreen> createState() => _VendorOffersScreenState();
}

class _VendorOffersScreenState extends State<VendorOffersScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  final OffersService _offersService = OffersService();
  final FirebaseService _firebaseService = FirebaseService();

  String? _vendorId;
  OfferStats? _stats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVendorData();
  }

  Future<void> _loadVendorData() async {
    final userId = _firebaseService.currentUser?.uid;
    if (userId != null) {
      setState(() {
        _vendorId = userId;
      });
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    if (_vendorId != null) {
      final stats = await _offersService.getOfferStats(_vendorId!);
      setState(() {
        _stats = stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TinyTrailsColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: TinyTrailsColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Offers & Coupons',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => _showAnalytics(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Active', icon: Icon(Icons.local_offer, size: 18)),
            Tab(text: 'All Offers', icon: Icon(Icons.list, size: 18)),
            Tab(text: 'Templates', icon: Icon(Icons.library_books_outlined, size: 18)),
          ],
        ),
      ),
      body: _vendorId == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatsHeader(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildActiveOffersTab(),
                      _buildAllOffersTab(),
                      _buildTemplatesTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewOffer(),
        backgroundColor: TinyTrailsColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Offer', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildStatsHeader() {
    if (_stats == null) {
      return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Total Offers', _stats!.totalOffers.toString(), Icons.campaign)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Active', _stats!.activeOffers.toString(), Icons.verified)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Redeemed', _stats!.totalRedemptions.toString(), Icons.redeem)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: TinyTrailsColors.primary, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOffersTab() {
    return StreamBuilder<List<OfferModel>>(
      stream: _offersService.getActiveVendorOffers(_vendorId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final offers = snapshot.data ?? [];

        if (offers.isEmpty) {
          return _buildEmptyState(
            'No Active Offers',
            'Create your first offer to attract more customers!',
            Icons.local_offer_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          itemBuilder: (context, index) => _buildOfferCard(offers[index]),
        );
      },
    );
  }

  Widget _buildAllOffersTab() {
    return StreamBuilder<List<OfferModel>>(
      stream: _offersService.getVendorOffers(_vendorId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final offers = snapshot.data ?? [];

        if (offers.isEmpty) {
          return _buildEmptyState(
            'No Offers Created',
            'Start by creating your first promotional offer',
            Icons.add_business_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          itemBuilder: (context, index) => _buildOfferCard(offers[index], showActions: true),
        );
      },
    );
  }

  Widget _buildTemplatesTab() {
    final templates = OfferTemplates.getTemplates(_vendorId!);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, index) => _buildTemplateCard(templates[index]),
    );
  }

  Widget _buildOfferCard(OfferModel offer, {bool showActions = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: offer.isFeatured
            ? Border.all(color: TinyTrailsColors.accent, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              offer.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _buildOfferStatusChip(offer),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        offer.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Offer details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildOfferDetailRow('Promo Code', offer.promoCode, Icons.code),
                _buildOfferDetailRow('Discount', _formatDiscount(offer), Icons.local_offer),
                _buildOfferDetailRow('Used', '${offer.totalUsed} times', Icons.redeem),
                if (offer.minOrderAmount != null)
                  _buildOfferDetailRow('Min Order', '₹${offer.minOrderAmount!.toInt()}', Icons.shopping_cart),
              ],
            ),
          ),

          // Actions
          if (showActions)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editOffer(offer),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TinyTrailsColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _duplicateOffer(offer),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Duplicate'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TinyTrailsColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _deleteOffer(offer),
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red[400],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(OfferModel template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.blue[400], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    template.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _useTemplate(template),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TinyTrailsColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Use Template'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              template.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            _buildOfferDetailRow('Code', template.promoCode, Icons.code),
            _buildOfferDetailRow('Discount', _formatDiscount(template), Icons.local_offer),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferStatusChip(OfferModel offer) {
    Color color;
    String text;

    if (offer.isExpired) {
      color = Colors.red;
      text = 'Expired';
    } else if (offer.status == OfferStatus.active) {
      color = TinyTrailsColors.success;
      text = 'Active';
    } else if (offer.status == OfferStatus.paused) {
      color = Colors.orange;
      text = 'Paused';
    } else {
      color = Colors.grey;
      text = 'Inactive';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDiscount(OfferModel offer) {
    switch (offer.type) {
      case OfferType.percentage:
        return '${offer.discountValue.toInt()}% OFF';
      case OfferType.fixedAmount:
        return '₹${offer.discountValue.toInt()} OFF';
      case OfferType.freeDelivery:
        return 'FREE DELIVERY';
      case OfferType.buyOneGetOne:
        return 'BOGO';
      default:
        return '${offer.discountValue.toInt()}% OFF';
    }
  }

  void _createNewOffer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateOfferScreen(vendorId: _vendorId!),
      ),
    ).then((_) => _loadStats());
  }

  void _editOffer(OfferModel offer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateOfferScreen(vendorId: _vendorId!, offer: offer),
      ),
    ).then((_) => _loadStats());
  }

  void _useTemplate(OfferModel template) {
    final offer = template.copyWith(
      id: '',
      vendorId: _vendorId!,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateOfferScreen(vendorId: _vendorId!, offer: offer),
      ),
    ).then((_) => _loadStats());
  }

  void _duplicateOffer(OfferModel offer) {
    final duplicated = offer.copyWith(
      id: '',
      title: '${offer.title} (Copy)',
      promoCode: '${offer.promoCode}COPY',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      totalUsed: 0,
      userUsage: {},
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateOfferScreen(vendorId: _vendorId!, offer: duplicated),
      ),
    ).then((_) => _loadStats());
  }

  Future<void> _deleteOffer(OfferModel offer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Offer'),
        content: Text('Are you sure you want to delete "${offer.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _offersService.deleteOffer(offer.id);
        _loadStats();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Offer deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting offer: $e')),
          );
        }
      }
    }
  }

  void _showAnalytics() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildAnalyticsSheet(),
    );
  }

  Widget _buildAnalyticsSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Offers Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (_stats != null) ...[
            _buildAnalyticsRow('Total Offers Created', _stats!.totalOffers.toString()),
            _buildAnalyticsRow('Currently Active', _stats!.activeOffers.toString()),
            _buildAnalyticsRow('Total Redemptions', _stats!.totalRedemptions.toString()),
            _buildAnalyticsRow('Est. Discount Given', '₹${_stats!.totalDiscountGiven.toInt()}'),
            const SizedBox(height: 20),
            Text(
              'Performance Tips:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: TinyTrailsColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text('• Create time-limited offers to drive urgency'),
            const Text('• Use first-order discounts to attract new customers'),
            const Text('• Monitor redemption rates and adjust accordingly'),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}