import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Lead lifecycle statuses with high-contrast color coding for quick scanning.
enum InquiryStatus {
  newLead('New'),
  followUp('Follow-Up'),
  trialScheduled('Trial Scheduled'),
  joined('Joined'),
  notInterested('Not Interested');

  final String label;
  const InquiryStatus(this.label);

  static InquiryStatus fromString(String? value) {
    return InquiryStatus.values.firstWhere(
      (status) => status.label.toLowerCase() == value?.toLowerCase(),
      orElse: () => InquiryStatus.newLead,
    );
  }

  /// High-visibility badge background color
  Color get backgroundColor {
    switch (this) {
      case InquiryStatus.newLead:
        return const Color(0xFFEEF2FF); // Soft Indigo
      case InquiryStatus.followUp:
        return const Color(0xFFFEF3C7); // Warm Amber
      case InquiryStatus.trialScheduled:
        return const Color(0xFFF3E8FF); // Soft Purple
      case InquiryStatus.joined:
        return const Color(0xFFDCFCE7); // Fresh Green
      case InquiryStatus.notInterested:
        return const Color(0xFFFEE2E2); // Soft Red
    }
  }

  /// High-contrast badge foreground/text color
  Color get foregroundColor {
    switch (this) {
      case InquiryStatus.newLead:
        return const Color(0xFF4F46E5);
      case InquiryStatus.followUp:
        return const Color(0xFFB45309);
      case InquiryStatus.trialScheduled:
        return const Color(0xFF7E22CE);
      case InquiryStatus.joined:
        return const Color(0xFF15803D);
      case InquiryStatus.notInterested:
        return const Color(0xFFB91C1C);
    }
  }
}

class Inquiry {
  final String id;
  final String name;
  final String areaCity;
  final String phone;
  final String email;
  final InquiryStatus status;
  final String remarks;
  final DateTime createdAt;
  final DateTime? followUpDate;

  const Inquiry({
    required this.id,
    required this.name,
    required this.areaCity,
    required this.phone,
    required this.email,
    required this.status,
    required this.remarks,
    required this.createdAt,
    this.followUpDate,
  });

  /// Returns true if this inquiry is in Follow-Up status and scheduled for [date].
  bool isFollowUpDueOn(DateTime date) {
    if (status != InquiryStatus.followUp || followUpDate == null) return false;
    return followUpDate!.year == date.year &&
        followUpDate!.month == date.month &&
        followUpDate!.day == date.day;
  }

  Inquiry copyWith({
    String? id,
    String? name,
    String? areaCity,
    String? phone,
    String? email,
    InquiryStatus? status,
    String? remarks,
    DateTime? createdAt,
    DateTime? followUpDate,
    bool clearFollowUpDate = false,
  }) {
    return Inquiry(
      id: id ?? this.id,
      name: name ?? this.name,
      areaCity: areaCity ?? this.areaCity,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      followUpDate:
          clearFollowUpDate ? null : (followUpDate ?? this.followUpDate),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'areaCity': areaCity,
      'phone': phone,
      'email': email,
      'status': status.label,
      'remarks': remarks,
      'createdAt': Timestamp.fromDate(createdAt),
      'followUpDate':
          followUpDate != null ? Timestamp.fromDate(followUpDate!) : null,
    };
  }

  factory Inquiry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final timestamp = data['createdAt'] as Timestamp?;
    final followUpTs = data['followUpDate'] as Timestamp?;

    return Inquiry(
      id: doc.id,
      name: data['name'] as String? ?? 'Unknown Lead',
      areaCity: data['areaCity'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      status: InquiryStatus.fromString(data['status'] as String?),
      remarks: data['remarks'] as String? ?? '',
      createdAt: timestamp?.toDate() ?? DateTime.now(),
      followUpDate: followUpTs?.toDate(),
    );
  }
}
