import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/services/activity_logger.dart';
import '../domain/stock_item_model.dart';

class LocalStockNotifier extends StateNotifier<List<StockItem>> {
  LocalStockNotifier()
      : super([
          const StockItem(
            id: 'item-1',
            name: 'Printed Course Workbooks (Level 1)',
            quantity: 24,
            category: 'Course Materials',
            minThreshold: 5,
          ),
          const StockItem(
            id: 'item-2',
            name: 'Student Welcome Bags',
            quantity: 3, // < 5 -> Red alert
            category: 'Welcome Kit',
            minThreshold: 5,
          ),
          const StockItem(
            id: 'item-3',
            name: 'Practice Toolkits & Brushes',
            quantity: 4, // < 5 -> Red alert
            category: 'Practical Tools',
            minThreshold: 5,
          ),
          const StockItem(
            id: 'item-4',
            name: 'Institute ID Card & Lanyards',
            quantity: 16,
            category: 'Stationery',
            minThreshold: 5,
          ),
          const StockItem(
            id: 'item-5',
            name: 'Official Certificate Folders',
            quantity: 10,
            category: 'Certificates',
            minThreshold: 5,
          ),
        ]);

  void addItem(StockItem item) {
    final newItem = item.id.isEmpty
        ? item.copyWith(id: 'item-${DateTime.now().millisecondsSinceEpoch}')
        : item;
    state = [...state, newItem];
  }

  void updateItem(StockItem updated) {
    state = [
      for (final item in state)
        if (item.id == updated.id) updated else item,
    ];
  }

  void deleteItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void adjustQuantity(String id, int delta) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(quantity: (item.quantity + delta).clamp(0, 9999))
        else
          item,
    ];
  }
}

final localStockProvider =
    StateNotifierProvider<LocalStockNotifier, List<StockItem>>(
  (ref) => LocalStockNotifier(),
);

/// Maps `studentId` -> `Set<String>` (set of `stockItemId` assigned to this student)
class StudentKitAssignmentsNotifier
    extends StateNotifier<Map<String, Set<String>>> {
  StudentKitAssignmentsNotifier()
      : super({
          'inq-4': {'item-1', 'item-2', 'item-4'}, // Kabir Malhotra
          'inq-5': {'item-1'}, // Aarav Sharma
          'inq-6': {'item-1', 'item-3', 'item-4'}, // Priya Nair
        });

  void toggleAssignment(String studentId, String itemId) {
    final current = Set<String>.from(state[studentId] ?? <String>{});
    if (current.contains(itemId)) {
      current.remove(itemId);
    } else {
      current.add(itemId);
    }
    state = {
      ...state,
      studentId: current,
    };
  }

  void assignAll(String studentId, Iterable<String> itemIds) {
    state = {
      ...state,
      studentId: Set<String>.from(itemIds),
    };
  }

  void clearAll(String studentId) {
    final next = Map<String, Set<String>>.from(state);
    next.remove(studentId);
    state = next;
  }
}

final studentKitAssignmentsProvider = StateNotifierProvider<
    StudentKitAssignmentsNotifier, Map<String, Set<String>>>(
  (ref) => StudentKitAssignmentsNotifier(),
);

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final stockNotifier = ref.read(localStockProvider.notifier);
  final assignmentsNotifier =
      ref.read(studentKitAssignmentsProvider.notifier);
  final logger = ref.read(activityLoggerProvider);
  return InventoryRepository(
    firestore,
    stockNotifier,
    assignmentsNotifier,
    logger,
  );
});

class InventoryRepository {
  final FirebaseFirestore? _firestore;
  final LocalStockNotifier _stockNotifier;
  final StudentKitAssignmentsNotifier _assignmentsNotifier;
  final ActivityLogger _logger;

  InventoryRepository(
    this._firestore,
    this._stockNotifier,
    this._assignmentsNotifier,
    this._logger,
  );

  CollectionReference<Map<String, dynamic>>? get _stockCollection =>
      _firestore?.collection('stock_items');

  CollectionReference<Map<String, dynamic>>? get _assignmentsCollection =>
      _firestore?.collection('student_kit_assignments');

  Future<void> addStockItem(StockItem item) async {
    _stockNotifier.addItem(item);
    await _logger.log(
      actorName: 'Inventory Manager',
      action: 'Added stock item "${item.name}" (Qty: ${item.quantity})',
      category: 'Inventory',
    );
    if (_stockCollection != null) {
      await _stockCollection!.add(item.toMap());
    }
  }

  Future<void> updateStockItem(StockItem item) async {
    _stockNotifier.updateItem(item);
    await _logger.log(
      actorName: 'Inventory Manager',
      action: 'Updated stock item "${item.name}" (Qty: ${item.quantity})',
      category: 'Inventory',
    );
    if (_stockCollection != null) {
      await _stockCollection!.doc(item.id).update(item.toMap());
    }
  }

  Future<void> deleteStockItem(String itemId, String itemName) async {
    _stockNotifier.deleteItem(itemId);
    await _logger.log(
      actorName: 'Inventory Manager',
      action: 'Deleted stock item "$itemName"',
      category: 'Inventory',
    );
    if (_stockCollection != null) {
      await _stockCollection!.doc(itemId).delete();
    }
  }

  Future<void> adjustQuantity(String itemId, String itemName, int delta) async {
    _stockNotifier.adjustQuantity(itemId, delta);
    final sign = delta > 0 ? '+$delta' : '$delta';
    await _logger.log(
      actorName: 'Inventory Manager',
      action: 'Adjusted stock quantity for "$itemName" ($sign)',
      category: 'Inventory',
    );
    if (_stockCollection != null) {
      await _stockCollection!
          .doc(itemId)
          .update({'quantity': FieldValue.increment(delta)});
    }
  }

  Future<void> toggleStudentItem({
    required String studentId,
    required String studentName,
    required StockItem item,
    required bool willBeAssigned,
  }) async {
    _assignmentsNotifier.toggleAssignment(studentId, item.id);
    final verb = willBeAssigned ? 'Assigned' : 'Unassigned';
    await _logger.log(
      actorName: 'Front Desk',
      action: '$verb "${item.name}" for student $studentName',
      category: 'Kits',
    );
    if (_assignmentsCollection != null) {
      await _assignmentsCollection!.doc(studentId).set(
        {
          'assignedItemIds': willBeAssigned
              ? FieldValue.arrayUnion([item.id])
              : FieldValue.arrayRemove([item.id]),
          'studentName': studentName,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
  }

  Future<void> assignAllItemsToStudent({
    required String studentId,
    required String studentName,
    required List<StockItem> allStockItems,
  }) async {
    final itemIds = allStockItems.map((e) => e.id).toList();
    _assignmentsNotifier.assignAll(studentId, itemIds);
    await _logger.log(
      actorName: 'Front Desk',
      action:
          'Assigned all ${itemIds.length} materials & kit items to student $studentName',
      category: 'Kits',
    );
    if (_assignmentsCollection != null) {
      await _assignmentsCollection!.doc(studentId).set(
        {
          'assignedItemIds': itemIds,
          'studentName': studentName,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
  }
}
