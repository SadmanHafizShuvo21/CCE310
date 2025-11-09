import 'package:flutter/material.dart';
import '../widgets/order_history_item.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order History')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OrderHistoryItem(
            orderId: '#12345',
            date: 'Oct 15, 2023',
            status: 'Delivered',
            total: 25.99,
            items: 5,
            onTap: () {
              Navigator.pushNamed(context, '/order-status');
            },
          ),
          OrderHistoryItem(
            orderId: '#12346',
            date: 'Oct 10, 2023',
            status: 'Delivered',
            total: 18.50,
            items: 3,
            onTap: () {
              Navigator.pushNamed(context, '/order-status');
            },
          ),
          OrderHistoryItem(
            orderId: '#12347',
            date: 'Oct 5, 2023',
            status: 'Cancelled',
            total: 32.75,
            items: 7,
            onTap: () {
              Navigator.pushNamed(context, '/order-status');
            },
          ),
        ],
      ),
    );
  }
}
