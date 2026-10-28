import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/activity_logger.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Institute Overview'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMarkAttendanceDialog(context, ref),
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
                const _ActionAlertRow(
                  badgeText: '5 New Leads',
                  badgeColor: Color(0xFF2563EB),
                  description: 'Uncontacted inquiries from the last 24 hours.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Today's Classes List View
          Text(
            "Today's Classes",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const _TodayClassTile(
            timeSlot: '09:30 AM - 11:00 AM',
            batchName: 'Morning Foundation Batch A',
            room: 'Room 101',
            studentCount: 18,
            statusLabel: 'In Progress',
            statusColor: Color(0xFF15803D),
          ),
          const _TodayClassTile(
            timeSlot: '11:30 AM - 01:00 PM',
            batchName: 'Advanced Practical Batch B',
            room: 'Lab 2',
            studentCount: 12,
            statusLabel: 'Upcoming',
            statusColor: Color(0xFF1D4ED8),
          ),
          const _TodayClassTile(
            timeSlot: '04:00 PM - 05:30 PM',
            batchName: 'Evening Fast-Track Cohort',
            room: 'Room 102',
            studentCount: 15,
            statusLabel: 'Upcoming',
            statusColor: Color(0xFF1D4ED8),
          ),
        ],
      ),
    );
  }

  Future<void> _showMarkAttendanceDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final attendance = <String, bool>{
      'Aarav Sharma': true,
      'Priya Nair': true,
      'Rohan Mehta': true,
      'Sneha Kulkarni': false,
      'Kabir Malhotra': true,
    };

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Mark Daily Attendance • Morning Batch A'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: attendance.entries.map((entry) {
                    return CheckboxListTile(
                      title: Text(entry.key),
                      subtitle: Text(entry.value ? 'Present' : 'Absent'),
                      value: entry.value,
                      onChanged: (checked) {
                        if (checked != null) {
                          setModalState(() => attendance[entry.key] = checked);
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final presentCount =
                        attendance.values.where((v) => v).length;
                    await ref.read(activityLoggerProvider).log(
                          actorName: 'Owner',
                          action:
                              'Marked daily attendance ($presentCount/${attendance.length} present)',
                          category: 'Attendance',
                        );
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Attendance saved: $presentCount/${attendance.length} students present.',
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
  final String timeSlot;
  final String batchName;
  final String room;
  final int studentCount;
  final String statusLabel;
  final Color statusColor;

  const _TodayClassTile({
    required this.timeSlot,
    required this.batchName,
    required this.room,
    required this.studentCount,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        title: Text(
          batchName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('$timeSlot  •  $room  •  $studentCount Students'),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
