import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/activity_logger.dart';

class StudentLedgerItem {
  final String student;
  final double totalFee;
  final double paidAmount;
  final String dueDate;

  const StudentLedgerItem({
    required this.student,
    required this.totalFee,
    required this.paidAmount,
    required this.dueDate,
  });

  StudentLedgerItem copyWith({double? paidAmount, String? dueDate}) {
    return StudentLedgerItem(
      student: student,
      totalFee: totalFee,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}

class PaymentsLedgerScreen extends ConsumerStatefulWidget {
  const PaymentsLedgerScreen({super.key});

  @override
  ConsumerState<PaymentsLedgerScreen> createState() =>
      _PaymentsLedgerScreenState();
}

class _PaymentsLedgerScreenState extends ConsumerState<PaymentsLedgerScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedStudent = 'Priya Nair';
  String _selectedMethod = 'UPI';
  DateTime _selectedDate = DateTime.now();

  late List<StudentLedgerItem> _dueThisWeek;

  @override
  void initState() {
    super.initState();
    _dueThisWeek = [
      const StudentLedgerItem(
        student: 'Priya Nair',
        totalFee: 25000.0,
        paidAmount: 15000.0,
        dueDate: 'Due Tomorrow',
      ),
      const StudentLedgerItem(
        student: 'Rohan Mehta',
        totalFee: 18000.0,
        paidAmount: 9000.0,
        dueDate: 'Due Friday',
      ),
      const StudentLedgerItem(
        student: 'Sneha Kulkarni',
        totalFee: 30000.0,
        paidAmount: 24000.0,
        dueDate: 'Due Saturday',
      ),
    ];
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _recordPayment() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid payment amount.')),
      );
      return;
    }

    setState(() {
      _dueThisWeek = _dueThisWeek.map((entry) {
        if (entry.student == _selectedStudent) {
          final updatedPaid =
              (entry.paidAmount + amount).clamp(0.0, entry.totalFee);
          return entry.copyWith(
            paidAmount: updatedPaid,
            dueDate: updatedPaid >= entry.totalFee ? 'Paid in Full' : entry.dueDate,
          );
        }
        return entry;
      }).toList();
    });

    await ref.read(activityLoggerProvider).log(
          actorName: 'Front Desk',
          action:
              'Recorded ₹${amount.toStringAsFixed(0)} ($_selectedMethod) for $_selectedStudent',
          category: 'Payments',
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recorded ₹${amount.toStringAsFixed(0)} for $_selectedStudent via $_selectedMethod',
          ),
        ),
      );
      _amountController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 640;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments Ledger'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Record Payment Form (Adaptive layout for mobile & tablet)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.add_card_rounded,
                        color: Color(0xFF1E40AF),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Record Payment',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (isMobile) ...[
                    // Mobile: clean vertical stack
                    DropdownButtonFormField<String>(
                      initialValue: _selectedStudent,
                      isDense: true,
                      decoration: const InputDecoration(labelText: 'Student'),
                      items: _dueThisWeek
                          .map((e) => DropdownMenuItem(
                                value: e.student,
                                child: Text(e.student),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedStudent = value);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              isDense: true,
                              labelText: 'Amount (₹)',
                              prefixIcon: Icon(Icons.currency_rupee, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
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
                              DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedMethod = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            icon: const Icon(Icons.calendar_today_outlined,
                                size: 18),
                            label: Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _recordPayment,
                            icon: const Icon(Icons.check_circle_outline,
                                size: 18),
                            label: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Tablet / Web: horizontal flow
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 200,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedStudent,
                            isDense: true,
                            decoration:
                                const InputDecoration(labelText: 'Student'),
                            items: _dueThisWeek
                                .map((e) => DropdownMenuItem(
                                      value: e.student,
                                      child: Text(e.student),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedStudent = value);
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          width: 170,
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              isDense: true,
                              labelText: 'Amount (₹)',
                              prefixIcon:
                                  Icon(Icons.currency_rupee, size: 18),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedMethod,
                            isDense: true,
                            decoration:
                                const InputDecoration(labelText: 'Method'),
                            items: const [
                              DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                              DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedMethod = value);
                              }
                            },
                          ),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(140, 48),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_today_outlined,
                              size: 18),
                          label: Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _recordPayment,
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Save Payment'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Due This Week List
          Text(
            'Due This Week',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          ..._dueThisWeek.map((entry) {
            final progress = (entry.paidAmount / entry.totalFee).clamp(0.0, 1.0);
            final isPaidFull = entry.paidAmount >= entry.totalFee;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.student,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isPaidFull
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            entry.dueDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: isPaidFull
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFB45309),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(6),
                      backgroundColor: const Color(0xFFE2E8F0),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Paid ₹${entry.paidAmount.toStringAsFixed(0)} of ₹${entry.totalFee.toStringAsFixed(0)} '
                      '(Balance: ₹${(entry.totalFee - entry.paidAmount).toStringAsFixed(0)})',
                      style: Theme.of(context).textTheme.bodyMedium,
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
