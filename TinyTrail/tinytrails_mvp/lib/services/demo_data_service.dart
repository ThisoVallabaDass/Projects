import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import 'offers_service.dart';

/// Service for managing demo data
class DemoDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Demo vendor credentials
  static const Map<String, Map<String, String>> demoAccounts = {
    'food_demo': {
      'email': 'demo.food@tinytrails.com',
      'password': 'demo123',
      'name': 'Ravi Kumar',
      'businessName': 'Chennai Delights',
      'category': 'food',
    },
    'non_food_demo': {
      'email': 'demo.crafts@tinytrails.com',
      'password': 'demo123',
      'name': 'Priya Sharma',
      'businessName': 'Handmade Crafts Studio',
      'category': 'non-food',
    },
  };

  /// Create demo vendor accounts if they don't exist
  static Future<void> createDemoAccounts() async {
    for (final entry in demoAccounts.entries) {
      final accountType = entry.key;
      final accountData = entry.value;

      try {
        // Check if demo account already exists
        final email = accountData['email']!;
        final existingUser = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (existingUser.docs.isEmpty) {
          // Create Firebase Auth user
          final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: accountData['password']!,
          );

          // Create user document in Firestore
          final now = DateTime.now();
          final user = UserModel(
            uid: userCredential.user!.uid,
            email: email,
            name: accountData['name']!,
            role: UserRole.vendor,
            createdAt: now,
            updatedAt: now,
            trustTier: TrustTier.gold, // Give demo accounts better trust tier
            hygieneScore: accountData['category'] == 'food' ? 95 : null,
            isLive: false,
            businessName: accountData['businessName']!,
            businessType: accountData['category']!, // e.g., 'food' or 'non-food'
            vendorCategory: accountData['category']!, // EXPLICIT: 'food' or 'non-food'
            hasPassedOnboarding: true, // Demo accounts are fully set up
          );

          // Debug logging to verify correct values
          print('📝 Creating demo account:');
          print('   Email: $email');
          print('   Business: ${accountData['businessName']}');
          print('   Category: ${accountData['category']}');
          print('   Hygiene Score: ${accountData['category'] == 'food' ? 95 : "null (non-food)"}');

          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(user.toJson());

          // Create demo products for this vendor
          await _createDemoProducts(userCredential.user!.uid, accountData['category']!);

          // Create demo offers for this vendor
          await _createDemoOffers(userCredential.user!.uid, accountData['category']!);

          print('Created demo account: ${accountData['businessName']} (${accountData['email']})');
        }
      } catch (e) {
        print('Error creating demo account $accountType: $e');
        // Continue with other accounts even if one fails
      }
    }
  }

  /// Create demo products for a vendor
  static Future<void> _createDemoProducts(String vendorId, String category) async {
    final products = category == 'food' ? _getDemoFoodProducts(vendorId) : _getDemoNonFoodProducts(vendorId);

    for (final product in products) {
      try {
        await _firestore.collection('products').add(product.toJson());
      } catch (e) {
        print('Error creating product ${product.name}: $e');
      }
    }
  }

  /// Create demo offers for a vendor
  static Future<void> _createDemoOffers(String vendorId, String category) async {
    final offers = category == 'food' ? _getDemoFoodOffers(vendorId) : _getDemoNonFoodOffers(vendorId);
    final offersService = OffersService();

    for (final offer in offers) {
      try {
        await offersService.createOffer(offer);
      } catch (e) {
        print('Error creating offer ${offer.title}: $e');
      }
    }
  }

  /// Get demo food products
  static List<ProductModel> _getDemoFoodProducts(String vendorId) {
    final now = DateTime.now();
    return [
      ProductModel(
        id: '', // Will be set by Firestore
        vendorId: vendorId,
        name: 'Paneer Tikka Wrap',
        description: 'Grilled paneer with mint chutney and fresh vegetables wrapped in soft roti',
        price: 120.0,
        category: 'Main Course',
        isVeg: true,
        inStock: true,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: '',
        vendorId: vendorId,
        name: 'Mysore Pak',
        description: 'Traditional South Indian sweet made with gram flour and ghee',
        price: 45.0,
        category: 'Sweets',
        isVeg: true,
        inStock: true,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: '',
        vendorId: vendorId,
        name: 'Filter Coffee',
        description: 'Authentic South Indian coffee made with fresh filter',
        price: 25.0,
        category: 'Beverages',
        isVeg: true,
        inStock: true,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: '',
        vendorId: vendorId,
        name: 'Crispy Samosa',
        description: 'Deep fried pastry filled with spiced potato and served with chutney',
        price: 20.0,
        category: 'Snacks',
        isVeg: true,
        inStock: false, // Demo out of stock item
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: '',
        vendorId: vendorId,
        name: 'Masala Dosa',
        description: 'Crispy crepe filled with spiced potato curry, served with sambar and chutney',
        price: 80.0,
        category: 'Main Course',
        isVeg: true,
        inStock: true,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: '',
        vendorId: vendorId,
        name: 'Chicken Biryani',
        description: 'Aromatic basmati rice cooked with tender chicken pieces and spices',
        price: 180.0,
        category: 'Main Course',
        isVeg: false,
        inStock: true,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: '',
        vendorId: vendorId,
        name: 'Fresh Lime Soda',
        description: 'Refreshing homemade lime soda with mint',
        price: 30.0,
        category: 'Beverages',
        isVeg: true,
        inStock: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  /// Get demo non-food products
  static List<ProductModel> _getDemoNonFoodProducts(String vendorId) {
    final now = DateTime.now();
    return [
      ProductModel(
        id: '',
        vendorId: vendorId,
        name: 'Handwoven Cotton Scarf',
        description: 'Beautiful handwoven cotton scarf with traditional patterns',
        price: 350.0,
        category: 'Textiles',
        isVeg: true, // Not applicable for non-food, but keeping true
        inStock: true,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: '',
        vendorId: vendorId,
        name: 'Ceramic Tea Set',
        description: 'Hand-painted ceramic tea set with 4 cups and teapot',
        price: 800.0,
        category: 'Pottery',
        isVeg: true,
        inStock: true,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: '',
        vendorId: vendorId,
        name: 'Beaded Jewelry Set',
        description: 'Handmade beaded necklace and earrings set',
        price: 450.0,
        category: 'Jewelry',
        isVeg: true,
        inStock: true,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: '',
        vendorId: vendorId,
        name: 'Bamboo Pen Holder',
        description: 'Eco-friendly bamboo pen holder with carved designs',
        price: 200.0,
        category: 'Home Decor',
        isVeg: true,
        inStock: false, // Demo out of stock item
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: '',
        vendorId: vendorId,
        name: 'Macrame Wall Hanging',
        description: 'Beautiful macrame wall art for home decoration',
        price: 600.0,
        category: 'Home Decor',
        isVeg: true,
        inStock: true,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: '',
        vendorId: vendorId,
        name: 'Embroidered Pillow Covers',
        description: 'Set of 2 embroidered pillow covers with traditional motifs',
        price: 280.0,
        category: 'Textiles',
        isVeg: true,
        inStock: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  /// Get demo food vendor offers
  static List<OfferModel> _getDemoFoodOffers(String vendorId) {
    final now = DateTime.now();
    return [
      OfferModel(
        id: '',
        vendorId: vendorId,
        title: 'Welcome Deal',
        description: 'Get 30% off on your first order from Chennai Delights!',
        type: OfferType.percentage,
        status: OfferStatus.active,
        discountValue: 30,
        maxDiscountAmount: 150,
        minOrderAmount: 100,
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
        perUserLimit: 1,
        terms: ['Valid for new customers only', 'Maximum discount ₹150', 'Minimum order ₹100'],
        isNewUserOnly: true,
        promoCode: 'WELCOME30',
        isVisible: true,
        isFeatured: true,
        priority: 10,
        tags: ['first-order', 'welcome'],
        createdAt: now,
        updatedAt: now,
      ),
      OfferModel(
        id: '',
        vendorId: vendorId,
        title: 'Weekend Special',
        description: 'Flat ₹50 off on orders above ₹400 this weekend!',
        type: OfferType.fixedAmount,
        status: OfferStatus.active,
        discountValue: 50,
        minOrderAmount: 400,
        startDate: now,
        endDate: now.add(const Duration(days: 7)),
        terms: ['Valid on weekends only', 'Minimum order ₹400', 'Valid till stocks last'],
        promoCode: 'WEEKEND50',
        isVisible: true,
        isFeatured: true,
        priority: 8,
        tags: ['weekend', 'flat-discount'],
        createdAt: now,
        updatedAt: now,
      ),
      OfferModel(
        id: '',
        vendorId: vendorId,
        title: 'Free Delivery',
        description: 'Free delivery on all orders above ₹300',
        type: OfferType.freeDelivery,
        status: OfferStatus.active,
        discountValue: 0,
        minOrderAmount: 300,
        startDate: now,
        endDate: now.add(const Duration(days: 15)),
        terms: ['No delivery charges', 'Minimum order ₹300', 'Valid for Chennai Delights only'],
        promoCode: 'FREEDEL',
        isVisible: true,
        isFeatured: false,
        priority: 5,
        tags: ['free-delivery', 'no-charges'],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  /// Get demo non-food vendor offers
  static List<OfferModel> _getDemoNonFoodOffers(String vendorId) {
    final now = DateTime.now();
    return [
      OfferModel(
        id: '',
        vendorId: vendorId,
        title: 'Craft Lover Special',
        description: 'Get 25% off on handmade textiles and pottery!',
        type: OfferType.percentage,
        status: OfferStatus.active,
        discountValue: 25,
        maxDiscountAmount: 200,
        minOrderAmount: 500,
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
        terms: ['Valid on textiles and pottery only', 'Maximum discount ₹200', 'Minimum order ₹500'],
        promoCode: 'CRAFT25',
        isVisible: true,
        isFeatured: true,
        priority: 9,
        tags: ['crafts', 'handmade', 'textiles'],
        createdAt: now,
        updatedAt: now,
      ),
      OfferModel(
        id: '',
        vendorId: vendorId,
        title: 'First Time Buyer',
        description: 'Flat ₹100 off on your first purchase from our craft studio',
        type: OfferType.fixedAmount,
        status: OfferStatus.active,
        discountValue: 100,
        minOrderAmount: 300,
        startDate: now,
        endDate: now.add(const Duration(days: 60)),
        perUserLimit: 1,
        terms: ['Valid for first-time customers', 'Minimum purchase ₹300', 'One use per customer'],
        isNewUserOnly: true,
        promoCode: 'FIRSTCRAFT100',
        isVisible: true,
        isFeatured: true,
        priority: 10,
        tags: ['first-order', 'new-customer'],
        createdAt: now,
        updatedAt: now,
      ),
      OfferModel(
        id: '',
        vendorId: vendorId,
        title: 'Bulk Order Discount',
        description: '15% off when you buy 3 or more handcrafted items',
        type: OfferType.percentage,
        status: OfferStatus.active,
        discountValue: 15,
        maxDiscountAmount: 300,
        minOrderAmount: 800,
        startDate: now,
        endDate: now.add(const Duration(days: 45)),
        terms: ['Valid on orders of 3+ items', 'Maximum discount ₹300', 'Minimum order ₹800'],
        promoCode: 'BULK15',
        isVisible: true,
        isFeatured: false,
        priority: 6,
        tags: ['bulk-order', 'multiple-items'],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  /// Sign in to demo account (for testing)
  static Future<User?> signInToDemo(String accountType) async {
    try {
      final accountData = demoAccounts[accountType];
      if (accountData == null) return null;

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: accountData['email']!,
        password: accountData['password']!,
      );

      return credential.user;
    } catch (e) {
      print('Error signing in to demo account: $e');
      return null;
    }
  }

  /// Check if current user is a demo account
  static bool isDemoAccount(String email) {
    return demoAccounts.values.any((account) => account['email'] == email);
  }

  /// Fix craft demo account specifically (utility method)
  static Future<void> fixCraftDemoAccount() async {
    print('🛠️ Fixing craft demo account category...');

    const email = 'demo.crafts@tinytrails.com';

    try {
      // Find the craft demo account
      final existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        final doc = existingUser.docs.first;

        // Update with correct non-food values
        await _firestore.collection('users').doc(doc.id).update({
          'vendorCategory': 'non-food',
          'businessType': 'non-food',
          'hygieneScore': FieldValue.delete(), // Remove hygiene score for non-food
          'hasPassedOnboarding': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('✅ Fixed craft demo account - now properly set as non-food vendor');
        print('   Email: $email');
        print('   Business: Handmade Crafts Studio');
        print('   Category: non-food');
        print('   Hygiene Score: removed (non-food vendors don\'t need this)');
      } else {
        print('❌ Craft demo account not found. Creating new one...');
        await createDemoAccounts();
      }
    } catch (e) {
      print('❌ Error fixing craft demo account: $e');
    }
  }

  /// Force refresh demo accounts (useful for troubleshooting category issues)
  static Future<void> refreshDemoAccounts() async {
    print('🔄 Force refreshing demo accounts...');

    for (final entry in demoAccounts.entries) {
      final accountData = entry.value;
      final email = accountData['email']!;

      try {
        // Find existing user document
        final existingUser = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (existingUser.docs.isNotEmpty) {
          final doc = existingUser.docs.first;

          // Update the document with correct values
          await _firestore.collection('users').doc(doc.id).update({
            'vendorCategory': accountData['category'],
            'businessType': accountData['category'],
            'hygieneScore': accountData['category'] == 'food' ? 95 : null,
            'hasPassedOnboarding': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          print('✅ Refreshed ${accountData['businessName']} - Category: ${accountData['category']}');
        }
      } catch (e) {
        print('❌ Error refreshing $email: $e');
      }
    }
  }
}