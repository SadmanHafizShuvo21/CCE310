// Full Code: admin_analytics.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  int totalProducts = 0;
  int totalUsers = 0;
  int totalOrders = 0;
  double totalRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    final productsSnapshot =
        await FirebaseFirestore.instance.collection('products').get();
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    final ordersSnapshot =
        await FirebaseFirestore.instance.collection('orders').get();

    double revenue = 0.0;
    for (var doc in ordersSnapshot.docs) {
      final data = doc.data();
      if (data['status'] == 'approved' && data['total'] != null) {
        revenue += (data['total'] as num).toDouble();
      }
    }

    setState(() {
      totalProducts = productsSnapshot.size;
      totalUsers = usersSnapshot.size;
      totalOrders = ordersSnapshot.size;
      totalRevenue = revenue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAnalytics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Stats Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard('Products', totalProducts.toString(),
                      Icons.inventory_2, Colors.blue),
                  _buildStatCard('Users', totalUsers.toString(),
                      Icons.people, Colors.orange),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard('Orders', totalOrders.toString(),
                      Icons.shopping_cart, Colors.green),
                  _buildStatCard('Revenue', '\$${totalRevenue.toStringAsFixed(2)}',
                      Icons.attach_money, Colors.purple),
                ],
              ),
              const SizedBox(height: 30),

              // Chart Example
              const Text(
                'Orders Trend (Demo)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: true),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          FlSpot(0, 1),
                          FlSpot(1, 3),
                          FlSpot(2, 2),
                          FlSpot(3, 5),
                          FlSpot(4, 4),
                        ],
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}

