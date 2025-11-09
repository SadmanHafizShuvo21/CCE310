import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _color1Controller = TextEditingController(text: '#4CAF50');
  final _color2Controller = TextEditingController(text: '#8BC34A');
  final _routeController = TextEditingController(text: '/categories');
  final _orderController = TextEditingController(text: '0');

  String? _imageBase64;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _color1Controller.dispose();
    _color2Controller.dispose();
    _routeController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  // Compress image to fit Firestore 1MB limit (1,048,576 bytes)
  Future<Uint8List?> _compressImageBytes(
    Uint8List imageBytes, {
    double maxWidth = 600,
    double maxHeight = 600,
  }) async {
    try {
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: maxWidth.toInt(),
        targetHeight: maxHeight.toInt(),
      );
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      frame.image.dispose();
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60, // Start with lower quality
        maxWidth: 800, // Limit width
        maxHeight: 800, // Limit height
      );

      if (picked != null) {
        Uint8List bytes = await picked.readAsBytes();
        String base64String = base64Encode(bytes);

        // Firestore limit is 1MB (1,048,576 bytes) per field
        // Base64 increases size by ~33%, so we check for ~750KB base64 string
        const int maxBase64Size = 750000; // ~750KB to be safe

        // If still too large, compress further using dart:ui
        if (base64String.length > maxBase64Size) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image is large, compressing...'),
                duration: Duration(seconds: 1),
              ),
            );
          }

          // Try compressing with progressively smaller dimensions
          double width = 600;
          double height = 600;

          while (base64String.length > maxBase64Size && width >= 300) {
            final compressedBytes = await _compressImageBytes(
              bytes,
              maxWidth: width,
              maxHeight: height,
            );

            if (compressedBytes != null) {
              base64String = base64Encode(compressedBytes);
              bytes = compressedBytes;

              if (base64String.length > maxBase64Size) {
                width -= 100;
                height -= 100;
              } else {
                break;
              }
            } else {
              break;
            }
          }

          // Final check - if still too large, show error
          if (base64String.length > maxBase64Size) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Image is too large (max 1MB). Please select a smaller image.',
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
            }
            return;
          }
        }

        setState(() => _imageBase64 = base64String);

        if (mounted) {
          final sizeInKB = (base64String.length / 1024).toStringAsFixed(1);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image selected successfully (${sizeInKB} KB)'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image pick failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addBanner() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBase64 == null || _imageBase64!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an image')));
      return;
    }

    // Final size check before saving to Firestore
    // Firestore limit is 1MB (1,048,576 bytes) per field
    const int maxBase64Size = 1000000; // 1MB to be safe (leaving some margin)

    if (_imageBase64!.length > maxBase64Size) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Image is too large (max 1MB). Please select a smaller image.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('banners').add({
        'title': _titleController.text.trim(),
        'subtitle': _subtitleController.text.trim(),
        'color1': _color1Controller.text.trim(),
        'color2': _color2Controller.text.trim(),
        'imageBase64': _imageBase64!,
        'route': _routeController.text.trim(),
        'order': int.tryParse(_orderController.text.trim()) ?? 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner added successfully!')),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _subtitleController.clear();
    _color1Controller.text = '#4CAF50';
    _color2Controller.text = '#8BC34A';
    _routeController.text = '/categories';
    _orderController.text = '0';
    setState(() => _imageBase64 = null);
  }

  Future<void> _deleteBanner(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Banner'),
        content: const Text('Are you sure you want to delete this banner?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('banners')
            .doc(docId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Banner deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Banners'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Banner Form
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add New Banner',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Please enter title' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _subtitleController,
                        decoration: const InputDecoration(
                          labelText: 'Subtitle',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Please enter subtitle' : null,
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _color1Controller,
                              decoration: const InputDecoration(
                                labelText: 'Color 1 (Hex)',
                                border: OutlineInputBorder(),
                                hintText: '#4CAF50',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _color2Controller,
                              decoration: const InputDecoration(
                                labelText: 'Color 2 (Hex)',
                                border: OutlineInputBorder(),
                                hintText: '#8BC34A',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _routeController,
                        decoration: const InputDecoration(
                          labelText: 'Route',
                          border: OutlineInputBorder(),
                          hintText: '/categories',
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _orderController,
                        decoration: const InputDecoration(
                          labelText: 'Order',
                          border: OutlineInputBorder(),
                          hintText: '0',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 15),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: _imageBase64 == null
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo, size: 50),
                                      SizedBox(height: 10),
                                      Text('Tap to select image'),
                                    ],
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    base64Decode(_imageBase64!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _addBanner,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text('Add Banner'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Existing Banners List
            const Text(
              'Existing Banners',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('banners')
                  .orderBy('order', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final banners = snapshot.data?.docs ?? [];
                if (banners.isEmpty) {
                  return const Center(child: Text('No banners added yet'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: banners.length,
                  itemBuilder: (context, index) {
                    final doc = banners[index];
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final imageBase64 = data['imageBase64'] as String? ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: imageBase64.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildBannerImage(imageBase64, 60, 60),
                              )
                            : const Icon(Icons.image, size: 60),
                        title: Text(data['title'] ?? 'Banner'),
                        subtitle: Text(data['subtitle'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteBanner(doc.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerImage(String base64String, double width, double height) {
    try {
      // Clean base64 string if it has data:image prefix
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',')[1];
      }
      final imageBytes = base64Decode(cleanBase64);
      return Image.memory(
        imageBytes,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade200,
            child: const Icon(Icons.image_not_supported, size: 30),
          );
        },
      );
    } catch (e) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image_not_supported, size: 30),
      );
    }
  }
}
