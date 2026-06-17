import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'ai/ai_concierge.dart';
import 'customer/customer_orders.dart';
import 'shared.dart';
import 'vendor/vendor_orders.dart';

class TinyTrailShell extends StatefulWidget {
  const TinyTrailShell({
    super.key,
    required this.profile,
  });

  final AppProfile profile;

  @override
  State<TinyTrailShell> createState() => _TinyTrailShellState();
}

class _TinyTrailShellState extends State<TinyTrailShell> {
  int selectedIndex = 0;
  bool shiftStarted = false;
  bool seeding = false;
  bool highHygieneOnly = false;
  String selectedCategory = 'All';
  String customerPincode = '600062';
  String searchQuery = '';
  String? infoText;
  String? editingProductId;

  final pincodeController = TextEditingController(text: '600062');
  final shopName = TextEditingController();
  final address = TextEditingController();
  final story = TextEditingController();
  final storyVideoUrl = TextEditingController();
  final handwrittenMenuUrl = TextEditingController();
  final productName = TextEditingController();
  final productDescription = TextEditingController();
  final productCategory = TextEditingController();
  final productPrice = TextEditingController();

  final List<Map<String, dynamic>> cartItems = <Map<String, dynamic>>[];

  bool get isVendor => widget.profile.role == 'SELLER';

