import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/offer_model.dart';

class OffersService {
  static const String _collection = 'offers';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new offer
  Future<String> createOffer(OfferModel offer) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final offerWithId = offer.copyWith(id: docRef.id);
      await docRef.set(offerWithId.toJson());

      print('✅ Offer created successfully: ${offerWithId.title}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating offer: $e');
      rethrow;
    }
  }

  // Update an existing offer
  Future<void> updateOffer(OfferModel offer) async {
    try {
      final updatedOffer = offer.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection(_collection)
          .doc(offer.id)
          .update(updatedOffer.toJson());

      print('✅ Offer updated successfully: ${offer.title}');
    } catch (e) {
      print('❌ Error updating offer: $e');
      rethrow;
    }
  }

  // Delete an offer
  Future<void> deleteOffer(String offerId) async {
    try {
      await _firestore.collection(_collection).doc(offerId).delete();
      print('✅ Offer deleted successfully: $offerId');
    } catch (e) {
      print('❌ Error deleting offer: $e');
      rethrow;
    }
  }

  // Get offers for a specific vendor
  Stream<List<OfferModel>> getVendorOffers(String vendorId) {
    return _firestore
        .collection(_collection)
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('priority', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OfferModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Get active offers for a vendor (customer view)
  Stream<List<OfferModel>> getActiveVendorOffers(String vendorId) {
    final now = Timestamp.fromDate(DateTime.now());

    return _firestore
        .collection(_collection)
        .where('vendorId', isEqualTo: vendorId)
        .where('status', isEqualTo: 'OfferStatus.active')
        .where('isVisible', isEqualTo: true)
        .where('startDate', isLessThanOrEqualTo: now)
        .where('endDate', isGreaterThan: now)
        .orderBy('endDate')
        .orderBy('isFeatured', descending: true)
        .orderBy('priority', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OfferModel.fromJson(doc.data()))
          .where((offer) => offer.isActive)
          .toList();
    });
  }

  // Get featured offers (homepage)
  Stream<List<OfferModel>> getFeaturedOffers() {
    final now = Timestamp.fromDate(DateTime.now());

    return _firestore
        .collection(_collection)
        .where('isFeatured', isEqualTo: true)
        .where('status', isEqualTo: 'OfferStatus.active')
        .where('isVisible', isEqualTo: true)
        .where('startDate', isLessThanOrEqualTo: now)
        .where('endDate', isGreaterThan: now)
        .orderBy('startDate')
        .orderBy('priority', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OfferModel.fromJson(doc.data()))
          .where((offer) => offer.isActive)
          .toList();
    });
  }

  // Validate and apply coupon
  Future<CouponValidationResult> validateCoupon({
    required String promoCode,
    required String userId,
    required String vendorId,
    required double orderAmount,
    required List<String> productIds,
  }) async {
    try {
      // Find the coupon
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('promoCode', isEqualTo: promoCode.toUpperCase())
          .where('vendorId', isEqualTo: vendorId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return CouponValidationResult(
          isValid: false,
          error: 'Invalid coupon code',
        );
      }

      final offer = OfferModel.fromJson(querySnapshot.docs.first.data());

      // Check if user can use this coupon
      if (!offer.canUserUse(userId)) {
        String error = 'Coupon not available';
        if (offer.isExpired) {
          error = 'Coupon has expired';
        } else if (offer.totalUsageLimit != null && offer.totalUsed >= offer.totalUsageLimit!) {
          error = 'Coupon usage limit reached';
        } else if (offer.perUserLimit != null) {
          final userUsage = offer.userUsage[userId] ?? 0;
          if (userUsage >= offer.perUserLimit!) {
            error = 'You have already used this coupon';
          }
        }

        return CouponValidationResult(
          isValid: false,
          error: error,
        );
      }

      // Calculate discount
      final discount = offer.calculateDiscount(orderAmount, productIds);

      if (discount <= 0) {
        String error = 'Coupon not applicable';
        if (offer.minOrderAmount != null && orderAmount < offer.minOrderAmount!) {
          error = 'Minimum order amount ₹${offer.minOrderAmount!.toInt()} required';
        }

        return CouponValidationResult(
          isValid: false,
          error: error,
        );
      }

      return CouponValidationResult(
        isValid: true,
        offer: offer,
        discountAmount: discount,
        finalAmount: orderAmount - discount,
      );

    } catch (e) {
      print('❌ Error validating coupon: $e');
      return CouponValidationResult(
        isValid: false,
        error: 'Failed to validate coupon',
      );
    }
  }

  // Apply coupon (increment usage)
  Future<void> applyCoupon(String offerId, String userId) async {
    try {
      final docRef = _firestore.collection(_collection).doc(offerId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) throw 'Offer not found';

        final offer = OfferModel.fromJson(doc.data()!);
        final updatedUserUsage = Map<String, int>.from(offer.userUsage);
        updatedUserUsage[userId] = (updatedUserUsage[userId] ?? 0) + 1;

        transaction.update(docRef, {
          'totalUsed': offer.totalUsed + 1,
          'userUsage': updatedUserUsage,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      });

      print('✅ Coupon applied successfully');
    } catch (e) {
      print('❌ Error applying coupon: $e');
      rethrow;
    }
  }

  // Get offer statistics
  Future<OfferStats> getOfferStats(String vendorId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('vendorId', isEqualTo: vendorId)
          .get();

      int totalOffers = snapshot.docs.length;
      int activeOffers = 0;
      int totalRedemptions = 0;
      double totalDiscountGiven = 0;

      for (final doc in snapshot.docs) {
        final offer = OfferModel.fromJson(doc.data());
        if (offer.isActive) activeOffers++;
        totalRedemptions += offer.totalUsed;
        // Estimate discount given (simplified)
        totalDiscountGiven += offer.totalUsed * offer.discountValue;
      }

      return OfferStats(
        totalOffers: totalOffers,
        activeOffers: activeOffers,
        totalRedemptions: totalRedemptions,
        totalDiscountGiven: totalDiscountGiven,
      );
    } catch (e) {
      print('❌ Error getting offer stats: $e');
      return OfferStats(
        totalOffers: 0,
        activeOffers: 0,
        totalRedemptions: 0,
        totalDiscountGiven: 0,
      );
    }
  }

  // Auto-expire offers
  Future<void> expireOldOffers() async {
    try {
      final now = Timestamp.fromDate(DateTime.now());
      final expiredSnapshot = await _firestore
          .collection(_collection)
          .where('endDate', isLessThan: now)
          .where('status', isEqualTo: 'OfferStatus.active')
          .get();

      final batch = _firestore.batch();
      for (final doc in expiredSnapshot.docs) {
        batch.update(doc.reference, {
          'status': 'OfferStatus.expired',
          'updatedAt': now,
        });
      }

      if (expiredSnapshot.docs.isNotEmpty) {
        await batch.commit();
        print('✅ Expired ${expiredSnapshot.docs.length} old offers');
      }
    } catch (e) {
      print('❌ Error expiring offers: $e');
    }
  }

  // Search offers by promo code
  Future<OfferModel?> getOfferByPromoCode(String promoCode, String vendorId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('promoCode', isEqualTo: promoCode.toUpperCase())
          .where('vendorId', isEqualTo: vendorId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return OfferModel.fromJson(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('❌ Error searching offer by promo code: $e');
      return null;
    }
  }
}

// Supporting classes
class CouponValidationResult {
  final bool isValid;
  final String? error;
  final OfferModel? offer;
  final double? discountAmount;
  final double? finalAmount;

  CouponValidationResult({
    required this.isValid,
    this.error,
    this.offer,
    this.discountAmount,
    this.finalAmount,
  });
}

class OfferStats {
  final int totalOffers;
  final int activeOffers;
  final int totalRedemptions;
  final double totalDiscountGiven;

  OfferStats({
    required this.totalOffers,
    required this.activeOffers,
    required this.totalRedemptions,
    required this.totalDiscountGiven,
  });
}