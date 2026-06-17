import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../theme/theme.dart';
import 'customer_shop_detail.dart';

class CustomerMapTab extends StatefulWidget {
  const CustomerMapTab({super.key});

  @override
  State<CustomerMapTab> createState() => _CustomerMapTabState();
}

class _CustomerMapTabState extends State<CustomerMapTab> {
  final MapController _mapController = MapController();
  static const LatLng _chennaiCenter = LatLng(13.0827, 80.2707);
  final TextEditingController _searchController = TextEditingController();

  LatLng? _userLocation;
  Map<String, dynamic>? _selectedVendor;
  String? _selectedCategory;

  final List<Map<String, dynamic>> _nearbyVendors = [
    {
      'id': 'lakshmi-sweets',
      'name': 'Lakshmi Sweets',
      'category': 'Home Chefs',
      'rating': 4.7,
      'distance': '0.8 km',
      'deliveryTime': '30-40 min',
      'isOpen': true,
      'isVeg': true,
      'position': const LatLng(13.0860, 80.2715),
      'imageUrl': 'https://images.unsplash.com/photo-1535141192574-5d4897c12636?w=400',
    },
    {
      'id': 'rajus-pushcart',
      'name': "Raju's Pushcart",
      'category': 'Street Snacks',
      'rating': 4.4,
      'distance': '1.2 km',
      'deliveryTime': '20-30 min',
      'isOpen': true,
      'isVeg': false,
      'position': const LatLng(13.0798, 80.2662),
      'imageUrl': 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400',
    },
    {
      'id': 'spice-garden',
      'name': 'Spice Garden Restaurant',
      'category': 'Restaurants',
      'rating': 4.6,
      'distance': '1.5 km',
      'deliveryTime': '35-45 min',
      'isOpen': true,
      'isVeg': false,
      'position': const LatLng(13.0904, 80.2768),
      'imageUrl': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400',
    },
    {
      'id': 'green-basket',
      'name': 'Green Basket',
      'category': 'Fresh Produce',
      'rating': 4.5,
      'distance': '0.5 km',
      'deliveryTime': '45-60 min',
      'isOpen': true,
      'isVeg': true,
      'position': const LatLng(13.0815, 80.2680),
      'imageUrl': 'https://images.unsplash.com/photo-1546470427-e26264be0b0d?w=400',
    },
    {
      'id': 'glow-beauty',
      'name': 'Glow Beauty Store',
      'category': 'Beauty Products',
      'rating': 4.3,
      'distance': '2.0 km',
      'deliveryTime': '1-2 days',
      'isOpen': true,
      'isVeg': false,
      'position': const LatLng(13.0780, 80.2750),
      'imageUrl': 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400',
    },
    {
      'id': 'fixit-works',
      'name': 'FixIt Works',
      'category': 'Repairs',
      'rating': 4.1,
      'distance': '1.8 km',
      'deliveryTime': 'Same day',
      'isOpen': true,
      'isVeg': false,
      'position': const LatLng(13.0850, 80.2630),
      'imageUrl': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400',
    },
  ];

  List<Map<String, dynamic>> get _filteredVendors {
    if (_selectedCategory == null) return _nearbyVendors;
    return _nearbyVendors.where((v) => v['category'] == _selectedCategory).toList();
  }

