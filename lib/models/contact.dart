// models/contact_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Contact {
  final String id;
  final String personName;
  final String companyName;
  final String location;
  final String phoneNumber;
  final String email;
  final String notes;
  final String contactType;
  final DateTime timestamp;
  final String status;

  Contact({
    required this.id,
    required this.personName,
    required this.companyName,
    required this.location,
    required this.phoneNumber,
    required this.email,
    required this.notes,
    required this.contactType,
    required this.timestamp,
    required this.status,
  });

  factory Contact.fromMap(Map<String, dynamic> map, String id) {
    return Contact(
      id: id,
      personName: map['personName'] ?? '',
      companyName: map['companyName'] ?? '',
      location: map['location'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'] ?? '',
      notes: map['notes'] ?? '',
      contactType: map['contactType'] ?? 'Business',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      status: map['status'] ?? 'Active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'personName': personName,
      'companyName': companyName,
      'location': location,
      'phoneNumber': phoneNumber,
      'email': email,
      'notes': notes,
      'contactType': contactType,
      'timestamp': timestamp,
      'status': status,
    };
  }
}