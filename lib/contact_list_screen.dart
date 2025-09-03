// screens/contact_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_maintain/riverpod/show_provider.dart';
import 'package:intl/intl.dart';

import 'contact_screen.dart';
import 'models/contact.dart';

class ContactListScreen extends ConsumerWidget {
  const ContactListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider); // Watch the StreamProvider
    final searchQuery = ref.watch(searchQueryProvider);
    final filteredContacts = ref.watch(filteredContactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactInfoScreen()),
              );
            },
            tooltip: 'Add New Contact',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
            ),
          ),

          // Contacts List
          Expanded(
            child: contactsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading contacts',
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(contactsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (contacts) {
                // Use the filtered contacts instead of raw contacts
                final displayContacts = searchQuery.isEmpty ? contacts : filteredContacts;

                if (displayContacts.isEmpty) {
                  return _buildEmptyState(searchQuery);
                }

                return ListView.builder(
                  itemCount: displayContacts.length,
                  itemBuilder: (context, index) {
                    final contact = displayContacts[index];
                    return _ContactCard(contact: contact);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ContactInfoScreen()),
          );
        },
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(String searchQuery) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.contacts, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty ? 'No contacts found' : 'No matching contacts',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'Tap the + button to add your first contact'
                : 'Try a different search term',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Contact contact;

  const _ContactCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showContactDetails(context, contact),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: _getColorFromName(contact.personName),
                radius: 24,
                child: Text(
                  contact.personName.isNotEmpty ? contact.personName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Contact Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.personName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (contact.companyName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        contact.companyName,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (contact.phoneNumber.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '📞 ${contact.phoneNumber}',
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Added: ${DateFormat('MMM dd, yyyy').format(contact.timestamp)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Contact Type Chip
              Chip(
                label: Text(
                  contact.contactType,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
                backgroundColor: _getColorForType(contact.contactType),
                side: BorderSide.none,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorFromName(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    final index = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'business':
        return Colors.blue;
      case 'personal':
        return Colors.green;
      case 'client':
        return Colors.orange;
      case 'supplier':
        return Colors.purple;
      case 'colleague':
        return Colors.teal;
      case 'friend':
        return Colors.pink;
      case 'family':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showContactDetails(BuildContext context, Contact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          contact.personName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (contact.companyName.isNotEmpty)
                _DetailItem('Company', contact.companyName),
              if (contact.phoneNumber.isNotEmpty)
                _DetailItem('Phone', contact.phoneNumber),
              if (contact.email.isNotEmpty)
                _DetailItem('Email', contact.email),
              if (contact.location.isNotEmpty)
                _DetailItem('Location', contact.location),
              if (contact.notes.isNotEmpty)
                _DetailItem('Notes', contact.notes),
              _DetailItem('Type', contact.contactType),
              _DetailItem('Status', contact.status),
              _DetailItem('Added', DateFormat('MMM dd, yyyy - HH:mm').format(contact.timestamp)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}