import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart';

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

    // Get buyer info from current user
    final userDoc = await _firestore.collection('users').doc(_userId).get();
    final buyerName = userDoc.data()?['name'] ?? '';
    final buyerEmail = userDoc.data()?['email'] ?? '';

    // Determine sellerId from first item (assuming single seller per order)
    final sellerId = cartItems.first['sellerId'] ?? '';
    if (sellerId.isEmpty) {
      throw Exception('Unable to determine seller');
    }

    // Calculate total amount, subtotal, tax, and service fee
    double subtotal = 0.0;
    for (var item in cartItems) {
      subtotal += (item['price'] as double) * (item['quantity'] as int);
    }
    // Assuming tax is 10% and service fee is 5% for example
    // In a real app, these would be configurable
    final tax = subtotal * 0.10;
    final serviceFee = subtotal * 0.05;
    final totalAmount = subtotal + tax + serviceFee;

    // Create order items
    final List<OrderItem> orderItems = [];
    for (var item in cartItems) {
      orderItems.add(
        OrderItem(
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

    final MarketplaceOrder order = MarketplaceOrder(
      orderId: orderId,
      buyerId: _userId,
      sellerId: sellerId,
      buyerName: buyerName,
      buyerEmail: buyerEmail,
      items: orderItems,
      subtotal: subtotal,
      tax: tax,
      serviceFee: serviceFee,
      totalAmount: totalAmount,
      status: 'pending',
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );

    await orderDoc.set(order.toMap());

    return orderId;
  }

  // Get orders for the current user
  Stream<List<MarketplaceOrder>> getUserOrders() {
    if (_userId.isEmpty) {
      return const Stream.empty();
    }
    return _ordersCollection
        .where('buyerId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MarketplaceOrder.fromDocument(doc))
            .toList());
  }

  // Get a single order by ID
  Future<MarketplaceOrder?> getOrderById(String orderId) async {
    if (_userId.isEmpty) return null;

    final doc = await _ordersCollection.doc(orderId).get();
    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>;
    // Ensure the order belongs to the current user (security)
    if (data['buyerId'] != _userId) return null;

    return MarketplaceOrder.fromDocument(doc);
  }

  // Get orders for the current user as a seller
  Stream<List<MarketplaceOrder>> getSellerOrders() {
    if (_userId.isEmpty) {
      return const Stream.empty();
    }
    return _ordersCollection
        .where('sellerId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MarketplaceOrder.fromDocument(doc))
            .toList());
  }

  // Get orders by sellerId
  Stream<List<MarketplaceOrder>> getOrdersBySeller(String sellerId) {
    if (sellerId.isEmpty) {
      return const Stream.empty();
    }
    return _ordersCollection
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MarketplaceOrder.fromDocument(doc))
            .toList());
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    if (_userId.isEmpty) return;

    final docRef = _ordersCollection.doc(orderId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    // Ensure the order belongs to the current user as seller (security)
    if (data['sellerId'] != _userId) return;

    await docRef.update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }
}