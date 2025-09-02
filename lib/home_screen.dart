import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stock_maintain/screens/product_list.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  // Form controllers
  final TextEditingController _modelNameController = TextEditingController();
  final TextEditingController _serialNumberController = TextEditingController();
  final TextEditingController _manufacturerController = TextEditingController();
  final TextEditingController _specificationsController =
  TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  // Image handling
  final List<XFile> _productImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  // UI state
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  // Categories
  final List<String> _categories = [
    'Smartphones',
    'Laptops',
    'Tablets',
    'Cameras',
    'Audio Devices',
    'Wearables',
    'Gaming Consoles',
    'Accessories',
    'Other'
  ];
  String _selectedCategory = 'Smartphones';

  // Conditions
  final List<String> _conditions = [
    'New',
    'Refurbished',
    'Used - Like New',
    'Used - Good',
    'Used - Fair'
  ];
  String _selectedCondition = 'New';

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
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _productImages.addAll(images);
        });
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
        setState(() {
          _productImages.add(image);
        });
      }
    } catch (e) {
      _showError('Failed to capture image: $e');
    }
  }

  Future<void> _saveProduct() async {
    if (_productImages.isEmpty) {
      _showError('Please add at least one product image');
      return;
    }

    if (_modelNameController.text.isEmpty) {
      _showError('Please enter model name');
      return;
    }

    if (_serialNumberController.text.isEmpty) {
      _showError('Please enter serial number');
      return;
    }

    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      _showError('Please enter a valid price');
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 1;
    if (quantity <= 0) {
      _showError('Please enter a valid quantity');
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Saving product...';
    });

    try {
      // Generate unique ID for this product
      final String productId = const Uuid().v4();
      final DateTime now = DateTime.now();

      // Upload images to Firebase Storage with authentication
      setState(() {
        _uploadProgress = 0.1;
        _uploadStatus = 'Preparing image upload...';
      });

      // Call the correct function with the entire list
      List<String> imageUrls = await uploadMultipleImagesWithAuth(
        _productImages,
        productId,
            (progress, status) {
          setState(() {
            _uploadProgress = progress;
            _uploadStatus = status;
          });
        },
      );

      // Prepare product data
      final productData = {
        'id': productId,
        'timestamp': now,
        'modelName': _modelNameController.text,
        'serialNumber': _serialNumberController.text,
        'manufacturer': _manufacturerController.text,
        'category': _selectedCategory,
        'condition': _selectedCondition,
        'specifications': _specificationsController.text,
        'price': price,
        'quantity': quantity,
        'imageUrls': imageUrls,
        'status': 'Available',
        'userId': FirebaseAuth.instance.currentUser?.uid,
      };

      // Save to Firestore
      setState(() {
        _uploadStatus = 'Saving product details...';
        _uploadProgress = 0.8;
      });

      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .set(productData);

      setState(() {
        _uploadProgress = 1.0;
        _uploadStatus = 'Product saved successfully!';
      });

      _showSuccess('Product "${_modelNameController.text}" saved successfully!');
      _clearForm();
    } catch (e) {
      _showError('Failed to save product: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<String>> uploadMultipleImagesWithAuth(
      List<XFile> images,
      String productId,
      void Function(double progress, String status) onProgress,
      ) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('User not authenticated. Please sign in first.');
      }

      List<String> imageUrls = [];
      final int totalImages = images.length;

      for (int i = 0; i < totalImages; i++) {
        // Update progress
        final double progress = 0.2 + (0.6 * i / totalImages);
        onProgress(progress, 'Uploading image ${i + 1}/$totalImages...');

        // Create unique file name with user ID and product ID
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${user.uid}/$productId/${productId}_${i}_$timestamp.jpg';

        // Create reference with user-specific path
        final ref = FirebaseStorage.instance.ref().child('product_images/$fileName');

        // Upload the file
        final uploadTask = ref.putFile(File(images[i].path));

        // Wait for upload to complete
        final snapshot = await uploadTask;

        // Get download URL
        final downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);

        print('Image ${i + 1}/$totalImages uploaded successfully');
      }

      return imageUrls;
    } on FirebaseException catch (e) {
      throw Exception('Firebase upload error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  void _clearForm() {
    setState(() {
      _modelNameController.clear();
      _serialNumberController.clear();
      _manufacturerController.clear();
      _specificationsController.clear();
      _priceController.clear();
      _quantityController.clear();
      _productImages.clear();
      _selectedCategory = 'Smartphones';
      _selectedCondition = 'New';
      _uploadProgress = 0.0;
      _uploadStatus = '';
    });
  }

  void _removeImage(int index) {
    setState(() {
      _productImages.removeAt(index);
    });
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Electronic Product Catalog'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearForm,
            tooltip: 'Clear Form',
          ),
          IconButton(onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context)=>ProductListScreen()));
          }, icon: Icon(Icons.list))
        ],
      ),
      body: _isLoading ? _buildProgressIndicator() : _buildProductForm(),
    );
  }

  Widget _buildProgressIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(value: _uploadProgress),
          const SizedBox(height: 20),
          Text(
            _uploadStatus,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            '${(_uploadProgress * 100).toStringAsFixed(0)}% complete',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProductForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Center(
            child: Text(
              'Add New Product',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Product Images Section
          _buildImageSection(),
          const SizedBox(height: 24),

          // Product Details Section
          _buildProductDetailsSection(),
          const SizedBox(height: 24),

          // Save Button
          _buildSaveButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
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
              '📷 Product Images',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add clear images showing the product from different angles',
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
            if (_productImages.isNotEmpty) ...[
              const Text(
                'Selected Images',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _productImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(_productImages[index].path),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
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

  Widget _buildProductDetailsSection() {
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
              '📋 Product Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Model Name
            TextFormField(
              controller: _modelNameController,
              decoration: InputDecoration(
                labelText: 'Model Name *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.model_training),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter model name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Serial Number
            TextFormField(
              controller: _serialNumberController,
              decoration: InputDecoration(
                labelText: 'Serial Number *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.confirmation_number),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter serial number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Manufacturer
            TextFormField(
              controller: _manufacturerController,
              decoration: InputDecoration(
                labelText: 'Manufacturer',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.business),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 12),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.category),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: _categories.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
            ),
            const SizedBox(height: 12),

            // Condition Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCondition,
              decoration: InputDecoration(
                labelText: 'Condition',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.construction),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: _conditions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCondition = newValue!;
                });
              },
            ),
            const SizedBox(height: 12),

            // Price and Quantity in a row for larger screens
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 500) {
                  return Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            labelText: 'Price (\$)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.attach_money),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter price';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          decoration: InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.inventory),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter quantity';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'Price (\$)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.attach_money),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter price';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.inventory),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter quantity';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 12),

            // Specifications
            TextFormField(
              controller: _specificationsController,
              decoration: InputDecoration(
                labelText: 'Specifications & Features',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                alignLabelWithHint: true,
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 4,
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
        onPressed: _saveProduct,
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
            Text('SAVE PRODUCT TO CATALOG'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _modelNameController.dispose();
    _serialNumberController.dispose();
    _manufacturerController.dispose();
    _specificationsController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}