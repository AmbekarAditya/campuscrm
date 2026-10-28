import 'package:flutter/material.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final List<({String name, int quantity})> _stockItems = [
    (name: 'Printed Course Workbooks (Level 1)', quantity: 24),
    (name: 'Student Welcome Bags', quantity: 3), // < 5 -> Red alert rule
    (name: 'Practice Toolkits', quantity: 4), // < 5 -> Red alert rule
    (name: 'ID Card Lanyards', quantity: 6),
  ];

  final Map<String, bool> _studentKitAssignments = {
    'Aarav Sharma — Starter Kit': true,
    'Priya Nair — Starter Kit': false,
    'Rohan Mehta — Starter Kit': true,
    'Sneha Kulkarni — Starter Kit': false,
  };

  void _updateQuantity(int index, int delta) {
    setState(() {
      final current = _stockItems[index];
      final nextQty = (current.quantity + delta).clamp(0, 999);
      _stockItems[index] = (name: current.name, quantity: nextQty);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Materials & Inventory'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stock Items',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Text(
                'Rule: Quantity < 5 highlights in Red',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(_stockItems.length, (index) {
            final item = _stockItems[index];
            // UI logic rule: if Quantity < 5, change text color to red
            final isLowStock = item.quantity < 5;
            final textColor =
                isLowStock ? const Color(0xFFDC2626) : const Color(0xFF0F172A);

            return Card(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                subtitle: isLowStock
                    ? const Text(
                        'Low Stock — Reorder Needed',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Decrease quantity',
                      onPressed: () => _updateQuantity(index, -1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Qty: ${item.quantity}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Increase quantity',
                      onPressed: () => _updateQuantity(index, 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 28),
          Text(
            'Assign Student Kits',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: _studentKitAssignments.entries.map((entry) {
                return CheckboxListTile(
                  title: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  value: entry.value,
                  onChanged: (checked) {
                    if (checked != null) {
                      setState(() {
                        _studentKitAssignments[entry.key] = checked;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
