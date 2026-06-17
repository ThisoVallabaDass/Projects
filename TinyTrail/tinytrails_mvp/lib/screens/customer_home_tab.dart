import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/cart_service.dart';
import '../theme/theme.dart';
import '../widgets/customer_offer_widgets.dart';
import 'customer_cart_tab.dart';
import 'customer_shop_detail.dart';
import 'customer_help_screen.dart';
import 'customer_ai_chat_screen.dart';

enum ProductFilter { all, veg, nonVeg }
enum SearchMode { products, shops }

class CustomerHomeTab extends StatefulWidget {
  const CustomerHomeTab({super.key});

  @override
  State<CustomerHomeTab> createState() => _CustomerHomeTabState();
}

class _CustomerHomeTabState extends State<CustomerHomeTab> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  ProductFilter _activeFilter = ProductFilter.all;
  String? _activeCategory;
  String _locationLabel = 'Locating...';
  String _fullAddress = '';
  bool _isLocating = true;
  SearchMode _searchMode = SearchMode.products;

  final List<String> _categories = [
    'Restaurants',
    'Home Chefs',
    'Street Snacks',
    'Fresh Produce',
    'Beauty Products',
    'Jewellery',
    'Tailors',
    'Artisans',
    'Repairs',
  ];

  final Map<String, IconData> _categoryIcons = {
    'Restaurants': Icons.restaurant,
    'Home Chefs': Icons.restaurant_menu,
    'Street Snacks': Icons.fastfood,
    'Fresh Produce': Icons.eco,
    'Beauty Products': Icons.face_retouching_natural,
    'Jewellery': Icons.diamond_outlined,
    'Tailors': Icons.content_cut,
    'Artisans': Icons.palette_outlined,
    'Repairs': Icons.build_circle_outlined,
  };

  // Dummy shops/vendors
  final List<Map<String, dynamic>> _dummyShops = [
    {
      'id': 'lakshmi-sweets',
      'name': 'Lakshmi Sweets',
      'category': 'Home Chefs',
      'rating': 4.7,
      'isVeg': true,
      'isOpen': true,
      'deliveryTime': '30-40 min',
      'imageUrl': 'assets/Pictures/laddu.jpg',
    },
    {
      'id': 'rajus-pushcart',
      'name': "Raju's Pushcart",
      'category': 'Street Snacks',
      'rating': 4.4,
      'isVeg': false,
      'isOpen': true,
      'deliveryTime': '20-30 min',
      'imageUrl': 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400',
    },
    {
      'id': 'green-basket',
      'name': 'Green Basket',
      'category': 'Fresh Produce',
      'rating': 4.5,
      'isVeg': true,
      'isOpen': true,
      'deliveryTime': '45-60 min',
      'imageUrl': 'https://images.unsplash.com/photo-1546470427-e26264be0b0d?w=400',
    },
    {
      'id': 'spice-garden',
      'name': 'Spice Garden Restaurant',
      'category': 'Restaurants',
      'rating': 4.6,
      'isVeg': false,
      'isOpen': true,
      'deliveryTime': '35-45 min',
      'imageUrl': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400',
    },
    {
      'id': 'glow-beauty',
      'name': 'Glow Beauty Store',
      'category': 'Beauty Products',
      'rating': 4.3,
      'isVeg': false,
      'isOpen': true,
      'deliveryTime': '1-2 days',
      'imageUrl': 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400',
    },
    {
      'id': 'golden-jewels',
      'name': 'Golden Jewels',
      'category': 'Jewellery',
      'rating': 4.8,
      'isVeg': false,
      'isOpen': true,
      'deliveryTime': '2-3 days',
      'imageUrl': 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=400',
    },
    {
      'id': 'selvi-tailors',
      'name': 'Selvi Tailors',
      'category': 'Tailors',
      'rating': 4.2,
      'isVeg': false,
      'isOpen': true,
      'deliveryTime': '3-5 days',
      'imageUrl': 'https://images.unsplash.com/photo-1584736286279-5f915a8d2f17?w=400',
    },
    {
      'id': 'clay-craft',
      'name': 'Clay Craft Studio',
      'category': 'Artisans',
      'rating': 4.6,
      'isVeg': false,
      'isOpen': true,
      'deliveryTime': '2-4 days',
      'imageUrl': 'https://images.unsplash.com/photo-1610701596007-11502861dcfa?w=400',
    },
    {
      'id': 'fixit-works',
      'name': 'FixIt Works',
      'category': 'Repairs',
      'rating': 4.1,
      'isVeg': false,
      'isOpen': true,
      'deliveryTime': 'Same day',
      'imageUrl': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400',
    },
    {
      'id': 'curry-house',
      'name': 'The Curry House',
      'category': 'Restaurants',
      'rating': 4.5,
      'isVeg': false,
      'isOpen': true,
      'deliveryTime': '40-50 min',
      'imageUrl': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400',
    },
    {
      'id': 'veggie-delight',
      'name': 'Veggie Delight',
      'category': 'Restaurants',
      'rating': 4.4,
      'isVeg': true,
      'isOpen': true,
      'deliveryTime': '30-40 min',
      'imageUrl': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
    },
    {
      'id': 'chai-corner',
      'name': 'Chai Corner',
      'category': 'Street Snacks',
      'rating': 4.3,
      'isVeg': true,
      'isOpen': true,
      'deliveryTime': '15-25 min',
      'imageUrl': 'https://images.unsplash.com/photo-1564890369478-c89ca6d9cde9?w=400',
    },
  ];

  final List<Map<String, dynamic>> _dummyProducts = [
    {
      'id': 'lak-1',
      'vendorId': 'lakshmi-sweets',
      'vendorName': 'Lakshmi Sweets',
      'dishName': 'Mysore Pak',
      'price': 90.0,
      'isVeg': true,
      'category': 'Home Chefs',
      'rating': 4.7,
      'imageUrl': 'assets/Pictures/mysore-pak.jpg'
    },
    {
      'id': 'lak-2',
      'vendorId': 'lakshmi-sweets',
      'vendorName': 'Lakshmi Sweets',
      'dishName': 'Kaju Katli',
      'price': 120.0,
      'isVeg': true,
      'category': 'Home Chefs',
      'rating': 4.6,
      'imageUrl': 'assets/Pictures/kaju-katli.jpg'
    },
    {
      'id': 'lak-3',
      'vendorId': 'lakshmi-sweets',
      'vendorName': 'Lakshmi Sweets',
      'dishName': 'Jalebi',
      'price': 80.0,
      'isVeg': true,
      'category': 'Home Chefs',
      'rating': 4.8,
      'imageUrl': 'assets/Pictures/Jalebi.jpg'
    },
    {
      'id': 'lak-4',
      'vendorId': 'lakshmi-sweets',
      'vendorName': 'Lakshmi Sweets',
      'dishName': 'Gulab Jamun',
      'price': 110.0,
      'isVeg': true,
      'category': 'Home Chefs',
      'rating': 4.9,
      'imageUrl': 'assets/Pictures/Gulab Jamun.jpg'
    },
    {
      'id': 'lak-5',
      'vendorId': 'lakshmi-sweets',
      'vendorName': 'Lakshmi Sweets',
      'dishName': 'Rasugulla',
      'price': 75.0,
      'isVeg': true,
      'category': 'Home Chefs',
      'rating': 4.5,
      'imageUrl': 'assets/Pictures/Rasugulla.jpg'
    },
    {
      'id': 'raj-1',
      'vendorId': 'rajus-pushcart',
      'vendorName': "Raju's Pushcart",
      'dishName': 'Samosa',
      'price': 50.0,
      'isVeg': true,
      'category': 'Street Snacks',
      'rating': 4.4,
      'imageUrl': 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400'
    },
    {
      'id': 'raj-2',
      'vendorId': 'rajus-pushcart',
      'vendorName': "Raju's Pushcart",
      'dishName': 'Egg Kothu Roll',
      'price': 85.0,
      'isVeg': false,
      'category': 'Street Snacks',
      'rating': 4.3,
      'imageUrl': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400'
    },
    {
      'id': 'fr-1',
      'vendorId': 'green-basket',
      'vendorName': 'Green Basket',
      'dishName': 'Tomato Basket',
      'price': 40.0,
      'isVeg': true,
      'category': 'Fresh Produce',
      'rating': 4.5,
      'imageUrl': 'https://images.unsplash.com/photo-1546470427-e26264be0b0d?w=400'
    },
    {
      'id': 'sg-1',
      'vendorId': 'spice-garden',
      'vendorName': 'Spice Garden Restaurant',
      'dishName': 'Butter Chicken',
      'price': 280.0,
      'isVeg': false,
      'category': 'Restaurants',
      'rating': 4.6,
      'imageUrl': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400'
    },
    {
      'id': 'sg-2',
      'vendorId': 'spice-garden',
      'vendorName': 'Spice Garden Restaurant',
      'dishName': 'Paneer Tikka',
      'price': 220.0,
      'isVeg': true,
      'category': 'Restaurants',
      'rating': 4.5,
      'imageUrl': 'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=400'
    },
    {
      'id': 'tl-1',
      'vendorId': 'selvi-tailors',
      'vendorName': 'Selvi Tailors',
      'dishName': 'Cotton Mask',
      'price': 70.0,
      'isVeg': false,
      'category': 'Tailors',
      'rating': 4.2,
      'imageUrl': 'https://images.unsplash.com/photo-1584736286279-5f915a8d2f17?w=400'
    },
    {
      'id': 'ar-1',
      'vendorId': 'clay-craft',
      'vendorName': 'Clay Craft',
      'dishName': 'Clay Pot',
      'price': 220.0,
      'isVeg': false,
      'category': 'Artisans',
      'rating': 4.6,
      'imageUrl': 'https://images.unsplash.com/photo-1610701596007-11502861dcfa?w=400'
    },
    {
      'id': 'rp-1',
      'vendorId': 'fixit-works',
      'vendorName': 'FixIt Works',
      'dishName': 'Mixer Repair Service',
      'price': 180.0,
      'isVeg': false,
      'category': 'Repairs',
      'rating': 4.1,
      'imageUrl': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400'
    },
  ];

  // Notification items
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'Order Delivered!',
      'message': 'Your order from Lakshmi Sweets has been delivered.',
      'time': '2 mins ago',
      'read': false,
      'icon': Icons.check_circle,
      'color': TinyTrailsColors.emeraldGreen,
    },
    {
      'id': '2',
      'title': 'Special Offer',
      'message': 'Get 20% off on your next order! Use code: TINY20',
      'time': '1 hour ago',
      'read': false,
      'icon': Icons.local_offer,
      'color': TinyTrailsColors.royalBlue,
    },
    {
      'id': '3',
      'title': 'New Restaurant',
      'message': 'Spice Garden is now available in your area!',
      'time': '2 hours ago',
      'read': true,
      'icon': Icons.restaurant,
      'color': TinyTrailsColors.warning,
    },
  ];

  late List<Map<String, dynamic>> _visibleProducts;
  late List<Map<String, dynamic>> _visibleShops;

  @override
  void initState() {
    super.initState();
    _visibleProducts = List<Map<String, dynamic>>.from(_dummyProducts);
    _visibleShops = List<Map<String, dynamic>>.from(_dummyShops);
    _determinePosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _isLocating = false;
          _locationLabel = 'Enable location';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          _isLocating = false;
          _locationLabel = 'Location denied';
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _isLocating = false;
          _locationLabel = 'Enable in settings';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String area = 'Current Location';
      String fullAddr = '';
      if (places.isNotEmpty) {
        final place = places.first;
        area = (place.subLocality?.trim().isNotEmpty ?? false)
            ? place.subLocality!.trim()
            : ((place.street?.trim().isNotEmpty ?? false)
                ? place.street!.trim()
                : ((place.locality?.trim().isNotEmpty ?? false)
                    ? place.locality!.trim()
                    : 'Current Location'));
        fullAddr = '${place.street}, ${place.subLocality}, ${place.locality} - ${place.postalCode}';
      }

      if (!mounted) return;
      setState(() {
        _isLocating = false;
        _locationLabel = area;
        _fullAddress = fullAddr;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Location fetch failed: $e');
      }
      if (!mounted) return;
      setState(() {
        _isLocating = false;
        _locationLabel = 'Current Location';
      });
    }
  }

  void _filterContent() {
    final query = _searchController.text.trim().toLowerCase();

    // Filter products
    final filteredProducts = _dummyProducts.where((item) {
      final name = (item['dishName'] as String).toLowerCase();
      final vendor = (item['vendorName'] as String).toLowerCase();
      final matchesSearch = query.isEmpty || name.contains(query) || vendor.contains(query);

      final category = item['category'] as String;
      final matchesCategory = _activeCategory == null || category == _activeCategory;

      final isVeg = item['isVeg'] == true;
      final matchesVegState = _activeFilter == ProductFilter.all ||
          (_activeFilter == ProductFilter.veg && isVeg) ||
          (_activeFilter == ProductFilter.nonVeg && !isVeg);

      return matchesSearch && matchesCategory && matchesVegState;
    }).toList();

    // Filter shops
    final filteredShops = _dummyShops.where((shop) {
      final name = (shop['name'] as String).toLowerCase();
      final category = (shop['category'] as String).toLowerCase();
      final matchesSearch = query.isEmpty || name.contains(query) || category.contains(query);

      final shopCategory = shop['category'] as String;
      final matchesCategory = _activeCategory == null || shopCategory == _activeCategory;

      final isVeg = shop['isVeg'] == true;
      final matchesVegState = _activeFilter == ProductFilter.all ||
          (_activeFilter == ProductFilter.veg && isVeg) ||
          (_activeFilter == ProductFilter.nonVeg && !isVeg);

      return matchesSearch && matchesCategory && matchesVegState;
    }).toList();

    setState(() {
      _visibleProducts = filteredProducts;
      _visibleShops = filteredShops;
    });
  }

  Color get _backgroundTint {
    switch (_activeFilter) {
      case ProductFilter.veg:
        return const Color(0xFFF0FDF4);
      case ProductFilter.nonVeg:
        return const Color(0xFFFEF2F2);
      case ProductFilter.all:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: _backgroundTint,
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  _buildSearchBar(),
                  _buildSearchModeToggle(),
                  _buildFilterChips(),
                  _buildCategoryRow(),
                  // Featured offers will be added when offer content is ready
                  // CustomerOfferWidgets.featuredOffersCarousel(height: 140),
                  // const SizedBox(height: 6),
                  Expanded(child: _searchMode == SearchMode.products ? _buildProductFeed() : _buildShopFeed()),
                ],
              ),
              _buildCartBanner(),
              _buildFloatingChatButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showLocationPicker,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: TinyTrailsColors.royalBlue50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.location_on, color: TinyTrailsColors.royalBlue, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _showLocationPicker,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLocating ? 'Locating...' : 'Delivering to',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 11, color: TinyTrailsColors.gray500),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _locationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: TinyTrailsColors.charcoal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, size: 20, color: TinyTrailsColors.charcoal),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: TinyTrailsColors.gray100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                IconButton(
                  onPressed: _showNotificationsPanel,
                  icon: const Icon(Icons.notifications_none, color: TinyTrailsColors.charcoal, size: 22),
                ),
                if (_notifications.any((n) => n['read'] == false))
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: TinyTrailsColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
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

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 16),
            Text(
              'Delivery Location',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TinyTrailsColors.charcoal,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  // Current location card
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _determinePosition();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: TinyTrailsColors.royalBlue50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: TinyTrailsColors.royalBlue),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.my_location, color: TinyTrailsColors.royalBlue, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Use Current Location',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: TinyTrailsColors.royalBlue,
                                  ),
                                ),
                                if (_fullAddress.isNotEmpty)
                                  Text(
                                    _fullAddress,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: TinyTrailsColors.gray500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: TinyTrailsColors.royalBlue),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Saved Addresses',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: TinyTrailsColors.gray500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildSavedAddressTile('Home', 'Flat 12A, Sunshine Apartments, Anna Nagar', Icons.home_outlined),
                  _buildSavedAddressTile('Work', 'Building 5, 3rd Floor, Tech Park, OMR Road', Icons.work_outline),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddAddressSheet(context);
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add New Address'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: TinyTrailsColors.royalBlue),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAddressSheet(BuildContext context) {
    final flatController = TextEditingController();
    final buildingController = TextEditingController();
    final streetController = TextEditingController();
    final areaController = TextEditingController();
    final landmarkController = TextEditingController();
    final pincodeController = TextEditingController();
    String selectedType = 'Home';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Add New Address',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: TinyTrailsColors.charcoal,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      'Address Type',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: TinyTrailsColors.gray500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Home', 'Work', 'Other'].map((type) {
                        final isSelected = selectedType == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedType = type),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? TinyTrailsColors.royalBlue : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? TinyTrailsColors.royalBlue : TinyTrailsColors.gray200,
                                ),
                              ),
                              child: Text(
                                type,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isSelected ? Colors.white : TinyTrailsColors.gray500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _buildAddressTextField(flatController, 'Flat / House No.', 'e.g., Flat 12A'),
                    const SizedBox(height: 12),
                    _buildAddressTextField(buildingController, 'Building / Apartment Name', 'e.g., Sunshine Apartments'),
                    const SizedBox(height: 12),
                    _buildAddressTextField(streetController, 'Street / Road', 'e.g., MG Road'),
                    const SizedBox(height: 12),
                    _buildAddressTextField(areaController, 'Area / Locality', 'e.g., Anna Nagar'),
                    const SizedBox(height: 12),
                    _buildAddressTextField(landmarkController, 'Landmark (Optional)', 'e.g., Near City Mall'),
                    const SizedBox(height: 12),
                    _buildAddressTextField(pincodeController, 'Pincode', 'e.g., 600040', isNumber: true),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (flatController.text.isEmpty || areaController.text.isEmpty || pincodeController.text.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Please fill required fields')),
                            );
                            return;
                          }
                          final fullAddr = '${flatController.text}, ${buildingController.text.isNotEmpty ? '${buildingController.text}, ' : ''}${streetController.text.isNotEmpty ? '${streetController.text}, ' : ''}${areaController.text}${landmarkController.text.isNotEmpty ? ', Near ${landmarkController.text}' : ''} - ${pincodeController.text}';
                          setState(() {
                            _locationLabel = selectedType;
                            _fullAddress = fullAddr;
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Address saved successfully!'),
                              backgroundColor: TinyTrailsColors.emeraldGreen,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TinyTrailsColors.royalBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Save Address',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressTextField(TextEditingController controller, String label, String hint, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: TinyTrailsColors.gray500),
        hintStyle: GoogleFonts.inter(fontSize: 13, color: TinyTrailsColors.gray300),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: TinyTrailsColors.royalBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildSavedAddressTile(String label, String address, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _locationLabel = label;
          _fullAddress = address;
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TinyTrailsColors.gray200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: TinyTrailsColors.gray100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: TinyTrailsColors.gray500, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: TinyTrailsColors.charcoal,
                    ),
                  ),
                  Text(
                    address,
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
            const Icon(Icons.chevron_right, color: TinyTrailsColors.gray400),
          ],
        ),
      ),
    );
  }

  void _showNotificationsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: TinyTrailsColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: TinyTrailsColors.charcoal,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        for (var n in _notifications) {
                          n['read'] = true;
                        }
                      });
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Mark all read',
                      style: GoogleFonts.inter(
                        color: TinyTrailsColors.royalBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 60, color: TinyTrailsColors.gray300),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications',
                            style: GoogleFonts.inter(
                              color: TinyTrailsColors.gray500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final notif = _notifications[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: (notif['color'] as Color).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(notif['icon'] as IconData, color: notif['color'] as Color),
                          ),
                          title: Text(
                            notif['title'],
                            style: GoogleFonts.inter(
                              fontWeight: notif['read'] == true ? FontWeight.w500 : FontWeight.w700,
                              color: TinyTrailsColors.charcoal,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notif['message'],
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: TinyTrailsColors.gray500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif['time'],
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: TinyTrailsColors.gray400,
                                ),
                              ),
                            ],
                          ),
                          trailing: notif['read'] != true
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: TinyTrailsColors.royalBlue,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: TinyTrailsColors.gray200),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (_) => _filterContent(),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: _searchMode == SearchMode.products
                      ? 'Search products and dishes...'
                      : 'Search restaurants and shops...',
                  hintStyle: GoogleFonts.inter(fontSize: 14, color: TinyTrailsColors.gray400),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                onPressed: () {
                  _searchController.clear();
                  _filterContent();
                },
                icon: const Icon(Icons.close, size: 20),
              ),
            // Trail AI Button
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    TinyTrailsColors.royalBlue,
                    TinyTrailsColors.royalBlue400,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: TinyTrailsColors.royalBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CustomerAiChatScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: TinyTrailsColors.royalBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.search, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          _buildModeChip('Products', SearchMode.products),
          const SizedBox(width: 10),
          _buildModeChip('Shops & Restaurants', SearchMode.shops),
        ],
      ),
    );
  }

  Widget _buildModeChip(String label, SearchMode mode) {
    final isActive = _searchMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _searchMode = mode);
        _filterContent();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? TinyTrailsColors.royalBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? TinyTrailsColors.royalBlue : TinyTrailsColors.gray200,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : TinyTrailsColors.gray500,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Pure Veg',
            isActive: _activeFilter == ProductFilter.veg,
            isVegIndicator: true,
            onTap: () {
              _activeFilter = _activeFilter == ProductFilter.veg ? ProductFilter.all : ProductFilter.veg;
              _filterContent();
            },
          ),
          const SizedBox(width: 10),
          _buildFilterChip(
            label: 'Non-Veg',
            isActive: _activeFilter == ProductFilter.nonVeg,
            isVegIndicator: false,
            onTap: () {
              _activeFilter = _activeFilter == ProductFilter.nonVeg ? ProductFilter.all : ProductFilter.nonVeg;
              _filterContent();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required bool isVegIndicator,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? TinyTrailsColors.royalBlue : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? TinyTrailsColors.royalBlue : TinyTrailsColors.gray200,
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildVegIndicator(isVegIndicator, size: 14),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : TinyTrailsColors.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow() {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, index) {
          final category = _categories[index];
          final isActive = _activeCategory == category;
          return GestureDetector(
            onTap: () {
              _activeCategory = isActive ? null : category;
              _filterContent();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isActive ? TinyTrailsColors.royalBlue : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? TinyTrailsColors.royalBlue : TinyTrailsColors.gray200,
                    ),
                  ),
                  child: Icon(
                    _categoryIcons[category],
                    color: isActive ? Colors.white : TinyTrailsColors.gray500,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 60,
                  child: Text(
                    category,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: TinyTrailsColors.charcoal,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: _categories.length,
      ),
    );
  }

  Widget _buildProductFeed() {
    if (_visibleProducts.isEmpty) {
      return Center(
        child: Text(
          'No matching products found.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: TinyTrailsColors.gray500,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      itemCount: _visibleProducts.length,
      itemBuilder: (context, index) => _buildProductCard(_visibleProducts[index]),
    );
  }

  Widget _buildShopFeed() {
    if (_visibleShops.isEmpty) {
      return Center(
        child: Text(
          'No matching shops found.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: TinyTrailsColors.gray500,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      itemCount: _visibleShops.length,
      itemBuilder: (context, index) => _buildShopCard(_visibleShops[index]),
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop) {
    final String name = shop['name'] as String;
    final String category = shop['category'] as String;
    final String imageUrl = shop['imageUrl'] as String;
    final bool isVeg = shop['isVeg'] == true;
    final double rating = (shop['rating'] as num).toDouble();
    final String deliveryTime = shop['deliveryTime'] as String;
    final bool isOpen = shop['isOpen'] ?? true;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CustomerShopDetail(shop: shop)),
        ).then((_) {
          if (mounted) setState(() {});
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: imageUrl.startsWith('assets/')
                        ? Image.asset(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: TinyTrailsColors.gray100,
                              child: const Center(
                                child: Icon(Icons.image_not_supported,
                                  color: TinyTrailsColors.gray300),
                              ),
                            ),
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: TinyTrailsColors.gray100,
                              child: const Center(
                          child: Icon(Icons.storefront, size: 40, color: TinyTrailsColors.gray300),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isOpen)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: TinyTrailsColors.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Currently Closed',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Color(0xFFF59E0B), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: TinyTrailsColors.charcoal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _buildVegIndicator(isVeg, size: 18),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: TinyTrailsColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        category,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: TinyTrailsColors.gray500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: TinyTrailsColors.gray400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time, size: 14, color: TinyTrailsColors.gray500),
                      const SizedBox(width: 4),
                      Text(
                        deliveryTime,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: TinyTrailsColors.gray500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFFAF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, size: 14, color: Color(0xFF166534)),
                        const SizedBox(width: 4),
                        Text(
                          'AI Verified Safe',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF166534),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    final String id = item['id'] as String;
    final String vendorId = item['vendorId'] as String;
    final String vendorName = item['vendorName'] as String;
    final String dishName = item['dishName'] as String;
    final String imageUrl = item['imageUrl'] as String;
    final bool isVeg = item['isVeg'] == true;
    final double rating = (item['rating'] as num).toDouble();
    final double price = (item['price'] as num).toDouble();

    return GestureDetector(
      onTap: () {
        final shop = _dummyShops.firstWhere(
          (s) => s['id'] == vendorId,
          orElse: () => {'id': vendorId, 'name': vendorName, 'category': item['category'], 'rating': rating, 'imageUrl': imageUrl, 'isOpen': true},
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CustomerShopDetail(shop: shop)),
        ).then((_) {
          if (mounted) setState(() {});
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 102,
                height: 108,
                child: imageUrl.startsWith('assets/')
                    ? Image.asset(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: TinyTrailsColors.gray100,
                          child: Icon(Icons.restaurant, size: 34, color: TinyTrailsColors.gray300),
                        ),
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: TinyTrailsColors.gray100,
                          child: Icon(Icons.restaurant, size: 34, color: TinyTrailsColors.gray300),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: TinyTrailsColors.gray500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildVegIndicator(isVeg),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dishName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: TinyTrailsColors.charcoal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: TinyTrailsColors.charcoal,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFFAF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, size: 12, color: Color(0xFF166534)),
                              const SizedBox(width: 3),
                              Text(
                                '95% Safe',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF166534),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rs. ${price.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: TinyTrailsColors.charcoal,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _addToCart(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: TinyTrailsColors.royalBlue50,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: TinyTrailsColors.royalBlue, width: 1.4),
                            ),
                            child: Text(
                              'ADD +',
                              style: GoogleFonts.inter(
                                fontSize: 12,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(Map<String, dynamic> item) {
    final cart = CartService();
    final currentVendorId = cart.getVendorId();
    final newVendorId = item['vendorId'] as String;

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
            'Your cart contains items from another shop. Would you like to replace them?',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: TinyTrailsColors.gray500)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                cart.clearCart();
                _doAddToCart(item);
              },
              child: Text(
                'Replace',
                style: GoogleFonts.inter(color: TinyTrailsColors.royalBlue, fontWeight: FontWeight.w600),
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
    final String id = item['id'] as String;
    final String vendorId = item['vendorId'] as String;
    final String vendorName = item['vendorName'] as String;
    final String dishName = item['dishName'] as String;
    final bool isVeg = item['isVeg'] == true;
    final double price = (item['price'] as num).toDouble();

    CartService().addItem({
      'id': id,
      'name': dishName,
      'price': price,
      'isVeg': isVeg,
      'vendorId': vendorId,
      'vendorName': vendorName,
    });
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "$dishName" to cart'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: TinyTrailsColors.emeraldGreen,
      ),
    );
  }

  Widget _buildVegIndicator(bool isVeg, {double size = 16}) {
    final color = isVeg ? TinyTrailsColors.emeraldGreen : TinyTrailsColors.error;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color, width: 1.8),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Container(
          width: size * 0.48,
          height: size * 0.48,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _buildCartBanner() {
    final cart = CartService();
    if (cart.items.isEmpty) return const SizedBox.shrink();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerCartTab())).then((_) {
            if (mounted) setState(() {});
          });
        },
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: TinyTrailsColors.emeraldGreen,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: TinyTrailsColors.emeraldGreen.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${cart.getTotalItemCount()} Items | Rs. ${cart.getTotalPrice().toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'View Cart >',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingChatButton() {
    final cart = CartService();
    final bottomPadding = cart.items.isEmpty ? 24.0 : 90.0;

    return Positioned(
      right: 16,
      bottom: bottomPadding,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CustomerHelpScreen()),
          );
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: TinyTrailsColors.royalBlue,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: TinyTrailsColors.royalBlue.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
