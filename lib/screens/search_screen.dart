import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> recentSearches = [];
  List<Map<String, dynamic>> searchResults = [];
  bool isSearching = false;

  void _onSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => isSearching = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    setState(() {
      searchResults = snapshot.docs.map((doc) => doc.data()).toList();
      isSearching = false;

      // Update recent searches
      recentSearches.remove(query);
      recentSearches.insert(0, query);
      if (recentSearches.length > 5) recentSearches = recentSearches.sublist(0, 5);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      searchResults.clear();
      isSearching = false;
    });
  }

  Widget _buildSearchResults() {
    if (isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (searchResults.isEmpty) {
      return const Center(child: Text('No products found.'));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: searchResults.length,
      itemBuilder: (ctx, i) {
        final product = searchResults[i];
        return ListTile(
          leading: product['imageUrl'] != null
              ? Image.network(product['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
              : const Icon(Icons.image),
          title: Text(product['name']),
          subtitle: Text('${product['price']} Tk • ${product['category']}'),
        );
      },
    );
  }

  Widget _buildLatestProducts() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final docs = snapshot.data!.docs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Latest Products',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                leading: data['imageUrl'] != null
                    ? Image.network(data['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.image),
                title: Text(data['name']),
                subtitle: Text('${data['price']} Tk • ${data['category']}'),
              );
            }),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for products...',
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearSearch,
            ),
          ),
          onFieldSubmitted: _onSearch,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recentSearches.isNotEmpty) ...[
              const Text(
                'Recent Searches',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: recentSearches
                    .map((term) => ActionChip(
                          label: Text(term),
                          onPressed: () => _onSearch(term),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
            ],
            const Text(
              'Popular Categories',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: const [
                Chip(label: Text('Fruit')),
                Chip(label: Text('Vegetables')),
                Chip(label: Text('Dairy')),
                Chip(label: Text('Bakery')),
              ],
            ),
            const SizedBox(height: 20),
            if (searchResults.isNotEmpty || isSearching)
              _buildSearchResults()
            else
              _buildLatestProducts(),
          ],
        ),
      ),
    );
  }
}
