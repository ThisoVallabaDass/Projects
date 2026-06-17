import 'package:cloud_firestore/cloud_firestore.dart';

/// Product model for TinyTrails vendor menu items
class ProductModel {
  final String id;
  final String vendorId;
  final String name;
  final String? description;
  final double price;
  final bool isVeg;
  final bool inStock;
  final String? imageUrl;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.vendorId,
    required this.name,
    this.description,
    required this.price,
    required this.isVeg,
    required this.inStock,
    this.imageUrl,
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory ProductModel.fromJson(Map<String, dynamic> json, String documentId) {
    return ProductModel(
      id: documentId,
      vendorId: json['vendorId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      isVeg: json['isVeg'] ?? true,
      inStock: json['inStock'] ?? true,
      imageUrl: json['imageUrl'],
      category: json['category'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'vendorId': vendorId,
      'name': name,
      'description': description,
      'price': price,
      'isVeg': isVeg,
      'inStock': inStock,
      'imageUrl': imageUrl,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  ProductModel copyWith({
    String? id,
    String? vendorId,
    String? name,
    String? description,
    double? price,
    bool? isVeg,
    bool? inStock,
    String? imageUrl,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      isVeg: isVeg ?? this.isVeg,
      inStock: inStock ?? this.inStock,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Get formatted price string
  String get formattedPrice => '₹${price.toStringAsFixed(0)}';

  /// Get veg/non-veg indicator emoji
  String get vegIndicator => isVeg ? '🟢' : '🔴';

  /// Get stock status text
  String get stockStatus => inStock ? 'In Stock' : 'Out of Stock';

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, price: $price, isVeg: $isVeg, inStock: $inStock)';
  }
}
