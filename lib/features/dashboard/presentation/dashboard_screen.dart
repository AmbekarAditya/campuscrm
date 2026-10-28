import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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

  String _formatWeekday(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _launchActionUrl(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
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

    // Follow-ups pending on the selected date (e.g. Today)
    final pendingFollowUps = allInquiries
        .where((inq) => inq.isFollowUpDueOn(_selectedDate))
        .toList();

    // Batches scheduled for THIS date (matching date range AND weekday schedule)
    final todaysBatches = allBatches
        .where((batch) => batch.isActiveOn(_selectedDate))
        .toList();

    // Any batches outside the selected date (different weekday or different date range)
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
              icon: const Icon(Icons.calendar_month_rounded, size: 18),
              label: Text(
                isToday
                    ? 'Today: ${_formatShortDate(_selectedDate)}'
                    : _formatShortDate(_selectedDate),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          // Prominent Dashboard Date Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
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
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isToday ? "Today's Schedule" : 'Viewing Schedule For',
                          style: const TextStyle(
                            fontSize: 12,
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
                      icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                      label: const Text('Change Date'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Items Alert Widget
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFDC2626), size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Action Items Requiring Attention',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFF991B1B),
                              fontSize: 17,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const _ActionAlertRow(
                  badgeText: '3 Overdue',
                  badgeColor: Color(0xFFDC2626),
                  description: 'Fee installments due this week need follow-up.',
                ),
                if (pendingFollowUps.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _ActionAlertRow(
                    badgeText:
                        '${pendingFollowUps.length} Follow-ups ${isToday ? "Today" : ""}',
                    badgeColor: const Color(0xFFD97706),
                    description: isToday
                        ? '${pendingFollowUps.length} student inquiry follow-up(s) scheduled for today.'
                        : '${pendingFollowUps.length} follow-up(s) scheduled for ${_formatShortDate(_selectedDate)}.',
                  ),
                ],
                const SizedBox(height: 6),
                _ActionAlertRow(
                  badgeText: '$newLeadsCount New Leads',
                  badgeColor: const Color(0xFF2563EB),
                  description: 'Uncontacted inquiries awaiting follow-up.',
                ),
              ],
            ),
          ),

          // Follow-ups Pending Today section
          if (pendingFollowUps.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(
                  Icons.phone_callback_rounded,
                  color: Color(0xFFD97706),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  isToday
                      ? "Follow-ups Pending Today (${pendingFollowUps.length})"
                      : "Follow-ups on ${_formatShortDate(_selectedDate)} (${pendingFollowUps.length})",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...pendingFollowUps.map((lead) {
              return Card(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_pin_rounded,
                          color: Color(0xFFB45309),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lead.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${lead.areaCity} • ${lead.remarks.isEmpty ? "No follow-up notes" : lead.remarks}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF475569),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone_in_talk_rounded,
                            color: Color(0xFF2563EB), size: 20),
                        tooltip: 'Call ${lead.name}',
                        onPressed: () =>
                            _launchActionUrl(Uri.parse('tel:${lead.phone}')),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_rounded,
                            color: Color(0xFF16A34A), size: 20),
                        tooltip: 'WhatsApp ${lead.name}',
                        onPressed: () {
                          final clean =
                              lead.phone.replaceAll(RegExp(r'[^0-9]'), '');
                          _launchActionUrl(
                              Uri.parse('https://wa.me/$clean'));
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 20),

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
                          ? "Today's Classes (${_formatWeekday(_selectedDate)}, ${_formatShortDate(_selectedDate)})"
                          : 'Classes on ${_formatWeekday(_selectedDate)}, ${_formatShortDate(_selectedDate)}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Showing batches running on ${_formatWeekday(_selectedDate)}s. Click any batch to mark attendance.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (todaysBatches.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No classes scheduled on ${_formatWeekday(_selectedDate)}, ${_formatShortDate(_selectedDate)}.',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Batches only appear on days matching their weekly schedule (e.g. Every Day, Every Sunday, Mon-Wed-Fri). You can create or edit a batch in the "Batches" tab.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
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
                scheduleDescription: batch.scheduleDescription,
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

          // Other / Upcoming Batches (outside selected date/weekday)
          if (otherBatches.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Other Batches (Not Active on ${_formatWeekday(_selectedDate)}s)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            ...otherBatches.map((batch) {
              final enrolledStudents = allInquiries
                  .where((inq) => batch.studentIds.contains(inq.id))
                  .toList();
              final isWithinRange = batch.isWithinDateRange(_selectedDate);
              final reasonText = isWithinRange
                  ? 'Runs ${batch.scheduleDescription} (No class on ${_formatWeekday(_selectedDate)})'
                  : 'Batch duration: ${_formatShortDate(batch.startDate)} – ${_formatShortDate(batch.endDate)}';

              return Card(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  title: Text(
                    batch.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${batch.scheduleDescription} • ${batch.timings} • ${enrolledStudents.length} Student(s)\n$reasonText',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isWithinRange ? 'Off Today' : 'Out of Range',
                      style: const TextStyle(
                        fontSize: 12,
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

  Future<void> _showBatchAttendanceDialog({
    required BuildContext context,
    required Batch batch,
    required List<Inquiry> enrolledStudents,
    required Set<String>? existingPresentIds,
  }) async {
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
                    '${batch.scheduleDescription} | ${_formatFullDate(_selectedDate)} | ${batch.timings}',
                    style: const TextStyle(
                      fontSize: 13,
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
                    icon: const Icon(Icons.check_circle_outline, size: 18),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            badgeText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            description,
            style: const TextStyle(
              fontSize: 14,
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
  final String scheduleDescription;
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
    required this.scheduleDescription,
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
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 14,
            runSpacing: 10,
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
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.repeat_rounded,
                                size: 14, color: Color(0xFFB45309)),
                            const SizedBox(width: 4),
                            Text(
                              scheduleDescription,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_filled_rounded,
                            size: 15,
                            color: Color(0xFF7E22CE),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeSlot,
                            style: const TextStyle(
                              fontSize: 13,
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
                            size: 15,
                            color: Color(0xFF1D4ED8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Dates: $dateRange',
                            style: const TextStyle(
                              fontSize: 13,
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
                            size: 15,
                            color: Color(0xFF15803D),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$studentCount Joined Student(s)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (studentNames.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Students: $studentNames',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.35),
                    width: 1.2,
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
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAttendanceMarked
                          ? 'Present: $presentCount/$studentCount ($scheduleDateLabel)'
                          : 'Click to Mark Attendance',
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
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
