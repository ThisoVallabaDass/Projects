import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/cart_service.dart';
import '../services/offers_service.dart';
import '../theme/theme.dart';
import '../widgets/customer_offer_widgets.dart';
import 'customer_payment_screen.dart';

class CustomerCartTab extends StatefulWidget {
  const CustomerCartTab({super.key});

  @override
  State<CustomerCartTab> createState() => _CustomerCartTabState();
}

class _CustomerCartTabState extends State<CustomerCartTab> {
  final CartService _cartService = CartService();
  String _selectedAddressLabel = 'Home';
  String _selectedAddress = '123 Main St, Anna Nagar, Chennai - 600040';
  CouponValidationResult? _appliedCouponResult;

  final List<Map<String, dynamic>> _savedAddresses = [
    {
      'label': 'Home',
      'address': '123 Main St, Anna Nagar, Chennai - 600040',
      'icon': Icons.home_outlined,
    },
    {
      'label': 'Work',
      'address': 'Building 5, Tech Park, OMR Road, Chennai - 600096',
      'icon': Icons.work_outline,
    },
  ];

  double get _itemTotal => _cartService.getTotalPrice();
  int get _deliveryFee => 20;
  int get _platformFee => 5;
  double get _couponDiscount => _appliedCouponResult?.discountAmount ?? 0;
  double get _toPay => _itemTotal + _deliveryFee + _platformFee - _couponDiscount;

