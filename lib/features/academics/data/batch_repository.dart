import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/services/activity_logger.dart';
import '../domain/batch_model.dart';

class LocalBatchesNotifier extends StateNotifier<List<Batch>> {
  LocalBatchesNotifier()
      : super([
          Batch(
            id: 'batch-1',
            name: 'Morning Foundation Batch A',
            startDate: DateTime.now().subtract(const Duration(days: 14)),
            endDate: DateTime.now().add(const Duration(days: 75)),
            timings: '09:30 AM - 11:00 AM',
            studentIds: const ['inq-4', 'inq-5'],
            fee: 15000.0,
            scheduleDays: const [1, 2, 3, 4, 5], // Weekdays (Mon-Fri)
          ),
          Batch(
            id: 'batch-2',
            name: 'Advanced Practical Batch B',
            startDate: DateTime.now().subtract(const Duration(days: 7)),
            endDate: DateTime.now().add(const Duration(days: 80)),
            timings: '11:30 AM - 01:00 PM',
            studentIds: const ['inq-6'],
            fee: 22000.0,
            scheduleDays: const [6, 7], // Weekends (Sat-Sun)
          ),
          Batch(
            id: 'batch-3',
            name: 'Sunday Masterclass Cohort',
            startDate: DateTime.now().subtract(const Duration(days: 10)),
            endDate: DateTime.now().add(const Duration(days: 90)),
            timings: '02:00 PM - 04:30 PM',
            studentIds: const ['inq-4', 'inq-6'],
            fee: 8500.0,
            scheduleDays: const [7], // Every Sunday
          ),
        ]);

  void addBatch(Batch batch) {
    final created = batch.copyWith(
      id: 'batch-${DateTime.now().millisecondsSinceEpoch}',
    );
    state = [created, ...state];
  }

  void updateBatch(Batch updated) {
    state = [
      for (final b in state)
        if (b.id == updated.id) updated else b,
    ];
  }

  void updateBatchStudents(String batchId, List<String> studentIds) {
    state = [
      for (final b in state)
        if (b.id == batchId) b.copyWith(studentIds: studentIds) else b,
    ];
  }

  void removeBatch(String batchId) {
    state = state.where((b) => b.id != batchId).toList();
  }
}

final localBatchesProvider =
    StateNotifierProvider<LocalBatchesNotifier, List<Batch>>(
  (ref) => LocalBatchesNotifier(),
);

/// Stores attendance per batch and date key (`<batchId>_<yyyy-MM-dd>` -> set of present studentIds).
class BatchAttendanceNotifier extends StateNotifier<Map<String, Set<String>>> {
  BatchAttendanceNotifier() : super(const {});

  static String keyFor(String batchId, DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return '${batchId}_$dateStr';
  }

  void recordAttendance(
    String batchId,
    DateTime date,
    Set<String> presentStudentIds,
  ) {
    final key = keyFor(batchId, date);
    state = {
      ...state,
      key: Set<String>.from(presentStudentIds),
    };
  }
}

final batchAttendanceProvider =
    StateNotifierProvider<BatchAttendanceNotifier, Map<String, Set<String>>>(
  (ref) => BatchAttendanceNotifier(),
);

final batchRepositoryProvider = Provider<BatchRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final localNotifier = ref.read(localBatchesProvider.notifier);
  final attendanceNotifier = ref.read(batchAttendanceProvider.notifier);
  final logger = ref.read(activityLoggerProvider);
  return BatchRepository(
    firestore,
    localNotifier,
    attendanceNotifier,
    logger,
  );
});

class BatchRepository {
  final FirebaseFirestore? _firestore;
  final LocalBatchesNotifier _localNotifier;
  final BatchAttendanceNotifier _attendanceNotifier;
  final ActivityLogger _logger;

  BatchRepository(
    this._firestore,
    this._localNotifier,
    this._attendanceNotifier,
    this._logger,
  );

  CollectionReference<Map<String, dynamic>>? get _collection =>
      _firestore?.collection('batches');

  Future<void> createBatch(Batch batch) async {
    _localNotifier.addBatch(batch);
    await _logger.log(
      actorName: 'Owner',
      action:
          'Created batch "${batch.name}" (Fees: ₹${batch.fee.toStringAsFixed(0)}, ${batch.scheduleDescription}, ${batch.timings}) with ${batch.studentIds.length} joined student(s)',
      category: 'Batches',
    );
    if (_collection != null) {
      await _collection!.add(batch.toMap());
    }
  }

  Future<void> updateBatch(Batch batch) async {
    _localNotifier.updateBatch(batch);
    await _logger.log(
      actorName: 'Owner',
      action:
          'Updated batch "${batch.name}" (Fees: ₹${batch.fee.toStringAsFixed(0)}, ${batch.scheduleDescription}, ${batch.timings})',
      category: 'Batches',
    );
    if (_collection != null) {
      await _collection!.doc(batch.id).update(batch.toMap());
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

  Future<void> deleteBatch(String batchId, String batchName) async {
    _localNotifier.removeBatch(batchId);
    await _logger.log(
      actorName: 'Owner',
      action: 'Deleted batch "$batchName"',
      category: 'Batches',
    );
    if (_collection != null) {
      await _collection!.doc(batchId).delete();
    }
  }

  Future<void> markBatchAttendance({
    required Batch batch,
    required DateTime date,
    required Set<String> presentStudentIds,
    required int totalStudents,
  }) async {
    _attendanceNotifier.recordAttendance(batch.id, date, presentStudentIds);
    final formattedDate = DateFormat('dd MMM yyyy').format(date);
    await _logger.log(
      actorName: 'Owner',
      action:
          'Marked attendance for "${batch.name}" on $formattedDate (${presentStudentIds.length}/$totalStudents present)',
      category: 'Attendance',
    );
    if (_firestore != null) {
      final key = BatchAttendanceNotifier.keyFor(batch.id, date);
      await _firestore.collection('attendance').doc(key).set({
        'batchId': batch.id,
        'batchName': batch.name,
        'date': Timestamp.fromDate(date),
        'presentStudentIds': presentStudentIds.toList(),
        'totalStudents': totalStudents,
      });
    }
  }
}
