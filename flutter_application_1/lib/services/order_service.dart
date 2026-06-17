import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart' as app_order;

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  CollectionReference get _ordersCollection =>
      _firestore.collection('orders');

  // Create a new order from cart items
  Future<String> createOrder(List<Map<String, dynamic>> cartItems) async {
    if (_userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    if (cartItems.isEmpty) {
      throw Exception('Cart is empty');
    }

    // Determine sellerId from first item (assuming single seller per order)
    final sellerId = cartItems.first['sellerId'] ?? '';
    if (sellerId.isEmpty) {
      throw Exception('Unable to determine seller');
    }

    // Calculate total amount
    double totalAmount = 0.0;
    for (var item in cartItems) {
      totalAmount += (item['price'] as double) * (item['quantity'] as int);
    }

    // Create order items
    final List<app_order.OrderItem> orderItems = [];
    for (var item in cartItems) {
      orderItems.add(
        app_order.OrderItem(
          productId: item['productId'] ?? '',
          title: item['title'] ?? '',
          price: item['price'] as double,
          quantity: item['quantity'] as int,
          imageUrl: item['imageUrl'] ?? '',
        ),
      );
    }

    // Create order document
    final DocumentReference orderDoc = _ordersCollection.doc();
    final String orderId = orderDoc.id;

    final app_order.MarketplaceOrder order = app_order.MarketplaceOrder(
      orderId: orderId,
      buyerId: _userId,
      sellerId: sellerId,
      items: orderItems,
      totalAmount: totalAmount,
      status: 'pending',
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );

    await orderDoc.set(order.toMap());

    return orderId;
  }

  // Get orders for the current user
Stream<List<app_order.MarketplaceOrder>> getUserOrders() {
    if (_userId.isEmpty) {
      return const Stream.empty();
    }
    return _ordersCollection
        .where('buyerId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_order.MarketplaceOrder.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get a single order by ID
  Future<app_order.MarketplaceOrder?> getOrderById(String orderId) async {
    if (_userId.isEmpty) return null;

    final doc = await _ordersCollection.doc(orderId).get();
    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>;
    // Ensure the order belongs to the current user (security)
    if (data['buyerId'] != _userId) return null;

    return app_order.MarketplaceOrder.fromMap(data);
  }

  // Get orders for the current user as a seller
  Stream<List<app_order.MarketplaceOrder>> getSellerOrders() {
    if (_userId.isEmpty) {
      return const Stream.empty();
    }
    return _ordersCollection
        .where('sellerId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_order.MarketplaceOrder.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get orders by sellerId
  Stream<List<app_order.MarketplaceOrder>> getOrdersBySeller(String sellerId) {
    if (sellerId.isEmpty) {
      return const Stream.empty();
    }
    return _ordersCollection
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_order.MarketplaceOrder.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    if (_userId.isEmpty) return;

    final docRef = _ordersCollection.doc(orderId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    if (data['buyerId'] != _userId) return;

    await docRef.update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }
}