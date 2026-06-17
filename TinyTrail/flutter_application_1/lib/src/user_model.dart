import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String username;
  final String email;
  final String phone;
  final String pincode;
  final String role; // 'BUYER' or 'SELLER'
  final String businessType; // 'food', 'tailor', 'artisan', etc.
  final String? shopName;
  final String vendorCategory; // 'food' or 'non-food'
  final List<String> baselinePhotos; // URLs of 5 baseline onboarding photos
  final bool hasPassedOnboarding; // Whether vendor completed onboarding
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.pincode,
    required this.role,
    required this.businessType,
    this.shopName,
    required this.vendorCategory,
    this.baselinePhotos = const [],
    this.hasPassedOnboarding = false,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isVendor => role == 'SELLER';
  bool get isFoodVendor => isVendor && businessType == 'food';

  String get businessTypeLabel {
    switch (businessType) {
      case 'food':
        return 'Food Vendor';
      case 'tailor':
        return 'Tailor';
      case 'artisan':
        return 'Artisan';
      default:
        return isVendor ? 'Vendor' : 'Customer';
    }
  }

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'pincode': pincode,
      'role': role,
      'businessType': businessType,
      'shopName': shopName,
      'vendorCategory': vendorCategory,
      'baselinePhotos': baselinePhotos,
      'hasPassedOnboarding': hasPassedOnboarding,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create from JSON/Firestore document
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      pincode: json['pincode'] ?? '',
      role: json['role'] ?? 'BUYER',
      businessType: json['businessType'] ?? '',
      shopName: json['shopName'],
      vendorCategory: json['vendorCategory'] ?? 'non-food',
      baselinePhotos: List<String>.from(json['baselinePhotos'] ?? []),
      hasPassedOnboarding: json['hasPassedOnboarding'] ?? false,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null
          ? json['updatedAt'] is Timestamp
              ? (json['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? phone,
    String? pincode,
    String? role,
    String? businessType,
    String? shopName,
    String? vendorCategory,
    List<String>? baselinePhotos,
    bool? hasPassedOnboarding,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      pincode: pincode ?? this.pincode,
      role: role ?? this.role,
      businessType: businessType ?? this.businessType,
      shopName: shopName ?? this.shopName,
      vendorCategory: vendorCategory ?? this.vendorCategory,
      baselinePhotos: baselinePhotos ?? this.baselinePhotos,
      hasPassedOnboarding: hasPassedOnboarding ?? this.hasPassedOnboarding,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
