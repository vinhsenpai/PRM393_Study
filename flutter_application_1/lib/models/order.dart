import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String title;
  final double price;
  final int quantity;
  final String imageUrl;
  final String accountName;
  final String password;

  OrderItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.accountName,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'title': title,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'accountName': accountName,
      'password': password,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      title: map['title'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      quantity: map['quantity'] ?? 0,
      imageUrl: map['imageUrl'] ?? '',
      accountName: map['accountName'] ?? '',
      password: map['password'] ?? '',
    );
  }
}

class MarketplaceOrder {

  final String orderId;
  final String buyerId;
  final String sellerId;
  final String buyerName;
  final String buyerEmail;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double serviceFee;
  final double totalAmount;
  final String status; // pending, processing, completed, cancelled
  final String paymentMethod; // zalopay_sandbox, cod
  final Map<String, dynamic> paymentInfo; // gateway transaction details
  final Timestamp createdAt;
  final Timestamp updatedAt;

  MarketplaceOrder({
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.buyerName,
    required this.buyerEmail,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.serviceFee,
    required this.totalAmount,
    required this.status,
    this.paymentMethod = 'cod',
    this.paymentInfo = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'buyerName': buyerName,
      'buyerEmail': buyerEmail,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'serviceFee': serviceFee,
      'totalAmount': totalAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentInfo': paymentInfo,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory MarketplaceOrder.fromMap(Map<String, dynamic> map) {
    return MarketplaceOrder(
      orderId: map['orderId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      buyerEmail: map['buyerEmail'] ?? '',
      items: List<OrderItem>.from(
        map['items']?.map((item) => OrderItem.fromMap(item)) ?? [],
      ),
      subtotal: map['subtotal']?.toDouble() ?? 0.0,
      tax: map['tax']?.toDouble() ?? 0.0,
      serviceFee: map['serviceFee']?.toDouble() ?? 0.0,
      totalAmount: map['totalAmount']?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
      paymentMethod: map['paymentMethod'] ?? 'cod',
      paymentInfo: Map<String, dynamic>.from(map['paymentInfo'] ?? {}),
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  // Factory method to create from DocumentSnapshot (for use in stream)
  factory MarketplaceOrder.fromDocument(DocumentSnapshot doc) {
    return MarketplaceOrder.fromMap(doc.data() as Map<String, dynamic>);
  }
}