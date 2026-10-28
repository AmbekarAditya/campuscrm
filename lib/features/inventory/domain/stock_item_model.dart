import 'package:cloud_firestore/cloud_firestore.dart';

class StockItem {
  final String id;
  final String name;
  final int quantity;
  final String category;
  final int minThreshold;

  const StockItem({
    required this.id,
    required this.name,
    required this.quantity,
    this.category = 'General',
    this.minThreshold = 5,
  });

  /// UI logic rule: if Quantity < minThreshold (default 5), highlight in red.
  bool get isLowStock => quantity < minThreshold;

  StockItem copyWith({
    String? id,
    String? name,
    int? quantity,
    String? category,
    int? minThreshold,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      minThreshold: minThreshold ?? this.minThreshold,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'category': category,
      'minThreshold': minThreshold,
    };
  }

  factory StockItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return StockItem(
      id: doc.id,
      name: data['name'] as String? ?? 'Unnamed Item',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      category: data['category'] as String? ?? 'General',
      minThreshold: (data['minThreshold'] as num?)?.toInt() ?? 5,
    );
  }
}
