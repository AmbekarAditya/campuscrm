import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/services/activity_logger.dart';
import '../domain/batch_model.dart';

class LocalBatchesNotifier extends StateNotifier<List<Batch>> {
  LocalBatchesNotifier()
      : super([
          Batch(
            id: 'batch-1',
            name: 'Morning Foundation Batch A',
            startDate: DateTime(2026, 10, 1),
            endDate: DateTime(2026, 12, 31),
            timings: '09:30 AM - 11:00 AM',
            studentIds: const ['inq-4', 'inq-5'],
          ),
          Batch(
            id: 'batch-2',
            name: 'Advanced Practical Batch B',
            startDate: DateTime(2026, 10, 15),
            endDate: DateTime(2027, 1, 15),
            timings: '11:30 AM - 01:00 PM',
            studentIds: const ['inq-6'],
          ),
        ]);

  void addBatch(Batch batch) {
    final created = batch.copyWith(
      id: 'batch-${DateTime.now().millisecondsSinceEpoch}',
    );
    state = [created, ...state];
  }

  void updateBatchStudents(String batchId, List<String> studentIds) {
    state = [
      for (final b in state)
        if (b.id == batchId) b.copyWith(studentIds: studentIds) else b,
    ];
  }
}

final localBatchesProvider =
    StateNotifierProvider<LocalBatchesNotifier, List<Batch>>(
  (ref) => LocalBatchesNotifier(),
);

final batchRepositoryProvider = Provider<BatchRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final localNotifier = ref.read(localBatchesProvider.notifier);
  final logger = ref.read(activityLoggerProvider);
  return BatchRepository(firestore, localNotifier, logger);
});

class BatchRepository {
  final FirebaseFirestore? _firestore;
  final LocalBatchesNotifier _localNotifier;
  final ActivityLogger _logger;

  BatchRepository(this._firestore, this._localNotifier, this._logger);

  CollectionReference<Map<String, dynamic>>? get _collection =>
      _firestore?.collection('batches');

  Future<void> createBatch(Batch batch) async {
    _localNotifier.addBatch(batch);
    await _logger.log(
      actorName: 'Owner',
      action:
          'Created batch "${batch.name}" (${batch.timings}) with ${batch.studentIds.length} joined student(s)',
      category: 'Batches',
    );
    if (_collection != null) {
      await _collection!.add(batch.toMap());
    }
  }

  Future<void> updateBatchStudents(
    String batchId,
    String batchName,
    List<String> studentIds,
  ) async {
    _localNotifier.updateBatchStudents(batchId, studentIds);
    await _logger.log(
      actorName: 'Owner',
      action:
          'Updated students in "$batchName" (${studentIds.length} joined student(s))',
      category: 'Batches',
    );
    if (_collection != null) {
      await _collection!.doc(batchId).update({'studentIds': studentIds});
    }
  }
}
