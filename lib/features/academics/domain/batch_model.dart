import 'package:cloud_firestore/cloud_firestore.dart';

class Batch {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String timings;
  final List<String> studentIds;

  const Batch({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.timings,
    required this.studentIds,
  });

  Batch copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? timings,
    List<String>? studentIds,
  }) {
    return Batch(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      timings: timings ?? this.timings,
      studentIds: studentIds ?? this.studentIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'timings': timings,
      'studentIds': studentIds,
    };
  }

  factory Batch.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final startTs = data['startDate'] as Timestamp?;
    final endTs = data['endDate'] as Timestamp?;
    final rawIds = data['studentIds'] as List<dynamic>? ?? const [];

    return Batch(
      id: doc.id,
      name: data['name'] as String? ?? 'Unnamed Batch',
      startDate: startTs?.toDate() ?? DateTime.now(),
      endDate:
          endTs?.toDate() ?? DateTime.now().add(const Duration(days: 90)),
      timings: data['timings'] as String? ?? '',
      studentIds: rawIds.map((e) => e.toString()).toList(),
    );
  }
}
