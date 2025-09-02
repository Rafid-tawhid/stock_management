// models/product_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String modelName;
  final String serialNumber;
  final String manufacturer;
  final String category;
  final String condition;
  final String specifications;
  final double price;
  final int quantity;
  final List<String> imageUrls;
  final String status;
  final DateTime timestamp;
  final String? userId;

  Product({
    required this.id,
    required this.modelName,
    required this.serialNumber,
    required this.manufacturer,
    required this.category,
    required this.condition,
    required this.specifications,
    required this.price,
    required this.quantity,
    required this.imageUrls,
    required this.status,
    required this.timestamp,
    this.userId,
  });

  factory Product.fromMap(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      modelName: data['modelName'] ?? '',
      serialNumber: data['serialNumber'] ?? '',
      manufacturer: data['manufacturer'] ?? '',
      category: data['category'] ?? '',
      condition: data['condition'] ?? '',
      specifications: data['specifications'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      quantity: (data['quantity'] ?? 1).toInt(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      status: data['status'] ?? 'Available',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      userId: data['userId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'modelName': modelName,
      'serialNumber': serialNumber,
      'manufacturer': manufacturer,
      'category': category,
      'condition': condition,
      'specifications': specifications,
      'price': price,
      'quantity': quantity,
      'imageUrls': imageUrls,
      'status': status,
      'timestamp': timestamp,
      'userId': userId,
    };
  }

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  String get formattedDate => '${timestamp.day}/${timestamp.month}/${timestamp.year}';
}