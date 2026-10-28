import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../academics/data/batch_repository.dart';
import '../../academics/domain/batch_model.dart';
import '../../inquiries/data/inquiry_repository.dart';
import '../../inquiries/domain/inquiry_model.dart';
import '../data/payment_repository.dart';
import '../domain/payment_model.dart';

class PaymentsLedgerScreen extends ConsumerStatefulWidget {
  const PaymentsLedgerScreen({super.key});

  @override
  ConsumerState<PaymentsLedgerScreen> createState() =>
      _PaymentsLedgerScreenState();
}

class _PaymentsLedgerScreenState extends ConsumerState<PaymentsLedgerScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String? _selectedStudentId;
  String? _selectedBatchId;
  String _selectedMethod = 'UPI';
  DateTime _selectedDate = DateTime.now();

  PaymentStatus? _statusFilter;
  String _searchQuery = '';

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatShortDate(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Automatically detects the student's enrolled batch, looks up the batch fees,
  /// calculates the remaining balance due, and pre-fills the payment amount.
  void _onStudentSelected(
    String studentId,
    List<Inquiry> allInquiries,
    List<Batch> allBatches,
    List<PaymentRecord> allPayments,
  ) {
    setState(() {
      _selectedStudentId = studentId;

      final enrolledBatches = allBatches
          .where((b) => b.studentIds.contains(studentId))
          .toList();

      if (enrolledBatches.isNotEmpty) {
        final batch = enrolledBatches.first;
        _selectedBatchId = batch.id;

        final paidForBatch = allPayments
            .where((p) => p.studentId == studentId && p.batchId == batch.id)
            .fold<double>(0.0, (sum, p) => sum + p.amount);

        final balanceDue =
            (batch.fee - paidForBatch).clamp(0.0, double.infinity);

        if (balanceDue > 0) {
          _amountController.text = balanceDue == balanceDue.roundToDouble()
              ? balanceDue.toInt().toString()
              : balanceDue.toStringAsFixed(0);
        } else if (batch.fee > 0) {
          _amountController.text = batch.fee == batch.fee.roundToDouble()
              ? batch.fee.toInt().toString()
              : batch.fee.toStringAsFixed(0);
        } else {
          _amountController.clear();
        }
      } else {
        _selectedBatchId = null;
        _amountController.clear();
      }
    });
  }

  void _onBatchChanged(
    String batchId,
    List<Batch> allBatches,
    List<PaymentRecord> allPayments,
  ) {
    setState(() {
      _selectedBatchId = batchId;
      final batch = allBatches.firstWhere((b) => b.id == batchId);

      if (_selectedStudentId != null) {
        final paidForBatch = allPayments
            .where(
              (p) =>
                  p.studentId == _selectedStudentId && p.batchId == batch.id,
            )
            .fold<double>(0.0, (sum, p) => sum + p.amount);

        final balanceDue =
            (batch.fee - paidForBatch).clamp(0.0, double.infinity);

        if (balanceDue > 0) {
          _amountController.text = balanceDue == balanceDue.roundToDouble()
              ? balanceDue.toInt().toString()
              : balanceDue.toStringAsFixed(0);
        } else if (batch.fee > 0) {
          _amountController.text = batch.fee == batch.fee.roundToDouble()
              ? batch.fee.toInt().toString()
              : batch.fee.toStringAsFixed(0);
        }
      }
    });
  }

  Future<void> _openSearchableStudentPicker(
    BuildContext context,
    List<Inquiry> allStudents,
    List<Batch> allBatches,
    List<PaymentRecord> allPayments,
  ) async {
    final searchCtrl = TextEditingController();
    await showDialog<Inquiry>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final query = searchCtrl.text.trim().toLowerCase();
            final filtered = allStudents.where((s) {
              if (query.isEmpty) return true;
              final nameMatch = s.name.toLowerCase().contains(query);
              final phoneMatch = s.phone.toLowerCase().contains(query);
              final cityMatch = s.areaCity.toLowerCase().contains(query);

              final enrolled = allBatches
                  .where((b) => b.studentIds.contains(s.id))
                  .map((b) => b.name.toLowerCase())
                  .join(' ');
              final batchMatch = enrolled.contains(query);

              return nameMatch || phoneMatch || cityMatch || batchMatch;
            }).toList();

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.search_rounded, color: Color(0xFF1E40AF)),
                  SizedBox(width: 8),
                  Text('Search & Select Student'),
                ],
              ),
              content: SizedBox(
                width: 500,
                height: 480,
                child: Column(
                  children: [
                    TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Type student name, phone, or batch...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  searchCtrl.clear();
                                  setModalState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'No matching students found.',
                                style: TextStyle(color: Color(0xFF64748B)),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (itemCtx, index) {
                                final student = filtered[index];
                                final isSelected =
                                    student.id == _selectedStudentId;

                                final enrolledBatches = allBatches
                                    .where((b) => b.studentIds.contains(student.id))
                                    .toList();

                                final batchLabel = enrolledBatches.isNotEmpty
                                    ? '${enrolledBatches.first.name} (Fee: ₹${enrolledBatches.first.fee.toStringAsFixed(0)})'
                                    : 'No batch assigned';

                                return ListTile(
                                  selected: isSelected,
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? const Color(0xFF1E40AF)
                                        : const Color(0xFFE2E8F0),
                                    foregroundColor: isSelected
                                        ? Colors.white
                                        : const Color(0xFF1E293B),
                                    child: Text(_getInitials(student.name)),
                                  ),
                                  title: Text(
                                    student.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${student.phone} • $batchLabel',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: enrolledBatches.isNotEmpty
                                          ? const Color(0xFF1D4ED8)
                                          : const Color(0xFF64748B),
                                      fontWeight: enrolledBatches.isNotEmpty
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  onTap: () {
                                    Navigator.of(dialogCtx).pop(student);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    ).then((picked) {
      if (picked != null) {
        _onStudentSelected(
          picked.id,
          allStudents,
          allBatches,
          allPayments,
        );
      }
    });
  }

  Future<void> _recordPayment(
    List<Inquiry> allInquiries,
    List<Batch> allBatches,
  ) async {
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a student from the dropdown or search.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final amountText = _amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid payment amount.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final student = allInquiries.firstWhere(
      (s) => s.id == _selectedStudentId,
      orElse: () => Inquiry(
        id: _selectedStudentId!,
        name: 'Student',
        phone: '',
        email: '',
        areaCity: '',
        status: InquiryStatus.joined,
        remarks: '',
        createdAt: DateTime.now(),
      ),
    );

    final batch = allBatches.firstWhere(
      (b) => b.id == _selectedBatchId,
      orElse: () => Batch(
        id: _selectedBatchId ?? '',
        name: 'General Cohort',
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        timings: '',
        studentIds: const [],
        fee: amount,
      ),
    );

    final record = PaymentRecord(
      id: '',
      studentId: student.id,
      studentName: student.name,
      batchId: batch.id,
      batchName: batch.name,
      amount: amount,
      paymentMethod: _selectedMethod,
      paymentDate: _selectedDate,
      notes: _notesController.text.trim(),
    );

    await ref.read(paymentRepositoryProvider).recordPayment(record);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recorded ₹${amount.toStringAsFixed(0)} ($_selectedMethod) for ${student.name} (${batch.name}).',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF15803D),
        ),
      );
      _amountController.clear();
      _notesController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final allBatches = ref.watch(localBatchesProvider);
    final allPayments = ref.watch(localPaymentsProvider);
    final List<Inquiry> allInquiries =
        ref.watch(inquiriesStreamProvider).asData?.value ??
            ref.watch(localInquiriesProvider);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 720;
    final isMobile = screenWidth < 640;

    // Filter available students for selection: joined students or enrolled in batches
    final enrolledStudentIds =
        allBatches.expand((b) => b.studentIds).toSet();
    final availableStudents = allInquiries.where((inq) {
      return inq.status == InquiryStatus.joined ||
          enrolledStudentIds.contains(inq.id);
    }).toList();

    // Default select first student if not yet chosen
    if (_selectedStudentId == null && availableStudents.isNotEmpty) {
      _selectedStudentId = availableStudents.first.id;
      final enrolled = allBatches
          .where((b) => b.studentIds.contains(_selectedStudentId))
          .toList();
      if (enrolled.isNotEmpty) {
        _selectedBatchId = enrolled.first.id;
        final batch = enrolled.first;
        final paid = allPayments
            .where((p) =>
                p.studentId == _selectedStudentId && p.batchId == batch.id)
            .fold<double>(0.0, (sum, p) => sum + p.amount);
        final due = (batch.fee - paid).clamp(0.0, double.infinity);
        _amountController.text = (due > 0 ? due : batch.fee).toStringAsFixed(0);
      }
    }

    final selectedStudent = _selectedStudentId != null
        ? allInquiries.firstWhere(
            (s) => s.id == _selectedStudentId,
            orElse: () => availableStudents.isNotEmpty
                ? availableStudents.first
                : allInquiries.first,
          )
        : null;

    final studentEnrolledBatches = _selectedStudentId != null
        ? allBatches
            .where((b) => b.studentIds.contains(_selectedStudentId))
            .toList()
        : <Batch>[];

    final selectedBatch = studentEnrolledBatches.firstWhere(
      (b) => b.id == _selectedBatchId,
      orElse: () => studentEnrolledBatches.isNotEmpty
          ? studentEnrolledBatches.first
          : (allBatches.isNotEmpty
              ? allBatches.first
              : Batch(
                  id: '',
                  name: 'No Batch Assigned',
                  startDate: DateTime.now(),
                  endDate: DateTime.now(),
                  timings: '',
                  studentIds: const [],
                  fee: 0.0,
                )),
    );

    final currentStudentPaid = (_selectedStudentId != null &&
            selectedBatch.id.isNotEmpty)
        ? allPayments
            .where((p) =>
                p.studentId == _selectedStudentId &&
                p.batchId == selectedBatch.id)
            .fold<double>(0.0, (sum, p) => sum + p.amount)
        : 0.0;
    final currentStudentDue =
        (selectedBatch.fee - currentStudentPaid).clamp(0.0, double.infinity);

    // Build the complete Student Payment Ledger list for all batch enrollments
    final List<StudentPaymentLedger> allLedgerItems = [];
    for (final batch in allBatches) {
      for (final studentId in batch.studentIds) {
        final student = allInquiries.firstWhere(
          (s) => s.id == studentId,
          orElse: () => Inquiry(
            id: studentId,
            name: 'Student ($studentId)',
            phone: '',
            email: '',
            areaCity: '',
            status: InquiryStatus.joined,
            remarks: '',
            createdAt: DateTime.now(),
          ),
        );

        final studentPayments = allPayments
            .where(
              (p) =>
                  p.studentId == studentId &&
                  (p.batchId == batch.id || p.batchId.isEmpty),
            )
            .toList();

        final paidAmount = studentPayments.fold<double>(
          0.0,
          (sum, p) => sum + p.amount,
        );

        DateTime? lastDate;
        if (studentPayments.isNotEmpty) {
          studentPayments
              .sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
          lastDate = studentPayments.first.paymentDate;
        }

        allLedgerItems.add(
          StudentPaymentLedger(
            studentId: student.id,
            studentName: student.name,
            studentPhone: student.phone,
            studentCity: student.areaCity,
            batchId: batch.id,
            batchName: batch.name,
            batchTimings: batch.timings,
            batchSchedule: batch.scheduleDescription,
            totalFee: batch.fee,
            paidAmount: paidAmount,
            lastPaymentDate: lastDate,
          ),
        );
      }
    }

    // Filter ledger items by search query and status filter
    final filteredLedger = allLedgerItems.where((item) {
      final matchesStatus =
          _statusFilter == null || item.status == _statusFilter;
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          item.studentName.toLowerCase().contains(q) ||
          item.batchName.toLowerCase().contains(q) ||
          item.studentPhone.toLowerCase().contains(q) ||
          item.studentCity.toLowerCase().contains(q);
      return matchesStatus && matchesSearch;
    }).toList();

    final dueCount =
        allLedgerItems.where((i) => i.status == PaymentStatus.due).length;
    final partialCount = allLedgerItems
        .where((i) => i.status == PaymentStatus.partiallyPaid)
        .length;
    final paidCount =
        allLedgerItems.where((i) => i.status == PaymentStatus.paid).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments & Fee Ledger'),
        centerTitle: false,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 20 : 12,
          vertical: 14,
        ),
        children: [
          // 1. RECORD PAYMENT CARD
          Card(
            child: Padding(
              padding: EdgeInsets.all(isWide ? 20 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.add_card_rounded,
                          color: Color(0xFF1E40AF),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Record Payment',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontSize: isMobile ? 17 : 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const Text(
                              'Batch fee auto-fills when student is selected',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Student Selector Row (Dropdown + Instant Search Button)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(_selectedStudentId),
                          initialValue: _selectedStudentId,
                          isDense: true,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Select Student *',
                            prefixIcon: Icon(Icons.person_search_rounded, size: 20),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          items: availableStudents.map((s) {
                            final batches = allBatches
                                .where((b) => b.studentIds.contains(s.id))
                                .toList();
                            final batchInfo = batches.isNotEmpty
                                ? ' • ${batches.first.name}'
                                : '';
                            return DropdownMenuItem<String>(
                              value: s.id,
                              child: Text(
                                '${s.name}$batchInfo',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13.5),
                              ),
                            );
                          }).toList(),
                          onChanged: (id) {
                            if (id != null) {
                              _onStudentSelected(
                                id,
                                allInquiries,
                                allBatches,
                                allPayments,
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Responsive Search Button: Icon button on mobile to save space
                      if (isMobile)
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            backgroundColor: const Color(0xFFEFF6FF),
                            foregroundColor: const Color(0xFF1E40AF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: Color(0xFFBFDBFE)),
                            ),
                          ),
                          tooltip: 'Search Student',
                          onPressed: () => _openSearchableStudentPicker(
                            context,
                            availableStudents,
                            allBatches,
                            allPayments,
                          ),
                          icon: const Icon(Icons.search_rounded, size: 22),
                        )
                      else
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: () => _openSearchableStudentPicker(
                            context,
                            availableStudents,
                            allBatches,
                            allPayments,
                          ),
                          icon: const Icon(Icons.search_rounded, size: 18),
                          label: const Text('Search'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Auto-filled Enrolled Batch & 3-Column Fee Stat Boxes
                  if (selectedStudent != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Batch Name header with Switcher
                          Row(
                            children: [
                              const Icon(
                                Icons.school_rounded,
                                size: 16,
                                color: Color(0xFF1E40AF),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  studentEnrolledBatches.isNotEmpty
                                      ? 'Enrolled: ${selectedBatch.name}'
                                      : 'No Active Batch Assigned',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (studentEnrolledBatches.length > 1) ...[
                                const SizedBox(width: 4),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedBatchId,
                                    isDense: true,
                                    icon: const Icon(
                                      Icons.swap_horiz_rounded,
                                      size: 16,
                                      color: Color(0xFF1E40AF),
                                    ),
                                    items: studentEnrolledBatches.map((b) {
                                      return DropdownMenuItem<String>(
                                        value: b.id,
                                        child: Text(
                                          b.name,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (newBatchId) {
                                      if (newBatchId != null) {
                                        _onBatchChanged(
                                          newBatchId,
                                          allBatches,
                                          allPayments,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 3 Balanced Stat Boxes (Never overflows on mobile)
                          Row(
                            children: [
                              Expanded(
                                child: _FeeStatBox(
                                  label: 'Batch Fees',
                                  amount: '₹${selectedBatch.fee.toStringAsFixed(0)}',
                                  color: const Color(0xFF0F172A),
                                  bgColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _FeeStatBox(
                                  label: 'Paid So Far',
                                  amount: '₹${currentStudentPaid.toStringAsFixed(0)}',
                                  color: const Color(0xFF15803D),
                                  bgColor: const Color(0xFFF0FDF4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _FeeStatBox(
                                  label: 'Balance Due',
                                  amount: '₹${currentStudentDue.toStringAsFixed(0)}',
                                  color: currentStudentDue > 0
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF15803D),
                                  bgColor: currentStudentDue > 0
                                      ? const Color(0xFFFEF2F2)
                                      : const Color(0xFFF0FDF4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Payment Form Inputs
                  if (isMobile) ...[
                    // MOBILE VERTICAL FLOW
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Payment Amount (₹) *',
                        prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                        isDense: true,
                        suffixIcon: currentStudentDue > 0
                            ? TextButton(
                                onPressed: () {
                                  _amountController.text =
                                      currentStudentDue.toStringAsFixed(0);
                                },
                                child: const Text(
                                  'Full Due',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Payment Method dropdown
                        Expanded(
                          flex: 5,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedMethod,
                            isDense: true,
                            decoration: const InputDecoration(
                              labelText: 'Method',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                              DropdownMenuItem(
                                  value: 'Cash', child: Text('Cash')),
                              DropdownMenuItem(
                                  value: 'Card', child: Text('Card')),
                              DropdownMenuItem(
                                  value: 'Bank Transfer',
                                  child: Text('Bank Transfer')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedMethod = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Date picker button styled cleanly
                        Expanded(
                          flex: 5,
                          child: InkWell(
                            onTap: () async {
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
                            borderRadius: BorderRadius.circular(10),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 14,
                                    color: Color(0xFF1E40AF),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _formatDate(_selectedDate),
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Remarks / Transaction Reference',
                        hintText: 'E.g. Installment 1 of 2 or UPI Ref',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                        onPressed: () => _recordPayment(
                          allInquiries,
                          allBatches,
                        ),
                        icon: const Icon(Icons.check_circle_outline_rounded,
                            size: 18),
                        label: const Text(
                          'Save Payment Record',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ] else ...[
                    // TABLET & WEB HORIZONTAL FLOW
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _amountController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Payment Amount (₹) *',
                              prefixIcon:
                                  const Icon(Icons.currency_rupee, size: 20),
                              suffixIcon: currentStudentDue > 0
                                  ? TextButton(
                                      onPressed: () {
                                        _amountController.text =
                                            currentStudentDue.toStringAsFixed(0);
                                      },
                                      child: const Text('Full Due'),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedMethod,
                            isDense: true,
                            decoration: const InputDecoration(
                              labelText: 'Method',
                            ),
                            items: const [
                              DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                              DropdownMenuItem(
                                  value: 'Cash', child: Text('Cash')),
                              DropdownMenuItem(
                                  value: 'Card', child: Text('Card')),
                              DropdownMenuItem(
                                  value: 'Bank Transfer',
                                  child: Text('Bank Transfer')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedMethod = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 50),
                            ),
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
                            icon: const Icon(Icons.calendar_today_outlined,
                                size: 16),
                            label: Text(_formatDate(_selectedDate)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(160, 50),
                          ),
                          onPressed: () => _recordPayment(
                            allInquiries,
                            allBatches,
                          ),
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text(
                            'Save Payment',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Remarks / Transaction Reference (Optional)',
                        hintText: 'E.g. Installment 1 of 2 or UPI Ref 410293',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. STUDENT NAME, FEES, BATCH & PAYMENT STATUS LEDGER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Student Fee Ledger',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: isMobile ? 18 : 22,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${filteredLedger.length} Record(s)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search student, batch, city or phone...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 10),

          // Filter Chips: All, Due, Partially Paid, Paid (Scrollable on mobile)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: Text('All (${allLedgerItems.length})'),
                  selected: _statusFilter == null,
                  onSelected: (selected) {
                    if (selected) setState(() => _statusFilter = null);
                  },
                ),
                const SizedBox(width: 6),
                FilterChip(
                  avatar: const Icon(
                    Icons.warning_amber_rounded,
                    size: 15,
                    color: Color(0xFFDC2626),
                  ),
                  label: Text('Due ($dueCount)'),
                  selected: _statusFilter == PaymentStatus.due,
                  selectedColor: const Color(0xFFFEE2E2),
                  onSelected: (selected) {
                    setState(
                      () => _statusFilter =
                          selected ? PaymentStatus.due : null,
                    );
                  },
                ),
                const SizedBox(width: 6),
                FilterChip(
                  avatar: const Icon(
                    Icons.timelapse_rounded,
                    size: 15,
                    color: Color(0xFFB45309),
                  ),
                  label: Text('Partial ($partialCount)'),
                  selected: _statusFilter == PaymentStatus.partiallyPaid,
                  selectedColor: const Color(0xFFFEF3C7),
                  onSelected: (selected) {
                    setState(
                      () => _statusFilter =
                          selected ? PaymentStatus.partiallyPaid : null,
                    );
                  },
                ),
                const SizedBox(width: 6),
                FilterChip(
                  avatar: const Icon(
                    Icons.check_circle_rounded,
                    size: 15,
                    color: Color(0xFF15803D),
                  ),
                  label: Text('Paid ($paidCount)'),
                  selected: _statusFilter == PaymentStatus.paid,
                  selectedColor: const Color(0xFFDCFCE7),
                  onSelected: (selected) {
                    setState(
                      () => _statusFilter =
                          selected ? PaymentStatus.paid : null,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Ledger Items List
          if (filteredLedger.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        size: 44,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No students match "$_searchQuery".'
                            : 'No payment records match the selected filter.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...filteredLedger.map((item) {
              final status = item.status;
              return Card(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Avatar, Student Name, City/Phone & Status Badge
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: status.backgroundColor,
                            foregroundColor: status.foregroundColor,
                            radius: isMobile ? 17 : 20,
                            child: Text(
                              _getInitials(item.studentName),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: isMobile ? 12 : 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.studentName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontSize: isMobile ? 14.5 : 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.studentCity} • ${item.studentPhone}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Compact Status Badge on Mobile
                          _StatusBadge(status: status, isMobile: isMobile),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Enrolled Batch & Timings Row
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.class_rounded,
                              size: 14,
                              color: Color(0xFF7E22CE),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${item.batchName} (${item.batchTimings})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 3-Column Balanced Financial Stat Boxes
                      Row(
                        children: [
                          Expanded(
                            child: _FeeStatBox(
                              label: 'Total Fee',
                              amount: '₹${item.totalFee.toStringAsFixed(0)}',
                              color: const Color(0xFF0F172A),
                              bgColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _FeeStatBox(
                              label: 'Paid',
                              amount: '₹${item.paidAmount.toStringAsFixed(0)}',
                              color: const Color(0xFF15803D),
                              bgColor: const Color(0xFFF0FDF4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _FeeStatBox(
                              label: 'Balance Due',
                              amount: '₹${item.balanceDue.toStringAsFixed(0)}',
                              color: item.balanceDue > 0
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF15803D),
                              bgColor: item.balanceDue > 0
                                  ? const Color(0xFFFEF2F2)
                                  : const Color(0xFFF0FDF4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Progress Bar
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: item.progress,
                                minHeight: 8,
                                backgroundColor: const Color(0xFFE2E8F0),
                                color: status == PaymentStatus.paid
                                    ? const Color(0xFF15803D)
                                    : (status == PaymentStatus.partiallyPaid
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFFEF4444)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${(item.progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: status.foregroundColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Action Row: Last payment note & Quick Record Payment Button
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.lastPaymentDate != null
                                  ? 'Last paid: ${_formatShortDate(item.lastPaymentDate!)}'
                                  : 'No payments yet',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.balanceDue > 0) ...[
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E40AF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                minimumSize: const Size(0, 32),
                                elevation: 0,
                              ),
                              onPressed: () {
                                _onStudentSelected(
                                  item.studentId,
                                  allInquiries,
                                  allBatches,
                                  allPayments,
                                );
                                _onBatchChanged(
                                  item.batchId,
                                  allBatches,
                                  allPayments,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Loaded ${item.studentName} with due balance ₹${item.balanceDue.toStringAsFixed(0)}.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.payment_rounded,
                                size: 14,
                              ),
                              label: Text(
                                'Pay Due ₹${item.balanceDue.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
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
}

class _FeeStatBox extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final Color bgColor;

  const _FeeStatBox({
    required this.label,
    required this.amount,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final PaymentStatus status;
  final bool isMobile;

  const _StatusBadge({
    required this.status,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final label = isMobile
        ? (status == PaymentStatus.partiallyPaid
            ? 'Partial'
            : (status == PaymentStatus.paid ? 'Paid' : 'Due'))
        : status.label;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 10,
        vertical: isMobile ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: status.borderColor,
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: isMobile ? 13 : 15,
            color: status.foregroundColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.w800,
              color: status.foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
