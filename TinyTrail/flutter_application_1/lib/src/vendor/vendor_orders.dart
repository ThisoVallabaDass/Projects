import 'package:flutter/material.dart';

import '../shared.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen> {
  final List<Map<String, String>> orders = <Map<String, String>>[
    {
      'product': 'Mini Meals Box',
      'quantity': '2',
      'status': 'Pending',
      'imageUrl': 'https://picsum.photos/seed/vendor-order-1/400/300',
    },
    {
      'product': 'Masala Bajji Combo',
      'quantity': '1',
      'status': 'Ready',
      'imageUrl': 'https://picsum.photos/seed/vendor-order-2/400/300',
    },
    {
      'product': 'Homemade Murukku',
      'quantity': '3',
      'status': 'Delivered',
      'imageUrl': 'https://picsum.photos/seed/vendor-order-3/400/300',
    },
  ];

  Color statusColor(String status) {
    switch (status) {
      case 'Pending':
        return const Color(0xFFD97706);
      case 'Ready':
        return AppPalette.customer;
      default:
        return AppPalette.vendor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Orders')),
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
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        order['imageUrl']!,
                        width: 62,
                        height: 62,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 62,
                          height: 62,
                          color: const Color(0xFFEAF2FF),
                          child: const Icon(Icons.local_dining_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        order['product']!,
                        style: const TextStyle(
                          color: AppPalette.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Quantity: ${order['quantity']}',
                  style: const TextStyle(color: AppPalette.muted),
                ),
                const SizedBox(height: 10),
                StatusPill(
                  label: order['status']!,
                  background: color.withValues(alpha: 0.12),
                  foreground: color,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.tonal(
                      onPressed: () {
                        setState(() => order['status'] = 'Pending');
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Accept'),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () {
                        setState(() => order['status'] = 'Ready');
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined, size: 16),
                          SizedBox(width: 6),
                          Text('Ready'),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () {
                        setState(() => order['status'] = 'Delivered');
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.done_all_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Complete'),
                        ],
                      ),
                    ),
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
