import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Contact {
  final String id;
  final DateTime timestamp;
  final String personName;
  final String companyName;
  final String location;
  final String phoneNumber;
  final String email;
  final String contactType;
  final String notes;
  final String status;
  final String? userId;
  final List<String> imageUrls;
  final int imageCount;

  Contact({
    required this.id,
    required this.timestamp,
    required this.personName,
    required this.companyName,
    required this.location,
    required this.phoneNumber,
    required this.email,
    required this.contactType,
    required this.notes,
    required this.status,
    this.userId,
    required this.imageUrls,
    required this.imageCount,
  });

  // Convert a Contact into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp,
      'personName': personName,
      'companyName': companyName,
      'location': location,
      'phoneNumber': phoneNumber,
      'email': email,
      'contactType': contactType,
      'notes': notes,
      'status': status,
      'userId': userId,
      'imageUrls': imageUrls,
      'imageCount': imageCount,
    };
  }

  // Create a Contact from a Map
  factory Contact.fromMap(Map<String, dynamic> map,String? id) {
    return Contact(
      id: id??map['id']??'',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      personName: map['personName'] ?? '',
      companyName: map['companyName'] ?? '',
      location: map['location'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'] ?? '',
      contactType: map['contactType'] ?? '',
      notes: map['notes'] ?? '',
      status: map['status'] ?? 'Active',
      userId: map['userId'],
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      imageCount: map['imageCount'] ?? 0,
    );
  }

  // Copy method to create a new Contact with updated values
  Contact copyWith({
    String? id,
    DateTime? timestamp,
    String? personName,
    String? companyName,
    String? location,
    String? phoneNumber,
    String? email,
    String? contactType,
    String? notes,
    String? status,
    String? userId,
    List<String>? imageUrls,
    int? imageCount,
  }) {
    return Contact(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      personName: personName ?? this.personName,
      companyName: companyName ?? this.companyName,
      location: location ?? this.location,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      contactType: contactType ?? this.contactType,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      imageUrls: imageUrls ?? this.imageUrls,
      imageCount: imageCount ?? this.imageCount,
    );
  }

  // Helper method to create an empty contact
  factory Contact.empty() {
    return Contact(
      id: '',
      timestamp: DateTime.now(),
      personName: '',
      companyName: '',
      location: '',
      phoneNumber: '',
      email: '',
      contactType: '',
      notes: '',
      status: 'Active',
      userId: null,
      imageUrls: [],
      imageCount: 0,
    );
  }

  // Check if the contact is empty
  bool get isEmpty {
    return personName.isEmpty &&
        companyName.isEmpty &&
        location.isEmpty &&
        phoneNumber.isEmpty &&
        email.isEmpty;
  }

  // Convert to JSON for API calls
  String toJson() => json.encode(toMap());


  @override
  String toString() {
    return 'Contact(id: $id, personName: $personName, companyName: $companyName, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Contact &&
        other.id == id &&
        other.timestamp == timestamp &&
        other.personName == personName &&
        other.companyName == companyName &&
        other.location == location &&
        other.phoneNumber == phoneNumber &&
        other.email == email &&
        other.contactType == contactType &&
        other.notes == notes &&
        other.status == status &&
        other.userId == userId &&
        other.imageCount == imageCount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    timestamp.hashCode ^
    personName.hashCode ^
    companyName.hashCode ^
    location.hashCode ^
    phoneNumber.hashCode ^
    email.hashCode ^
    contactType.hashCode ^
    notes.hashCode ^
    status.hashCode ^
    userId.hashCode ^
    imageUrls.hashCode ^
    imageCount.hashCode;
  }
}