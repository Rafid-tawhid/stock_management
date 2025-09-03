// providers/contacts_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_maintain/models/contact_model.dart';

import '../models/contact.dart';

final contactsProvider = StreamProvider<List<Contact>>((ref) {
  return FirebaseFirestore.instance
      .collection('contacts')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return Contact.fromMap(doc.data(), doc.id);
    }).toList();
  });
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredContactsProvider = Provider<List<Contact>>((ref) {
  final contacts = ref.watch(contactsProvider).value ?? [];
  final searchQuery = ref.watch(searchQueryProvider);

  if (searchQuery.isEmpty) {
    return contacts;
  }

  return contacts.where((contact) {
    return contact.personName.toLowerCase().contains(searchQuery.toLowerCase()) ||
        contact.companyName.toLowerCase().contains(searchQuery.toLowerCase()) ||
        contact.phoneNumber.contains(searchQuery) ||
        contact.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
        contact.location.toLowerCase().contains(searchQuery.toLowerCase()) ||
        contact.contactType.toLowerCase().contains(searchQuery.toLowerCase());
  }).toList();
});