import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/theme.dart';
import '../models/product_model.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import 'customer_cart_screen.dart';

class CustomerVendorView extends StatefulWidget {
  final String vendorId;
  final String vendorName;
  final String? businessType;
  final int hygieneScore;
  final String trustTier;

  const CustomerVendorView({
    super.key,
    required this.vendorId,
    required this.vendorName,
    this.businessType,
    this.hygieneScore = 95,
    this.trustTier = 'gold',
  });

  @override
  State<CustomerVendorView> createState() => _CustomerVendorViewState();
}

class _CustomerVendorViewState extends State<CustomerVendorView>
    with SingleTickerProviderStateMixin {
  late AnimationController _cartAnimController;
  late Animation<Offset> _cartSlideAnimation;

  // Cart state
  final Map<String, CartItem> _cartItems = {};
  bool _isCartVisible = false;

  // Placeholder products - uses widget.vendorId
  List<ProductModel> get _products => [
    ProductModel(
      id: '1',
      vendorId: widget.vendorId,
      name: 'Homemade Murukku',
      description: 'Crispy spiral snack made fresh daily',
      price: 50,
      isVeg: true,
      inStock: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ProductModel(
      id: '2',
      vendorId: widget.vendorId,
      name: 'Crispy Vadai',
      description: 'Traditional South Indian lentil fritters',
      price: 30,
      isVeg: true,
      inStock: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ProductModel(
      id: '3',
      vendorId: widget.vendorId,
      name: 'Chicken Cutlet',
      description: 'Juicy spiced chicken patty',
      price: 45,
      isVeg: false,
      inStock: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ProductModel(
      id: '4',
      vendorId: widget.vendorId,
      name: 'Filter Coffee',
      description: 'Authentic South Indian coffee',
      price: 20,
      isVeg: true,
      inStock: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ProductModel(
      id: '5',
      vendorId: widget.vendorId,
      name: 'Samosa (2 pcs)',
      description: 'Crispy pastry with spiced potato filling',
      price: 40,
      isVeg: true,
      inStock: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ProductModel(
      id: '6',
      vendorId: widget.vendorId,
      name: 'Egg Puff',
      description: 'Flaky pastry with egg filling',
      price: 35,
      isVeg: false,
      inStock: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _cartAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _cartSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cartAnimController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _cartAnimController.dispose();
    super.dispose();
  }

  int get _totalItems {
    return _cartItems.values.fold(0, (sum, item) => sum + item.quantity);
  }

  double get _totalPrice {
    return _cartItems.values.fold(0, (sum, item) => sum + item.totalPrice);
  }

  void _addToCart(ProductModel product) {
    setState(() {
      if (_cartItems.containsKey(product.id)) {
        _cartItems[product.id]!.increment();
        CartService().incrementItem(product.id);
      } else {
        _cartItems[product.id] = CartItem(product: product);
        // Add to CartService with all required fields
        CartService().addItem({
          'id': product.id,
          'name': product.name,
          'price': product.price,
          'isVeg': product.isVeg,
          'vendorId': widget.vendorId,
          'vendorName': widget.vendorName,
        });
      }

      if (!_isCartVisible) {
        _isCartVisible = true;
        _cartAnimController.forward();
      }
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      if (_cartItems.containsKey(productId)) {
        if (_cartItems[productId]!.quantity > 1) {
          _cartItems[productId]!.decrement();
          CartService().decrementItem(productId);
        } else {
          _cartItems.remove(productId);
          CartService().removeItem(productId);
          if (_cartItems.isEmpty) {
            _cartAnimController.reverse().then((_) {
              setState(() {
                _isCartVisible = false;
              });
            });
          }
        }
      }
    });
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'gold':
        return TinyTrailsColors.badgeGold;
      case 'platinum':
        return TinyTrailsColors.badgePlatinum;
      default:
        return TinyTrailsColors.badgeBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TinyTrailsColors.white,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero Header
              SliverToBoxAdapter(
                child: _buildHeroHeader(),
              ),
              // Menu Section Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(
                    'Menu',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: TinyTrailsColors.charcoal,
                    ),
                  ),
                ),
              ),
              // Products List
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  _isCartVisible ? 100 : 24,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = _products[index];
                      return _buildProductItem(product);
                    },
                    childCount: _products.length,
                  ),
                ),
              ),
            ],
          ),
          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: _buildBackButton(),
          ),
          // Floating Cart Banner
          if (_isCartVisible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: _cartSlideAnimation,
                child: _buildCartBanner(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            TinyTrailsColors.royalBlue,
            TinyTrailsColors.royalBlue700,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background Pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.5,
                    colors: [
                      Colors.white,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Trust Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          size: 16,
                          color: _getTierColor(widget.trustTier),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.trustTier.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Vendor Name
                  Text(
                    widget.vendorName,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Business Type
                  if (widget.businessType != null)
                    Text(
                      widget.businessType!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Hygiene Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: TinyTrailsColors.emeraldGreen,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: TinyTrailsColors.emeraldGreen.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('✨', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.hygieneScore}% Safe',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
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

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_ios_new,
          size: 18,
          color: TinyTrailsColors.charcoal,
        ),
      ),
    );
  }

  Widget _buildProductItem(ProductModel product) {
    final cartItem = _cartItems[product.id];
    final quantity = cartItem?.quantity ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TinyTrailsColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TinyTrailsColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Veg/Non-Veg Indicator
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              border: Border.all(
                color: product.isVeg
                    ? TinyTrailsColors.emeraldGreen
                    : TinyTrailsColors.error,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: product.isVeg
                      ? TinyTrailsColors.emeraldGreen
                      : TinyTrailsColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: TinyTrailsColors.charcoal,
                  ),
                ),
                if (product.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    product.description!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: TinyTrailsColors.gray500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  product.formattedPrice,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: TinyTrailsColors.charcoal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Add/Quantity Button
          product.inStock
              ? quantity > 0
                  ? _buildQuantityControls(product, quantity)
                  : _buildAddButton(product)
              : _buildOutOfStockLabel(),
        ],
      ),
    );
  }

  Widget _buildAddButton(ProductModel product) {
    return GestureDetector(
      onTap: () => _addToCart(product),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: TinyTrailsColors.royalBlue50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: TinyTrailsColors.royalBlue,
            width: 1.5,
          ),
        ),
        child: Text(
          'ADD +',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: TinyTrailsColors.royalBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControls(ProductModel product, int quantity) {
    return Container(
      decoration: BoxDecoration(
        color: TinyTrailsColors.royalBlue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _removeFromCart(product.id),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.remove,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$quantity',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _addToCart(product),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.add,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutOfStockLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: TinyTrailsColors.gray100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Out of Stock',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: TinyTrailsColors.gray400,
        ),
      ),
    );
  }

  Widget _buildCartBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: TinyTrailsColors.emeraldGreen,
        boxShadow: [
          BoxShadow(
            color: TinyTrailsColors.emeraldGreen.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Item Count & Price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_totalItems ${_totalItems == 1 ? 'Item' : 'Items'}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${_totalPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // View Cart Button
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerCartScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Cart',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: TinyTrailsColors.emeraldGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: TinyTrailsColors.emeraldGreen,
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
}
