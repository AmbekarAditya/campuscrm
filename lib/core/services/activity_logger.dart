import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/firebase_providers.dart';

class ActivityLogEntry {
  final String id;
  final String actorName;
  final String action;
  final String category;
  final DateTime timestamp;

  const ActivityLogEntry({
    required this.id,
    required this.actorName,
    required this.action,
    required this.category,
    required this.timestamp,
  });
}

class LocalActivityLogNotifier extends StateNotifier<List<ActivityLogEntry>> {
  LocalActivityLogNotifier()
      : super([
          ActivityLogEntry(
            id: 'log-1',
            actorName: 'Neha Deshmukh',
            action: 'Scheduled trial class for Siddharth Rao (Bandra West)',
            category: 'Inquiries',
            timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
          ),
          ActivityLogEntry(
            id: 'log-2',
            actorName: 'Vikram Joshi',
            action: 'Marked attendance for Morning Foundation Batch A (18/18)',
            category: 'Attendance',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          ActivityLogEntry(
            id: 'log-3',
            actorName: 'Pooja Iyer',
            action: 'Recorded ₹15,000 UPI fee payment for Priya Nair',
            category: 'Payments',
            timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          ),
        ]);

  void addEntry({
    required String actorName,
    required String action,
    required String category,
  }) {
    state = [
      ActivityLogEntry(
        id: 'log-${DateTime.now().millisecondsSinceEpoch}',
        actorName: actorName,
        action: action,
        category: category,
        timestamp: DateTime.now(),
      ),
      ...state,
    ];
  }
}

final localActivityLogsProvider =
    StateNotifierProvider<LocalActivityLogNotifier, List<ActivityLogEntry>>(
  (ref) => LocalActivityLogNotifier(),
);

final activityLoggerProvider = Provider<ActivityLogger>((ref) {
  return ActivityLogger(
    ref.watch(firestoreProvider),
    ref.read(localActivityLogsProvider.notifier),
  );
});

class ActivityLogger {
  final FirebaseFirestore? _firestore;
  final LocalActivityLogNotifier _localLogs;

  ActivityLogger(this._firestore, this._localLogs);

  Future<void> log({
    required String actorName,
    required String action,
    required String category,
  }) async {
    _localLogs.addEntry(
      actorName: actorName,
      action: action,
      category: category,
    );

    if (_firestore != null) {
      await _firestore.collection('activity_logs').add({
        'actorName': actorName,
        'action': action,
        'category': category,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }
}
