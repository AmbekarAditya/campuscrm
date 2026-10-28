import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../academics/data/batch_repository.dart';
import '../../academics/domain/batch_model.dart';
import '../../inquiries/data/inquiry_repository.dart';
import '../../inquiries/domain/inquiry_model.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DateTime _selectedDate = DateTime.now();

  String _formatFullDate(DateTime date) {
    return DateFormat('EEEE, dd MMM yyyy').format(date);
  }

  String _formatShortDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final allBatches = ref.watch(localBatchesProvider);
    final attendanceMap = ref.watch(batchAttendanceProvider);
    final List<Inquiry> allInquiries =
        ref.watch(inquiriesStreamProvider).asData?.value ??
        ref.watch(localInquiriesProvider);

    final newLeadsCount = allInquiries
        .where((inq) => inq.status == InquiryStatus.newLead)
        .length;

    // Batches whose Date From - Date To includes the selected dashboard date
    final todaysBatches = allBatches
        .where((batch) => batch.isActiveOn(_selectedDate))
        .toList();

    // Any batches outside the selected date (e.g., future or past batches)
    final otherBatches = allBatches
        .where((batch) => !batch.isActiveOn(_selectedDate))
        .toList();

    final isToday = _isSameDay(_selectedDate, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Institute Overview'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2032),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(
                isToday
                    ? 'Today: ${_formatShortDate(_selectedDate)}'
                    : _formatShortDate(_selectedDate),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: todaysBatches.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _handleFloatingAttendanceButton(
                context,
                todaysBatches,
                allInquiries,
                attendanceMap,
              ),
              icon: const Icon(Icons.fact_check_rounded, size: 26),
              label: const Text(
                'Mark Daily Attendance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
        children: [
          // Prominent Dashboard Date Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.today_rounded,
                      color: Color(0xFF1E40AF),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isToday ? "Today's Date" : 'Selected Schedule Date',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                        Text(
                          _formatFullDate(_selectedDate),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: const Color(0xFF1E3A8A)),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isToday)
                      TextButton(
                        onPressed: () =>
                            setState(() => _selectedDate = DateTime.now()),
                        child: const Text('Reset to Today'),
                      ),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2032),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      icon: const Icon(Icons.edit_calendar_rounded),
                      label: const Text('Change Date'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Items Alert Widget
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFDC2626), size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Action Items Requiring Attention',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFF991B1B),
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _ActionAlertRow(
                  badgeText: '3 Overdue',
                  badgeColor: Color(0xFFDC2626),
                  description: 'Fee installments due this week need follow-up.',
                ),
                const SizedBox(height: 8),
                _ActionAlertRow(
                  badgeText: '$newLeadsCount New Leads',
                  badgeColor: const Color(0xFF2563EB),
                  description: 'Uncontacted inquiries awaiting follow-up.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Today's Classes Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday
                          ? "Today's Classes (${_formatShortDate(_selectedDate)})"
                          : 'Classes on ${_formatShortDate(_selectedDate)}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Click any class below to mark attendance for its enrolled students.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (todaysBatches.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No batches scheduled for ${_formatShortDate(_selectedDate)}. Create a batch in the "Batches" tab with dates covering this day.',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else
            ...todaysBatches.map((batch) {
              final enrolledStudents = allInquiries
                  .where((inq) => batch.studentIds.contains(inq.id))
                  .toList();
              final attendanceKey =
                  BatchAttendanceNotifier.keyFor(batch.id, _selectedDate);
              final markedPresentIds = attendanceMap[attendanceKey];

              return _TodayClassTile(
                batchName: batch.name,
                timeSlot: batch.timings,
                dateRange:
                    '${_formatShortDate(batch.startDate)} – ${_formatShortDate(batch.endDate)}',
                scheduleDateLabel: _formatShortDate(_selectedDate),
                studentCount: enrolledStudents.length,
                studentNames: enrolledStudents.map((s) => s.name).join(', '),
                isAttendanceMarked: markedPresentIds != null,
                presentCount: markedPresentIds?.length ?? 0,
                onTap: () => _showBatchAttendanceDialog(
                  context: context,
                  batch: batch,
                  enrolledStudents: enrolledStudents,
                  existingPresentIds: markedPresentIds,
                ),
              );
            }),

          // Other / Upcoming Batches (outside selected date)
          if (otherBatches.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Other Scheduled Batches',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            ...otherBatches.map((batch) {
              final enrolledStudents = allInquiries
                  .where((inq) => batch.studentIds.contains(inq.id))
                  .toList();
              return Card(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  title: Text(
                    batch.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${_formatShortDate(batch.startDate)} – ${_formatShortDate(batch.endDate)}  •  ${batch.timings}  •  ${enrolledStudents.length} Student(s)',
                    ),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Not Active Today',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<void> _handleFloatingAttendanceButton(
    BuildContext context,
    List<Batch> todaysBatches,
    List<Inquiry> allInquiries,
    Map<String, Set<String>> attendanceMap,
  ) async {
    if (todaysBatches.length == 1) {
      final batch = todaysBatches.first;
      final enrolled = allInquiries
          .where((inq) => batch.studentIds.contains(inq.id))
          .toList();
      final key = BatchAttendanceNotifier.keyFor(batch.id, _selectedDate);
      await _showBatchAttendanceDialog(
        context: context,
        batch: batch,
        enrolledStudents: enrolled,
        existingPresentIds: attendanceMap[key],
      );
      return;
    }

    // Multiple classes today: let the owner pick which class to mark
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Select Class • ${_formatShortDate(_selectedDate)}',
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: todaysBatches.map((batch) {
                final enrolled = allInquiries
                    .where((inq) => batch.studentIds.contains(inq.id))
                    .toList();
                final key =
                    BatchAttendanceNotifier.keyFor(batch.id, _selectedDate);
                final marked = attendanceMap[key];
                return ListTile(
                  leading: const Icon(
                    Icons.fact_check_outlined,
                    color: Color(0xFF1E40AF),
                  ),
                  title: Text(
                    batch.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${batch.timings} • ${enrolled.length} Student(s)',
                  ),
                  trailing: Text(
                    marked != null
                        ? '${marked.length}/${enrolled.length} Present'
                        : 'Mark Now',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: marked != null
                          ? const Color(0xFF15803D)
                          : const Color(0xFF1E40AF),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    _showBatchAttendanceDialog(
                      context: context,
                      batch: batch,
                      enrolledStudents: enrolled,
                      existingPresentIds: marked,
                    );
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showBatchAttendanceDialog({
    required BuildContext context,
    required Batch batch,
    required List<Inquiry> enrolledStudents,
    required Set<String>? existingPresentIds,
  }) async {
    // Default all enrolled students to Present if attendance hasn't been marked yet today
    final presentIds = existingPresentIds != null
        ? Set<String>.from(existingPresentIds)
        : enrolledStudents.map((s) => s.id).toSet();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mark Attendance • ${batch.name}'),
                  const SizedBox(height: 4),
                  Text(
                    'Date: ${_formatFullDate(_selectedDate)}  |  ${batch.timings}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 460,
                child: enrolledStudents.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No Joined students are assigned to this batch yet. Go to the "Batches" tab and click "Select Joined Students" to assign students.',
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Present: ${presentIds.length} / ${enrolledStudents.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setModalState(() {
                                      if (presentIds.length ==
                                          enrolledStudents.length) {
                                        presentIds.clear();
                                      } else {
                                        presentIds.addAll(
                                          enrolledStudents.map((s) => s.id),
                                        );
                                      }
                                    });
                                  },
                                  child: Text(
                                    presentIds.length == enrolledStudents.length
                                        ? 'Mark All Absent'
                                        : 'Mark All Present',
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 12),
                            ...enrolledStudents.map((student) {
                              final isPresent = presentIds.contains(student.id);
                              return CheckboxListTile(
                                title: Text(
                                  student.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${student.areaCity} • ${isPresent ? "Present" : "Absent"}',
                                  style: TextStyle(
                                    color: isPresent
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFFDC2626),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                value: isPresent,
                                onChanged: (checked) {
                                  setModalState(() {
                                    if (checked == true) {
                                      presentIds.add(student.id);
                                    } else {
                                      presentIds.remove(student.id);
                                    }
                                  });
                                },
                              );
                            }),
                          ],
                        ),
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                if (enrolledStudents.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(batchRepositoryProvider)
                          .markBatchAttendance(
                            batch: batch,
                            date: _selectedDate,
                            presentStudentIds: presentIds,
                            totalStudents: enrolledStudents.length,
                          );
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Attendance saved for "${batch.name}" (${presentIds.length}/${enrolledStudents.length} present on ${_formatShortDate(_selectedDate)}).',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Save Attendance'),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ActionAlertRow extends StatelessWidget {
  final String badgeText;
  final Color badgeColor;
  final String description;

  const _ActionAlertRow({
    required this.badgeText,
    required this.badgeColor,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            badgeText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7F1D1D),
            ),
          ),
        ),
      ],
    );
  }
}

class _TodayClassTile extends StatelessWidget {
  final String batchName;
  final String timeSlot;
  final String dateRange;
  final String scheduleDateLabel;
  final int studentCount;
  final String studentNames;
  final bool isAttendanceMarked;
  final int presentCount;
  final VoidCallback onTap;

  const _TodayClassTile({
    required this.batchName,
    required this.timeSlot,
    required this.dateRange,
    required this.scheduleDateLabel,
    required this.studentCount,
    required this.studentNames,
    required this.isAttendanceMarked,
    required this.presentCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = isAttendanceMarked
        ? const Color(0xFF15803D)
        : const Color(0xFF1E40AF);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    batchName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_filled_rounded,
                            size: 17,
                            color: Color(0xFF7E22CE),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            timeSlot,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7E22CE),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.date_range_rounded,
                            size: 17,
                            color: Color(0xFF1D4ED8),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Batch Dates: $dateRange',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people_alt_rounded,
                            size: 17,
                            color: Color(0xFF15803D),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$studentCount Joined Student(s)',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (studentNames.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Students: $studentNames',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAttendanceMarked
                          ? Icons.check_circle_rounded
                          : Icons.fact_check_outlined,
                      color: badgeColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAttendanceMarked
                          ? 'Present: $presentCount/$studentCount ($scheduleDateLabel)'
                          : 'Click to Mark Attendance',
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
