import 'package:cloud_firestore/cloud_firestore.dart';

/// Order status enum
enum OrderStatus {
  pending,
  accepted,
  preparing,
  ready,
  outForDelivery,
  delivered,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return OrderStatus.accepted;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'outfordelivery':
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }
}

/// Order item model
class OrderItemModel {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final bool isVeg;

  OrderItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.isVeg,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'isVeg': isVeg,
    };
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      isVeg: json['isVeg'] as bool,
    );
  }

  double get subtotal => price * quantity;
}

/// Order model
class OrderModel {
  final String? id;
  final String customerId;
  final String customerName;
  final String vendorId;
  final String vendorName;
  final List<OrderItemModel> items;
  final double itemTotal;
  final double deliveryFee;
  final double platformFee;
  final double discount;
  final double totalAmount;
  final String deliveryAddress;
  final String? couponCode;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? customerPhone;
  final String? specialInstructions;

  OrderModel({
    this.id,
    required this.customerId,
    required this.customerName,
    required this.vendorId,
    required this.vendorName,
    required this.items,
    required this.itemTotal,
    required this.deliveryFee,
    required this.platformFee,
    required this.discount,
    required this.totalAmount,
    required this.deliveryAddress,
    this.couponCode,
    this.status = OrderStatus.pending,
    required this.createdAt,
    this.updatedAt,
    this.customerPhone,
    this.specialInstructions,
  });

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'items': items.map((item) => item.toJson()).toList(),
      'itemTotal': itemTotal,
      'deliveryFee': deliveryFee,
      'platformFee': platformFee,
      'discount': discount,
      'totalAmount': totalAmount,
      'deliveryAddress': deliveryAddress,
      'couponCode': couponCode,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : Timestamp.fromDate(createdAt),
      'customerPhone': customerPhone,
      'specialInstructions': specialInstructions,
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json, String documentId) {
    return OrderModel(
      id: documentId,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      vendorId: json['vendorId'] as String,
      vendorName: json['vendorName'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      itemTotal: (json['itemTotal'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      platformFee: (json['platformFee'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      deliveryAddress: json['deliveryAddress'] as String,
      couponCode: json['couponCode'] as String?,
      status: OrderStatus.fromString(json['status'] as String? ?? 'pending'),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
      customerPhone: json['customerPhone'] as String?,
      specialInstructions: json['specialInstructions'] as String?,
    );
  }

  OrderModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? vendorId,
    String? vendorName,
    List<OrderItemModel>? items,
    double? itemTotal,
    double? deliveryFee,
    double? platformFee,
    double? discount,
    double? totalAmount,
    String? deliveryAddress,
    String? couponCode,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerPhone,
    String? specialInstructions,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      items: items ?? this.items,
      itemTotal: itemTotal ?? this.itemTotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      platformFee: platformFee ?? this.platformFee,
      discount: discount ?? this.discount,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      couponCode: couponCode ?? this.couponCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerPhone: customerPhone ?? this.customerPhone,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
}
