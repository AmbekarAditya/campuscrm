import 'package:cloud_firestore/cloud_firestore.dart';

class StaffMember {
  final String id;
  final String name;
  final String role;
  final String phone;
  final String loginId;
  final String password;
  final String pin;
  final bool canViewMoney;
  final bool canEditStudents;
  final bool canMarkAttendance;
  final bool canManageInventory;
  final DateTime createdAt;

  const StaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.loginId,
    required this.password,
    required this.pin,
    this.canViewMoney = false,
    this.canEditStudents = true,
    this.canMarkAttendance = true,
    this.canManageInventory = false,
    required this.createdAt,
  });

  StaffMember copyWith({
    String? id,
    String? name,
    String? role,
    String? phone,
    String? loginId,
    String? password,
    String? pin,
    bool? canViewMoney,
    bool? canEditStudents,
    bool? canMarkAttendance,
    bool? canManageInventory,
    DateTime? createdAt,
  }) {
    return StaffMember(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      loginId: loginId ?? this.loginId,
      password: password ?? this.password,
      pin: pin ?? this.pin,
      canViewMoney: canViewMoney ?? this.canViewMoney,
      canEditStudents: canEditStudents ?? this.canEditStudents,
      canMarkAttendance: canMarkAttendance ?? this.canMarkAttendance,
      canManageInventory: canManageInventory ?? this.canManageInventory,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'phone': phone,
      'loginId': loginId,
      'password': password,
      'pin': pin,
      'canViewMoney': canViewMoney,
      'canEditStudents': canEditStudents,
      'canMarkAttendance': canMarkAttendance,
      'canManageInventory': canManageInventory,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory StaffMember.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final ts = data['createdAt'] as Timestamp?;
    return StaffMember(
      id: doc.id,
      name: data['name'] as String? ?? 'Staff Member',
      role: data['role'] as String? ?? 'Staff',
      phone: data['phone'] as String? ?? '',
      loginId: data['loginId'] as String? ?? '',
      password: data['password'] as String? ?? '',
      pin: data['pin'] as String? ?? '1234',
      canViewMoney: data['canViewMoney'] as bool? ?? false,
      canEditStudents: data['canEditStudents'] as bool? ?? true,
      canMarkAttendance: data['canMarkAttendance'] as bool? ?? true,
      canManageInventory: data['canManageInventory'] as bool? ?? false,
      createdAt: ts?.toDate() ?? DateTime.now(),
    );
  }
}
