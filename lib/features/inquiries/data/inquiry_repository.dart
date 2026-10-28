import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/services/activity_logger.dart';
import '../domain/inquiry_model.dart';

class LocalInquiriesNotifier extends StateNotifier<List<Inquiry>> {
  LocalInquiriesNotifier()
      : super([
          Inquiry(
            id: 'inq-1',
            name: 'Riya Kapoor',
            areaCity: 'Andheri West, Mumbai',
            phone: '+919820112233',
            email: 'riya.kapoor@example.com',
            status: InquiryStatus.newLead,
            remarks: 'Inquired about Weekend Foundation Batch; wants brochure on WhatsApp.',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          Inquiry(
            id: 'inq-2',
            name: 'Siddharth Rao',
            areaCity: 'Bandra West, Mumbai',
            phone: '+919819445566',
            email: 'siddharth.rao@example.com',
            status: InquiryStatus.trialScheduled,
            remarks: 'Trial class booked for Saturday 11:00 AM with Senior Trainer.',
            createdAt: DateTime.now().subtract(const Duration(hours: 6)),
          ),
          Inquiry(
            id: 'inq-3',
            name: 'Ananya Deshmukh',
            areaCity: 'Kothrud, Pune',
            phone: '+919765001122',
            email: 'ananya.d@example.com',
            status: InquiryStatus.followUp,
            followUpDate: DateTime.now(), // Scheduled for TODAY
            remarks: 'Asked for 2-installment fee plan. Call back today at 4 PM.',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          Inquiry(
            id: 'inq-4',
            name: 'Kabir Malhotra',
            areaCity: 'Powai, Mumbai',
            phone: '+919821778899',
            email: 'kabir.m@example.com',
            status: InquiryStatus.joined,
            remarks: 'Paid registration fee via UPI. Ready for batch assignment.',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          Inquiry(
            id: 'inq-5',
            name: 'Aarav Sharma',
            areaCity: 'Dadar West, Mumbai',
            phone: '+919876543210',
            email: 'aarav.sharma@example.com',
            status: InquiryStatus.joined,
            remarks: 'Joined full course; prefers morning or afternoon timings.',
            createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
          ),
          Inquiry(
            id: 'inq-6',
            name: 'Priya Nair',
            areaCity: 'Vashi, Navi Mumbai',
            phone: '+919833221100',
            email: 'priya.nair@example.com',
            status: InquiryStatus.joined,
            remarks: 'First installment paid; enrolled for practical module.',
            createdAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
          Inquiry(
            id: 'inq-7',
            name: 'Meenal Joshi',
            areaCity: 'Thane West',
            phone: '+919920334455',
            email: 'meenal.joshi@example.com',
            status: InquiryStatus.notInterested,
            remarks: 'Looking for online-only night classes.',
            createdAt: DateTime.now().subtract(const Duration(days: 4)),
          ),
        ]);

  void add(Inquiry inquiry) {
    final created = inquiry.copyWith(
      id: 'inq-${DateTime.now().millisecondsSinceEpoch}',
    );
    state = [created, ...state];
  }

  void updateStatus(
    String id,
    InquiryStatus newStatus, {
    DateTime? followUpDate,
  }) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(
            status: newStatus,
            followUpDate: newStatus == InquiryStatus.followUp
                ? (followUpDate ?? item.followUpDate ?? DateTime.now())
                : item.followUpDate,
          )
        else
          item,
    ];
  }

  void updateFollowUpDate(String id, DateTime? followUpDate) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(
            followUpDate: followUpDate,
            clearFollowUpDate: followUpDate == null,
          )
        else
          item,
    ];
  }

  void updateRemarks(String id, String remarks) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(remarks: remarks) else item,
    ];
  }
}

final localInquiriesProvider =
    StateNotifierProvider<LocalInquiriesNotifier, List<Inquiry>>(
  (ref) => LocalInquiriesNotifier(),
);

final inquiryRepositoryProvider = Provider<InquiryRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final localNotifier = ref.read(localInquiriesProvider.notifier);
  final logger = ref.read(activityLoggerProvider);
  return InquiryRepository(firestore, localNotifier, logger);
});

