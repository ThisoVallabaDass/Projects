import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/theme.dart';
import '../services/cart_service.dart';

class CustomerCartScreen extends StatefulWidget {
  const CustomerCartScreen({super.key});

  @override
  State<CustomerCartScreen> createState() => _CustomerCartScreenState();
}

class _CustomerCartScreenState extends State<CustomerCartScreen> {
  final CartService _cart = CartService();
  bool _isPlacingOrder = false;

  static const double _deliveryFee = 10.0;
  static const GeoPoint _defaultCustomerLocation = GeoPoint(12.9342, 77.6101);

  double get _itemTotal => _cart.getTotalPrice();
  double get _grandTotal => _itemTotal + _deliveryFee;

  Future<void> _placeOrder() async {
    if (_cart.items.isEmpty) return;

    setState(() => _isPlacingOrder = true);

    try {
      final customerId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final vendorId = _cart.getVendorId() ?? '';

      await FirebaseFirestore.instance.collection('orders').add({
        'customerId': customerId,
        'vendorId': vendorId,
        'customerName': FirebaseAuth.instance.currentUser?.displayName ?? 'Customer',
        'items': _cart.items.map((item) => {
          'id': item['id'],
          'name': item['name'],
          'price': item['price'],
          'quantity': item['quantity'],
          'isVeg': item['isVeg'],
        }).toList(),
        'itemTotal': _itemTotal,
        'deliveryFee': _deliveryFee,
        'totalAmount': _grandTotal,
        'status': 'pending',
        'customerLocation': _defaultCustomerLocation,
        'riderLocation': null,
        'riderId': null,
        'statusTimeline': [
          {'status': 'pending', 'at': Timestamp.now()}
        ],
        'createdAt': FieldValue.serverTimestamp(),
      });

      _cart.clearCart();

      if (mounted) {
        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: TinyTrailsColors.emerald50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle, size: 48, color: TinyTrailsColors.emeraldGreen),
                ),
                const SizedBox(height: 20),
                Text(
                  'Order Placed!',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: TinyTrailsColors.charcoal),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your order has been sent to the vendor',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: TinyTrailsColors.gray500),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back to home
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TinyTrailsColors.emeraldGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Done', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order. Please try again.'),
            backgroundColor: TinyTrailsColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TinyTrailsColors.gray100,
      appBar: AppBar(
        backgroundColor: TinyTrailsColors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: TinyTrailsColors.charcoal, size: 20),
        ),
        title: Text(
          'Your Cart',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: TinyTrailsColors.charcoal),
        ),
        centerTitle: true,
      ),
      body: _cart.items.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCartItems(),
                        const SizedBox(height: 16),
                        _buildDeliveryAddress(),
                        const SizedBox(height: 16),
                        _buildBillSummary(),
                      ],
                    ),
                  ),
                ),
                _buildCheckoutButton(),
              ],
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: TinyTrailsColors.gray300),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: TinyTrailsColors.gray400),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to get started',
            style: GoogleFonts.inter(fontSize: 14, color: TinyTrailsColors.gray400),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TinyTrailsColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: TinyTrailsColors.charcoal),
          ),
          const SizedBox(height: 16),
          ..._cart.items.map((item) => _buildCartItem(item)),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    final isVeg = item['isVeg'] ?? true;
    final price = (item['price'] ?? 0).toDouble();
    final quantity = item['quantity'] ?? 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Veg indicator
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              border: Border.all(color: isVeg ? TinyTrailsColors.emeraldGreen : TinyTrailsColors.error, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isVeg ? TinyTrailsColors.emeraldGreen : TinyTrailsColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Text(
              item['name'] ?? 'Unknown',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: TinyTrailsColors.charcoal),
            ),
          ),
          // Quantity controls
          Container(
            decoration: BoxDecoration(
              color: TinyTrailsColors.royalBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    _cart.decrementItem(item['id']);
                    setState(() {});
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.remove, color: Colors.white, size: 16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$quantity',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _cart.incrementItem(item['id']);
                    setState(() {});
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Price
          Text(
            '₹${(price * quantity).toStringAsFixed(0)}',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: TinyTrailsColors.charcoal),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TinyTrailsColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: TinyTrailsColors.royalBlue50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.location_on, color: TinyTrailsColors.royalBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deliver to: Home',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: TinyTrailsColors.charcoal),
                ),
                const SizedBox(height: 2),
                Text(
                  '123 Main Street, City - 600001',
                  style: GoogleFonts.inter(fontSize: 12, color: TinyTrailsColors.gray500),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: TinyTrailsColors.gray400),
        ],
      ),
    );
  }

  Widget _buildBillSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TinyTrailsColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bill Summary',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: TinyTrailsColors.charcoal),
          ),
          const SizedBox(height: 16),
          _buildBillRow('Item Total', '₹${_itemTotal.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _buildBillRow('Delivery Fee', '₹${_deliveryFee.toStringAsFixed(0)}'),
          const Divider(height: 24),
          _buildBillRow('Grand Total', '₹${_grandTotal.toStringAsFixed(0)}', isBold: true),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? TinyTrailsColors.charcoal : TinyTrailsColors.gray500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: TinyTrailsColors.charcoal,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TinyTrailsColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isPlacingOrder ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: TinyTrailsColors.royalBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: TinyTrailsColors.royalBlue.withValues(alpha: 0.6),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isPlacingOrder
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    'Place Order: ₹${_grandTotal.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    );
  }
}
