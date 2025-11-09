import 'package:flutter/material.dart';

class OrderStatusScreen extends StatelessWidget {
  const OrderStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Status')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #12345',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text('Order Date:'), Text('Oct 15, 2023')],
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status:'),
                        Text(
                          'Delivered',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount:'),
                        Text(
                          '\$25.99',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Order Items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.food_bank_outlined),
                    title: Text('Organic Apple'),
                    subtitle: Text('2 x \$2.99'),
                    trailing: Text('\$5.98'),
                  ),
                  ListTile(
                    leading: Icon(Icons.food_bank_outlined),
                    title: Text('Banana'),
                    subtitle: Text('1 x \$1.49'),
                    trailing: Text('\$1.49'),
                  ),
                  ListTile(
                    leading: Icon(Icons.local_drink_outlined),
                    title: Text('Fresh Milk'),
                    subtitle: Text('1 x \$3.99'),
                    trailing: Text('\$3.99'),
                  ),
                  ListTile(
                    leading: Icon(Icons.bakery_dining_outlined),
                    title: Text('Whole Wheat Bread'),
                    subtitle: Text('1 x \$2.49'),
                    trailing: Text('\$2.49'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Delivery Address',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('John Doe'),
                    Text('123 Main Street'),
                    Text('New York, NY 10001'),
                    Text('United States'),
                    SizedBox(height: 10),
                    Text('Phone: +1 234-567-8900'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
