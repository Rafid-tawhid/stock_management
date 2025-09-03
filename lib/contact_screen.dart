// screens/contact_info_screen.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stock_maintain/riverpod/contact_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'contact_list_screen.dart';
import 'models/contact_model.dart';

class ContactInfoScreen extends ConsumerStatefulWidget {
  const ContactInfoScreen({super.key});

  @override
  ConsumerState<ContactInfoScreen> createState() => _ContactInfoScreenState();
}

class _ContactInfoScreenState extends ConsumerState<ContactInfoScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  // Contact types
  final List<String> _contactTypes = [
    'Business',
    'Personal',
    'Client',
    'Supplier',
    'Colleague',
    'Friend',
    'Family',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    try {
      // Check if user is already signed in
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }

      await Permission.storage.request();
      await Permission.photos.request();
      await Permission.mediaLibrary.request();
      await Permission.camera.request();
    } catch (e) {
      _showError('Failed to initialize: $e');
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 50,
      );

      if (images.isNotEmpty) {
        ref.read(contactProvider.notifier).addImages(images);
      }
    } catch (e) {
      _showError('Failed to pick images: $e');
    }
  }

  Future<void> _captureImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (image != null) {
        ref.read(contactProvider.notifier).addImages([image]);
      }
    } catch (e) {
      _showError('Failed to capture image: $e');
    }
  }

  Future<void> _saveContact() async {
    final state = ref.read(contactProvider);

    if (state.personName.isEmpty) {
      _showError('Please enter person name');
      return;
    }

    if (state.phoneNumber.isEmpty) {
      _showError('Please enter phone number');
      return;
    }

    ref.read(contactProvider.notifier).setLoading(true);
    ref.read(contactProvider.notifier).setUploadProgress(0.0);
    ref.read(contactProvider.notifier).setUploadStatus('Saving contact...');

    try {
      // Generate unique ID for this contact
      final String contactId = const Uuid().v4();
      final DateTime now = DateTime.now();

      // Prepare contact data
      final contactData = {
        'id': contactId,
        'timestamp': now,
        'personName': state.personName,
        'companyName': state.companyName,
        'location': state.location,
        'phoneNumber': state.phoneNumber,
        'email': state.email,
        'contactType': state.contactType,
        'notes': state.notes,
        'status': 'Active',
        'userId': FirebaseAuth.instance.currentUser?.uid,
      };

      // Save to Firestore
      ref.read(contactProvider.notifier).setUploadStatus('Saving contact details...');
      ref.read(contactProvider.notifier).setUploadProgress(0.8);

      await FirebaseFirestore.instance
          .collection('contacts')
          .doc(contactId)
          .set(contactData);

      ref.read(contactProvider.notifier).setUploadProgress(1.0);
      ref.read(contactProvider.notifier).setUploadStatus('Contact saved successfully!');

      _showSuccess('Contact "${state.personName}" saved successfully!');
      ref.read(contactProvider.notifier).clearForm();
    } catch (e) {
      _showError('Failed to save contact: $e');
    } finally {
      ref.read(contactProvider.notifier).setLoading(false);
    }
  }

  void _showError(String message) {
    debugPrint('Error: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contactProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Contact Information'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(contactProvider.notifier).clearForm(),
            tooltip: 'Clear Form',
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=>ContactListScreen()));
            },
            tooltip: 'Show Contact',
          ),
        ],
      ),
      body: state.isLoading ? _buildProgressIndicator(state) : _buildContactForm(state),
    );
  }

  Widget _buildProgressIndicator(ContactState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(value: state.uploadProgress),
          const SizedBox(height: 20),
          Text(
            state.uploadStatus,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            '${(state.uploadProgress * 100).toStringAsFixed(0)}% complete',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildContactForm(ContactState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Center(
            child: Text(
              'Add New Contact',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Contact Images Section
          _buildImageSection(state),
          const SizedBox(height: 24),

          // Contact Details Section
          _buildContactDetailsSection(state),
          const SizedBox(height: 24),

          // Save Button
          _buildSaveButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildImageSection(ContactState state) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📷 Contact Images',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add photos of the person or business card',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Image Selection Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.photo_library, size: 20),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _captureImage,
                    icon: const Icon(Icons.camera_alt, size: 20),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Selected Images Preview
            if (state.contactImages.isNotEmpty) ...[
              const Text(
                'Selected Images',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.contactImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(state.contactImages[index].path),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => ref.read(contactProvider.notifier).removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 14,
                                    color: Colors.white
                                ),
                              ),
                            ),
                          ),
                          if (index == 0)
                            const Positioned(
                              bottom: 4,
                              left: 4,
                              child: Text(
                                'Main',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  backgroundColor: Colors.black54,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactDetailsSection(ContactState state) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Contact Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Person Name
            TextFormField(
              initialValue: state.personName,
              decoration: InputDecoration(
                labelText: 'Person Name *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) => ref.read(contactProvider.notifier).updatePersonName(value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter person name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Company Name
            TextFormField(
              initialValue: state.companyName,
              decoration: InputDecoration(
                labelText: 'Company Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.business),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) => ref.read(contactProvider.notifier).updateCompanyName(value),
            ),
            const SizedBox(height: 12),

            // Location
            TextFormField(
              initialValue: state.location,
              decoration: InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.location_on),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) => ref.read(contactProvider.notifier).updateLocation(value),
            ),
            const SizedBox(height: 12),

            // Phone Number
            TextFormField(
              initialValue: state.phoneNumber,
              decoration: InputDecoration(
                labelText: 'Phone Number *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.phone),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) => ref.read(contactProvider.notifier).updatePhoneNumber(value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Email
            TextFormField(
              initialValue: state.email,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.email),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) => ref.read(contactProvider.notifier).updateEmail(value),
            ),
            const SizedBox(height: 12),

            // Contact Type Dropdown
            DropdownButtonFormField<String>(
              value: state.contactType,
              decoration: InputDecoration(
                labelText: 'Contact Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.category),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: _contactTypes.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  ref.read(contactProvider.notifier).updateContactType(newValue);
                }
              },
            ),
            const SizedBox(height: 12),

            // Notes
            TextFormField(
              initialValue: state.notes,
              decoration: InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                alignLabelWithHint: true,
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 4,
              onChanged: (value) => ref.read(contactProvider.notifier).updateNotes(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveContact,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save, size: 20),
            SizedBox(width: 8),
            Text('SAVE CONTACT'),
          ],
        ),
      ),
    );
  }
}