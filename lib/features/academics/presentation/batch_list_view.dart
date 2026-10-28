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
              onPressed: () => _showBatchFormDialog(
                context,
                ref,
                joinedStudents,
                allInquiries: allInquiries,
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
                  onPressed: () => _showBatchFormDialog(
                    context,
                    ref,
                    joinedStudents,
                    allInquiries: allInquiries,
                  ),
                  icon: const Icon(Icons.group_add_rounded),
                  label: const Text('New Batch'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (batches.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No active batches found. Click "Create Batch" to start a new cohort.',
                    style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                  ),
                ),
              ),
            ),

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
                    // Header: Batch Name & Action Buttons
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
                                  icon: Icons.currency_rupee_rounded,
                                  text: batch.fee > 0
                                      ? 'Fees: ₹${batch.fee.toStringAsFixed(0)}'
                                      : 'Fees: ₹0',
                                  bgColor: const Color(0xFFECFDF5),
                                  fgColor: const Color(0xFF047857),
                                ),
                                _InfoBadge(
                                  icon: Icons.repeat_rounded,
                                  text: batch.scheduleDescription,
                                  bgColor: const Color(0xFFFEF3C7),
                                  fgColor: const Color(0xFFB45309),
                                ),
                                _InfoBadge(
                                  icon: Icons.access_time_filled_rounded,
                                  text: batch.timings,
                                  bgColor: const Color(0xFFF3E8FF),
                                  fgColor: const Color(0xFF7E22CE),
                                ),
                                _InfoBadge(
                                  icon: Icons.date_range_rounded,
                                  text:
                                      '${_formatDate(batch.startDate)} – ${_formatDate(batch.endDate)}',
                                  bgColor: const Color(0xFFDBEAFE),
                                  fgColor: const Color(0xFF1E40AF),
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
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1E40AF),
                                side: const BorderSide(color: Color(0xFF93C5FD)),
                              ),
                              onPressed: () => _showBatchFormDialog(
                                context,
                                ref,
                                joinedStudents,
                                existingBatch: batch,
                                allInquiries: allInquiries,
                              ),
                              icon: const Icon(Icons.edit_note_rounded, size: 20),
                              label: const Text('Edit Batch'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _showManageStudentsDialog(
                                context,
                                ref,
                                batch,
                                joinedStudents,
                              ),
                              icon: const Icon(Icons.person_add_alt_1_outlined),
                              label: const Text('Students'),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                side: const BorderSide(color: Color(0xFFFCA5A5)),
                              ),
                              onPressed: () => _confirmDeleteBatchDialog(
                                context,
                                ref,
                                batch,
                              ),
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Delete Batch'),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Weekly Schedule Dots (Mon to Sun)
                    Row(
                      children: [
                        const Text(
                          'Weekly Schedule: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 4),
                        ...[1, 2, 3, 4, 5, 6, 7].map((day) {
                          final isActive =
                              batch.activeScheduleDays.contains(day);
                          const letters = [
                            'M',
                            'T',
                            'W',
                            'T',
                            'F',
                            'S',
                            'S'
                          ];
                          return Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF1E40AF)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isActive
                                    ? const Color(0xFF1E40AF)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              letters[day - 1],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isActive
                                    ? Colors.white
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: 14),
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

  Future<void> _showBatchFormDialog(
    BuildContext context,
    WidgetRef ref,
    List<Inquiry> joinedStudents, {
    Batch? existingBatch,
    List<Inquiry>? allInquiries,
  }) async {
    final isEditing = existingBatch != null;
    final nameCtrl = TextEditingController(text: existingBatch?.name ?? '');
    final feeCtrl = TextEditingController(
      text: existingBatch != null && existingBatch.fee > 0
          ? (existingBatch.fee == existingBatch.fee.roundToDouble()
              ? existingBatch.fee.toInt().toString()
              : existingBatch.fee.toString())
          : '',
    );
    DateTime startDate = existingBatch?.startDate ?? DateTime.now();
    DateTime endDate = existingBatch?.endDate ??
        DateTime.now().add(const Duration(days: 90));
    TimeOfDay startTime = const TimeOfDay(hour: 10, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 11, minute: 30);
    final timingsCtrl = TextEditingController(
      text: existingBatch?.timings ?? '10:00 AM - 11:30 AM',
    );
    final selectedStudentIds =
        Set<String>.from(existingBatch?.studentIds ?? const []);

    // Days selection: default to Daily [1,2,3,4,5,6,7] or existing batch days
    final selectedDays = Set<int>.from(
      existingBatch?.activeScheduleDays ?? const [1, 2, 3, 4, 5, 6, 7],
    );

    // Build selectable students list (joined students + already enrolled students)
    final studentMap = <String, Inquiry>{};
    for (final s in joinedStudents) {
      studentMap[s.id] = s;
    }
    if (existingBatch != null && allInquiries != null) {
      for (final s in allInquiries) {
        if (existingBatch.studentIds.contains(s.id)) {
          studentMap[s.id] = s;
        }
      }
    }
    final selectableStudents = studentMap.values.toList();

    String formatTimeOfDay(BuildContext ctx, TimeOfDay tod) {
      final localizations = MaterialLocalizations.of(ctx);
      return localizations.formatTimeOfDay(tod);
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            // Helper to get current schedule description preview
            final dummyBatch = Batch(
              id: '',
              name: '',
              startDate: startDate,
              endDate: endDate,
              timings: '',
              studentIds: const [],
              fee: 0,
              scheduleDays: selectedDays.toList(),
            );

            return AlertDialog(
              title: Text(isEditing
                  ? 'Edit Batch • ${existingBatch.name}'
                  : 'Create New Batch'),
              content: SizedBox(
                width: 560,
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
                          hintText:
                              'E.g. Sunday Masterclass or Weekday Fast-Track',
                          prefixIcon: Icon(Icons.class_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Batch Fees (₹)
                      TextField(
                        controller: feeCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Batch Fees (₹) *',
                          hintText: 'E.g. 15000',
                          prefixIcon: Icon(Icons.currency_rupee_rounded),
                          helperText:
                              'Standard course fee charged per student for this batch',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. Class Schedule / Recurring Days (Everyday, Sunday, Weekdays, etc.)
                      Text(
                        'Class Schedule (Recurring Days)',
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),

                      // Quick Preset Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _SchedulePresetChip(
                              label: 'Every Day',
                              isSelected: selectedDays.length == 7,
                              onTap: () {
                                setDialogState(() {
                                  selectedDays.clear();
                                  selectedDays.addAll([1, 2, 3, 4, 5, 6, 7]);
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                            _SchedulePresetChip(
                              label: 'Weekdays (Mon–Fri)',
                              isSelected: selectedDays.length == 5 &&
                                  selectedDays.containsAll([1, 2, 3, 4, 5]),
                              onTap: () {
                                setDialogState(() {
                                  selectedDays.clear();
                                  selectedDays.addAll([1, 2, 3, 4, 5]);
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                            _SchedulePresetChip(
                              label: 'Weekends (Sat–Sun)',
                              isSelected: selectedDays.length == 2 &&
                                  selectedDays.containsAll([6, 7]),
                              onTap: () {
                                setDialogState(() {
                                  selectedDays.clear();
                                  selectedDays.addAll([6, 7]);
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                            _SchedulePresetChip(
                              label: 'Every Sunday',
                              isSelected: selectedDays.length == 1 &&
                                  selectedDays.contains(7),
                              onTap: () {
                                setDialogState(() {
                                  selectedDays.clear();
                                  selectedDays.add(7);
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                            _SchedulePresetChip(
                              label: 'Every Saturday',
                              isSelected: selectedDays.length == 1 &&
                                  selectedDays.contains(6),
                              onTap: () {
                                setDialogState(() {
                                  selectedDays.clear();
                                  selectedDays.add(6);
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                            _SchedulePresetChip(
                              label: 'Mon, Wed, Fri',
                              isSelected: selectedDays.length == 3 &&
                                  selectedDays.containsAll([1, 3, 5]),
                              onTap: () {
                                setDialogState(() {
                                  selectedDays.clear();
                                  selectedDays.addAll([1, 3, 5]);
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                            _SchedulePresetChip(
                              label: 'Tue, Thu, Sat',
                              isSelected: selectedDays.length == 3 &&
                                  selectedDays.containsAll([2, 4, 6]),
                              onTap: () {
                                setDialogState(() {
                                  selectedDays.clear();
                                  selectedDays.addAll([2, 4, 6]);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Day-by-Day Toggle Buttons (Mon to Sun)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          (day: 1, name: 'Mon'),
                          (day: 2, name: 'Tue'),
                          (day: 3, name: 'Wed'),
                          (day: 4, name: 'Thu'),
                          (day: 5, name: 'Fri'),
                          (day: 6, name: 'Sat'),
                          (day: 7, name: 'Sun'),
                        ].map((d) {
                          final isSelected = selectedDays.contains(d.day);
                          return FilterChip(
                            label: Text(d.name),
                            selected: isSelected,
                            selectedColor: const Color(0xFFDBEAFE),
                            labelStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? const Color(0xFF1E40AF)
                                  : const Color(0xFF475569),
                            ),
                            onSelected: (checked) {
                              setDialogState(() {
                                if (checked) {
                                  selectedDays.add(d.day);
                                } else {
                                  if (selectedDays.length > 1) {
                                    selectedDays.remove(d.day);
                                  }
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),

                      // Schedule Preview Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.repeat_rounded,
                                size: 16, color: Color(0xFFB45309)),
                            const SizedBox(width: 6),
                            Text(
                              'Selected Schedule: ${dummyBatch.scheduleDescription}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. Date From & Date To
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
                                minimumSize: const Size(0, 50),
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
                              icon: const Icon(Icons.calendar_today_outlined,
                                  size: 18),
                              label: Text('From: ${_formatDate(startDate)}'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 50),
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
                              icon: const Icon(Icons.event_outlined, size: 18),
                              label: Text('To: ${_formatDate(endDate)}'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 5. Batch Timings
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
                              icon: const Icon(Icons.schedule_rounded,
                                  size: 18),
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
                              icon: const Icon(Icons.schedule_send_rounded,
                                  size: 18),
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
                          hintText: 'E.g. 10:00 AM - 11:30 AM',
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 6. Select Students with Status == Joined
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Assign Students (Status: Joined)',
                            style: Theme.of(ctx).textTheme.titleMedium,
                          ),
                          if (selectableStudents.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  if (selectedStudentIds.length ==
                                      selectableStudents.length) {
                                    selectedStudentIds.clear();
                                  } else {
                                    selectedStudentIds.addAll(
                                      selectableStudents.map((s) => s.id),
                                    );
                                  }
                                });
                              },
                              child: Text(
                                selectedStudentIds.length ==
                                        selectableStudents.length
                                    ? 'Clear All'
                                    : 'Select All (${selectableStudents.length})',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (selectableStudents.isEmpty)
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
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: selectableStudents.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final student = selectableStudents[index];
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
                    final feeValue = double.tryParse(
                            feeCtrl.text.trim().replaceAll(',', '')) ??
                        0.0;
                    final sortedDays = selectedDays.toList()..sort();
                    final timingsText = timingsCtrl.text.trim().isEmpty
                        ? '10:00 AM - 11:30 AM'
                        : timingsCtrl.text.trim();

                    if (isEditing) {
                      final updated = existingBatch.copyWith(
                        name: batchName,
                        fee: feeValue,
                        startDate: startDate,
                        endDate: endDate,
                        timings: timingsText,
                        studentIds: selectedStudentIds.toList(),
                        scheduleDays: sortedDays,
                      );
                      await ref
                          .read(batchRepositoryProvider)
                          .updateBatch(updated);
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Updated "$batchName" (Fees: ₹${feeValue.toStringAsFixed(0)}).',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } else {
                      await ref.read(batchRepositoryProvider).createBatch(
                            Batch(
                              id: '',
                              name: batchName,
                              fee: feeValue,
                              startDate: startDate,
                              endDate: endDate,
                              timings: timingsText,
                              studentIds: selectedStudentIds.toList(),
                              scheduleDays: sortedDays,
                            ),
                          );
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Created "$batchName" (Fees: ₹${feeValue.toStringAsFixed(0)}, ${dummyBatch.scheduleDescription}) with ${selectedStudentIds.length} joined student(s).',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(isEditing ? 'Update Batch' : 'Save Batch'),
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

  Future<void> _confirmDeleteBatchDialog(
    BuildContext context,
    WidgetRef ref,
    Batch batch,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Batch?'),
          content: Text(
            'Are you sure you want to delete "${batch.name}"? Enrolled students will remain in your Joined Inquiries list.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await ref
                    .read(batchRepositoryProvider)
                    .deleteBatch(batch.id, batch.name);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Deleted batch "${batch.name}".'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text('Delete Batch'),
            ),
          ],
        );
      },
    );
  }
}

class _SchedulePresetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SchedulePresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      backgroundColor:
          isSelected ? const Color(0xFF1E40AF) : const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isSelected ? Colors.white : const Color(0xFF334155),
      ),
      onPressed: onTap,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fgColor),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: fgColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
