import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/category_card.dart';
import '../widgets/product_card.dart';
import 'category_products_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _bannerController = PageController();
  int _currentBanner = 0;
  bool _navigatedToAdmin = false;
  String? _cachedRole;
  List<Map<String, dynamic>> _banners = [];
  bool _isLoadingBanners = true;
  List<Map<String, dynamic>> _products = [];
  bool _isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadBannersFromFirestore().then((_) {
      if (_banners.isNotEmpty) {
        _startBannerTimer();
      }
    });
    _loadProductsOnce();
  }

  // Load products once instead of using StreamBuilder
  Future<void> _loadProductsOnce() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .orderBy('createdAt', descending: true)
          .limit(9) // Limit to 9 products for better performance
          .get();

      if (mounted) {
        setState(() {
          _products = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'name': data['name'] ?? 'Unnamed',
              'price': (data['price'] ?? 0).toDouble(),
              'imageUrl': data['imageUrl'] ?? '',
              'imageBase64': data['imageBase64'] as String?,
              'category': data['category'] ?? 'General',
            };
          }).toList();
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
          _products = [];
        });
      }
    }
  }

  // Firestore থেকে banners fetch করা
  Future<void> _loadBannersFromFirestore() async {
    try {
      QuerySnapshot snapshot;
      try {
        // 'order' field দিয়ে sort করার চেষ্টা করা
        snapshot = await FirebaseFirestore.instance
            .collection('banners')
            .orderBy('order', descending: false)
            .get();
      } catch (e) {
        // 'order' field না থাকলে সব banners fetch করা
        snapshot = await FirebaseFirestore.instance.collection('banners').get();
      }

      if (mounted) {
        setState(() {
          _banners = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            // Color string থেকে Color object এ convert করা
            Color color1 = _parseColor(data['color1'] ?? '#4CAF50');
            Color color2 = _parseColor(data['color2'] ?? '#8BC34A');

            return {
              'title': data['title'] ?? 'Banner',
              'subtitle': data['subtitle'] ?? '',
              'color1': color1,
              'color2': color2,
              'imageBase64': data['imageBase64'] ?? '',
              'route': data['route'] ?? '/categories',
            };
          }).toList();

          // যদি কোনো banner না থাকে, default banner যোগ করা
          if (_banners.isEmpty) {
            _banners = [
              {
                'title': 'Fresh Vegetables',
                'subtitle': 'Get 20% OFF on your first order',
                'color1': const Color(0xFF4CAF50),
                'color2': const Color(0xFF8BC34A),
                'imageBase64': '',
                'route': '/categories',
              },
            ];
          }

          _isLoadingBanners = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBanners = false;
          // Error হলে default banner
          _banners = [
            {
              'title': 'Fresh Vegetables',
              'subtitle': 'Get 20% OFF on your first order',
              'color1': const Color(0xFF4CAF50),
              'color2': const Color(0xFF8BC34A),
              'imageBase64': '',
              'route': '/categories',
            },
          ];
        });
      }
    }
  }

  // Color string (#RRGGBB) থেকে Color object এ convert
  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        final hex = colorString.substring(1);
        return Color(int.parse('FF$hex', radix: 16));
      } else if (colorString.startsWith('0x')) {
        return Color(int.parse(colorString));
      }
    } catch (e) {
      // Error হলে default color return
    }
    return const Color(0xFF4CAF50);
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final role = doc.data()?['role'];
    if (mounted) {
      setState(() => _cachedRole = role);
    }
  }

  void _startBannerTimer() {
    if (_banners.isEmpty) return;
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _banners.isNotEmpty) {
        setState(() => _currentBanner = (_currentBanner + 1) % _banners.length);
        _bannerController.animateToPage(
          _currentBanner,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        _startBannerTimer();
      }
    });
  }

  void _handleNav(int index) {
    setState(() => _currentIndex = index);
    switch (index) {
      case 1:
        Navigator.pushNamed(context, '/categories');
        break;
      case 2:
        Navigator.pushNamed(context, '/cart');
        break;
      case 3:
        final user = FirebaseAuth.instance.currentUser;
        Navigator.pushNamed(context, user == null ? '/login' : '/profile');
        break;
    }
  }

  Future<void> _refreshHome() async {
    await Future.delayed(const Duration(seconds: 1));
    await _loadUserRole();
    await _loadBannersFromFirestore();
    await _loadProductsOnce();
    if (_banners.isNotEmpty) {
      _startBannerTimer();
    }
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 👇 Redirect admin users
    if (_cachedRole == 'Admin' && !_navigatedToAdmin) {
      _navigatedToAdmin = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'FreshGrocer',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.grey.shade700),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
          IconButton(
            icon: Icon(
              Icons.shopping_cart_outlined,
              color: Colors.grey.shade700,
            ),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshHome,
        child: SafeArea(
          child: _isLoadingBanners
              ? const Center(child: CircularProgressIndicator())
              : HomeContent(
                  banners: _banners,
                  pageController: _bannerController,
                  currentBanner: _currentBanner,
                  products: _products,
                  isLoadingProducts: _isLoadingProducts,
                ),
        ),
      ),
      floatingActionButton: _cachedRole == 'Admin'
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF4CAF50),
              onPressed: () => Navigator.pushNamed(context, '/add-product'),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _handleNav,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF4CAF50),
      unselectedItemColor: Colors.grey.shade600,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.category),
          label: 'Categories',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}