/// Real-time stream of inquiries from Cloud Firestore (works offline-first)
/// with automatic local fallback when Firebase is not yet configured.
final inquiriesStreamProvider = StreamProvider<List<Inquiry>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final localInquiries = ref.watch(localInquiriesProvider);
  if (firestore == null) {
    return Stream<List<Inquiry>>.value(localInquiries);
  }
  final repository = ref.watch(inquiryRepositoryProvider);
  return repository.watchInquiries();
});

/// Filtered list of students whose Inquiry status is [InquiryStatus.joined].
final joinedStudentsProvider = Provider<List<Inquiry>>((ref) {
  final inquiriesAsync = ref.watch(inquiriesStreamProvider);
  final List<Inquiry> inquiries =
      inquiriesAsync.asData?.value ?? ref.watch(localInquiriesProvider);
  return inquiries
      .where((inquiry) => inquiry.status == InquiryStatus.joined)
      .toList();
});

/// Pending follow-ups for a specific date (e.g. today).
final pendingFollowUpsForDateProvider =
    Provider.family<List<Inquiry>, DateTime>((ref, date) {
  final List<Inquiry> inquiries =
      ref.watch(inquiriesStreamProvider).asData?.value ??
          ref.watch(localInquiriesProvider);
  return inquiries.where((inq) => inq.isFollowUpDueOn(date)).toList();
});

/// Optional status filter selected on the Inquiries screen (`null` = show all).
final inquiryStatusFilterProvider = StateProvider<InquiryStatus?>((ref) => null);

/// Search query string for filtering inquiries by name, phone, or area.
final inquirySearchQueryProvider = StateProvider<String>((ref) => '');

class InquiryRepository {
  final FirebaseFirestore? _firestore;
  final LocalInquiriesNotifier _localNotifier;
  final ActivityLogger _logger;

  InquiryRepository(this._firestore, this._localNotifier, this._logger);

  CollectionReference<Map<String, dynamic>>? get _collection =>
      _firestore?.collection('inquiries');

  /// Streams inquiries ordered by newest first. Uses Firestore's local cache
  /// immediately when offline and syncs automatically when back online.
  Stream<List<Inquiry>> watchInquiries() {
    final col = _collection;
    if (col == null) {
      return const Stream.empty();
    }
    return col
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) =>
            snapshot.docs.map((doc) => Inquiry.fromFirestore(doc)).toList());
  }

  Future<void> addInquiry(Inquiry inquiry) async {
    _localNotifier.add(inquiry);
    await _logger.log(
      actorName: 'Front Desk',
      action:
          'Added new inquiry: ${inquiry.name} (${inquiry.areaCity}) [${inquiry.status.label}]',
      category: 'Inquiries',
    );
    if (_collection != null) {
      await _collection!.add(inquiry.toMap());
    }
  }

  Future<void> updateStatus(
    String inquiryId,
    InquiryStatus newStatus, {
    DateTime? followUpDate,
  }) async {
    _localNotifier.updateStatus(inquiryId, newStatus,
        followUpDate: followUpDate);
    await _logger.log(
      actorName: 'Front Desk',
      action: 'Updated lead status to "${newStatus.label}"',
      category: 'Inquiries',
    );
    if (_collection != null) {
      final data = <String, dynamic>{
        'status': newStatus.label,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (followUpDate != null) {
        data['followUpDate'] = Timestamp.fromDate(followUpDate);
      }
      await _collection!.doc(inquiryId).update(data);
    }
  }

  Future<void> updateFollowUpDate(
    String inquiryId,
    DateTime? followUpDate,
  ) async {
    _localNotifier.updateFollowUpDate(inquiryId, followUpDate);
    await _logger.log(
      actorName: 'Front Desk',
      action: 'Updated follow-up date for lead',
      category: 'Inquiries',
    );
    if (_collection != null) {
      await _collection!.doc(inquiryId).update({
        'followUpDate':
            followUpDate != null ? Timestamp.fromDate(followUpDate) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> updateRemarks(String inquiryId, String remarks) async {
    _localNotifier.updateRemarks(inquiryId, remarks);
    await _logger.log(
      actorName: 'Front Desk',
      action: 'Updated follow-up remarks for lead',
      category: 'Inquiries',
    );
    if (_collection != null) {
      await _collection!.doc(inquiryId).update({
        'remarks': remarks,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
