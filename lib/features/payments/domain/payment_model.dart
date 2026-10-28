import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum PaymentStatus {
  paid,
  partiallyPaid,
  due,
}

extension PaymentStatusX on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.paid:
        return 'Paid in Full';
      case PaymentStatus.partiallyPaid:
        return 'Partially Paid';
      case PaymentStatus.due:
        return 'Payment Due';
    }
  }

  Color get foregroundColor {
    switch (this) {
      case PaymentStatus.paid:
        return const Color(0xFF15803D); // Emerald Green
      case PaymentStatus.partiallyPaid:
        return const Color(0xFFB45309); // Amber
      case PaymentStatus.due:
        return const Color(0xFFDC2626); // Crimson Red
    }
  }

  Color get backgroundColor {
    switch (this) {
      case PaymentStatus.paid:
        return const Color(0xFFDCFCE7); // Light green
      case PaymentStatus.partiallyPaid:
        return const Color(0xFFFEF3C7); // Light amber
      case PaymentStatus.due:
        return const Color(0xFFFEE2E2); // Light red
    }
  }

  Color get borderColor {
    switch (this) {
      case PaymentStatus.paid:
        return const Color(0xFF86EFAC);
      case PaymentStatus.partiallyPaid:
        return const Color(0xFFFDE68A);
      case PaymentStatus.due:
        return const Color(0xFFFCA5A5);
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentStatus.paid:
        return Icons.check_circle_rounded;
      case PaymentStatus.partiallyPaid:
        return Icons.timelapse_rounded;
      case PaymentStatus.due:
        return Icons.warning_amber_rounded;
    }
  }
}

class PaymentRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String batchId;
  final String batchName;
  final double amount;
  final String paymentMethod; // 'UPI', 'Cash', 'Card', 'Bank Transfer'
  final DateTime paymentDate;
  final String notes;

  const PaymentRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.batchId,
    required this.batchName,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    this.notes = '',
  });

  PaymentRecord copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? batchId,
    String? batchName,
    double? amount,
    String? paymentMethod,
    DateTime? paymentDate,
    String? notes,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      batchId: batchId ?? this.batchId,
      batchName: batchName ?? this.batchName,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'batchId': batchId,
      'batchName': batchName,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'notes': notes,
    };
  }

  factory PaymentRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final ts = data['paymentDate'] as Timestamp?;
    return PaymentRecord(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      batchId: data['batchId'] as String? ?? '',
      batchName: data['batchName'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['paymentMethod'] as String? ?? 'UPI',
      paymentDate: ts?.toDate() ?? DateTime.now(),
      notes: data['notes'] as String? ?? '',
    );
  }
}

class StudentPaymentLedger {
  final String studentId;
  final String studentName;
  final String studentPhone;
  final String studentCity;
  final String batchId;
  final String batchName;
  final String batchTimings;
  final String batchSchedule;
  final double totalFee;
  final double paidAmount;
  final DateTime? lastPaymentDate;

  const StudentPaymentLedger({
    required this.studentId,
    required this.studentName,
    required this.studentPhone,
    required this.studentCity,
    required this.batchId,
    required this.batchName,
    required this.batchTimings,
    required this.batchSchedule,
    required this.totalFee,
    required this.paidAmount,
    this.lastPaymentDate,
  });

  double get balanceDue =>
      (totalFee - paidAmount).clamp(0.0, double.infinity);

  double get progress =>
      totalFee > 0 ? (paidAmount / totalFee).clamp(0.0, 1.0) : 0.0;

  PaymentStatus get status {
    if (totalFee > 0 && paidAmount >= totalFee) {
      return PaymentStatus.paid;
    } else if (paidAmount > 0) {
      return PaymentStatus.partiallyPaid;
    } else {
      return PaymentStatus.due;
    }
  }
}
