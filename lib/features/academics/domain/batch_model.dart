import 'package:cloud_firestore/cloud_firestore.dart';

class Batch {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String timings;
  final List<String> studentIds;

  /// Days of the week when this batch runs.
  /// 1 = Monday, 2 = Tuesday, 3 = Wednesday, 4 = Thursday, 5 = Friday, 6 = Saturday, 7 = Sunday.
  /// If empty, defaults to all 7 days (Daily).
  final List<int> scheduleDays;

  const Batch({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.timings,
    required this.studentIds,
    this.scheduleDays = const [1, 2, 3, 4, 5, 6, 7],
  });

  /// Normalized list of active weekdays (1..7).
  List<int> get activeScheduleDays =>
      scheduleDays.isEmpty ? const [1, 2, 3, 4, 5, 6, 7] : scheduleDays;

  /// Returns true if [date] falls within [startDate] and [endDate] AND matches the batch's weekday schedule.
  bool isActiveOn(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final inDateRange = !target.isBefore(start) && !target.isAfter(end);
    if (!inDateRange) return false;

    return activeScheduleDays.contains(date.weekday);
  }

  /// Returns true if [date] falls within [startDate] and [endDate] regardless of weekday.
  bool isWithinDateRange(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !target.isBefore(start) && !target.isAfter(end);
  }

  /// Human-readable schedule description (e.g. "Every Day", "Every Sunday", "Mon, Wed, Fri").
  String get scheduleDescription {
    final days = Set<int>.from(activeScheduleDays);

    if (days.length == 7) {
      return 'Every Day (Daily)';
    }
    if (days.length == 5 &&
        days.containsAll([DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday])) {
      return 'Weekdays (Mon–Fri)';
    }
    if (days.length == 2 &&
        days.containsAll([DateTime.saturday, DateTime.sunday])) {
      return 'Weekends (Sat–Sun)';
    }
    if (days.length == 1) {
      final day = days.first;
      switch (day) {
        case DateTime.monday:
          return 'Every Monday';
        case DateTime.tuesday:
          return 'Every Tuesday';
        case DateTime.wednesday:
          return 'Every Wednesday';
        case DateTime.thursday:
          return 'Every Thursday';
        case DateTime.friday:
          return 'Every Friday';
        case DateTime.saturday:
          return 'Every Saturday';
        case DateTime.sunday:
          return 'Every Sunday';
      }
    }
    if (days.length == 3 &&
        days.containsAll([DateTime.monday, DateTime.wednesday, DateTime.friday])) {
      return 'Mon, Wed, Fri';
    }
    if (days.length == 3 &&
        days.containsAll([DateTime.tuesday, DateTime.thursday, DateTime.saturday])) {
      return 'Tue, Thu, Sat';
    }

    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = days.toList()..sort();
    return sorted.map((d) => dayLabels[d - 1]).join(', ');
  }

  Batch copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? timings,
    List<String>? studentIds,
    List<int>? scheduleDays,
  }) {
    return Batch(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      timings: timings ?? this.timings,
      studentIds: studentIds ?? this.studentIds,
      scheduleDays: scheduleDays ?? this.scheduleDays,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'timings': timings,
      'studentIds': studentIds,
      'scheduleDays': scheduleDays,
    };
  }

  factory Batch.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final startTs = data['startDate'] as Timestamp?;
    final endTs = data['endDate'] as Timestamp?;
    final rawIds = data['studentIds'] as List<dynamic>? ?? const [];
    final rawDays = data['scheduleDays'] as List<dynamic>? ?? const [1, 2, 3, 4, 5, 6, 7];

    return Batch(
      id: doc.id,
      name: data['name'] as String? ?? 'Unnamed Batch',
      startDate: startTs?.toDate() ?? DateTime.now(),
      endDate:
          endTs?.toDate() ?? DateTime.now().add(const Duration(days: 90)),
      timings: data['timings'] as String? ?? '',
      studentIds: rawIds.map((e) => e.toString()).toList(),
      scheduleDays: rawDays.map((e) => (e as num).toInt()).toList(),
    );
  }
}