  static const List<_CategoryMeta> categories = <_CategoryMeta>[
    _CategoryMeta(
      label: 'Home Kitchens',
      icon: Icons.restaurant_menu_rounded,
      tint: Color(0xFFFFEAD7),
      iconColor: Color(0xFFCC6B1C),
    ),
    _CategoryMeta(
      label: 'Fresh Produce',
      icon: Icons.eco_rounded,
      tint: Color(0xFFE1F4E8),
      iconColor: Color(0xFF227A3B),
    ),
    _CategoryMeta(
      label: 'Street Snacks',
      icon: Icons.fastfood_rounded,
      tint: Color(0xFFFFE3E8),
      iconColor: Color(0xFFCC3E63),
    ),
    _CategoryMeta(
      label: 'Tailoring',
      icon: Icons.content_cut_rounded,
      tint: Color(0xFFE3E8FF),
      iconColor: Color(0xFF3359C9),
    ),
    _CategoryMeta(
      label: 'Artisans',
      icon: Icons.palette_outlined,
      tint: Color(0xFFF4E7FF),
      iconColor: Color(0xFF7A40B5),
    ),
    _CategoryMeta(
      label: 'Essentials',
      icon: Icons.shopping_basket_rounded,
      tint: Color(0xFFE4F6FF),
      iconColor: Color(0xFF0E7490),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bootstrapShell();
  }

  Future<void> _bootstrapShell() async {
    await _seedDemoDataIfNeeded();
    if (isVendor) {
      await _loadVendorProfile();
    }
  }

  Future<void> _seedDemoDataIfNeeded() async {
    final store = FirebaseFirestore.instance;
    final markerRef = store.collection('meta').doc('demo_seed_v2');
    final marker = await markerRef.get();
    if (marker.exists) return;

    if (mounted) setState(() => seeding = true);

    final batch = store.batch();
    final now = FieldValue.serverTimestamp();

    Map<String, dynamic> vendorSeed({
      required String id,
      required String shopName,
      required String tagline,
      required String storyText,
      required String businessType,
      required String badge,
      required String pincode,
      required String address,
      required String imageUrl,
      int? hygieneScore,
    }) {
      return <String, dynamic>{
        'id': id,
        'shopName': shopName,
        'tagline': tagline,
        'story': storyText,
        'businessType': businessType,
        'badge': badge,
        'hygieneScore': hygieneScore,
        'pincode': pincode,
        'address': address,
        'imageUrl': imageUrl,
        'updatedAt': now,
      };
    }

    Map<String, dynamic> productSeed({
      required String id,
      required String vendorId,
      required String vendorName,
      required String name,
      required String description,
      required String category,
      required double price,
      required String pincode,
      required double distanceKm,
      required bool moving,
      required String imageUrl,
      int? hygieneScore,
    }) {
      return <String, dynamic>{
        'id': id,
        'vendorId': vendorId,
        'vendorName': vendorName,
        'name': name,
        'description': description,
        'category': category,
        'price': price,
        'pincode': pincode,
        'hygieneScore': hygieneScore,
        'distanceKm': distanceKm,
        'moving': moving,
        'inStock': true,
        'imageUrl': imageUrl,
        'createdAt': now,
      };
    }

    final vendors = <Map<String, dynamic>>[
      vendorSeed(
        id: 'demo_vendor_amma_snacks',
        shopName: 'Amma Snacks',
        tagline: 'Murukku, mixture, and sweets made at home',
        storyText: 'A trusted home kitchen making fresh evening snack boxes for nearby families.',
        businessType: 'food',
        badge: 'Gold',
        hygieneScore: 95,
        pincode: '600062',
        address: 'Velachery Main Road',
        imageUrl: 'https://picsum.photos/seed/amma-snacks/400/300',
      ),
      vendorSeed(
        id: 'demo_vendor_ravi_street_foods',
        shopName: 'Ravi Street Foods',
        tagline: 'Hot bajji, samosa, tea, and evening street bites',
        storyText: 'Ravi serves fresh street snacks from a live cart with fast local pickup.',
        businessType: 'food',
        badge: 'Blue',
        hygieneScore: 91,
        pincode: '600062',
        address: 'Pallikaranai Market Street',
        imageUrl: 'https://picsum.photos/seed/ravi-street-foods/400/300',
      ),
      vendorSeed(
        id: 'demo_vendor_lakshmi_tailors',
        shopName: 'Lakshmi Tailors',
        tagline: 'Daily alterations, blouse stitching, and repairs',
        storyText: 'Simple neighborhood tailoring with fast turnarounds and custom fittings.',
        businessType: 'tailor',
        badge: 'Verified',
        pincode: '600062',
        address: 'Medavakkam Junction',
        imageUrl: 'https://picsum.photos/seed/lakshmi-tailors/400/300',
      ),
      vendorSeed(
        id: 'demo_vendor_kumar_fresh_juice',
        shopName: 'Kumar Fresh Juice',
        tagline: 'Fruit juices, shakes, and seasonal coolers',
        storyText: 'Fresh juice vendor with hygienic prep and quick service for office crowds.',
        businessType: 'food',
        badge: 'Platinum',
        hygieneScore: 96,
        pincode: '600062',
        address: 'OMR Bus Stop',
        imageUrl: 'https://picsum.photos/seed/kumar-fresh-juice/400/300',
      ),
      vendorSeed(
        id: 'demo_vendor_priya_crafts',
        shopName: 'Priya Handmade Crafts',
        tagline: 'Handmade gifts, pooja decor, and local craft items',
        storyText: 'Small-batch handmade products with custom festive gift packing.',
        businessType: 'artisan',
        badge: 'Verified',
        pincode: '600061',
        address: 'Madipakkam Bazaar',
        imageUrl: 'https://picsum.photos/seed/priya-crafts/400/300',
      ),
    ];

    for (final vendor in vendors) {
      batch.set(
        store.collection('vendors').doc(vendor['id'] as String),
        vendor,
        SetOptions(merge: true),
      );
    }

    final products = <Map<String, dynamic>>[
      productSeed(
        id: 'demo_product_1',
        vendorId: 'demo_vendor_amma_snacks',
        vendorName: 'Amma Snacks',
        name: 'Murukku',
        description: 'Crunchy spiral murukku packed fresh every morning.',
        category: 'Street Snacks',
        price: 50,
        pincode: '600062',
        hygieneScore: 95,
        distanceKm: 0.4,
        moving: false,
        imageUrl: 'https://picsum.photos/seed/murukku/400/300',
      ),
      productSeed(
        id: 'demo_product_2',
        vendorId: 'demo_vendor_amma_snacks',
        vendorName: 'Amma Snacks',
        name: 'Mixture',
        description: 'Spicy and crunchy mixture in family snack packs.',
        category: 'Street Snacks',
        price: 55,
        pincode: '600062',
        hygieneScore: 95,
        distanceKm: 0.5,
        moving: false,
        imageUrl: 'https://picsum.photos/seed/mixture/400/300',
      ),
      productSeed(
        id: 'demo_product_3',
        vendorId: 'demo_vendor_amma_snacks',
        vendorName: 'Amma Snacks',
        name: 'Laddu',
        description: 'Soft ladoos packed in sweet boxes for festivals and gifting.',
        category: 'Home Kitchens',
        price: 80,
        pincode: '600062',
        hygieneScore: 94,
        distanceKm: 0.7,
        moving: false,
        imageUrl: 'https://picsum.photos/seed/laddu/400/300',
      ),
      productSeed(
        id: 'demo_product_4',
        vendorId: 'demo_vendor_ravi_street_foods',
        vendorName: 'Ravi Street Foods',
        name: 'Samosa',
        description: 'Hot potato samosas served with chutney.',
        category: 'Street Snacks',
        price: 25,
        pincode: '600062',
        hygieneScore: 91,
        distanceKm: 0.3,
        moving: true,
        imageUrl: 'https://picsum.photos/seed/samosa/400/300',
      ),
      productSeed(
        id: 'demo_product_5',
        vendorId: 'demo_vendor_ravi_street_foods',
        vendorName: 'Ravi Street Foods',
        name: 'Bajji',
        description: 'Fresh chilli bajji with hot oil crunch and chutney.',
        category: 'Street Snacks',
        price: 30,
        pincode: '600062',
        hygieneScore: 90,
        distanceKm: 0.5,
        moving: true,
        imageUrl: 'https://picsum.photos/seed/bajji/400/300',
      ),
      productSeed(
        id: 'demo_product_6',
        vendorId: 'demo_vendor_ravi_street_foods',
        vendorName: 'Ravi Street Foods',
        name: 'Tea',
        description: 'Strong hot chai served through the evening rush.',
        category: 'Street Snacks',
        price: 15,
        pincode: '600062',
        hygieneScore: 91,
        distanceKm: 0.2,
        moving: true,
        imageUrl: 'https://picsum.photos/seed/tea/400/300',
      ),
      productSeed(
        id: 'demo_product_7',
        vendorId: 'demo_vendor_lakshmi_tailors',
        vendorName: 'Lakshmi Tailors',
        name: 'Blouse Stitching',
        description: 'Custom blouse stitching with fitting session included.',
        category: 'Tailoring',
        price: 450,
        pincode: '600062',
        distanceKm: 1.0,
        moving: false,
        imageUrl: 'https://picsum.photos/seed/blouse-stitching/400/300',
      ),
      productSeed(
        id: 'demo_product_8',
        vendorId: 'demo_vendor_lakshmi_tailors',
        vendorName: 'Lakshmi Tailors',
        name: 'Pants Alteration',
        description: 'Quick tapering and hemming for daily wear.',
        category: 'Tailoring',
        price: 180,
        pincode: '600062',
        distanceKm: 1.3,
        moving: false,
        imageUrl: 'https://picsum.photos/seed/pants-alteration/400/300',
      ),
      productSeed(
        id: 'demo_product_9',
        vendorId: 'demo_vendor_lakshmi_tailors',
        vendorName: 'Lakshmi Tailors',
        name: 'Zip Repair',
        description: 'Bag and blouse zip replacement service.',
        category: 'Tailoring',
        price: 120,
        pincode: '600062',
        distanceKm: 0.9,
        moving: false,
        imageUrl: 'https://picsum.photos/seed/zip-repair/400/300',
      ),
      productSeed(
        id: 'demo_product_10',
        vendorId: 'demo_vendor_kumar_fresh_juice',
        vendorName: 'Kumar Fresh Juice',
        name: 'Orange Juice',
        description: 'Fresh pressed orange juice with no added sugar.',
        category: 'Fresh Produce',
        price: 70,
        pincode: '600062',
        hygieneScore: 96,
        distanceKm: 0.6,
        moving: true,
        imageUrl: 'https://picsum.photos/seed/orange-juice/400/300',
      ),
      productSeed(
        id: 'demo_product_11',
        vendorId: 'demo_vendor_kumar_fresh_juice',
        vendorName: 'Kumar Fresh Juice',
        name: 'Mosambi Juice',
        description: 'Light and fresh mosambi juice for afternoon heat.',
        category: 'Fresh Produce',
        price: 65,
        pincode: '600062',
        hygieneScore: 95,
        distanceKm: 0.7,
        moving: true,
        imageUrl: 'https://picsum.photos/seed/mosambi-juice/400/300',
      ),
      productSeed(
        id: 'demo_product_12',
        vendorId: 'demo_vendor_kumar_fresh_juice',
        vendorName: 'Kumar Fresh Juice',
        name: 'Watermelon Cooler',
        description: 'Cold watermelon cooler for quick summer refresh.',
        category: 'Fresh Produce',
        price: 60,
        pincode: '600062',
        hygieneScore: 96,
        distanceKm: 0.8,
        moving: true,
        imageUrl: 'https://picsum.photos/seed/watermelon-cooler/400/300',
      ),
      productSeed(
        id: 'demo_product_13',
        vendorId: 'demo_vendor_priya_crafts',
        vendorName: 'Priya Handmade Crafts',
        name: 'Handmade Diyas',
        description: 'Clay diyas painted by hand for festive gifting.',
        category: 'Artisans',
        price: 150,
        pincode: '600061',
        distanceKm: 1.5,
        moving: false,
        imageUrl: 'https://picsum.photos/seed/diyas/400/300',
      ),
      productSeed(
        id: 'demo_product_14',
        vendorId: 'demo_vendor_priya_crafts',
        vendorName: 'Priya Handmade Crafts',
        name: 'Macrame Wall Decor',
        description: 'Soft handmade wall decor pieces for home gifting.',
        category: 'Artisans',
        price: 420,
        pincode: '600061',
        distanceKm: 1.7,
        moving: false,
        imageUrl: 'https://picsum.photos/seed/macrame/400/300',
      ),
      productSeed(
        id: 'demo_product_15',
        vendorId: 'demo_vendor_priya_crafts',
        vendorName: 'Priya Handmade Crafts',
        name: 'Gift Tag Set',
        description: 'Small handmade gift tag bundle for events and orders.',
        category: 'Artisans',
        price: 90,
        pincode: '600061',
        distanceKm: 1.2,
        moving: false,
        imageUrl: 'https://picsum.photos/seed/gift-tags/400/300',
      ),
    ];

    for (final product in products) {
      batch.set(
        store.collection('products').doc(product['id'] as String),
        product,
        SetOptions(merge: true),
      );
    }

    batch.set(markerRef, <String, dynamic>{'seededAt': now});
    await batch.commit();

    if (mounted) setState(() => seeding = false);
  }

  Future<void> _loadVendorProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _ensureCurrentVendorWorkspaceSeeded(user);

    final data = await _getVendorData(user.uid);
    if (data == null) return;
    final location = data['location'] is Map<String, dynamic>
        ? data['location'] as Map<String, dynamic>
        : (data['location'] is Map ? Map<String, dynamic>.from(data['location'] as Map) : null);

    shopName.text = (data['shopName'] as String?) ?? '';
    address.text = (data['address'] as String?) ?? (data['description'] as String?) ?? '';
    story.text = (data['story'] as String?) ?? '';
    storyVideoUrl.text = (data['storyVideoUrl'] as String?) ?? '';
    handwrittenMenuUrl.text = (data['handwrittenMenuUrl'] as String?) ?? '';
    pincodeController.text =
        (data['pincode'] as String?) ?? (location?['pincode'] as String?) ?? customerPincode;
  }

