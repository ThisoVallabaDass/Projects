import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/theme.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _currentNavIndex = 0;
  bool _isVegActive = false;
  bool _isNonVegActive = false;

  // Placeholder categories
  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.shopping_cart, 'name': 'Karts', 'emoji': '🛒'},
    {'icon': Icons.restaurant, 'name': 'Home Chefs', 'emoji': '👨‍🍳'},
    {'icon': Icons.fastfood, 'name': 'Street Snacks', 'emoji': '🍿'},
    {'icon': Icons.local_grocery_store, 'name': 'Groceries', 'emoji': '🥬'},
    {'icon': Icons.brush, 'name': 'Artisans', 'emoji': '🎨'},
  ];

  // Placeholder vendors
  final List<Map<String, dynamic>> _vendors = [
    {
      'name': 'Amma\'s Kitchen',
      'type': 'Home Chef',
      'distance': '1.2 km',
      'isMoving': false,
      'hygiene': 98,
      'tier': 'gold',
      'rating': 4.8,
      'image': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=300',
    },
    {
      'name': 'Raju\'s Chai Cart',
      'type': 'Mobile Kart',
      'distance': '800m',
      'isMoving': true,
      'hygiene': 95,
      'tier': 'blue',
      'rating': 4.6,
      'image': 'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=300',
    },
    {
      'name': 'Fresh Bakes Studio',
      'type': 'Home Chef',
      'distance': '2.5 km',
      'isMoving': false,
      'hygiene': 99,
      'tier': 'platinum',
      'rating': 4.9,
      'image': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=300',
    },
    {
      'name': 'Street Samosa King',
      'type': 'Street Vendor',
      'distance': '500m',
      'isMoving': true,
      'hygiene': 92,
      'tier': 'blue',
      'rating': 4.5,
      'image': 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=300',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TinyTrailsColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: _buildHeader(),
                ),
                // Search & Filters
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickySearchDelegate(
                    child: _buildSearchZone(),
                  ),
                ),
                // Category Carousel
                SliverToBoxAdapter(
                  child: _buildCategoryCarousel(),
                ),
                // Live Radar Banner
                SliverToBoxAdapter(
                  child: _buildLiveRadarBanner(),
                ),
                // Section Title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Near You',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: TinyTrailsColors.charcoal,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'See All',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TinyTrailsColors.royalBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Vendor Feed
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildVendorCard(_vendors[index]);
                      },
                      childCount: _vendors.length,
                    ),
                  ),
                ),
                // Bottom Spacing for nav
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
            // Bottom Navigation
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomNav(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Location
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: TinyTrailsColors.royalBlue50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.location_on,
                  color: TinyTrailsColors.royalBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivering to',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: TinyTrailsColors.gray500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '600062',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: TinyTrailsColors.charcoal,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 20,
                        color: TinyTrailsColors.charcoal,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Notification Bell
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: TinyTrailsColors.gray100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: TinyTrailsColors.charcoal,
                  size: 22,
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: TinyTrailsColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: TinyTrailsColors.white,
                      width: 1.5,
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

  Widget _buildSearchZone() {
    return Container(
      color: TinyTrailsColors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          // Search Bar
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: TinyTrailsColors.gray100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(
                  Icons.search,
                  color: TinyTrailsColors.gray400,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for snacks, tailors...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: TinyTrailsColors.gray400,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: TinyTrailsColors.charcoal,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: TinyTrailsColors.gray300,
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.mic_none,
                    color: TinyTrailsColors.royalBlue,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Veg / Non-Veg Filters
          Row(
            children: [
              _buildFilterChip(
                label: 'Veg',
                emoji: '🟢',
                isActive: _isVegActive,
                onTap: () {
                  setState(() {
                    _isVegActive = !_isVegActive;
                  });
                },
              ),
              const SizedBox(width: 10),
              _buildFilterChip(
                label: 'Non-Veg',
                emoji: '🔴',
                isActive: _isNonVegActive,
                onTap: () {
                  setState(() {
                    _isNonVegActive = !_isNonVegActive;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String emoji,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? TinyTrailsColors.charcoal : TinyTrailsColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? TinyTrailsColors.charcoal : TinyTrailsColors.gray200,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? TinyTrailsColors.white : TinyTrailsColors.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCarousel() {
    return Container(
      height: 110,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        TinyTrailsColors.royalBlue50,
                        TinyTrailsColors.royalBlue100,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: TinyTrailsColors.royalBlue.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      category['emoji'],
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  category['name'],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: TinyTrailsColors.charcoal,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiveRadarBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TinyTrailsColors.royalBlue,
            TinyTrailsColors.royalBlue700,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: TinyTrailsColors.royalBlue.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Radar Animation Placeholder
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3 Mobile Karts near you!',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track them live on the radar',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: TinyTrailsColors.royalBlue,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Open Map',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorCard(Map<String, dynamic> vendor) {
    Color getTierColor(String tier) {
      switch (tier) {
        case 'gold':
          return TinyTrailsColors.badgeGold;
        case 'platinum':
          return TinyTrailsColors.badgePlatinum;
        default:
          return TinyTrailsColors.badgeBlue;
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/customer-vendor-view',
          arguments: {
            'vendorId': vendor['name'], // Use name as ID for now
            'vendorName': vendor['name'],
            'businessType': vendor['type'],
            'hygieneScore': vendor['hygiene'],
            'trustTier': vendor['tier'],
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: TinyTrailsColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image with Hygiene Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  child: Container(
                    width: 120,
                    height: 130,
                    color: TinyTrailsColors.gray100,
                    child: Icon(
                      Icons.restaurant,
                      size: 40,
                      color: TinyTrailsColors.gray300,
                    ),
                  ),
                ),
                // Hygiene Badge
                Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: TinyTrailsColors.emeraldGreen,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: TinyTrailsColors.emeraldGreen.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '✨',
                        style: TextStyle(fontSize: 10),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${vendor['hygiene']}%',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Trust Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vendor['name'],
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: TinyTrailsColors.charcoal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: getTierColor(vendor['tier']).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified,
                          size: 16,
                          color: getTierColor(vendor['tier']),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Type
                  Text(
                    vendor['type'],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: TinyTrailsColors.gray500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Distance & Rating
                  Row(
                    children: [
                      // Movement indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: vendor['isMoving']
                              ? TinyTrailsColors.royalBlue50
                              : TinyTrailsColors.gray100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              vendor['isMoving']
                                  ? Icons.directions_walk
                                  : Icons.store,
                              size: 14,
                              color: vendor['isMoving']
                                  ? TinyTrailsColors.royalBlue
                                  : TinyTrailsColors.gray500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              vendor['isMoving']
                                  ? 'Moving • ${vendor['distance']}'
                                  : vendor['distance'],
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: vendor['isMoving']
                                    ? TinyTrailsColors.royalBlue
                                    : TinyTrailsColors.gray500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Rating
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: TinyTrailsColors.warning,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${vendor['rating']}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: TinyTrailsColors.charcoal,
                            ),
                          ),
                        ],
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

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: TinyTrailsColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
            _buildNavItem(1, Icons.radar_outlined, Icons.radar, 'Live Map'),
            _buildNavItem(
                2, Icons.shopping_bag_outlined, Icons.shopping_bag, 'Cart'),
            _buildNavItem(3, Icons.person_outline, Icons.person, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentNavIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? TinyTrailsColors.royalBlue50 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive
                  ? TinyTrailsColors.royalBlue
                  : TinyTrailsColors.gray400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? TinyTrailsColors.royalBlue
                    : TinyTrailsColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sticky Search Header Delegate
class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickySearchDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 130;

  @override
  double get minExtent => 130;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
