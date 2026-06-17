import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class EditListingScreen extends StatefulWidget {
  final String sellerId;
  final String productId;
  final Product initialProduct;

  const EditListingScreen({
    super.key,
    required this.sellerId,
    required this.productId,
    required this.initialProduct,
  });

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _gameController = TextEditingController();
  final _priceController = TextEditingController();
  final _tagsController = TextEditingController();
  final ProductService _productService = ProductService();
  final StorageService _storageService = StorageService();
  List<File> _selectedImages = [];
  List<String> _imageUrls = [];
  bool _isLoading = false;
  ProductStatus _selectedStatus = ProductStatus.available;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing product data
    _titleController.text = widget.initialProduct.title;
    _descriptionController.text = widget.initialProduct.description;
    _gameController.text = widget.initialProduct.game;
    _priceController.text = widget.initialProduct.price.toString();
    _tagsController.text = widget.initialProduct.tags.join(', ');
    _selectedStatus = widget.initialProduct.stockStatus;
    _imageUrls = List.from(widget.initialProduct.imageUrls);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _gameController.dispose();
    _priceController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await ImagePicker().pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((x) => File(x.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  void _removeImage(int index, bool isNew) {
    setState(() {
      if (isNew) {
        _selectedImages.removeAt(index);
      } else {
        // Remove existing image
        _imageUrls.removeAt(index);
      }
    });
  }

  Future<void> _uploadNewImages() async {
    if (_selectedImages.isEmpty) return;
    
    try {
      final filePaths = _selectedImages.map((file) => file.path).toList();
      final urls = await _storageService.uploadFiles(filePaths, 'product_images');
      setState(() {
        _imageUrls.insertAll(0, urls); // Add new images at the beginning
        _selectedImages.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading images: $e')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Upload new images if any
      await _uploadNewImages();
      
      // Update product
      final updatedProduct = Product(
        id: widget.productId,
        sellerId: widget.sellerId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        game: _gameController.text.trim(),
        price: double.parse(_priceController.text),
        imageUrls: _imageUrls,
        tags: _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(),
        stockStatus: _selectedStatus,
        createdAt: widget.initialProduct.createdAt,
        updatedAt: DateTime.now(),
      );
      
      await _productService.updateProduct(widget.productId, updatedProduct);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully!')),
        );
        
        // Navigate back
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating product: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Listing'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Preview Section
                    (_imageUrls.isNotEmpty || _selectedImages.isNotEmpty)
                        ? SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _imageUrls.length + _selectedImages.length,
                              itemBuilder: (context, index) {
                                final isNew = index >= _imageUrls.length;
                                final imageIndex = isNew ? index - _imageUrls.length : index;
                                
                                return Stack(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      width: 100,
                                      child: isNew
                                          ? Image.file(
                                              _selectedImages[imageIndex],
                                              fit: BoxFit.cover,
                                            )
                                          : Image.network(
                                              _imageUrls[imageIndex],
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () => _removeImage(imageIndex, isNew),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          )
                        : const SizedBox(height: 100, child: Center(child: Text('No images'))),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.image),
                      label: const Text('Add More Images'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Form Fields
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Product Title',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _gameController,
                      decoration: const InputDecoration(
                        labelText: 'Game Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.gamepad),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the game name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price (VND)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags (comma separated)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Status Selector
                    DropdownButtonFormField<ProductStatus>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Stock Status',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory),
                      ),
                      items: ProductStatus.values.map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.toString().split('.').last.toUpperCase()),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Update Listing',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text('Are you sure you want to delete this listing? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _deleteProduct(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct() async {
    Navigator.of(context).pop(); // Close dialog
    
    setState(() => _isLoading = true);
    
    try {
      // Delete images first
      await _storageService.deleteFiles(_imageUrls);
      
      // Delete product
      await _productService.deleteProduct(widget.productId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully!')),
        );
        
        // Navigate back
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting product: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}