  Future<Map<String, dynamic>?> _getVendorData(String uid) async {
    final store = FirebaseFirestore.instance;
    final directDoc = await store.collection('vendors').doc(uid).get();
    if (directDoc.exists) {
      return directDoc.data();
    }

    final ownerQuery =
        await store.collection('vendors').where('ownerId', isEqualTo: uid).limit(1).get();
    if (ownerQuery.docs.isNotEmpty) {
      return ownerQuery.docs.first.data();
    }

    return null;
  }

  Future<void> _ensureCurrentVendorWorkspaceSeeded(User user) async {
    final email = user.email?.toLowerCase() ?? '';
    if (email != 'vendor@tinytrail.com' &&
        email != 'tailor@tinytrail.com' &&
        email != 'artisan@tinytrail.com') {
      return;
    }

    final store = FirebaseFirestore.instance;
    final vendorRef = store.collection('vendors').doc(user.uid);
    final existingVendor = await vendorRef.get();

    final businessType = email == 'vendor@tinytrail.com'
        ? 'food'
        : (email == 'tailor@tinytrail.com' ? 'tailor' : 'artisan');
    final vendorName = email == 'vendor@tinytrail.com'
        ? 'Amma Snacks'
        : (email == 'tailor@tinytrail.com'
            ? 'Lakshmi Tailors'
            : 'Priya Handmade Crafts');
    final vendorStory = email == 'vendor@tinytrail.com'
        ? 'Fresh home snacks prepared in small batches for nearby families.'
        : (email == 'tailor@tinytrail.com'
            ? 'Friendly neighborhood tailoring with quick pickup and fitting.'
            : 'Handmade local craft products for gifts and festive occasions.');
    final pincode = email == 'artisan@tinytrail.com' ? '600061' : '600062';

    if (!existingVendor.exists) {
      await vendorRef.set({
        'ownerId': user.uid,
        'shopName': vendorName,
        'address': email == 'vendor@tinytrail.com'
            ? 'Velachery Main Road'
            : (email == 'tailor@tinytrail.com'
                ? 'Medavakkam Junction'
                : 'Madipakkam Bazaar'),
        'pincode': pincode,
        'story': vendorStory,
        'storyVideoUrl': '',
        'handwrittenMenuUrl': '',
        'businessType': businessType,
        'badge': businessType == 'food' ? 'Gold' : 'Verified',
        'hygieneScore': businessType == 'food' ? 94 : null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    final products = await store
        .collection('products')
        .where('vendorId', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (products.docs.isNotEmpty) return;

    final batch = store.batch();
    final demoProducts = email == 'vendor@tinytrail.com'
        ? <Map<String, dynamic>>[
            {
              'name': 'Murukku',
              'description': 'Crunchy spiral murukku packed fresh every morning.',
              'category': 'Street Snacks',
              'price': 50,
              'imageUrl': 'https://picsum.photos/seed/demo-food-1/400/300',
            },
            {
              'name': 'Mixture',
              'description': 'Spicy mixture snack box for evening tea.',
              'category': 'Street Snacks',
              'price': 55,
              'imageUrl': 'https://picsum.photos/seed/demo-food-2/400/300',
            },
            {
              'name': 'Laddu',
              'description': 'Sweet laddus packed in gift-ready boxes.',
              'category': 'Home Kitchens',
              'price': 80,
              'imageUrl': 'https://picsum.photos/seed/demo-food-3/400/300',
            },
          ]
        : email == 'tailor@tinytrail.com'
            ? <Map<String, dynamic>>[
                {
                  'name': 'Blouse Stitching',
                  'description': 'Custom blouse stitching with fitting session.',
                  'category': 'Tailoring',
                  'price': 450,
                  'imageUrl': 'https://picsum.photos/seed/demo-tailor-1/400/300',
                },
                {
                  'name': 'Pants Alteration',
                  'description': 'Quick taper and hemming for daily wear.',
                  'category': 'Tailoring',
                  'price': 180,
                  'imageUrl': 'https://picsum.photos/seed/demo-tailor-2/400/300',
                },
                {
                  'name': 'Zip Repair',
                  'description': 'Replacement and repair for dresses and bags.',
                  'category': 'Tailoring',
                  'price': 120,
                  'imageUrl': 'https://picsum.photos/seed/demo-tailor-3/400/300',
                },
              ]
            : <Map<String, dynamic>>[
                {
                  'name': 'Handmade Diyas',
                  'description': 'Painted clay diyas for festive gifting.',
                  'category': 'Artisans',
                  'price': 150,
                  'imageUrl': 'https://picsum.photos/seed/demo-artisan-1/400/300',
                },
                {
                  'name': 'Macrame Decor',
                  'description': 'Soft handmade decor pieces for home styling.',
                  'category': 'Artisans',
                  'price': 420,
                  'imageUrl': 'https://picsum.photos/seed/demo-artisan-2/400/300',
                },
                {
                  'name': 'Gift Tag Set',
                  'description': 'Small handmade tag set for events and packaging.',
                  'category': 'Artisans',
                  'price': 90,
                  'imageUrl': 'https://picsum.photos/seed/demo-artisan-3/400/300',
                },
              ];

    for (var index = 0; index < demoProducts.length; index++) {
      final item = demoProducts[index];
      batch.set(store.collection('products').doc('${user.uid}_demo_$index'), {
        'vendorId': user.uid,
        'vendorName': vendorName,
        'name': item['name'],
        'description': item['description'],
        'category': item['category'],
        'price': item['price'],
        'pincode': pincode,
        'businessType': businessType,
        'hygieneScore': businessType == 'food' ? 94 : null,
        'distanceKm': 0.2 + (index * 0.1),
        'moving': businessType == 'food',
        'inStock': true,
        'imageUrl': item['imageUrl'],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> saveVendorProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('vendors').doc(user.uid).set({
      'ownerId': user.uid,
      'shopName': shopName.text.trim(),
      'address': address.text.trim(),
      'pincode': pincodeController.text.trim(),
      'location': {
        'lat': 0,
        'lng': 0,
        'pincode': pincodeController.text.trim(),
      },
      'story': story.text.trim(),
      'storyVideoUrl': storyVideoUrl.text.trim(),
      'handwrittenMenuUrl': handwrittenMenuUrl.text.trim(),
      'businessType': widget.profile.businessType,
      'badge': widget.profile.isFoodVendor ? 'Gold' : 'Verified',
      'hygieneScore': widget.profile.isFoodVendor ? 94 : null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'pincode': pincodeController.text.trim(),
      'businessType': widget.profile.businessType,
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() => infoText = 'Vendor profile saved.');
  }

  void _startEditingProduct(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    setState(() {
      editingProductId = doc.id;
      productName.text = (data['name'] as String?) ?? '';
      productDescription.text = (data['description'] as String?) ?? '';
      productCategory.text = (data['category'] as String?) ?? '';
      productPrice.text = (((data['price'] as num?) ?? 0)).toString();
      infoText = 'Editing ${(data['name'] as String?) ?? 'product'}';
    });
  }

  Future<void> _deleteProduct(String productId) async {
    await FirebaseFirestore.instance.collection('products').doc(productId).delete();
    if (!mounted) return;
    setState(() => infoText = 'Product deleted.');
  }

  Future<void> addProduct() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final payload = {
      'vendorId': user.uid,
      'vendorName': shopName.text.trim().isEmpty ? widget.profile.username : shopName.text.trim(),
      'name': productName.text.trim(),
      'description': productDescription.text.trim(),
      'category': productCategory.text.trim().isEmpty ? 'Home Kitchens' : productCategory.text.trim(),
      'price': double.tryParse(productPrice.text.trim()) ?? 0,
      'pincode': pincodeController.text.trim().isEmpty ? customerPincode : pincodeController.text.trim(),
      'businessType': widget.profile.businessType,
      'hygieneScore': widget.profile.isFoodVendor ? 94 : null,
      'distanceKm': 0.2,
      'moving': widget.profile.isFoodVendor,
      'inStock': true,
      'imageUrl':
          'https://picsum.photos/seed/${Uri.encodeComponent(productName.text.trim().isEmpty ? 'tinytrail-product' : productName.text.trim())}/400/300',
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (editingProductId != null) {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(editingProductId)
          .set(payload, SetOptions(merge: true));
    } else {
      await FirebaseFirestore.instance.collection('products').add(payload);
    }

    final wasEditing = editingProductId != null;
    editingProductId = null;
    productName.clear();
    productDescription.clear();
    productCategory.clear();
    productPrice.clear();

    if (!mounted) return;
    setState(() => infoText = wasEditing ? 'Product updated.' : 'Product added.');
  }

  void _addToCart(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final index = cartItems.indexWhere((item) => item['id'] == doc.id);

    setState(() {
      if (index >= 0) {
        cartItems[index]['quantity'] = (cartItems[index]['quantity'] as int) + 1;
      } else {
        cartItems.add(<String, dynamic>{
          'id': doc.id,
          'name': (data['name'] as String?) ?? 'Product',
          'vendorName': (data['vendorName'] as String?) ?? 'Local Vendor',
          'price': ((data['price'] as num?) ?? 0).toDouble(),
          'quantity': 1,
        });
      }
      infoText = 'Added ${(data['name'] as String?) ?? 'item'} to cart.';
    });
  }

  Future<void> _openAiConcierge() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AiConciergeScreen(),
      ),
    );
  }

  Future<void> _openCustomerOrders() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CustomerOrdersScreen(),
      ),
    );
  }

  Future<void> _openVendorOrders() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const VendorOrdersScreen(),
      ),
    );
  }

  @override
  void dispose() {
    pincodeController.dispose();
    shopName.dispose();
    address.dispose();
    story.dispose();
    storyVideoUrl.dispose();
    handwrittenMenuUrl.dispose();
    productName.dispose();
    productDescription.dispose();
    productCategory.dispose();
    productPrice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: selectedIndex,
          children: isVendor
              ? <Widget>[
                  VendorDashboardView(
                    vendorName: widget.profile.username,
                    businessType: widget.profile.businessType,
                    shiftStarted: shiftStarted,
                    onToggleShift: () => setState(() => shiftStarted = !shiftStarted),
                    onOpenProducts: () => setState(() => selectedIndex = 1),
                    onOpenOrders: _openVendorOrders,
                    onOpenProfile: () => setState(() => selectedIndex = 3),
                  ),
                  VendorProductsView(
                    profile: widget.profile,
                    shopName: shopName,
                    address: address,
                    story: story,
                    storyVideoUrl: storyVideoUrl,
                    handwrittenMenuUrl: handwrittenMenuUrl,
                    pincodeController: pincodeController,
                    productName: productName,
                    productDescription: productDescription,
                    productCategory: productCategory,
                    productPrice: productPrice,
                    onSaveVendor: saveVendorProfile,
                    onAddProduct: addProduct,
                    onEditProduct: _startEditingProduct,
                    onDeleteProduct: _deleteProduct,
                    editingProductId: editingProductId,
                    infoText: infoText,
                  ),
                  VendorEarningsView(infoText: infoText),
                  ProfileView(
                    profile: widget.profile,
                    isVendor: true,
                    shiftStarted: shiftStarted,
                    onOpenOrders: _openVendorOrders,
                  ),
                ]
              : <Widget>[
                  CustomerHomeView(
                    profile: widget.profile,
                    pincodeController: pincodeController,
                    customerPincode: customerPincode,
                    searchQuery: searchQuery,
                    selectedCategory: selectedCategory,
                    highHygieneOnly: highHygieneOnly,
                    seeding: seeding,
                    onSearchChanged: (value) => setState(() => searchQuery = value),
                    onCategoryChanged: (value) => setState(() => selectedCategory = value),
                    onToggleHygiene: () => setState(() => highHygieneOnly = !highHygieneOnly),
                    onApplyPincode: () => setState(() {
                      customerPincode = pincodeController.text.trim();
                    }),
                    onAddToCart: _addToCart,
                    onBrowseProducts: () => setState(() => selectedCategory = 'All'),
                    onOpenAi: _openAiConcierge,
                    onOpenOrders: _openCustomerOrders,
                    onOpenProfile: () => setState(() => selectedIndex = 3),
                    onOpenLiveMap: () => setState(() => selectedIndex = 1),
                  ),
                  LiveMapView(pincode: customerPincode),
                  CartView(
                    items: cartItems,
                    onClear: () => setState(() => cartItems.clear()),
                  ),
                  ProfileView(
                    profile: widget.profile,
                    isVendor: false,
                    shiftStarted: false,
                    onOpenOrders: _openCustomerOrders,
                  ),
                ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => setState(() => selectedIndex = index),
        destinations: isVendor
            ? const <NavigationDestination>[
                NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
                NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Products'),
                NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Earnings'),
                NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
              ]
            : const <NavigationDestination>[
                NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Live Map'),
                NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), label: 'Cart'),
                NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
              ],
      ),
    );
  }
}

