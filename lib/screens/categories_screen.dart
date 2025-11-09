import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_products_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _searchQuery = '';
  String? _selectedCategory;

  // Default categories if Firestore is empty
  final List<Map<String, dynamic>> _defaultCategories = [
    {
      'name': 'Fruits',
      'icon': Icons.apple_outlined,
      'color': const Color(0xFFFF6B6B),
      'description': 'Fresh and juicy fruits',
    },
    {
      'name': 'Vegetables',
      'icon': Icons.grass_outlined,
      'color': const Color(0xFF4CAF50),
      'description': 'Organic vegetables',
    },
    {
      'name': 'Dairy',
      'icon': Icons.local_drink_outlined,
      'color': const Color(0xFF2196F3),
      'description': 'Fresh dairy products',
    },
    {
      'name': 'Bakery',
      'icon': Icons.bakery_dining_outlined,
      'color': const Color(0xFF795548),
      'description': 'Fresh baked goods',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Categories',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Search categories...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categories').snapshots(),
        builder: (context, snapshot) {
          List<Map<String, dynamic>> categories = [];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // If Firestore has categories, use them; otherwise use defaults
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            categories = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'id': doc.id,
                'name': data['name'] ?? 'Category',
                'icon': _getIconFromString(data['icon'] ?? 'category'),
                'color': _getColorFromString(data['color'] ?? '#4CAF50'),
                'description': data['description'] ?? '',
                'imageUrl': data['imageUrl'] ?? '',
              };
            }).toList();
          } else {
            categories = _defaultCategories;
          }

          // Filter categories based on search
          if (_searchQuery.isNotEmpty) {
            categories = categories
                .where(
                  (cat) => cat['name'].toString().toLowerCase().contains(
                    _searchQuery,
                  ),
                )
                .toList();
          }

          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No categories found',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategory == category['name'];

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = category['name']);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CategoryProductsScreen(category: category['name']),
                      ),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF4CAF50)
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.05),
                          blurRadius: isSelected ? 10 : 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: (category['color'] as Color).withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            category['icon'] as IconData,
                            size: 40,
                            color: category['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          category['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (category['description'] != null &&
                            category['description'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              category['description'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 8),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('products')
                              .where(
                                'category',
                                isEqualTo: category['name']
                                    .toString()
                                    .toLowerCase(),
                              )
                              .snapshots(),
                          builder: (context, productSnapshot) {
                            final count =
                                productSnapshot.data?.docs.length ?? 0;
                            return Text(
                              '$count items',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'apple':
      case 'fruits':
        return Icons.apple_outlined;
      case 'grass':
      case 'vegetables':
        return Icons.grass_outlined;
      case 'drink':
      case 'dairy':
        return Icons.local_drink_outlined;
      case 'bakery':
        return Icons.bakery_dining_outlined;
      default:
        return Icons.category;
    }
  }

  Color _getColorFromString(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        final hex = colorString.substring(1);
        return Color(int.parse('FF$hex', radix: 16));
      }
    } catch (e) {
      // Return default color on error
    }
    return const Color(0xFF4CAF50);
  }
}
