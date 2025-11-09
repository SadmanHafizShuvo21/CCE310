import 'package:flutter/material.dart';

class OrderHistoryItem extends StatelessWidget {
  final String orderId;
  final String date;
  final String status;
  final double total;
  final int items;
  final VoidCallback onTap;

  const OrderHistoryItem({
    super.key,
    required this.orderId,
    required this.date,
    required this.status,
    required this.total,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.green;
    if (status == 'Cancelled') {
      statusColor = Colors.red;
    } else if (status == 'Processing') {
      statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        onTap: onTap,
        title: Text('Order $orderId'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date),
            const SizedBox(height: 5),
            Text('$items items • \$$total'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              status,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
