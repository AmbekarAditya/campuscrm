import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../inquiries/data/inquiry_repository.dart';
import '../../inquiries/domain/inquiry_model.dart';
import '../data/batch_repository.dart';
import '../domain/batch_model.dart';
import 'student_profile_screen.dart';

class BatchListView extends ConsumerWidget {
  const BatchListView({super.key});

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = ref.watch(localBatchesProvider);
    final joinedStudents = ref.watch(joinedStudentsProvider);
    final List<Inquiry> allInquiries =
        ref.watch(inquiriesStreamProvider).asData?.value ??
        ref.watch(localInquiriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students & Active Batches'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showCreateBatchDialog(
                context,
                ref,
                joinedStudents,
              ),
              icon: const Icon(Icons.add_box_rounded),
              label: const Text('Create Batch'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Joined Students Summary Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFF15803D),
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${joinedStudents.length} student(s) currently have status "Joined" and are available for batch selection.',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF14532D),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showCreateBatchDialog(
                    context,
                    ref,
                    joinedStudents,
                  ),
                  icon: const Icon(Icons.group_add_rounded),
                  label: const Text('New Batch'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Batches List
          ...batches.map((batch) {
            final enrolledStudents = allInquiries
                .where((inq) => batch.studentIds.contains(inq.id))
                .toList();

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Batch Name & Edit Students Button
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              batch.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                _InfoBadge(
                                  icon: Icons.date_range_rounded,
                                  text:
                                      '${_formatDate(batch.startDate)} – ${_formatDate(batch.endDate)}',
                                  bgColor: const Color(0xFFDBEAFE),
                                  fgColor: const Color(0xFF1E40AF),
                                ),
                                _InfoBadge(
                                  icon: Icons.access_time_filled_rounded,
                                  text: batch.timings,
                                  bgColor: const Color(0xFFF3E8FF),
                                  fgColor: const Color(0xFF7E22CE),
                                ),
                                _InfoBadge(
                                  icon: Icons.people_alt_rounded,
                                  text:
                                      '${enrolledStudents.length} Joined Student(s)',
                                  bgColor: const Color(0xFFDCFCE7),
                                  fgColor: const Color(0xFF15803D),
                                ),
                              ],
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _showManageStudentsDialog(
                            context,
                            ref,
                            batch,
                            joinedStudents,
                          ),
                          icon: const Icon(Icons.person_add_alt_1_outlined),
                          label: const Text('Select Joined Students'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 14),

                    Text(
                      'Enrolled Students (Click to view profile & certificate):',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 10),

                    if (enrolledStudents.isEmpty)
                      const Text(
                        'No students assigned yet. Click "Select Joined Students" to assign.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: enrolledStudents.map((student) {
                          return ActionChip(
                            avatar: const CircleAvatar(
                              backgroundColor: Color(0xFF1E40AF),
                              child: Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            label: Text(
                              '${student.name} (${student.areaCity})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => StudentProfileScreen(
                                    studentName: student.name,
                                    phone: student.phone,
                                    email: student.email,
                                    assignedBatch:
                                        '${batch.name} (${batch.timings})',
                                    attendanceDaysPresent: 24,
                                    attendanceTotalDays: 26,
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _showCreateBatchDialog(
    BuildContext context,
    WidgetRef ref,
    List<Inquiry> joinedStudents,
  ) async {
    final nameCtrl = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 90));
    TimeOfDay startTime = const TimeOfDay(hour: 10, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 11, minute: 30);
    final timingsCtrl = TextEditingController(text: '10:00 AM - 11:30 AM');
    final selectedStudentIds = <String>{};

    String formatTimeOfDay(BuildContext ctx, TimeOfDay tod) {
      final localizations = MaterialLocalizations.of(ctx);
      return localizations.formatTimeOfDay(tod);
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Create New Batch'),
              content: SizedBox(
                width: 540,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Batch Name
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Batch Name *',
                          hintText: 'E.g. Evening Fast-Track Batch C',
                          prefixIcon: Icon(Icons.class_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Date From & Date To
                      Text(
                        'Batch Duration (Date From – Date To)',
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 52),
                              ),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: startDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2032),
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    startDate = picked;
                                    if (endDate.isBefore(startDate)) {
                                      endDate = startDate
                                          .add(const Duration(days: 30));
                                    }
                                  });
                                }
                              },
                              icon: const Icon(Icons.calendar_today_outlined),
                              label: Text('From: ${_formatDate(startDate)}'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 52),
                              ),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: endDate,
                                  firstDate: startDate,
                                  lastDate: DateTime(2032),
                                );
                                if (picked != null) {
                                  setDialogState(() => endDate = picked);
                                }
                              },
                              icon: const Icon(Icons.event_outlined),
                              label: Text('To: ${_formatDate(endDate)}'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 3. Batch Timings
                      Text(
                        'Class Timings',
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                              ),
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: ctx,
                                  initialTime: startTime,
                                );
                                if (picked != null && ctx.mounted) {
                                  setDialogState(() {
                                    startTime = picked;
                                    timingsCtrl.text =
                                        '${formatTimeOfDay(ctx, startTime)} - ${formatTimeOfDay(ctx, endTime)}';
                                  });
                                }
                              },
                              icon: const Icon(Icons.schedule_rounded),
                              label: Text(
                                'Start: ${formatTimeOfDay(ctx, startTime)}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                              ),
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: ctx,
                                  initialTime: endTime,
                                );
                                if (picked != null && ctx.mounted) {
                                  setDialogState(() {
                                    endTime = picked;
                                    timingsCtrl.text =
                                        '${formatTimeOfDay(ctx, startTime)} - ${formatTimeOfDay(ctx, endTime)}';
                                  });
                                }
                              },
                              icon: const Icon(Icons.schedule_send_rounded),
                              label: Text(
                                'End: ${formatTimeOfDay(ctx, endTime)}',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: timingsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Timings Label',
                          hintText: 'E.g. 10:00 AM - 11:30 AM (Mon–Fri)',
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 4. Select Students with Status == Joined
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Students (Status: Joined)',
                            style: Theme.of(ctx).textTheme.titleMedium,
                          ),
                          if (joinedStudents.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  if (selectedStudentIds.length ==
                                      joinedStudents.length) {
                                    selectedStudentIds.clear();
                                  } else {
                                    selectedStudentIds.addAll(
                                      joinedStudents.map((s) => s.id),
                                    );
                                  }
                                });
                              },
                              child: Text(
                                selectedStudentIds.length ==
                                        joinedStudents.length
                                    ? 'Clear All'
                                    : 'Select All (${joinedStudents.length})',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (joinedStudents.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'No leads have status "Joined" yet. Mark inquiries as "Joined" in the Inquiries tab to assign them here.',
                          ),
                        )
                      else
                        Container(
                          constraints: const BoxConstraints(maxHeight: 220),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: joinedStudents.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final student = joinedStudents[index];
                              final isSelected =
                                  selectedStudentIds.contains(student.id);
                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: (checked) {
                                  setDialogState(() {
                                    if (checked == true) {
                                      selectedStudentIds.add(student.id);
                                    } else {
                                      selectedStudentIds.remove(student.id);
                                    }
                                  });
                                },
                                title: Text(
                                  student.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${student.areaCity} • ${student.phone}',
                                ),
                                secondary: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: InquiryStatus.joined.backgroundColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    InquiryStatus.joined.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          InquiryStatus.joined.foregroundColor,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final batchName = nameCtrl.text.trim();
                    if (batchName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a Batch Name.'),
                        ),
                      );
                      return;
                    }
                    await ref.read(batchRepositoryProvider).createBatch(
                          Batch(
                            id: '',
                            name: batchName,
                            startDate: startDate,
                            endDate: endDate,
                            timings: timingsCtrl.text.trim().isEmpty
                                ? '10:00 AM - 11:30 AM'
                                : timingsCtrl.text.trim(),
                            studentIds: selectedStudentIds.toList(),
                          ),
                        );
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Created "$batchName" with ${selectedStudentIds.length} joined student(s).',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Save Batch'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showManageStudentsDialog(
    BuildContext context,
    WidgetRef ref,
    Batch batch,
    List<Inquiry> joinedStudents,
  ) async {
    final selectedIds = Set<String>.from(batch.studentIds);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text('Select Joined Students • ${batch.name}'),
              content: SizedBox(
                width: 480,
                child: joinedStudents.isEmpty
                    ? const Text(
                        'No students currently have status "Joined". Change a lead status to "Joined" in Inquiries first.',
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: joinedStudents.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final student = joinedStudents[index];
                          final isChecked = selectedIds.contains(student.id);
                          return CheckboxListTile(
                            value: isChecked,
                            title: Text(
                              student.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle:
                                Text('${student.areaCity} • ${student.phone}'),
                            onChanged: (checked) {
                              setDialogState(() {
                                if (checked == true) {
                                  selectedIds.add(student.id);
                                } else {
                                  selectedIds.remove(student.id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await ref.read(batchRepositoryProvider).updateBatchStudents(
                          batch.id,
                          batch.name,
                          selectedIds.toList(),
                        );
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Update Batch Students'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color bgColor;
  final Color fgColor;

  const _InfoBadge({
    required this.icon,
    required this.text,
    required this.bgColor,
    required this.fgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fgColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: fgColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
