import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/services/activity_logger.dart';
import '../domain/payment_model.dart';

class LocalPaymentsNotifier extends StateNotifier<List<PaymentRecord>> {
  LocalPaymentsNotifier()
      : super([
          PaymentRecord(
            id: 'pay-1',
            studentId: 'inq-6',
            studentName: 'Priya Nair',
            batchId: 'batch-2',
            batchName: 'Advanced Practical Batch B',
            amount: 22000.0,
            paymentMethod: 'UPI',
            paymentDate: DateTime.now().subtract(const Duration(days: 3)),
            notes: 'Batch fee paid in full',
          ),
          PaymentRecord(
            id: 'pay-2',
            studentId: 'inq-4',
            studentName: 'Kabir Malhotra',
            batchId: 'batch-1',
            batchName: 'Morning Foundation Batch A',
            amount: 7500.0,
            paymentMethod: 'Cash',
            paymentDate: DateTime.now().subtract(const Duration(days: 2)),
            notes: 'First installment of 50%',
          ),
        ]);

  void addPayment(PaymentRecord record) {
    final created = record.copyWith(
      id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
    );
    state = [created, ...state];
  }

  void removePayment(String id) {
    state = state.where((p) => p.id != id).toList();
  }
}

final localPaymentsProvider =
    StateNotifierProvider<LocalPaymentsNotifier, List<PaymentRecord>>(
  (ref) => LocalPaymentsNotifier(),
);

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final localNotifier = ref.read(localPaymentsProvider.notifier);
  final logger = ref.read(activityLoggerProvider);
  return PaymentRepository(firestore, localNotifier, logger);
});

class PaymentRepository {
  final FirebaseFirestore? _firestore;
  final LocalPaymentsNotifier _localNotifier;
  final ActivityLogger _logger;

  PaymentRepository(
    this._firestore,
    this._localNotifier,
    this._logger,
  );

  CollectionReference<Map<String, dynamic>>? get _collection =>
      _firestore?.collection('payments');

  Future<void> recordPayment(PaymentRecord record) async {
    _localNotifier.addPayment(record);
    await _logger.log(
      actorName: 'Front Desk',
      action:
          'Recorded payment of ₹${record.amount.toStringAsFixed(0)} (${record.paymentMethod}) for ${record.studentName} in batch "${record.batchName}"',
      category: 'Payments',
    );
    if (_collection != null) {
      await _collection!.add(record.toMap());
    }
  }
}