  final List<String> _categories = [
    'All',
    'Restaurants',
    'Home Chefs',
    'Street Snacks',
    'Fresh Produce',
    'Beauty Products',
    'Repairs',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Map location error: $e');
      }
    }
  }

  void _recenterMap() {
    final target = _userLocation ?? _chennaiCenter;
    _mapController.move(target, _userLocation == null ? 13.0 : 15.0);
  }

  void _selectVendor(Map<String, dynamic> vendor) {
    setState(() {
      _selectedVendor = vendor;
    });
    _mapController.move(vendor['position'] as LatLng, 16.0);
  }

  @override
  Widget build(BuildContext context) {
    final vendorMarkers = _filteredVendors.map((vendor) {
      final isSelected = _selectedVendor?['id'] == vendor['id'];
      final position = vendor['position'] as LatLng;

      return Marker(
        point: position,
        width: isSelected ? 60 : 52,
        height: isSelected ? 60 : 52,
        child: GestureDetector(
          onTap: () => _selectVendor(vendor),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? TinyTrailsColors.royalBlue : TinyTrailsColors.emeraldGreen,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: isSelected ? 3 : 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isSelected ? 0.25 : 0.18),
                  blurRadius: isSelected ? 12 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _getCategoryIcon(vendor['category']),
              color: Colors.white,
              size: isSelected ? 28 : 22,
            ),
          ),
        ),
      );
    }).toList();

    final userMarker = _userLocation == null
        ? <Marker>[]
        : [
            Marker(
              point: _userLocation!,
              width: 24,
              height: 24,
              child: Container(
                decoration: BoxDecoration(
                  color: TinyTrailsColors.royalBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: TinyTrailsColors.royalBlue.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ];

    final userCircle = _userLocation == null
        ? <CircleMarker>[]
        : [
            CircleMarker(
              point: _userLocation!,
              radius: 60,
              color: TinyTrailsColors.royalBlue.withValues(alpha: 0.12),
              borderColor: TinyTrailsColors.royalBlue.withValues(alpha: 0.30),
              borderStrokeWidth: 1,
            ),
          ];

    return Scaffold(
      backgroundColor: TinyTrailsColors.white,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _chennaiCenter,
              initialZoom: 13.0,
              onTap: (_, __) {
                setState(() => _selectedVendor = null);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tinytrails.mvp',
              ),
              CircleLayer(circles: userCircle),
              MarkerLayer(markers: [...vendorMarkers, ...userMarker]),
            ],
          ),
          // Search bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search nearby vendors...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: TinyTrailsColors.gray400,
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        // Simple search filter
                        setState(() {});
                      },
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: TinyTrailsColors.royalBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.search, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ),
          // Category filter chips
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = (category == 'All' && _selectedCategory == null) ||
                      _selectedCategory == category;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category == 'All' ? null : category;
                        _selectedVendor = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? TinyTrailsColors.royalBlue : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        category,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : TinyTrailsColors.gray500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Vendor cards at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: SizedBox(
              height: 130,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _filteredVendors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _buildVendorCard(_filteredVendors[index]),
              ),
            ),
          ),
          // Recenter button
          Positioned(
            bottom: 170,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: TinyTrailsColors.charcoal),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.remove, color: TinyTrailsColors.charcoal),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'recenter',
                  onPressed: _recenterMap,
                  backgroundColor: TinyTrailsColors.royalBlue,
                  elevation: 4,
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
              ],
            ),
          ),
          // Selected vendor detail card
          if (_selectedVendor != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 120,
              left: 16,
              right: 16,
              child: _buildSelectedVendorCard(),
            ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Restaurants':
        return Icons.restaurant;
      case 'Home Chefs':
        return Icons.restaurant_menu;
      case 'Street Snacks':
        return Icons.fastfood;
      case 'Fresh Produce':
        return Icons.eco;
      case 'Beauty Products':
        return Icons.face_retouching_natural;
      case 'Repairs':
        return Icons.build;
      default:
        return Icons.storefront;
    }
  }

  Widget _buildVendorCard(Map<String, dynamic> vendor) {
    final isSelected = _selectedVendor?['id'] == vendor['id'];

    return GestureDetector(
      onTap: () => _selectVendor(vendor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: TinyTrailsColors.royalBlue, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.15 : 0.08),
              blurRadius: isSelected ? 16 : 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: TinyTrailsColors.emeraldGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(vendor['category']),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    vendor['name'],
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: TinyTrailsColors.charcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vendor['category'],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: TinyTrailsColors.gray500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        '${vendor['rating']}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.location_on_outlined, size: 14, color: TinyTrailsColors.gray400),
                      const SizedBox(width: 2),
                      Text(
                        vendor['distance'],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: TinyTrailsColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedVendorCard() {
    final vendor = _selectedVendor!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  vendor['imageUrl'],
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 70,
                    height: 70,
                    color: TinyTrailsColors.gray100,
                    child: Icon(
                      _getCategoryIcon(vendor['category']),
                      color: TinyTrailsColors.gray400,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vendor['name'],
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: TinyTrailsColors.charcoal,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _selectedVendor = null),
                          icon: const Icon(Icons.close, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    Text(
                      vendor['category'],
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: TinyTrailsColors.gray500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: TinyTrailsColors.emeraldGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                '${vendor['rating']}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.location_on_outlined, size: 16, color: TinyTrailsColors.gray400),
                        const SizedBox(width: 4),
                        Text(
                          vendor['distance'],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: TinyTrailsColors.gray500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time, size: 16, color: TinyTrailsColors.gray400),
                        const SizedBox(width: 4),
                        Text(
                          vendor['deliveryTime'],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: TinyTrailsColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Getting directions to ${vendor['name']}...')),
                    );
                  },
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('Directions'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: TinyTrailsColors.royalBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerShopDetail(shop: vendor),
                      ),
                    );
                  },
                  icon: const Icon(Icons.storefront, size: 18),
                  label: const Text('View Shop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TinyTrailsColors.royalBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
