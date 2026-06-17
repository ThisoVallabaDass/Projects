import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/cart_service.dart';
import '../theme/theme.dart';
import '../widgets/customer_offer_widgets.dart';

class CustomerShopDetail extends StatefulWidget {
  final Map<String, dynamic> shop;

  const CustomerShopDetail({super.key, required this.shop});

  @override
  State<CustomerShopDetail> createState() => _CustomerShopDetailState();
}

class _CustomerShopDetailState extends State<CustomerShopDetail> {
  int _selectedTab = 0;

  List<Map<String, dynamic>> get _menuItems {
    final vendorId = widget.shop['id'];
    return _allMenuItems.where((item) => item['vendorId'] == vendorId).toList();
  }

  static final List<Map<String, dynamic>> _allMenuItems = [
    // Lakshmi Sweets
    {'id': 'lak-1', 'vendorId': 'lakshmi-sweets', 'name': 'Mysore Pak', 'price': 90.0, 'isVeg': true, 'isBestseller': true, 'description': 'Traditional ghee-based sweet from Mysore'},
    {'id': 'lak-2', 'vendorId': 'lakshmi-sweets', 'name': 'Kaju Katli', 'price': 120.0, 'isVeg': true, 'isBestseller': true, 'description': 'Premium cashew fudge'},
    {'id': 'lak-3', 'vendorId': 'lakshmi-sweets', 'name': 'Gulab Jamun', 'price': 60.0, 'isVeg': true, 'isBestseller': false, 'description': 'Deep-fried milk solids in sugar syrup'},
    {'id': 'lak-4', 'vendorId': 'lakshmi-sweets', 'name': 'Rasgulla', 'price': 70.0, 'isVeg': true, 'isBestseller': false, 'description': 'Soft cottage cheese balls in syrup'},
    {'id': 'lak-5', 'vendorId': 'lakshmi-sweets', 'name': 'Jalebi', 'price': 50.0, 'isVeg': true, 'isBestseller': true, 'description': 'Crispy spiral sweet in sugar syrup'},
    {'id': 'lak-6', 'vendorId': 'lakshmi-sweets', 'name': 'Laddu', 'price': 80.0, 'isVeg': true, 'isBestseller': false, 'description': 'Traditional besan laddu'},
    {'id': 'lak-7', 'vendorId': 'lakshmi-sweets', 'name': 'Peda', 'price': 100.0, 'isVeg': true, 'isBestseller': false, 'description': 'Soft milk-based sweet'},
    {'id': 'lak-8', 'vendorId': 'lakshmi-sweets', 'name': 'Badam Halwa', 'price': 150.0, 'isVeg': true, 'isBestseller': true, 'description': 'Rich almond halwa'},
    // Raju's Pushcart
    {'id': 'raj-1', 'vendorId': 'rajus-pushcart', 'name': 'Samosa', 'price': 50.0, 'isVeg': true, 'isBestseller': true, 'description': 'Crispy pastry with spiced potato filling'},
    {'id': 'raj-2', 'vendorId': 'rajus-pushcart', 'name': 'Egg Kothu Roll', 'price': 85.0, 'isVeg': false, 'isBestseller': true, 'description': 'Scrambled egg wrapped in paratha'},
    {'id': 'raj-3', 'vendorId': 'rajus-pushcart', 'name': 'Pani Puri', 'price': 40.0, 'isVeg': true, 'isBestseller': false, 'description': 'Crispy shells with tangy water'},
    {'id': 'raj-4', 'vendorId': 'rajus-pushcart', 'name': 'Vada Pav', 'price': 45.0, 'isVeg': true, 'isBestseller': false, 'description': 'Mumbai style potato fritter burger'},
    // Green Basket
    {'id': 'fr-1', 'vendorId': 'green-basket', 'name': 'Tomato Basket', 'price': 40.0, 'isVeg': true, 'isBestseller': true, 'description': 'Fresh farm tomatoes - 500g'},
    {'id': 'fr-2', 'vendorId': 'green-basket', 'name': 'Onion Pack', 'price': 35.0, 'isVeg': true, 'isBestseller': false, 'description': 'Fresh onions - 500g'},
    {'id': 'fr-3', 'vendorId': 'green-basket', 'name': 'Potato Sack', 'price': 50.0, 'isVeg': true, 'isBestseller': true, 'description': 'Farm fresh potatoes - 1kg'},
    // Spice Garden Restaurant
    {'id': 'sg-1', 'vendorId': 'spice-garden', 'name': 'Butter Chicken', 'price': 280.0, 'isVeg': false, 'isBestseller': true, 'description': 'Creamy tomato-based chicken curry'},
    {'id': 'sg-2', 'vendorId': 'spice-garden', 'name': 'Paneer Tikka', 'price': 220.0, 'isVeg': true, 'isBestseller': true, 'description': 'Grilled cottage cheese with spices'},
    {'id': 'sg-3', 'vendorId': 'spice-garden', 'name': 'Biryani', 'price': 250.0, 'isVeg': false, 'isBestseller': true, 'description': 'Aromatic rice with tender meat'},
    {'id': 'sg-4', 'vendorId': 'spice-garden', 'name': 'Dal Makhani', 'price': 180.0, 'isVeg': true, 'isBestseller': false, 'description': 'Creamy black lentils'},
    // Glow Beauty
    {'id': 'gb-1', 'vendorId': 'glow-beauty', 'name': 'Face Serum', 'price': 450.0, 'isVeg': false, 'isBestseller': true, 'description': 'Vitamin C brightening serum'},
    {'id': 'gb-2', 'vendorId': 'glow-beauty', 'name': 'Hair Oil', 'price': 350.0, 'isVeg': false, 'isBestseller': false, 'description': 'Herbal hair nourishment'},
    {'id': 'gb-3', 'vendorId': 'glow-beauty', 'name': 'Face Cream', 'price': 280.0, 'isVeg': false, 'isBestseller': true, 'description': 'Moisturizing day cream'},
    // Golden Jewels
    {'id': 'gj-1', 'vendorId': 'golden-jewels', 'name': 'Gold Earrings', 'price': 4500.0, 'isVeg': false, 'isBestseller': true, 'description': 'Traditional gold studs'},
    {'id': 'gj-2', 'vendorId': 'golden-jewels', 'name': 'Silver Chain', 'price': 1200.0, 'isVeg': false, 'isBestseller': false, 'description': 'Sterling silver necklace'},
    {'id': 'gj-3', 'vendorId': 'golden-jewels', 'name': 'Bangles Set', 'price': 2800.0, 'isVeg': false, 'isBestseller': true, 'description': 'Gold plated bangles set of 4'},
    // Selvi Tailors
    {'id': 'tl-1', 'vendorId': 'selvi-tailors', 'name': 'Cotton Mask', 'price': 70.0, 'isVeg': false, 'isBestseller': false, 'description': 'Handmade cotton face mask'},
    {'id': 'tl-2', 'vendorId': 'selvi-tailors', 'name': 'Blouse Stitching', 'price': 350.0, 'isVeg': false, 'isBestseller': true, 'description': 'Custom blouse tailoring'},
    {'id': 'tl-3', 'vendorId': 'selvi-tailors', 'name': 'Pants Alteration', 'price': 150.0, 'isVeg': false, 'isBestseller': false, 'description': 'Professional alterations'},
    // Clay Craft
    {'id': 'ar-1', 'vendorId': 'clay-craft', 'name': 'Clay Pot', 'price': 220.0, 'isVeg': false, 'isBestseller': true, 'description': 'Handcrafted terracotta pot'},
    {'id': 'ar-2', 'vendorId': 'clay-craft', 'name': 'Decorative Vase', 'price': 450.0, 'isVeg': false, 'isBestseller': true, 'description': 'Painted ceramic vase'},
    // FixIt Works
    {'id': 'rp-1', 'vendorId': 'fixit-works', 'name': 'Mixer Repair Service', 'price': 180.0, 'isVeg': false, 'isBestseller': true, 'description': 'Professional mixer/grinder repair'},
    {'id': 'rp-2', 'vendorId': 'fixit-works', 'name': 'Fan Service', 'price': 120.0, 'isVeg': false, 'isBestseller': false, 'description': 'Ceiling fan cleaning and repair'},
    // The Curry House
    {'id': 'ch-1', 'vendorId': 'curry-house', 'name': 'Chicken Curry', 'price': 260.0, 'isVeg': false, 'isBestseller': true, 'description': 'Spicy home-style chicken curry'},
    {'id': 'ch-2', 'vendorId': 'curry-house', 'name': 'Mutton Rogan Josh', 'price': 320.0, 'isVeg': false, 'isBestseller': true, 'description': 'Kashmiri style slow-cooked mutton'},
    {'id': 'ch-3', 'vendorId': 'curry-house', 'name': 'Fish Fry', 'price': 220.0, 'isVeg': false, 'isBestseller': false, 'description': 'Crispy masala fried fish'},
    {'id': 'ch-4', 'vendorId': 'curry-house', 'name': 'Egg Curry', 'price': 150.0, 'isVeg': false, 'isBestseller': false, 'description': 'Boiled eggs in rich gravy'},
    // Veggie Delight
    {'id': 'vd-1', 'vendorId': 'veggie-delight', 'name': 'Palak Paneer', 'price': 200.0, 'isVeg': true, 'isBestseller': true, 'description': 'Cottage cheese in spinach gravy'},
    {'id': 'vd-2', 'vendorId': 'veggie-delight', 'name': 'Veg Biryani', 'price': 180.0, 'isVeg': true, 'isBestseller': true, 'description': 'Aromatic vegetable rice'},
    {'id': 'vd-3', 'vendorId': 'veggie-delight', 'name': 'Chole Bhature', 'price': 140.0, 'isVeg': true, 'isBestseller': false, 'description': 'Spiced chickpeas with fried bread'},
    {'id': 'vd-4', 'vendorId': 'veggie-delight', 'name': 'Aloo Gobi', 'price': 120.0, 'isVeg': true, 'isBestseller': false, 'description': 'Potato and cauliflower curry'},
    // Chai Corner
    {'id': 'cc-1', 'vendorId': 'chai-corner', 'name': 'Masala Chai', 'price': 20.0, 'isVeg': true, 'isBestseller': true, 'description': 'Traditional spiced tea'},
    {'id': 'cc-2', 'vendorId': 'chai-corner', 'name': 'Filter Coffee', 'price': 30.0, 'isVeg': true, 'isBestseller': true, 'description': 'South Indian filter coffee'},
    {'id': 'cc-3', 'vendorId': 'chai-corner', 'name': 'Bun Maska', 'price': 35.0, 'isVeg': true, 'isBestseller': false, 'description': 'Soft bun with butter'},
    {'id': 'cc-4', 'vendorId': 'chai-corner', 'name': 'Bread Omelette', 'price': 50.0, 'isVeg': false, 'isBestseller': false, 'description': 'Classic egg omelette with toast'},
  ];

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final shopName = shop['name'] as String;
    final category = shop['category'] as String;
    final rating = (shop['rating'] as num).toDouble();
    final imageUrl = shop['imageUrl'] as String;
    final isOpen = shop['isOpen'] ?? true;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildAppBar(shopName, imageUrl, isOpen),
          SliverToBoxAdapter(child: _buildShopInfo(shopName, category, rating)),
          SliverToBoxAdapter(child: _buildOffersBanner()),
          SliverToBoxAdapter(child: _buildTabBar()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: _buildMenuList(),
          ),
        ],
      ),
      bottomNavigationBar: _buildCartBar(),
    );
  }

  Widget _buildAppBar(String shopName, String imageUrl, bool isOpen) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: TinyTrailsColors.royalBlue,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
          ),
          child: const Icon(Icons.arrow_back, color: TinyTrailsColors.charcoal, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
            ),
            child: const Icon(Icons.favorite_border, color: TinyTrailsColors.charcoal, size: 20),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Added to favorites!')),
            );
          },
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
            ),
            child: const Icon(Icons.share_outlined, color: TinyTrailsColors.charcoal, size: 20),
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: TinyTrailsColors.royalBlue100,
                child: const Icon(Icons.storefront, size: 60, color: TinyTrailsColors.royalBlue),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                ),
              ),
            ),
            if (!isOpen)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: TinyTrailsColors.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Currently Closed',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopInfo(String shopName, String category, double rating) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  shopName,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: TinyTrailsColors.charcoal,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: TinyTrailsColors.emeraldGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            category,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: TinyTrailsColors.gray500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(Icons.access_time, '30-40 min'),
              const SizedBox(width: 12),
              _buildInfoChip(Icons.location_on_outlined, '2.5 km'),
              const SizedBox(width: 12),
              _buildInfoChip(Icons.currency_rupee, 'Rs.20 delivery'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFFAF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified, color: Color(0xFF166534), size: 18),
                const SizedBox(width: 8),
                Text(
                  'AI Hygiene Verified',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF166534),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '95% Safe Score',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF166534),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TinyTrailsColors.gray100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: TinyTrailsColors.gray500),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: TinyTrailsColors.gray500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersBanner() {
    return CustomerOfferWidgets.offerBanner(
      vendorId: widget.shop['id'],
      height: 140,
      padding: const EdgeInsets.all(16),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Menu', 'Reviews', 'Info'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? TinyTrailsColors.royalBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? TinyTrailsColors.royalBlue : TinyTrailsColors.gray200,
                ),
              ),
              child: Text(
                tabs[index],
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.white : TinyTrailsColors.gray500,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMenuList() {
    if (_selectedTab == 1) {
      return SliverToBoxAdapter(child: _buildReviewsTab());
    }
    if (_selectedTab == 2) {
      return SliverToBoxAdapter(child: _buildInfoTab());
    }

    if (_menuItems.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Text(
              'No menu items available',
              style: GoogleFonts.inter(color: TinyTrailsColors.gray500),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildMenuItem(_menuItems[index]),
        childCount: _menuItems.length,
      ),
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item) {
    final isVeg = item['isVeg'] == true;
    final isBestseller = item['isBestseller'] == true;
    final price = (item['price'] as num).toDouble();

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildVegIndicator(isVeg),
                    if (isBestseller) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'BESTSELLER',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item['name'],
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: TinyTrailsColors.charcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${price.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: TinyTrailsColors.charcoal,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item['description'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: TinyTrailsColors.gray500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Container(
                width: 100,
                height: 80,
                decoration: BoxDecoration(
                  color: TinyTrailsColors.gray100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.restaurant, color: TinyTrailsColors.gray300, size: 32),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _addToCart(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: TinyTrailsColors.royalBlue50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: TinyTrailsColors.royalBlue, width: 1.5),
                  ),
                  child: Text(
                    'ADD',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: TinyTrailsColors.royalBlue,
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

  void _addToCart(Map<String, dynamic> item) {
    final cart = CartService();
    final currentVendorId = cart.getVendorId();
    final newVendorId = widget.shop['id'] as String;

    if (currentVendorId != null && currentVendorId != newVendorId) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Replace cart items?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Your cart contains items from another shop. Would you like to replace them with this item?',
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
                Navigator.pop(context);
                cart.clearCart();
                _doAddToCart(item);
              },
              child: Text(
                'Replace',
                style: GoogleFonts.inter(
                  color: TinyTrailsColors.royalBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      _doAddToCart(item);
    }
  }

  void _doAddToCart(Map<String, dynamic> item) {
    final price = (item['price'] as num).toDouble();
    CartService().addItem({
      'id': item['id'],
      'name': item['name'],
      'price': price,
      'isVeg': item['isVeg'],
      'vendorId': widget.shop['id'],
      'vendorName': widget.shop['name'],
    });
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${item['name']}" to cart'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: TinyTrailsColors.emeraldGreen,
      ),
    );
  }

  Widget _buildVegIndicator(bool isVeg) {
    final color = isVeg ? TinyTrailsColors.emeraldGreen : TinyTrailsColors.error;
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
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

  Widget _buildReviewsTab() {
    final reviews = [
      {'name': 'Priya S.', 'rating': 5, 'comment': 'Amazing quality! Will order again.', 'time': '2 days ago'},
      {'name': 'Rahul K.', 'rating': 4, 'comment': 'Good service, slightly delayed delivery.', 'time': '1 week ago'},
      {'name': 'Anita M.', 'rating': 5, 'comment': 'Best in the area! Highly recommend.', 'time': '2 weeks ago'},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: reviews.map((review) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: TinyTrailsColors.royalBlue50,
                      child: Text(
                        review['name'].toString()[0],
                        style: GoogleFonts.inter(
                          color: TinyTrailsColors.royalBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review['name'] as String,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < (review['rating'] as int) ? Icons.star : Icons.star_border,
                                size: 14,
                                color: const Color(0xFFF59E0B),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      review['time'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: TinyTrailsColors.gray400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  review['comment'] as String,
                  style: GoogleFonts.inter(color: TinyTrailsColors.gray500),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Icons.access_time, 'Timing', '9:00 AM - 10:00 PM'),
            const Divider(height: 24),
            _buildInfoRow(Icons.location_on_outlined, 'Address', '123 Main Street, Anna Nagar, Chennai'),
            const Divider(height: 24),
            _buildInfoRow(Icons.phone_outlined, 'Contact', '+91 98765 43210'),
            const Divider(height: 24),
            _buildInfoRow(Icons.info_outline, 'About', 'Serving quality food with love since 2020. We believe in fresh ingredients and authentic recipes.'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: TinyTrailsColors.royalBlue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: TinyTrailsColors.gray400,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: TinyTrailsColors.charcoal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartBar() {
    final cart = CartService();
    if (cart.items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      decoration: BoxDecoration(
        color: TinyTrailsColors.emeraldGreen,
        boxShadow: [
          BoxShadow(
            color: TinyTrailsColors.emeraldGreen.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${cart.getTotalItemCount()} items | Rs. ${cart.getTotalPrice().toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Extra charges may apply',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: TinyTrailsColors.emeraldGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'View Cart',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
