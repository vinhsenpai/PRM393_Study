import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection references
  CollectionReference get _products => _firestore.collection('products');

  // Create a new product
  Future<String> createProduct(Product product) async {
    try {
      final docRef = await _products.add(product.toDocument());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Get a product by ID
  Future<Product?> getProduct(String productId) async {
    try {
      final doc = await _products.doc(productId).get();
      if (doc.exists) {
        return Product.fromDocument(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Update a product
  Future<void> updateProduct(String productId, Product product) async {
    try {
      await _products.doc(productId).update(product.toDocument());
    } catch (e) {
      rethrow;
    }
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      await _products.doc(productId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Get products by seller ID
  Stream<List<Product>> getProductsBySeller(String sellerId) {
    return _products
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromDocument(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get all products (for browsing)
  Stream<List<Product>> getAllProducts() {
    return _products
        .where('stockStatus', isEqualTo: 'available')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromDocument(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Upload product images to Firebase Storage
  Future<List<String>> uploadProductImages(List<String> filePaths) async {
    try {
      final List<String> imageUrls = [];
      for (final filePath in filePaths) {
        final fileName = 'products/${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';
        final ref = _storage.ref().child(fileName);
        await ref.putFile(File(filePath));
        final downloadUrl = await ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }
      return imageUrls;
    } catch (e) {
      rethrow;
    }
  }

  // Delete product images from Firebase Storage
  Future<void> deleteProductImages(List<String> imageUrls) async {
    try {
      for (final url in imageUrls) {
        // Extract file path from URL
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          final filePath = pathSegments.join('/');
          final ref = _storage.ref().child(filePath);
          await ref.delete();
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}