class HomeContent extends StatelessWidget {
  final List<Map<String, dynamic>> banners;
  final PageController pageController;
  final int currentBanner;
  final List<Map<String, dynamic>> products;
  final bool isLoadingProducts;

  const HomeContent({
    super.key,
    required this.banners,
    required this.pageController,
    required this.currentBanner,
    required this.products,
    required this.isLoadingProducts,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(),
          const SizedBox(height: 20),
          _buildBannerCarousel(context),
          const SizedBox(height: 10),
          _buildBannerIndicators(),
          const SizedBox(height: 25),
          _buildCategoriesSection(context),
          const SizedBox(height: 25),
          _buildProductsSection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final name = user?.displayName ?? user?.email?.split('@')[0] ?? 'Guest';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $name 👋',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'What would you like to buy today?',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBannerCarousel(BuildContext context) {
    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: pageController,
        itemCount: banners.length,
        itemBuilder: (context, index) {
          final banner = banners[index];
          final imageBase64 = banner['imageBase64'] as String?;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [banner['color1'], banner['color2']],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Base64 image display
                if (imageBase64 != null && imageBase64.isNotEmpty)
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: _buildBase64Image(imageBase64, 100, 100),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banner['title'] ?? 'Banner',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        banner['subtitle'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          banner['route'] ?? '/categories',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4CAF50),
                        ),
                        child: const Text('Shop Now'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Base64 image display করার জন্য helper widget
  Widget _buildBase64Image(String base64String, double width, double height) {
    try {
      // Check if base64 string is empty or too large
      if (base64String.isEmpty) {
        return _buildImagePlaceholder(width, height);
      }

      // Base64 string clean করা (data:image prefix থাকলে remove করা)
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',')[1];
      }

      // Check if base64 string is too large (Firestore limit is 1MB)
      if (cleanBase64.length > 1048576) {
        return _buildImagePlaceholder(width, height);
      }

      final imageBytes = base64Decode(cleanBase64);
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            imageBytes,
            width: width,
            height: height,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              return _buildImagePlaceholder(width, height);
            },
          ),
        ),
      );
    } catch (e) {
      // Error হলে placeholder show করা
      return _buildImagePlaceholder(width, height);
    }
  }

  Widget _buildImagePlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.image_not_supported,
        color: Colors.white70,
        size: 40,
      ),
    );
  }

  Widget _buildBannerIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        banners.length,
        (index) => Container(
          margin: const EdgeInsets.all(3),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == currentBanner
                ? const Color(0xFF4CAF50)
                : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categories',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              CategoryCard(
                icon: Icons.apple_outlined,
                title: 'Fruits',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const CategoryProductsScreen(category: 'Fruits'),
                  ),
                ),
              ),
              CategoryCard(
                icon: Icons.grass_outlined,
                title: 'Vegetables',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const CategoryProductsScreen(category: 'Vegetables'),
                  ),
                ),
              ),
              CategoryCard(
                icon: Icons.local_drink_outlined,
                title: 'Dairy',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const CategoryProductsScreen(category: 'Dairy'),
                  ),
                ),
              ),
              CategoryCard(
                icon: Icons.bakery_dining_outlined,
                title: 'Bakery',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const CategoryProductsScreen(category: 'Bakery'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 🔥 Display products from cached list (loaded once)
  Widget _buildProductsSection() {
    if (isLoadingProducts) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest Products',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    if (products.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest Products',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('No products available'),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Latest Products',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemHeight =
                constraints.maxWidth / 2 * 0.75 +
                20; // Calculate based on aspect ratio
            final gridHeight = (products.length / 2).ceil() * itemHeight;
            return SizedBox(
              height: gridHeight,
              child: GridView.builder(
                key: const PageStorageKey('latest_products_grid'),
                shrinkWrap: false,
                physics: const NeverScrollableScrollPhysics(),
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                cacheExtent: 0,
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return RepaintBoundary(
                    key: ValueKey('product_${product['name']}_$index'),
                    child: ProductCard(
                      key: ValueKey('product_card_${product['name']}_$index'),
                      name: product['name'] ?? 'Unnamed',
                      price: product['price'] ?? 0.0,
                      image: product['imageUrl'] ?? '',
                      imageBase64: product['imageBase64'] as String?,
                      category: product['category'] ?? 'General',
                      onTap: () {},
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
