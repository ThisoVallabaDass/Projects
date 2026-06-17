import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum representing user roles in TinyTrails
enum UserRole {
  customer,
  vendor;

  String get value {
    switch (this) {
      case UserRole.customer:
        return 'customer';
      case UserRole.vendor:
        return 'vendor';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'vendor':
        return UserRole.vendor;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }
}

/// Enum representing vendor trust tiers
enum TrustTier {
  blue,
  gold,
  platinum;

  String get displayName {
    switch (this) {
      case TrustTier.blue:
        return 'Tier 1: Verified';
      case TrustTier.gold:
        return 'Tier 2: Licensed';
      case TrustTier.platinum:
        return 'Tier 3: Premium';
    }
  }

  String get emoji {
    switch (this) {
      case TrustTier.blue:
        return '🛡️';
      case TrustTier.gold:
        return '🏆';
      case TrustTier.platinum:
        return '💎';
    }
  }

  static TrustTier fromString(String tier) {
    switch (tier.toLowerCase()) {
      case 'gold':
        return TrustTier.gold;
      case 'platinum':
        return TrustTier.platinum;
      case 'blue':
      default:
        return TrustTier.blue;
    }
  }
}

/// User model for TinyTrails
class UserModel {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? phoneNumber;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Vendor-specific fields
  final TrustTier? trustTier;
  final int? hygieneScore;
  final bool? isLive;
  final String? businessName;
  final String? businessType;
  final String vendorCategory;
  final List<String> baselinePhotos;
  final bool hasPassedOnboarding;
  final GeoPoint? location;

  // Customer-specific fields
  final String? defaultAddress;
  final String? pincode;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.phoneNumber,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    // Vendor fields
    this.trustTier,
    this.hygieneScore,
    this.isLive,
    this.businessName,
    this.businessType,
    this.vendorCategory = 'non-food',
    this.baselinePhotos = const [],
    this.hasPassedOnboarding = false,
    this.location,
    // Customer fields
    this.defaultAddress,
    this.pincode,
  });

  /// Create from Firestore document
  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    return UserModel(
      uid: documentId,
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: UserRole.fromString(json['role'] ?? 'customer'),
      phoneNumber: json['phoneNumber'],
      photoUrl: json['photoUrl'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // Vendor fields
      trustTier: json['trustTier'] != null
          ? TrustTier.fromString(json['trustTier'])
          : null,
      hygieneScore: json['hygieneScore'],
      isLive: json['isLive'],
      businessName: json['businessName'],
      businessType: json['businessType'],
      vendorCategory: (json['vendorCategory'] as String?) ??
          ((json['businessType'] as String?) == 'food' ? 'food' : 'non-food'),
      baselinePhotos: List<String>.from(json['baselinePhotos'] ?? const []),
      hasPassedOnboarding: json['hasPassedOnboarding'] == true,
      location: json['location'],
      // Customer fields
      defaultAddress: json['defaultAddress'],
      pincode: json['pincode'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'email': email,
      'name': name,
      'role': role.value,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };

    // Add vendor-specific fields
    if (role == UserRole.vendor) {
      data['trustTier'] = trustTier?.name ?? 'blue';
      // Only set hygiene score for food vendors
      if (vendorCategory == 'food' && hygieneScore != null) {
        data['hygieneScore'] = hygieneScore;
      }
      data['isLive'] = isLive ?? false;
      data['businessName'] = businessName;
      data['businessType'] = businessType;
      data['vendorCategory'] = vendorCategory;
      data['baselinePhotos'] = baselinePhotos;
      data['hasPassedOnboarding'] = hasPassedOnboarding;
      if (location != null) {
        data['location'] = location;
      }
    }

    // Add customer-specific fields
    if (role == UserRole.customer) {
      data['defaultAddress'] = defaultAddress;
      data['pincode'] = pincode;
    }

    return data;
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    UserRole? role,
    String? phoneNumber,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    TrustTier? trustTier,
    int? hygieneScore,
    bool? isLive,
    String? businessName,
    String? businessType,
    String? vendorCategory,
    List<String>? baselinePhotos,
    bool? hasPassedOnboarding,
    GeoPoint? location,
    String? defaultAddress,
    String? pincode,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      trustTier: trustTier ?? this.trustTier,
      hygieneScore: hygieneScore ?? this.hygieneScore,
      isLive: isLive ?? this.isLive,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      vendorCategory: vendorCategory ?? this.vendorCategory,
      baselinePhotos: baselinePhotos ?? this.baselinePhotos,
      hasPassedOnboarding: hasPassedOnboarding ?? this.hasPassedOnboarding,
      location: location ?? this.location,
      defaultAddress: defaultAddress ?? this.defaultAddress,
      pincode: pincode ?? this.pincode,
    );
  }

  /// Check if user is a vendor
  bool get isVendor => role == UserRole.vendor;

  /// Check if user is a customer
  bool get isCustomer => role == UserRole.customer;

  /// Get display hygiene score with percentage
  String get hygieneDisplay => '${hygieneScore ?? 0}%';

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, name: $name, role: ${role.value})';
  }
}
