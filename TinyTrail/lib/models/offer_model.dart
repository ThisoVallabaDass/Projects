import 'package:cloud_firestore/cloud_firestore.dart';

enum OfferType {
  percentage, // 20% off
  fixedAmount, // ₹50 off
  buyOneGetOne, // BOGO
  freeDelivery, // Free delivery
  combo, // Combo deals
  firstOrder, // First-time user
  loyaltyPoints // Points-based
}

enum OfferStatus {
  active,
  inactive,
  scheduled,
  expired,
  paused
}

class OfferModel {
  final String id;
  final String vendorId;
  final String title;
  final String description;
  final String? imageUrl;
  final OfferType type;
  final OfferStatus status;

  // Discount details
  final double discountValue;
  final double? maxDiscountAmount;
  final double? minOrderAmount;

  // Validity
  final DateTime startDate;
  final DateTime endDate;
  final int? totalUsageLimit;
  final int? perUserLimit;

  // Terms & Conditions
  final List<String> terms;
  final List<String> applicableProducts; // Product IDs if specific
  final bool isNewUserOnly;
  final List<String> excludedProducts;

  // Usage tracking
  final int totalUsed;
  final Map<String, int> userUsage; // userId -> usage count

  // Marketing
  final List<String> tags;
  final String promoCode;
  final bool isVisible;
  final bool isFeatured;
  final int priority; // Higher = shown first

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  OfferModel({
    required this.id,
    required this.vendorId,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.type,
    required this.status,
    required this.discountValue,
    this.maxDiscountAmount,
    this.minOrderAmount,
    required this.startDate,
    required this.endDate,
    this.totalUsageLimit,
    this.perUserLimit,
    required this.terms,
    this.applicableProducts = const [],
    this.isNewUserOnly = false,
    this.excludedProducts = const [],
    this.totalUsed = 0,
    this.userUsage = const {},
    this.tags = const [],
    required this.promoCode,
    this.isVisible = true,
    this.isFeatured = false,
    this.priority = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Firebase document
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'type': type.toString(),
      'status': status.toString(),
      'discountValue': discountValue,
      'maxDiscountAmount': maxDiscountAmount,
      'minOrderAmount': minOrderAmount,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalUsageLimit': totalUsageLimit,
      'perUserLimit': perUserLimit,
      'terms': terms,
      'applicableProducts': applicableProducts,
      'isNewUserOnly': isNewUserOnly,
      'excludedProducts': excludedProducts,
      'totalUsed': totalUsed,
      'userUsage': userUsage,
      'tags': tags,
      'promoCode': promoCode,
      'isVisible': isVisible,
      'isFeatured': isFeatured,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firebase document
  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'] ?? '',
      vendorId: json['vendorId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      type: _parseOfferType(json['type']),
      status: _parseOfferStatus(json['status']),
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      maxDiscountAmount: json['maxDiscountAmount']?.toDouble(),
      minOrderAmount: json['minOrderAmount']?.toDouble(),
      startDate: (json['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (json['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(Duration(days: 30)),
      totalUsageLimit: json['totalUsageLimit'],
      perUserLimit: json['perUserLimit'],
      terms: List<String>.from(json['terms'] ?? []),
      applicableProducts: List<String>.from(json['applicableProducts'] ?? []),
      isNewUserOnly: json['isNewUserOnly'] ?? false,
      excludedProducts: List<String>.from(json['excludedProducts'] ?? []),
      totalUsed: json['totalUsed'] ?? 0,
      userUsage: Map<String, int>.from(json['userUsage'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
      promoCode: json['promoCode'] ?? '',
      isVisible: json['isVisible'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      priority: json['priority'] ?? 1,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static OfferType _parseOfferType(String? type) {
    try {
      return OfferType.values.firstWhere((e) => e.toString() == type);
    } catch (e) {
      return OfferType.percentage;
    }
  }

  static OfferStatus _parseOfferStatus(String? status) {
    try {
      return OfferStatus.values.firstWhere((e) => e.toString() == status);
    } catch (e) {
      return OfferStatus.active;
    }
  }

  // Helper methods
  bool get isActive => status == OfferStatus.active &&
    DateTime.now().isAfter(startDate) &&
    DateTime.now().isBefore(endDate);

  bool get isExpired => DateTime.now().isAfter(endDate) || status == OfferStatus.expired;

  bool get hasUsageLimit => totalUsageLimit != null || perUserLimit != null;

  bool canUserUse(String userId) {
    if (!isActive) return false;
    if (totalUsageLimit != null && totalUsed >= totalUsageLimit!) return false;
    if (perUserLimit != null) {
      final userUsageCount = userUsage[userId] ?? 0;
      if (userUsageCount >= perUserLimit!) return false;
    }
    return true;
  }

  double calculateDiscount(double orderAmount, List<String> productIds) {
    // Check minimum order amount
    if (minOrderAmount != null && orderAmount < minOrderAmount!) return 0;

    // Check applicable products if specified
    if (applicableProducts.isNotEmpty) {
      final hasApplicableProduct = productIds.any((id) => applicableProducts.contains(id));
      if (!hasApplicableProduct) return 0;
    }

    // Check excluded products
    if (excludedProducts.isNotEmpty) {
      final hasExcludedProduct = productIds.any((id) => excludedProducts.contains(id));
      if (hasExcludedProduct) return 0;
    }

    double discount = 0;

    switch (type) {
      case OfferType.percentage:
        discount = orderAmount * (discountValue / 100);
        break;
      case OfferType.fixedAmount:
        discount = discountValue;
        break;
      case OfferType.freeDelivery:
        discount = 0; // Handle delivery fee separately
        break;
      default:
        discount = 0;
    }

    // Apply maximum discount limit
    if (maxDiscountAmount != null && discount > maxDiscountAmount!) {
      discount = maxDiscountAmount!;
    }

    return discount;
  }

  OfferModel copyWith({
    String? id,
    String? vendorId,
    String? title,
    String? description,
    String? imageUrl,
    OfferType? type,
    OfferStatus? status,
    double? discountValue,
    double? maxDiscountAmount,
    double? minOrderAmount,
    DateTime? startDate,
    DateTime? endDate,
    int? totalUsageLimit,
    int? perUserLimit,
    List<String>? terms,
    List<String>? applicableProducts,
    bool? isNewUserOnly,
    List<String>? excludedProducts,
    int? totalUsed,
    Map<String, int>? userUsage,
    List<String>? tags,
    String? promoCode,
    bool? isVisible,
    bool? isFeatured,
    int? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OfferModel(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      status: status ?? this.status,
      discountValue: discountValue ?? this.discountValue,
      maxDiscountAmount: maxDiscountAmount ?? this.maxDiscountAmount,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalUsageLimit: totalUsageLimit ?? this.totalUsageLimit,
      perUserLimit: perUserLimit ?? this.perUserLimit,
      terms: terms ?? this.terms,
      applicableProducts: applicableProducts ?? this.applicableProducts,
      isNewUserOnly: isNewUserOnly ?? this.isNewUserOnly,
      excludedProducts: excludedProducts ?? this.excludedProducts,
      totalUsed: totalUsed ?? this.totalUsed,
      userUsage: userUsage ?? this.userUsage,
      tags: tags ?? this.tags,
      promoCode: promoCode ?? this.promoCode,
      isVisible: isVisible ?? this.isVisible,
      isFeatured: isFeatured ?? this.isFeatured,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Predefined offer templates
class OfferTemplates {
  static List<OfferModel> getTemplates(String vendorId) {
    final now = DateTime.now();
    return [
      OfferModel(
        id: '',
        vendorId: vendorId,
        title: 'First Order Special',
        description: 'Get 25% off on your first order',
        type: OfferType.percentage,
        status: OfferStatus.active,
        discountValue: 25,
        maxDiscountAmount: 200,
        minOrderAmount: 99,
        startDate: now,
        endDate: now.add(Duration(days: 30)),
        perUserLimit: 1,
        terms: ['Valid for new users only', 'Minimum order ₹99'],
        isNewUserOnly: true,
        promoCode: 'FIRST25',
        tags: ['first-order', 'new-user'],
        createdAt: now,
        updatedAt: now,
      ),
      OfferModel(
        id: '',
        vendorId: vendorId,
        title: 'Weekend Special',
        description: 'Flat ₹100 off on orders above ₹500',
        type: OfferType.fixedAmount,
        status: OfferStatus.active,
        discountValue: 100,
        minOrderAmount: 500,
        startDate: now,
        endDate: now.add(Duration(days: 7)),
        terms: ['Valid on weekends only', 'Minimum order ₹500'],
        promoCode: 'WEEKEND100',
        tags: ['weekend', 'flat-discount'],
        createdAt: now,
        updatedAt: now,
      ),
      OfferModel(
        id: '',
        vendorId: vendorId,
        title: 'Free Delivery',
        description: 'Free delivery on all orders',
        type: OfferType.freeDelivery,
        status: OfferStatus.active,
        discountValue: 0,
        startDate: now,
        endDate: now.add(Duration(days: 15)),
        terms: ['No minimum order amount', 'Valid till stock lasts'],
        promoCode: 'FREEDEL',
        tags: ['free-delivery'],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}