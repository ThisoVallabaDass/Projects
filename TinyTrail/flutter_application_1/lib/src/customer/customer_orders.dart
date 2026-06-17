import 'package:flutter/material.dart';

import '../shared.dart';

class CustomerOrdersScreen extends StatelessWidget {
  const CustomerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const orders = <Map<String, String>>[
      {
        'product': 'Mini Meals Box',
        'price': 'Rs. 110',
        'status': 'Pending',
        'date': 'Today, 1:15 PM',
      },
      {
        'product': 'Homemade Murukku',
        'price': 'Rs. 50',
        'status': 'Confirmed',
        'date': 'Yesterday',
      },
      {
        'product': 'Masala Bajji Combo',
        'price': 'Rs. 60',
        'status': 'Delivered',
        'date': '12 Mar 2026',
      },
    ];

    Color statusColor(String status) {
      switch (status) {
        case 'Pending':
          return const Color(0xFFD97706);
        case 'Confirmed':
          return AppPalette.customer;
        default:
          return AppPalette.vendor;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = orders[index];
          final color = statusColor(order['status']!);
          return SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['product']!,
                  style: const TextStyle(
                    color: AppPalette.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 8),
                Text(order['price']!, style: const TextStyle(color: AppPalette.muted)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    StatusPill(
                      label: order['status']!,
                      background: color.withValues(alpha: 0.12),
                      foreground: color,
                    ),
                    const Spacer(),
                    Text(order['date']!, style: const TextStyle(color: AppPalette.muted)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
