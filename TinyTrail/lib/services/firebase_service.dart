import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/models.dart';

/// Result class for authentication operations
class AuthResult {
  final bool success;
  final UserModel? user;
  final String? errorMessage;

  AuthResult({
    required this.success,
    this.user,
    this.errorMessage,
  });

  factory AuthResult.success(UserModel user) {
    return AuthResult(success: true, user: user);
  }

  factory AuthResult.failure(String message) {
    return AuthResult(success: false, errorMessage: message);
  }
}

/// Firebase service for authentication and Firestore operations
class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String ordersCollection = 'orders';

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ==================== AUTHENTICATION ====================

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure('Sign in failed. Please try again.');
      }

      // Fetch user data from Firestore
      final userData = await getUserData(credential.user!.uid);
      if (userData == null) {
        return AuthResult.failure('User profile not found.');
      }

      return AuthResult.success(userData);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred.');
    }
  }

  /// Register with email and password
  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? businessName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure('Registration failed. Please try again.');
      }

      // Create user document in Firestore
      final now = DateTime.now();
      final user = UserModel(
        uid: credential.user!.uid,
        email: email.trim(),
        name: name.trim(),
        role: role,
        createdAt: now,
        updatedAt: now,
        trustTier: role == UserRole.vendor ? TrustTier.blue : null,
        hygieneScore: role == UserRole.vendor ? 0 : null,
        isLive: role == UserRole.vendor ? false : null,
        businessName: businessName,
      );

      await _firestore
          .collection(usersCollection)
          .doc(credential.user!.uid)
          .set(user.toJson());

      return AuthResult.success(user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred.');
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle({required UserRole role}) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResult.failure('Google sign-in was cancelled.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        return AuthResult.failure('Google sign-in failed.');
      }

      // Check if user exists in Firestore
      final existingUser = await getUserData(userCredential.user!.uid);

      if (existingUser != null) {
        return AuthResult.success(existingUser);
      }

      // Create new user document
      final now = DateTime.now();
      final newUser = UserModel(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email ?? '',
        name: userCredential.user!.displayName ?? 'User',
        role: role,
        photoUrl: userCredential.user!.photoURL,
        createdAt: now,
        updatedAt: now,
        trustTier: role == UserRole.vendor ? TrustTier.blue : null,
        hygieneScore: role == UserRole.vendor ? 0 : null,
        isLive: role == UserRole.vendor ? false : null,
      );

      await _firestore
          .collection(usersCollection)
          .doc(userCredential.user!.uid)
          .set(newUser.toJson());

      return AuthResult.success(newUser);
    } catch (e) {
      return AuthResult.failure('Google sign-in failed. Please try again.');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(uid).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return UserModel.fromJson(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  /// Get user role
  Future<UserRole?> getUserRole(String uid) async {
    final user = await getUserData(uid);
    return user?.role;
  }

  /// Update user data
  Future<bool> updateUserData(UserModel user) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .update(user.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==================== PRODUCTS ====================

  /// Add a new product
  Future<ProductModel?> addProduct(ProductModel product) async {
    try {
      final docRef = await _firestore.collection(productsCollection).add(product.toJson());
      return product.copyWith(id: docRef.id);
    } catch (e) {
      return null;
    }
  }

  /// Update product
  Future<bool> updateProduct(ProductModel product) async {
    try {
      await _firestore
          .collection(productsCollection)
          .doc(product.id)
          .update(product.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete product
  Future<bool> deleteProduct(String productId) async {
    try {
      await _firestore.collection(productsCollection).doc(productId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get products for a vendor
  Stream<List<ProductModel>> getVendorProducts(String vendorId) {
    return _firestore
        .collection(productsCollection)
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Get all available products (for customers)
  Stream<List<ProductModel>> getAvailableProducts({bool? isVeg}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(productsCollection)
        .where('inStock', isEqualTo: true);

    if (isVeg != null) {
      query = query.where('isVeg', isEqualTo: isVeg);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => ProductModel.fromJson(doc.data(), doc.id))
        .toList());
  }

  // ==================== VENDORS ====================

  /// Get all vendors
  Stream<List<UserModel>> getVendors() {
    return _firestore
        .collection(usersCollection)
        .where('role', isEqualTo: 'vendor')
        .where('isLive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Get vendor by ID
  Future<UserModel?> getVendorById(String vendorId) async {
    return await getUserData(vendorId);
  }

  /// Update vendor live status
  Future<bool> updateVendorLiveStatus(String vendorId, bool isLive) async {
    try {
      await _firestore.collection(usersCollection).doc(vendorId).update({
        'isLive': isLive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update vendor hygiene score
  Future<bool> updateHygieneScore(String vendorId, int score) async {
    try {
      await _firestore.collection(usersCollection).doc(vendorId).update({
        'hygieneScore': score,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==================== ORDERS ====================

  /// Create a new order
  Future<String?> createOrder(OrderModel order) async {
    try {
      final docRef = await _firestore.collection(ordersCollection).add(order.toJson());
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  /// Get orders for a vendor
  Stream<List<Map<String, dynamic>>> getVendorOrders(String vendorId) {
    return _firestore
        .collection(ordersCollection)
        .where('vendorId', isEqualTo: vendorId)
        .where('status', whereIn: ['pending', 'accepted', 'preparing'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection(ordersCollection).doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==================== HELPERS ====================

  /// Get human-readable error message
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

/// Singleton instance
final firebaseService = FirebaseService();