  @override
  Widget build(BuildContext context) {
    final items = _cartService.items;
    final vendorName = items.isNotEmpty ? items.first['vendorName'] as String? ?? 'Shop' : 'Shop';

    if (items.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'Your Cart',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: TinyTrailsColors.charcoal,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: TinyTrailsColors.charcoal),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 80, color: TinyTrailsColors.gray300),
              const SizedBox(height: 16),
              Text(
                'Your cart is empty',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: TinyTrailsColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add items to start an order',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: TinyTrailsColors.gray500,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TinyTrailsColors.royalBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                child: Text(
                  'Browse Shops',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Cart',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: TinyTrailsColors.charcoal,
              ),
            ),
            Text(
              'from $vendorName',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: TinyTrailsColors.gray500,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TinyTrailsColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text(
                    'Clear Cart',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                  content: Text(
                    'Are you sure you want to clear all items from your cart?',
                    style: GoogleFonts.inter(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(color: TinyTrailsColors.gray500),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _cartService.clearCart();
                        setState(() {
                          _appliedCouponResult = null;
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Clear',
                        style: GoogleFonts.inter(
                          color: TinyTrailsColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: Text(
              'Clear',
              style: GoogleFonts.inter(
                color: TinyTrailsColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          ...List.generate(items.length, (index) => _buildCartItemCard(items[index])),
          const SizedBox(height: 14),
          _buildAddressCard(),
          const SizedBox(height: 14),
          _buildCouponCard(),
          const SizedBox(height: 14),
          _buildBillDetailsCard(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerPaymentScreen(
                      totalAmount: _toPay,
                      selectedAddress: _selectedAddress,
                      selectedAddressLabel: _selectedAddressLabel,
                      couponCode: _appliedCouponResult?.offer?.promoCode,
                      couponDiscount: _couponDiscount,
                    ),
                  ),
                ).then((_) {
                  // Refresh cart state when returning from payment
                  if (mounted) setState(() {});
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TinyTrailsColors.royalBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                elevation: 0,
              ),
              child: Text(
                'Proceed to Pay | Rs. ${_toPay.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartItemCard(Map<String, dynamic> item) {
    final isVeg = item['isVeg'] == true;
    final price = (item['price'] as num).toDouble();
    final quantity = item['quantity'] ?? 1;
    final itemId = item['id'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildVegIndicator(isVeg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: TinyTrailsColors.charcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${price.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TinyTrailsColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          _buildQtyPill(itemId, quantity),
        ],
      ),
    );
  }

  Widget _buildQtyPill(String itemId, int quantity) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TinyTrailsColors.royalBlue, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () {
              _cartService.decrementItem(itemId);
              setState(() {});
            },
            icon: Icon(
              quantity > 1 ? Icons.remove : Icons.delete_outline,
              size: 16,
              color: quantity > 1 ? TinyTrailsColors.royalBlue : TinyTrailsColors.error,
            ),
          ),
          Text(
            '$quantity',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: TinyTrailsColors.royalBlue,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () {
              _cartService.incrementItem(itemId);
              setState(() {});
            },
            icon: const Icon(Icons.add, size: 16, color: TinyTrailsColors.royalBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return GestureDetector(
      onTap: _showAddressSelector,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: TinyTrailsColors.royalBlue50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.location_on, color: TinyTrailsColors.royalBlue, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Delivering to: ',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: TinyTrailsColors.gray500,
                        ),
                      ),
                      Text(
                        _selectedAddressLabel,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: TinyTrailsColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedAddress,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: TinyTrailsColors.gray500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: TinyTrailsColors.royalBlue50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Change',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: TinyTrailsColors.royalBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddressSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TinyTrailsColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select Delivery Address',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TinyTrailsColors.charcoal,
              ),
            ),
            const SizedBox(height: 16),
            ..._savedAddresses.map((addr) => _buildAddressTile(addr)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add new address')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add New Address'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: TinyTrailsColors.royalBlue),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressTile(Map<String, dynamic> addr) {
    final isSelected = _selectedAddressLabel == addr['label'];

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAddressLabel = addr['label'];
          _selectedAddress = addr['address'];
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? TinyTrailsColors.royalBlue50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? TinyTrailsColors.royalBlue : TinyTrailsColors.gray200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? TinyTrailsColors.royalBlue : TinyTrailsColors.gray100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                addr['icon'],
                color: isSelected ? Colors.white : TinyTrailsColors.gray500,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    addr['label'],
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: TinyTrailsColors.charcoal,
                    ),
                  ),
                  Text(
                    addr['address'],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: TinyTrailsColors.gray500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: TinyTrailsColors.royalBlue, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponCard() {
    final items = _cartService.items;
    if (items.isEmpty) return const SizedBox.shrink();

    final vendorId = items.first['vendorId'] as String? ?? '';
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final productIds = items.map((item) => item['id'] as String).toList();

    return CustomerOfferWidgets.couponInputWidget(
      vendorId: vendorId,
      userId: userId,
      orderAmount: _itemTotal,
      productIds: productIds,
      onCouponApplied: (result) {
        setState(() {
          _appliedCouponResult = result.isValid ? result : null;
        });
      },
    );
  }

  Widget _buildBillDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bill Details',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: TinyTrailsColors.charcoal,
            ),
          ),
          const SizedBox(height: 12),
          _billRow('Item Total', 'Rs. ${_itemTotal.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _billRow('Delivery Partner Fee', 'Rs. $_deliveryFee'),
          const SizedBox(height: 8),
          _billRow('Platform Fee', 'Rs. $_platformFee'),
          if (_couponDiscount > 0) ...[
            const SizedBox(height: 8),
            _billRow(
              'Coupon Discount',
              '- Rs. ${_couponDiscount.toStringAsFixed(0)}',
              isDiscount: true,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          _billRow('To Pay', 'Rs. ${_toPay.toStringAsFixed(0)}', isBold: true),
        ],
      ),
    );
  }

  Widget _billRow(String title, String value, {bool isBold = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isDiscount ? TinyTrailsColors.emeraldGreen : TinyTrailsColors.gray500,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDiscount ? TinyTrailsColors.emeraldGreen : TinyTrailsColors.charcoal,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildVegIndicator(bool isVeg) {
    final color = isVeg ? TinyTrailsColors.emeraldGreen : TinyTrailsColors.error;
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.7),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
