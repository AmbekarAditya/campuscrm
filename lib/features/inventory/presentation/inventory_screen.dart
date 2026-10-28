import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../academics/data/batch_repository.dart';
import '../../inquiries/data/inquiry_repository.dart';
import '../../inquiries/domain/inquiry_model.dart';
import '../data/inventory_repository.dart';
import '../domain/stock_item_model.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _stockSearchQuery = '';

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Dialog to Add or Edit a Stock Item
  Future<void> _showStockItemDialog(
    BuildContext context, {
    StockItem? existingItem,
  }) async {
    final isEditing = existingItem != null;
    final nameCtrl = TextEditingController(text: existingItem?.name ?? '');
    final qtyCtrl = TextEditingController(
      text: existingItem != null ? existingItem.quantity.toString() : '10',
    );
    final categoryCtrl =
        TextEditingController(text: existingItem?.category ?? 'Course Materials');
    int quantity = existingItem?.quantity ?? 10;
    int minThreshold = existingItem?.minThreshold ?? 5;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_note_rounded : Icons.add_box_rounded,
                    color: const Color(0xFF4F46E5),
                  ),
                  const SizedBox(width: 8),
                  Text(isEditing ? 'Edit Stock Item' : 'Add Stock Item'),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Name
                      TextField(
                        controller: nameCtrl,
                        autofocus: !isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Item Name *',
                          hintText: 'E.g. Printed Workbooks, Practice Toolkits',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Category
                      TextField(
                        controller: categoryCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          hintText: 'E.g. Course Materials, Kits, Stationery',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Quantity with quick step buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: qtyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Stock Quantity *',
                                prefixIcon: Icon(Icons.numbers_rounded),
                              ),
                              onChanged: (val) {
                                final parsed = int.tryParse(val);
                                if (parsed != null) {
                                  setDialogState(() => quantity = parsed);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.outlined(
                            tooltip: 'Decrease',
                            onPressed: () {
                              if (quantity > 0) {
                                setDialogState(() {
                                  quantity--;
                                  qtyCtrl.text = quantity.toString();
                                });
                              }
                            },
                            icon: const Icon(Icons.remove),
                          ),
                          const SizedBox(width: 4),
                          IconButton.outlined(
                            tooltip: 'Increase',
                            onPressed: () {
                              setDialogState(() {
                                quantity++;
                                qtyCtrl.text = quantity.toString();
                              });
                            },
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Low Stock Rule notice
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: quantity < minThreshold
                              ? const Color(0xFFFEF2F2)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: quantity < minThreshold
                                ? const Color(0xFFFCA5A5)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              quantity < minThreshold
                                  ? Icons.warning_amber_rounded
                                  : Icons.info_outline_rounded,
                              size: 16,
                              color: quantity < minThreshold
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                quantity < minThreshold
                                    ? 'Warning: Quantity ($quantity) is below $minThreshold and will trigger a Red Alert.'
                                    : 'Items with quantity < $minThreshold will automatically highlight in Red.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: quantity < minThreshold
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter an Item Name.'),
                        ),
                      );
                      return;
                    }

                    final parsedQty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                    final category = categoryCtrl.text.trim().isEmpty
                        ? 'General'
                        : categoryCtrl.text.trim();

                    final repo = ref.read(inventoryRepositoryProvider);
                    if (isEditing) {
                      final updated = existingItem.copyWith(
                        name: name,
                        quantity: parsedQty,
                        category: category,
                        minThreshold: minThreshold,
                      );
                      await repo.updateStockItem(updated);
                      if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Updated stock item "$name".'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } else {
                      final newItem = StockItem(
                        id: '',
                        name: name,
                        quantity: parsedQty,
                        category: category,
                        minThreshold: minThreshold,
                      );
                      await repo.addStockItem(newItem);
                      if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added "$name" to inventory.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(isEditing ? 'Update Item' : 'Add Item'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Confirm Delete Stock Item Dialog
  Future<void> _confirmDeleteStockItem(
    BuildContext context,
    StockItem item,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFDC2626), size: 26),
            SizedBox(width: 8),
            Text('Delete Stock Item?'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${item.name}"? It will also be removed from all student kit assignments.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ref
                  .read(inventoryRepositoryProvider)
                  .deleteStockItem(item.id, item.name);
              if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted "${item.name}" from inventory.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Dialog to view/toggle all kit checklist items for a specific student
  Future<void> _showStudentKitChecklistDialog(
    BuildContext context,
    Inquiry student,
    List<StockItem> allStockItems,
    Set<String> assignedIds,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return Consumer(
          builder: (ctx, consumerRef, _) {
            final currentMap =
                consumerRef.watch(studentKitAssignmentsProvider);
            final currentAssigned =
                currentMap[student.id] ?? <String>{};

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.checklist_rounded,
                      color: Color(0xFF4F46E5)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kit Materials: ${student.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: allStockItems.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No stock items in inventory. Add stock items first.',
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${currentAssigned.length} of ${allStockItems.length} items assigned',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final repo = consumerRef
                                      .read(inventoryRepositoryProvider);
                                  if (currentAssigned.length ==
                                      allStockItems.length) {
                                    consumerRef
                                        .read(
                                            studentKitAssignmentsProvider.notifier)
                                        .clearAll(student.id);
                                  } else {
                                    await repo.assignAllItemsToStudent(
                                      studentId: student.id,
                                      studentName: student.name,
                                      allStockItems: allStockItems,
                                    );
                                  }
                                },
                                child: Text(
                                  currentAssigned.length ==
                                          allStockItems.length
                                      ? 'Clear All'
                                      : 'Assign All',
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 1),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 320),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: allStockItems.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (itemCtx, index) {
                                final stock = allStockItems[index];
                                final isChecked =
                                    currentAssigned.contains(stock.id);

                                return CheckboxListTile(
                                  value: isChecked,
                                  title: Text(
                                    stock.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: stock.isLowStock
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${stock.category} • In stock: ${stock.quantity}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: stock.isLowStock
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                  onChanged: (checked) async {
                                    await consumerRef
                                        .read(inventoryRepositoryProvider)
                                        .toggleStudentItem(
                                          studentId: student.id,
                                          studentName: student.name,
                                          item: stock,
                                          willBeAssigned: checked == true,
                                        );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stockItems = ref.watch(localStockProvider);
    final assignmentsMap = ref.watch(studentKitAssignmentsProvider);
    final joinedStudents = ref.watch(joinedStudentsProvider);
    final allBatches = ref.watch(localBatchesProvider);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 640;

    // Filter stock items by search query
    final filteredStockItems = stockItems.where((item) {
      final q = _stockSearchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return item.name.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q);
    }).toList();

    final lowStockCount = stockItems.where((i) => i.isLowStock).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Materials & Inventory'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showStockItemDialog(context),
              icon: const Icon(Icons.add_box_rounded),
              label: const Text('Add Item'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 20,
          vertical: 16,
        ),
        children: [
          // -------------------------------------------------------------
          // SECTION 1: STOCK & INVENTORY ITEMS (ADD / EDIT / DELETE)
          // -------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stock Items',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: isMobile ? 18 : 22,
                    ),
              ),
              if (lowStockCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$lowStockCount Low Stock (< 5)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${stockItems.length} Total Items',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Rule: If Quantity < 5, item highlights in Red with a Low Stock alert.',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),

          // Search Bar for Stock
          TextField(
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search stock item or category...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _stockSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () =>
                          setState(() => _stockSearchQuery = ''),
                    )
                  : null,
            ),
            onChanged: (val) => setState(() => _stockSearchQuery = val),
          ),
          const SizedBox(height: 12),

          // Stock Items List
          if (filteredStockItems.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 40, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 8),
                      Text(
                        _stockSearchQuery.isNotEmpty
                            ? 'No stock items match "$_stockSearchQuery".'
                            : 'No inventory items yet. Click "Add Item" to add stock.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...filteredStockItems.map((item) {
              final isLowStock = item.isLowStock;
              final textColor = isLowStock
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF0F172A);

              return Card(
                color: isLowStock ? const Color(0xFFFEF2F2) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isLowStock
                        ? const Color(0xFFFCA5A5)
                        : const Color(0xFFE2E8F0),
                    width: isLowStock ? 1.4 : 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Name + Category + Edit/Delete Icons
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isLowStock
                                ? Icons.warning_amber_rounded
                                : Icons.inventory_2_outlined,
                            size: 20,
                            color: isLowStock
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF4F46E5),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: TextStyle(
                                    fontSize: isMobile ? 14.5 : 16,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isLowStock
                                            ? const Color(0xFFFEE2E2)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.category,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isLowStock
                                              ? const Color(0xFFB91C1C)
                                              : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    if (isLowStock)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDC2626),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Low Stock: ${item.quantity} left',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Edit Button
                          IconButton(
                            iconSize: 18,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            tooltip: 'Edit Item',
                            onPressed: () => _showStockItemDialog(
                              context,
                              existingItem: item,
                            ),
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Delete Button
                          IconButton(
                            iconSize: 18,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            tooltip: 'Delete Item',
                            onPressed: () =>
                                _confirmDeleteStockItem(context, item),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Quantity Counter Adjuster
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Available Stock:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton.outlined(
                                iconSize: 16,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                                tooltip: 'Decrease 1',
                                onPressed: () {
                                  if (item.quantity > 0) {
                                    ref
                                        .read(inventoryRepositoryProvider)
                                        .adjustQuantity(item.id, item.name, -1);
                                  }
                                },
                                icon: const Icon(Icons.remove),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(
                                  '${item.quantity}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              IconButton.outlined(
                                iconSize: 16,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                                tooltip: 'Increase 1',
                                onPressed: () {
                                  ref
                                      .read(inventoryRepositoryProvider)
                                      .adjustQuantity(item.id, item.name, 1);
                                },
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 28),

          // -------------------------------------------------------------
          // SECTION 2: ASSIGNED VS NOT ASSIGNED TO JOINED STUDENTS
          // -------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Student Kit & Material Tracking',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: isMobile ? 18 : 22,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Text(
                  '${joinedStudents.length} Joined Student(s)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Displays items assigned (green ✓) and items not yet assigned (amber +) from your stock inventory above.',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),

          if (joinedStudents.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.group_outlined,
                          size: 40, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 8),
                      const Text(
                        'No students currently have status "Joined".',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Change an inquiry status to "Joined" in Inquiries tab to start kit tracking.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...joinedStudents.map((student) {
              final assignedSet =
                  assignmentsMap[student.id] ?? <String>{};

              // Look up assigned and not assigned items from the live stock items
              final assignedItems = stockItems
                  .where((item) => assignedSet.contains(item.id))
                  .toList();
              final notAssignedItems = stockItems
                  .where((item) => !assignedSet.contains(item.id))
                  .toList();

              final totalItems = stockItems.length;
              final progress = totalItems > 0
                  ? (assignedItems.length / totalItems).clamp(0.0, 1.0)
                  : 0.0;
              final isComplete =
                  totalItems > 0 && assignedItems.length == totalItems;

              // Enrolled batch info
              final enrolledBatches = allBatches
                  .where((b) => b.studentIds.contains(student.id))
                  .toList();
              final batchTitle = enrolledBatches.isNotEmpty
                  ? enrolledBatches.first.name
                  : 'No Batch Assigned';

              return Card(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Student Avatar, Name, Batch info & Completion Badge
                      Row(
                        children: [
                          CircleAvatar(
                            radius: isMobile ? 18 : 20,
                            backgroundColor: isComplete
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFEEF2FF),
                            foregroundColor: isComplete
                                ? const Color(0xFF15803D)
                                : const Color(0xFF4F46E5),
                            child: Text(
                              _getInitials(student.name),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: isMobile ? 12 : 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontSize: isMobile ? 15 : 16.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${student.phone} • $batchTitle',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: enrolledBatches.isNotEmpty
                                        ? const Color(0xFF4F46E5)
                                        : const Color(0xFF64748B),
                                    fontWeight: enrolledBatches.isNotEmpty
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Distribution Progress Tag
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isComplete
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isComplete
                                    ? const Color(0xFF86EFAC)
                                    : const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isComplete
                                      ? Icons.check_circle_rounded
                                      : Icons.timelapse_rounded,
                                  size: 13,
                                  color: isComplete
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFB45309),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${assignedItems.length}/$totalItems',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isComplete
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE2E8F0),
                          color: isComplete
                              ? const Color(0xFF15803D)
                              : const Color(0xFF4F46E5),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 1. ASSIGNED ITEMS (GREEN CHIPS)
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 15,
                            color: Color(0xFF15803D),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Assigned Items (${assignedItems.length}):',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (assignedItems.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Text(
                            'No items assigned yet. Tap any pending item below to assign.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: assignedItems.map((item) {
                            return Tooltip(
                              message: 'Tap to unassign ${item.name}',
                              child: InkWell(
                                onTap: () async {
                                  await ref
                                      .read(inventoryRepositoryProvider)
                                      .toggleStudentItem(
                                        studentId: student.id,
                                        studentName: student.name,
                                        item: item,
                                        willBeAssigned: false,
                                      );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF86EFAC),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.check_rounded,
                                        size: 14,
                                        color: Color(0xFF15803D),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF14532D),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.close_rounded,
                                        size: 13,
                                        color: Color(0xFF15803D),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 12),

                      // 2. NOT ASSIGNED ITEMS (AMBER/GRAY CHIPS)
                      Row(
                        children: [
                          const Icon(
                            Icons.pending_actions_rounded,
                            size: 15,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Not Assigned / Remaining (${notAssignedItems.length}):',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (notAssignedItems.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: Color(0xFF15803D),
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'All stock materials & kit items have been fully handed over to this student!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: notAssignedItems.map((item) {
                            return Tooltip(
                              message: 'Tap to assign ${item.name} to ${student.name}',
                              child: InkWell(
                                onTap: () async {
                                  await ref
                                      .read(inventoryRepositoryProvider)
                                      .toggleStudentItem(
                                        studentId: student.id,
                                        studentName: student.name,
                                        item: item,
                                        willBeAssigned: true,
                                      );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFFDE68A),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.add_rounded,
                                        size: 14,
                                        color: Color(0xFFB45309),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF92400E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 12),

                      // Footer Action Bar: Quick "Assign All" and "Manage Checklist"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (notAssignedItems.isNotEmpty)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                minimumSize: const Size(0, 32),
                              ),
                              onPressed: () async {
                                await ref
                                    .read(inventoryRepositoryProvider)
                                    .assignAllItemsToStudent(
                                      studentId: student.id,
                                      studentName: student.name,
                                      allStockItems: stockItems,
                                    );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Assigned all inventory items to ${student.name}.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.done_all_rounded,
                                size: 15,
                              ),
                              label: const Text(
                                'Assign All Remaining',
                                style: TextStyle(fontSize: 12),
                              ),
                            )
                          else
                            const SizedBox(),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: const Size(0, 32),
                            ),
                            onPressed: () => _showStudentKitChecklistDialog(
                              context,
                              student,
                              stockItems,
                              assignedSet,
                            ),
                            icon: const Icon(
                              Icons.checklist_rounded,
                              size: 16,
                            ),
                            label: const Text(
                              'Checklist View',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
