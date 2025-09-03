// repositories/product_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/contact_model.dart';

// class ProductRepository {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   Stream<List<Product>> getAllProducts() {
//     return _firestore
//         .collection('products')
//         .orderBy('timestamp', descending: true)
//         .snapshots()
//         .map((snapshot) => snapshot.docs
//         .map((doc) => Product.fromMap(doc.data(), doc.id))
//         .toList());
//   }
//
//   Stream<List<Product>> searchProducts(String query) {
//     return _firestore
//         .collection('products')
//         .orderBy('timestamp', descending: true)
//         .snapshots()
//         .map((snapshot) => snapshot.docs
//         .map((doc) => Product.fromMap(doc.data(), doc.id))
//         .where((product) =>
//     product.modelName.toLowerCase().contains(query.toLowerCase()) ||
//         product.serialNumber.toLowerCase().contains(query.toLowerCase()) ||
//         product.manufacturer.toLowerCase().contains(query.toLowerCase()) ||
//         product.category.toLowerCase().contains(query.toLowerCase()))
//         .toList());
//   }
//
//   Future<void> deleteProduct(String productId) async {
//     await _firestore.collection('products').doc(productId).delete();
//   }
// }