class CustomerHomeView extends StatelessWidget {
  const CustomerHomeView({
    super.key,
    required this.profile,
    required this.pincodeController,
    required this.customerPincode,
    required this.searchQuery,
    required this.selectedCategory,
    required this.highHygieneOnly,
    required this.seeding,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onToggleHygiene,
    required this.onApplyPincode,
    required this.onAddToCart,
    required this.onBrowseProducts,
    required this.onOpenAi,
    required this.onOpenOrders,
    required this.onOpenProfile,
    required this.onOpenLiveMap,
  });

  final AppProfile profile;
  final TextEditingController pincodeController;
  final String customerPincode;
  final String searchQuery;
  final String selectedCategory;
  final bool highHygieneOnly;
  final bool seeding;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onToggleHygiene;
  final VoidCallback onApplyPincode;
  final void Function(DocumentSnapshot<Map<String, dynamic>>) onAddToCart;
  final VoidCallback onBrowseProducts;
  final VoidCallback onOpenAi;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenLiveMap;

  bool _matchesProduct(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final category = (data['category'] as String?) ?? '';
    final name = (data['name'] as String?) ?? '';
    final description = (data['description'] as String?) ?? '';
    final hygiene = ((data['hygieneScore'] as num?) ?? 0).toInt();
    final inStock = (data['inStock'] as bool?) ?? true;
    final combined = '$name $description $category'.toLowerCase();

    final matchesCategory =
        selectedCategory == 'All' || category.toLowerCase().contains(selectedCategory.toLowerCase());
    final matchesQuery =
        searchQuery.trim().isEmpty || combined.contains(searchQuery.trim().toLowerCase());
    final matchesHygiene = !highHygieneOnly || hygiene >= 90;

    return inStock && matchesCategory && matchesQuery && matchesHygiene;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SoftCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppPalette.customer, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Delivering to $customerPincode',
                          style: const TextStyle(
                            color: AppPalette.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: AppPalette.muted),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _RoundIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: () {},
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 19,
                backgroundColor: AppPalette.customer,
                child: Text(
                  profile.username.isEmpty ? 'U' : profile.username[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A2563EB),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order from home kitchens, street carts, and local makers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Discover trusted vendors near $customerPincode and quickly reorder the things you love.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    StatusPill(
                      label: 'Snacks',
                      background: Colors.white24,
                      foreground: Colors.white,
                    ),
                    StatusPill(
                      label: 'Meals',
                      background: Colors.white24,
                      foreground: Colors.white,
                    ),
                    StatusPill(
                      label: 'Tailoring',
                      background: Colors.white24,
                      foreground: Colors.white,
                    ),
                    StatusPill(
                      label: 'Crafts',
                      background: Colors.white24,
                      foreground: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Talk or type in Tamil or English: e.g. evlo price murukku near me',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: const Icon(Icons.mic_none_rounded, color: AppPalette.customer),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: onToggleHygiene,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppPalette.customer,
                        side: BorderSide(
                          color: highHygieneOnly ? AppPalette.customer : const Color(0xFFD7E0EA),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                      ),
                      child: Icon(highHygieneOnly ? Icons.verified_rounded : Icons.tune_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pincodeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Pincode',
                          prefixIcon: Icon(Icons.pin_drop_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: onApplyPincode,
                        child: const Text('Update'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _AdaptiveCardGrid(
            mainAxisExtent: 174,
            children: [
              _ActionShortcutCard(
                icon: Icons.storefront_outlined,
                title: 'Browse Products',
                subtitle: 'See local items nearby',
                accent: AppPalette.customer,
                onTap: onBrowseProducts,
              ),
              _ActionShortcutCard(
                icon: Icons.auto_awesome_rounded,
                title: 'Ask TinyTrails',
                subtitle: 'Search by voice or text',
                accent: AppPalette.customer,
                onTap: onOpenAi,
              ),
              _ActionShortcutCard(
                icon: Icons.receipt_long_outlined,
                title: 'My Orders',
                subtitle: 'Track active and past orders',
                accent: AppPalette.customer,
                onTap: onOpenOrders,
              ),
              _ActionShortcutCard(
                icon: Icons.person_outline_rounded,
                title: 'Profile',
                subtitle: 'Account and delivery details',
                accent: AppPalette.customer,
                onTap: onOpenProfile,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SectionHeader(
            title: 'Shop by category',
            action: 'See all',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _TinyTrailShellState.categories
                .map(
                  (category) => Container(
                    width: 104,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: category.tint,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          ),
                          child: Icon(category.icon, color: category.iconColor),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          category.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppPalette.ink,
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Moving vendors near you',
                  subtitle: 'Live carts pulse here when they enter your area.',
                ),
                const SizedBox(height: 14),
                Container(
                  height: 124,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: const Color(0xFFE9F2FF),
                  ),
                  child: Stack(
                    children: const [
                      _RadarDot(left: 34, top: 28),
                      _RadarDot(right: 52, top: 58),
                      _RadarDot(left: 132, bottom: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.tonal(
                  onPressed: onOpenLiveMap,
                  style: FilledButton.styleFrom(
                    foregroundColor: AppPalette.customer,
                    backgroundColor: const Color(0xFFE8F0FE),
                  ),
                  child: const Text('View Live Map'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeader(
            title: 'Popular in your pincode',
            action: 'Trusted locals',
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('vendors')
                  .where('pincode', isEqualTo: customerPincode)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                if (docs.isEmpty && !seeding) {
                  return const Center(
                    child: Text(
                      'Local vendors will appear here once added.',
                      style: TextStyle(color: AppPalette.muted),
                    ),
                  );
                }

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    return VendorPreviewCard(
                      name: (data['shopName'] as String?) ?? 'Local Vendor',
                      note: (data['tagline'] as String?) ??
                          (data['story'] as String?) ??
                          'Hyperlocal marketplace vendor',
                      badge: (data['badge'] as String?) ?? 'Blue',
                      hygiene: (data['businessType'] as String?) == 'food'
                          ? '${((data['hygieneScore'] as num?) ?? 0).toInt()}% Safe'
                          : 'Trusted seller',
                      avatarColor: index.isEven ? AppPalette.vendor : AppPalette.customer,
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeader(
            title: 'Product listing',
            subtitle: 'Local results around your pincode',
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Home Kitchens', 'Fresh Produce', 'Street Snacks', 'Tailoring', 'Artisans', 'Essentials']
                  .map(
                    (label) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _CategoryFilterChip(
                        label: label,
                        selected: selectedCategory == label,
                        onTap: () => onCategoryChanged(label),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where('pincode', isEqualTo: customerPincode)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = (snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                  .where(_matchesProduct)
                  .toList();

              if (docs.isEmpty) {
                return const SoftCard(
                  child: Column(
                    children: [
                      Icon(Icons.shopping_basket_outlined, size: 44, color: Color(0xFF8AA0BE)),
                      SizedBox(height: 14),
                      Text(
                        'It\'s quiet around here!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppPalette.ink,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No vendors are currently live in your area. Try another pincode or come back soon.',
                        style: TextStyle(color: AppPalette.muted, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: docs.map((doc) {
                  final data = doc.data();
                  return SizedBox(
                    width: (MediaQuery.of(context).size.width - 48 - 12) / 2,
                    child: MarketplaceProductCard(
                      name: (data['name'] as String?) ?? 'Product',
                      description: (data['description'] as String?) ?? 'No description',
                      vendorName: (data['vendorName'] as String?) ?? 'Local Vendor',
                      price: ((data['price'] as num?) ?? 0).toDouble(),
                      hygieneLabel: ((data['businessType'] as String?) ?? 'food') == 'food'
                          ? '${((data['hygieneScore'] as num?) ?? 0).toInt()}% Safe'
                          : 'Trusted seller',
                      distanceLabel: '${((data['distanceKm'] as num?) ?? 0).toString()} km',
                      isMoving: (data['moving'] as bool?) ?? false,
                      imageUrl: data['imageUrl'] as String?,
                      onAdd: () => onAddToCart(doc),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class LiveMapView extends StatelessWidget {
  const LiveMapView({
    super.key,
    required this.pincode,
  });

  final String pincode;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Live Map',
            subtitle: 'Moving vendors and digital hails will appear here.',
          ),
          const SizedBox(height: 16),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    StatusPill(
                      label: 'Radius 2 km',
                      background: Color(0xFFEAF2FF),
                      foreground: AppPalette.customer,
                    ),
                    SizedBox(width: 8),
                    StatusPill(
                      label: 'Open now',
                      background: Color(0xFFF4F6F8),
                      foreground: AppPalette.ink,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: const Color(0xFFEAF2FF),
                  ),
                  child: Stack(
                    children: const [
                      _RadarDot(left: 44, top: 46),
                      _RadarDot(left: 184, top: 98),
                      _RadarDot(right: 54, bottom: 42),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('vendors')
                .where('pincode', isEqualTo: pincode)
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              return Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SoftCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppPalette.customer,
                            child: Text(
                              ((data['shopName'] as String?) ?? 'V')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (data['shopName'] as String?) ?? 'Local Vendor',
                                  style: const TextStyle(
                                    color: AppPalette.ink,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (data['tagline'] as String?) ?? 'Moving vendor nearby',
                                  style: const TextStyle(color: AppPalette.muted),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFE8F0FE),
                              foregroundColor: AppPalette.customer,
                            ),
                            child: const Text('Hail'),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class CartView extends StatelessWidget {
  const CartView({
    super.key,
    required this.items,
    required this.onClear,
  });

  final List<Map<String, dynamic>> items;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(
      0,
      (runningTotal, item) => runningTotal + ((item['price'] as double) * (item['quantity'] as int)),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Cart',
            subtitle: 'Shared cart and checkout flow can plug in here next.',
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const SoftCard(
              child: Column(
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 44, color: Color(0xFF8AA0BE)),
                  SizedBox(height: 14),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.ink,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button on products to build your order.',
                    style: TextStyle(color: AppPalette.muted, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else ...[
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SoftCard(
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.local_dining_rounded, color: AppPalette.customer),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] as String,
                              style: const TextStyle(
                                color: AppPalette.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['vendorName'] as String,
                              style: const TextStyle(color: AppPalette.muted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'x${item['quantity']}',
                        style: const TextStyle(
                          color: AppPalette.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total: Rs. ${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppPalette.ink,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () {},
                          child: const Text('Checkout'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: onClear,
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class VendorDashboardView extends StatelessWidget {
  const VendorDashboardView({
    super.key,
    required this.vendorName,
    required this.businessType,
    required this.shiftStarted,
    required this.onToggleShift,
    required this.onOpenProducts,
    required this.onOpenOrders,
    required this.onOpenProfile,
  });

  final String vendorName;
  final String businessType;
  final bool shiftStarted;
  final VoidCallback onToggleShift;
  final VoidCallback onOpenProducts;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final requiresHygiene = businessType == 'food';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF6EE7B7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2210B981),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.storefront_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Good Morning, $vendorName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  shiftStarted
                      ? 'You are live now and have 5 new orders waiting.'
                      : 'Start your shift when your workspace is ready for customers.',
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SoftCard(
            color: shiftStarted ? const Color(0xFFE7F7EB) : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusPill(
                      label: shiftStarted ? 'LIVE' : 'OFFLINE',
                      background: shiftStarted
                          ? const Color(0xFFD8F5DF)
                          : const Color(0xFFF4F6F8),
                      foreground: shiftStarted ? AppPalette.vendor : AppPalette.ink,
                    ),
                    const Spacer(),
                    StatusPill(
                      label: requiresHygiene ? 'Food Vendor' : 'Non-food Vendor',
                      background: const Color(0xFFEAF2FF),
                      foreground: AppPalette.customer,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  shiftStarted ? 'You are live on TinyTrails' : 'Start My Shift',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppPalette.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  requiresHygiene
                      ? 'Your hygiene gate is cleared for today. Use shift mode to begin broadcast and accept digital hails.'
                      : 'Tailors, artisans, and service vendors can start work directly without hygiene capture.',
                  style: TextStyle(color: AppPalette.muted, height: 1.5),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onToggleShift,
                  style: FilledButton.styleFrom(
                    backgroundColor: shiftStarted ? const Color(0xFFB42318) : AppPalette.vendor,
                  ),
                  child: Text(shiftStarted ? 'End Shift' : 'Start My Shift'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Orders today',
                  value: '12',
                  accent: AppPalette.customer,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Today earnings',
                  value: 'Rs. 1420',
                  accent: AppPalette.vendor,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Rating',
                  value: '4.8',
                  accent: Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SectionHeader(
            title: 'Run your business',
            subtitle: 'Your most-used actions stay here for quick access.',
          ),
          const SizedBox(height: 12),
          _AdaptiveCardGrid(
            mainAxisExtent: 182,
            children: [
              _ActionShortcutCard(
                icon: Icons.add_box_outlined,
                title: 'Add Product',
                subtitle: 'Create a new listing',
                accent: AppPalette.vendor,
                onTap: onOpenProducts,
              ),
              _ActionShortcutCard(
                icon: Icons.inventory_2_outlined,
                title: 'My Listings',
                subtitle: 'Edit stock and products',
                accent: AppPalette.vendor,
                onTap: onOpenProducts,
              ),
              _ActionShortcutCard(
                icon: Icons.shopping_bag_outlined,
                title: 'Orders',
                subtitle: 'Accept and update requests',
                accent: AppPalette.vendor,
                onTap: onOpenOrders,
              ),
              _ActionShortcutCard(
                icon: Icons.person_outline_rounded,
                title: 'Profile',
                subtitle: 'Business details and logout',
                accent: AppPalette.vendor,
                onTap: onOpenProfile,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SoftCard(
            color: Color(0xFFE3F6E8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merit Score: 4.8',
                  style: TextStyle(
                    color: AppPalette.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'You are currently visible to 120 nearby customers in your 2 km radius. Better ratings and cleaner shifts help you appear higher in customer feeds.',
                  style: TextStyle(color: AppPalette.ink, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Hails & Orders Queue'),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F7EC),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hail Request! Customer 200m ahead.',
                        style: TextStyle(
                          color: AppPalette.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () {},
                              style: FilledButton.styleFrom(backgroundColor: AppPalette.vendor),
                              child: const Text('Accept & Stop'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              child: const Text('Ignore'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const _VendorOrderRow(name: '2x Mini Meals', meta: 'Ready in 15 mins'),
                const _VendorOrderRow(name: '1x Lemon Rice Combo', meta: 'Pickup queue'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VendorProductsView extends StatelessWidget {
  const VendorProductsView({
    super.key,
    required this.profile,
    required this.shopName,
    required this.address,
    required this.story,
    required this.storyVideoUrl,
    required this.handwrittenMenuUrl,
    required this.pincodeController,
    required this.productName,
    required this.productDescription,
    required this.productCategory,
    required this.productPrice,
    required this.onSaveVendor,
    required this.onAddProduct,
    required this.onEditProduct,
    required this.onDeleteProduct,
    required this.editingProductId,
    required this.infoText,
  });

  final AppProfile profile;
  final TextEditingController shopName;
  final TextEditingController address;
  final TextEditingController story;
  final TextEditingController storyVideoUrl;
  final TextEditingController handwrittenMenuUrl;
  final TextEditingController pincodeController;
  final TextEditingController productName;
  final TextEditingController productDescription;
  final TextEditingController productCategory;
  final TextEditingController productPrice;
  final VoidCallback onSaveVendor;
  final VoidCallback onAddProduct;
  final void Function(DocumentSnapshot<Map<String, dynamic>>) onEditProduct;
  final Future<void> Function(String productId) onDeleteProduct;
  final String? editingProductId;
  final String? infoText;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Vendor Products',
            subtitle: 'Add listings, save your story, and manage stock.',
          ),
          const SizedBox(height: 16),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vendor profile',
                  style: TextStyle(
                    color: AppPalette.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(controller: shopName, decoration: const InputDecoration(labelText: 'Shop name')),
                const SizedBox(height: 12),
                TextField(controller: address, maxLines: 3, decoration: const InputDecoration(labelText: 'Address')),
                const SizedBox(height: 12),
                TextField(controller: pincodeController, decoration: const InputDecoration(labelText: 'Pincode')),
                const SizedBox(height: 12),
                TextField(controller: story, maxLines: 3, decoration: const InputDecoration(labelText: 'Story text')),
                const SizedBox(height: 12),
                TextField(controller: storyVideoUrl, decoration: const InputDecoration(labelText: 'Story video URL')),
                const SizedBox(height: 12),
                TextField(
                  controller: handwrittenMenuUrl,
                  decoration: const InputDecoration(labelText: 'Handwritten menu image URL'),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: onSaveVendor,
                  style: FilledButton.styleFrom(backgroundColor: AppPalette.vendor),
                  child: const Text('Save vendor profile'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add product',
                  style: TextStyle(
                    color: AppPalette.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (editingProductId != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Update the fields below and save the listing again.',
                    style: TextStyle(color: AppPalette.muted),
                  ),
                ],
                const SizedBox(height: 14),
                TextField(controller: productName, decoration: const InputDecoration(labelText: 'Product title')),
                const SizedBox(height: 12),
                TextField(
                  controller: productDescription,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                TextField(controller: productCategory, decoration: const InputDecoration(labelText: 'Category')),
                const SizedBox(height: 12),
                TextField(
                  controller: productPrice,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price'),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: onAddProduct,
                  style: FilledButton.styleFrom(backgroundColor: AppPalette.vendor),
                  child: Text(editingProductId != null ? 'Update product' : 'Add product'),
                ),
              ],
            ),
          ),
          if (infoText != null) ...[
            const SizedBox(height: 14),
            Text(
              infoText!,
              style: const TextStyle(
                color: AppPalette.vendor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const SectionHeader(
            title: 'Your products',
            subtitle: 'Toggle stock availability without leaving the page.',
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where('vendorId', isEqualTo: profile.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              if (docs.isEmpty) {
                return const SoftCard(
                  child: Text(
                    'No products yet. Add your first listing above.',
                    style: TextStyle(color: AppPalette.muted),
                  ),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  final inStock = (data['inStock'] as bool?) ?? true;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SoftCard(
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: SizedBox(
                                  width: 74,
                                  height: 74,
                                  child: Image.network(
                                    (data['imageUrl'] as String?) ??
                                        'https://picsum.photos/seed/vendor-card/400/300',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: const Color(0xFFE3F6E8),
                                      child: const Icon(
                                        Icons.inventory_2_rounded,
                                        color: AppPalette.vendor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            (data['name'] as String?) ?? 'Product',
                                            style: const TextStyle(
                                              color: AppPalette.ink,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        StatusPill(
                                          label: inStock ? 'In Stock' : 'Out of Stock',
                                          background: inStock
                                              ? const Color(0xFFE7F7EB)
                                              : const Color(0xFFFEE4E2),
                                          foreground:
                                              inStock ? AppPalette.vendor : const Color(0xFFB42318),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Rs. ${(((data['price'] as num?) ?? 0)).toString()}',
                                      style: const TextStyle(color: AppPalette.muted),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      (data['category'] as String?) ?? 'Category',
                                      style: const TextStyle(
                                        color: AppPalette.ink,
                                        fontWeight: FontWeight.w700,
                                      ),
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
                                  onPressed: () => onEditProduct(doc),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Edit'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => onDeleteProduct(doc.id),
                                  icon: const Icon(Icons.delete_outline_rounded),
                                  label: const Text('Delete'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Switch(
                                value: inStock,
                                activeThumbColor: AppPalette.vendor,
                                onChanged: (value) {
                                  doc.reference.set({'inStock': value}, SetOptions(merge: true));
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class VendorEarningsView extends StatelessWidget {
  const VendorEarningsView({
    super.key,
    this.infoText,
  });

  final String? infoText;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Earnings',
            subtitle: 'Simple payout and sales summary for the day.',
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Today',
                  value: 'Rs. 1,420',
                  accent: AppPalette.vendor,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'This week',
                  value: 'Rs. 8,600',
                  accent: AppPalette.customer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SoftCard(
            child: Text(
              'Settlements, wallet, and payout history can plug into this view next.',
              style: TextStyle(color: AppPalette.muted, height: 1.5),
            ),
          ),
          if (infoText != null) ...[
            const SizedBox(height: 12),
            Text(
              infoText!,
              style: const TextStyle(
                color: AppPalette.vendor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({
    super.key,
    required this.profile,
    required this.isVendor,
    required this.shiftStarted,
    this.onOpenOrders,
  });

  final AppProfile profile;
  final bool isVendor;
  final bool shiftStarted;
  final VoidCallback? onOpenOrders;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isVendor ? AppPalette.vendor : AppPalette.customer,
                      child: Text(
                        profile.username.isEmpty ? 'T' : profile.username[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.username,
                            style: const TextStyle(
                              color: AppPalette.ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppPalette.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ProfileInfoRow(
                  icon: Icons.call_outlined,
                  label: 'Phone',
                  value: profile.phone.isEmpty ? 'Not set' : profile.phone,
                ),
                const SizedBox(height: 10),
                _ProfileInfoRow(
                  icon: Icons.pin_drop_outlined,
                  label: 'Pincode',
                  value: profile.pincode,
                ),
                const SizedBox(height: 10),
                _ProfileInfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Role',
                  value: isVendor ? profile.businessTypeLabel : 'Customer',
                ),
                if (isVendor) ...[
                  const SizedBox(height: 10),
                  _ProfileInfoRow(
                    icon: Icons.radar_outlined,
                    label: 'Shift status',
                    value: shiftStarted ? 'Live' : 'Offline',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(
                label: isVendor ? profile.businessTypeLabel : 'TinyTrail Plus',
                background: (isVendor ? AppPalette.vendor : AppPalette.customer)
                    .withValues(alpha: 0.12),
                foreground: isVendor ? AppPalette.vendor : AppPalette.customer,
              ),
              StatusPill(
                label: 'Pincode ${profile.pincode}',
                background: const Color(0xFFF4F6F8),
                foreground: AppPalette.ink,
              ),
              if (isVendor)
                StatusPill(
                  label: shiftStarted ? 'Live now' : 'Shift offline',
                  background: shiftStarted
                      ? const Color(0xFFD8F5DF)
                      : const Color(0xFFF4F6F8),
                  foreground: shiftStarted ? AppPalette.vendor : AppPalette.ink,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isVendor)
            Column(
              children: [
                const SoftCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: _MiniProfileStat(
                          label: 'Active',
                          value: '2',
                          accent: AppPalette.customer,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _MiniProfileStat(
                          label: 'Saved',
                          value: '8',
                          accent: Color(0xFFF59E0B),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _MiniProfileStat(
                          label: 'Rewards',
                          value: '240',
                          accent: AppPalette.vendor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: onOpenOrders,
                  borderRadius: BorderRadius.circular(24),
                  child: const SoftCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Orders',
                                style: TextStyle(
                                  color: AppPalette.ink,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Active orders, map tracking, and reorder history now live inside Profile.',
                                style: TextStyle(color: AppPalette.muted, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: AppPalette.customer),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _AdaptiveCardGrid(
                  mainAxisExtent: 168,
                  children: [
                    _ProfileActionCard(
                      icon: Icons.map_outlined,
                      title: 'Saved Address',
                      subtitle: 'Manage delivery spots',
                      accent: AppPalette.customer,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Address manager comes next.')),
                        );
                      },
                    ),
                    _ProfileActionCard(
                      icon: Icons.favorite_border_rounded,
                      title: 'Favorites',
                      subtitle: 'Loved vendors and dishes',
                      accent: AppPalette.customer,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Favorites view comes next.')),
                        );
                      },
                    ),
                    _ProfileActionCard(
                      icon: Icons.language_outlined,
                      title: 'Language',
                      subtitle: 'English / Tamil',
                      accent: AppPalette.customer,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Language settings will be added next.')),
                        );
                      },
                    ),
                    _ProfileActionCard(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Payments',
                      subtitle: 'UPI and refund methods',
                      accent: AppPalette.customer,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Payment settings placeholder.')),
                        );
                      },
                    ),
                    _ProfileActionCard(
                      icon: Icons.support_agent_outlined,
                      title: 'Support',
                      subtitle: 'Need help quickly?',
                      accent: AppPalette.customer,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Support center placeholder.')),
                        );
                      },
                    ),
                    _ProfileActionCard(
                      icon: Icons.notifications_active_outlined,
                      title: 'Alerts',
                      subtitle: 'Order and vendor updates',
                      accent: AppPalette.customer,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notification preferences coming next.')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          if (isVendor)
            Column(
              children: [
                const SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trust Tier: Tier 2 - Licensed Vendor',
                        style: TextStyle(
                          color: AppPalette.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Upload certificates to unlock wider delivery radius and stronger marketplace ranking.',
                        style: TextStyle(color: AppPalette.muted, height: 1.5),
                      ),
                      SizedBox(height: 14),
                      LinearProgressIndicator(
                        value: 0.72,
                        minHeight: 8,
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                        backgroundColor: Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(AppPalette.vendor),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Next unlock: upload FSSAI or trade documents to extend your reach.',
                        style: TextStyle(color: AppPalette.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SoftCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: _MiniProfileStat(
                          label: profile.isFoodVendor ? 'Hygiene' : 'Trust',
                          value: profile.isFoodVendor ? '94%' : 'Verified',
                          accent: AppPalette.vendor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: _MiniProfileStat(
                          label: 'Payout',
                          value: 'Rs. 4.2K',
                          accent: AppPalette.customer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: _MiniProfileStat(
                          label: 'Reach',
                          value: '120',
                          accent: Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _AdaptiveCardGrid(
                  mainAxisExtent: 170,
                  children: [
                    _ProfileActionCard(
                      icon: Icons.auto_stories_outlined,
                      title: 'Business Story',
                      subtitle: 'Edit story and banner',
                      accent: AppPalette.vendor,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Edit your business story from Products.')),
                        );
                      },
                    ),
                    _ProfileActionCard(
                      icon: Icons.verified_user_outlined,
                      title: 'Documents',
                      subtitle: 'Trust and verification',
                      accent: AppPalette.vendor,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vendor document flow comes next.')),
                        );
                      },
                    ),
                    _ProfileActionCard(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Payouts',
                      subtitle: 'Bank and UPI settings',
                      accent: AppPalette.vendor,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Payout setup placeholder.')),
                        );
                      },
                    ),
                    _ProfileActionCard(
                      icon: Icons.receipt_long_outlined,
                      title: 'Orders',
                      subtitle: 'View live order queue',
                      accent: AppPalette.vendor,
                      onTap: onOpenOrders ?? () {},
                    ),
                    _ProfileActionCard(
                      icon: Icons.schedule_rounded,
                      title: 'Working Hours',
                      subtitle: 'Shift timing and status',
                      accent: AppPalette.vendor,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Working hours manager placeholder.')),
                        );
                      },
                    ),
                    _ProfileActionCard(
                      icon: Icons.help_outline_rounded,
                      title: 'Help',
                      subtitle: 'Quick vendor support',
                      accent: AppPalette.vendor,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vendor support section placeholder.')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => FirebaseAuth.instance.signOut(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFEE4E2),
              foregroundColor: const Color(0xFFB42318),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _MiniProfileStat extends StatelessWidget {
  const _MiniProfileStat({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppPalette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppPalette.muted),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: const TextStyle(
            color: AppPalette.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppPalette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120F172A),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppPalette.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppPalette.muted,
                      fontSize: 12,
                      height: 1.4,
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
}

class _AdaptiveCardGrid extends StatelessWidget {
  const _AdaptiveCardGrid({
    required this.children,
    this.mainAxisExtent = 174,
  });

  final List<Widget> children;
  final double mainAxisExtent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 680 ? 4 : 2;
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final effectiveMainAxisExtent =
            mainAxisExtent + ((textScale - 1).clamp(0.0, 0.45) * 36);
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: effectiveMainAxisExtent,
          ),
          children: children,
        );
      },
    );
  }
}

class _VendorOrderRow extends StatelessWidget {
  const _VendorOrderRow({
    required this.name,
    required this.meta,
  });

  final String name;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: AppPalette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(meta, style: const TextStyle(color: AppPalette.muted)),
        ],
      ),
    );
  }
}

class _ActionShortcutCard extends StatelessWidget {
  const _ActionShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120F172A),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppPalette.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppPalette.muted,
                      fontSize: 12,
                      height: 1.4,
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
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppPalette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x120F172A),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: AppPalette.ink),
      ),
    );
  }
}

class _RadarDot extends StatelessWidget {
  const _RadarDot({
    this.left,
    this.right,
    this.top,
    this.bottom,
  });

  final double? left;
  final double? right;
  final double? top;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: AppPalette.customer,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFB8D2FF), width: 4),
        ),
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppPalette.customer : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppPalette.customer : const Color(0xFFD7E0EA),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppPalette.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CategoryMeta {
  const _CategoryMeta({
    required this.label,
    required this.icon,
    required this.tint,
    required this.iconColor,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final Color iconColor;
}
