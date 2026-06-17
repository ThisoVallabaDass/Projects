import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firebase_service.dart';
import '../services/cart_service.dart';
import '../models/models.dart';
import '../theme/theme.dart';

class CustomerPaymentScreen extends StatefulWidget {
  final double totalAmount;
  final String selectedAddress;
  final String selectedAddressLabel;
  final String? couponCode;
  final double couponDiscount;

  const CustomerPaymentScreen({
    super.key,
    required this.totalAmount,
    required this.selectedAddress,
    required this.selectedAddressLabel,
    this.couponCode,
    required this.couponDiscount,
  });

  @override
  State<CustomerPaymentScreen> createState() => _CustomerPaymentScreenState();
}

class _CustomerPaymentScreenState extends State<CustomerPaymentScreen> {
  String _selectedPaymentMethod = 'upi';
  bool _isProcessing = false;

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    // Create order
    final success = await _createOrder();

    setState(() => _isProcessing = false);

    if (success) {
      // Show success and navigate back
      if (mounted) {
        Navigator.pop(context); // Close payment screen
        Navigator.pop(context); // Close cart screen
        _showSuccessDialog();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment failed. Please try again.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: TinyTrailsColors.error,
          ),
        );
      }
    }
  }

  Future<bool> _createOrder() async {
    try {
      final cart = CartService();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || cart.items.isEmpty) {
        return false;
      }

      // Get user data
      final userData = await firebaseService.getUserData(user.uid);
      if (userData == null) {
        return false;
      }

      // Create order items from cart
      final orderItems = cart.items.map((cartItem) {
        return OrderItemModel(
          id: cartItem['id'] as String,
          name: cartItem['name'] as String,
          price: (cartItem['price'] as num).toDouble(),
          quantity: cartItem['quantity'] ?? 1,
          isVeg: cartItem['isVeg'] as bool,
        );
      }).toList();

      final itemTotal = cart.getTotalPrice();
      const deliveryFee = 20.0;
      const platformFee = 5.0;
      final discount = widget.couponDiscount;

      // Create order model
      final order = OrderModel(
        customerId: user.uid,
        customerName: userData.name,
        vendorId: cart.getVendorId() ?? '',
        vendorName: cart.items.first['vendorName'] as String,
        items: orderItems,
        itemTotal: itemTotal,
        deliveryFee: deliveryFee,
        platformFee: platformFee,
        discount: discount,
        totalAmount: widget.totalAmount,
        deliveryAddress: '${widget.selectedAddressLabel} - ${widget.selectedAddress}',
        couponCode: widget.couponCode,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        customerPhone: userData.phoneNumber,
      );

      // Save to Firebase
      final orderId = await firebaseService.createOrder(order);

      if (orderId != null) {
        // Clear cart
        cart.clearCart();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error creating order: $e');
      return false;
    }
  }

  void _showSuccessDialog() {
    showDialog(
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
                color: TinyTrailsColors.emeraldGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 50,
                color: TinyTrailsColors.emeraldGreen,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Order Placed!',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: TinyTrailsColors.charcoal,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your order has been successfully placed and sent to the vendor.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: TinyTrailsColors.gray500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TinyTrailsColors.emeraldGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TinyTrailsColors.offWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: TinyTrailsColors.charcoal),
        ),
        title: Text(
          'Payment',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: TinyTrailsColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(TinyTrailsColors.royalBlue),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Processing your payment...',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: TinyTrailsColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: TinyTrailsColors.gray500,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Amount Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        TinyTrailsColors.royalBlue,
                        TinyTrailsColors.royalBlue700,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: TinyTrailsColors.royalBlue.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total Amount',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${widget.totalAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Payment Methods
                Text(
                  'Select Payment Method',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: TinyTrailsColors.charcoal,
                  ),
                ),
                const SizedBox(height: 16),

                _buildPaymentMethodOption(
                  'upi',
                  'UPI',
                  Icons.account_balance_wallet,
                  'Pay via UPI',
                ),
                const SizedBox(height: 12),
                _buildPaymentMethodOption(
                  'card',
                  'Debit/Credit Card',
                  Icons.credit_card,
                  'Pay via Card',
                ),
                const SizedBox(height: 12),
                _buildPaymentMethodOption(
                  'cod',
                  'Cash on Delivery',
                  Icons.money,
                  'Pay with Cash',
                ),

                const SizedBox(height: 32),

                // Delivery Address
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: TinyTrailsColors.gray200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: TinyTrailsColors.royalBlue50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: TinyTrailsColors.royalBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivering to',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: TinyTrailsColors.gray500,
                              ),
                            ),
                            Text(
                              widget.selectedAddressLabel,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: TinyTrailsColors.charcoal,
                              ),
                            ),
                            Text(
                              widget.selectedAddress,
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
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _isProcessing
          ? null
          : Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: TinyTrailsColors.gray200)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TinyTrailsColors.emeraldGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Pay ₹${widget.totalAmount.toStringAsFixed(0)} Securely',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPaymentMethodOption(
    String value,
    String title,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? TinyTrailsColors.royalBlue : TinyTrailsColors.gray100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : TinyTrailsColors.gray500,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: TinyTrailsColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: TinyTrailsColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: TinyTrailsColors.royalBlue,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
