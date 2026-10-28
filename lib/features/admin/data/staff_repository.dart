import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/services/activity_logger.dart';
import '../domain/staff_model.dart';

class LocalStaffNotifier extends StateNotifier<List<StaffMember>> {
  LocalStaffNotifier()
      : super([
          StaffMember(
            id: 'staff-1',
            name: 'Neha Deshmukh',
            role: 'Front Desk Coordinator',
            phone: '+919820011223',
            loginId: 'neha.desk',
            password: 'password123',
            pin: '1234',
            canViewMoney: true,
            canEditStudents: true,
            canMarkAttendance: true,
            canManageInventory: true,
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
          ),
          StaffMember(
            id: 'staff-2',
            name: 'Vikram Joshi',
            role: 'Senior Trainer',
            phone: '+919820044556',
            loginId: 'vikram.trainer',
            password: 'password123',
            pin: '5678',
            canViewMoney: false,
            canEditStudents: true,
            canMarkAttendance: true,
            canManageInventory: false,
            createdAt: DateTime.now().subtract(const Duration(days: 20)),
          ),
          StaffMember(
            id: 'staff-3',
            name: 'Pooja Iyer',
            role: 'Admissions Counselor',
            phone: '+919820077889',
            loginId: 'pooja.counselor',
            password: 'password123',
            pin: '9012',
            canViewMoney: false,
            canEditStudents: true,
            canMarkAttendance: false,
            canManageInventory: false,
            createdAt: DateTime.now().subtract(const Duration(days: 10)),
          ),
        ]);

  void addStaff(StaffMember member) {
    final newItem = member.id.isEmpty
        ? member.copyWith(id: 'staff-${DateTime.now().millisecondsSinceEpoch}')
        : member;
    state = [...state, newItem];
  }

  void deleteStaff(String id) {
    state = state.where((s) => s.id != id).toList();
  }

  void updatePermissions(
    String id, {
    bool? canViewMoney,
    bool? canEditStudents,
    bool? canMarkAttendance,
    bool? canManageInventory,
  }) {
    state = [
      for (final s in state)
        if (s.id == id)
          s.copyWith(
            canViewMoney: canViewMoney,
            canEditStudents: canEditStudents,
            canMarkAttendance: canMarkAttendance,
            canManageInventory: canManageInventory,
          )
        else
          s,
    ];
  }
}

final localStaffProvider =
    StateNotifierProvider<LocalStaffNotifier, List<StaffMember>>(
  (ref) => LocalStaffNotifier(),
);

/// Currently authenticated session: null represents the Admin/Owner session.
final activeStaffSessionProvider = StateProvider<StaffMember?>((ref) => null);

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final localNotifier = ref.read(localStaffProvider.notifier);
  final sessionNotifier = ref.read(activeStaffSessionProvider.notifier);
  final logger = ref.read(activityLoggerProvider);
  return StaffRepository(
    firestore,
    localNotifier,
    sessionNotifier,
    logger,
  );
});

class StaffRepository {
  final FirebaseFirestore? _firestore;
  final LocalStaffNotifier _localNotifier;
  final StateController<StaffMember?> _sessionNotifier;
  final ActivityLogger _logger;

  StaffRepository(
    this._firestore,
    this._localNotifier,
    this._sessionNotifier,
    this._logger,
  );

  CollectionReference<Map<String, dynamic>>? get _collection =>
      _firestore?.collection('staff_members');

  Future<void> createStaff(StaffMember member) async {
    _localNotifier.addStaff(member);
    await _logger.log(
      actorName: 'Admin',
      action:
          'Created staff account for "${member.name}" (${member.role}) with Login ID "@${member.loginId}"',
      category: 'Admin',
    );
    if (_collection != null) {
      await _collection!.add(member.toMap());
    }
  }

  Future<void> deleteStaff(String staffId, String staffName) async {
    _localNotifier.deleteStaff(staffId);
    if (_sessionNotifier.state?.id == staffId) {
      _sessionNotifier.state = null; // Reset session if active
    }
    await _logger.log(
      actorName: 'Admin',
      action: 'Deleted staff member "$staffName" and revoked login access',
      category: 'Admin',
    );
    if (_collection != null) {
      await _collection!.doc(staffId).delete();
    }
  }

  Future<StaffMember?> loginStaff({
    required String loginId,
    required String password,
    required List<StaffMember> allStaff,
  }) async {
    final cleanLogin = loginId.trim().toLowerCase();
    for (final staff in allStaff) {
      if (staff.loginId.trim().toLowerCase() == cleanLogin &&
          staff.password == password) {
        _sessionNotifier.state = staff;
        await _logger.log(
          actorName: staff.name,
          action: 'Staff member logged in successfully (${staff.role})',
          category: 'Auth',
        );
        return staff;
      }
    }
    return null;
  }

  Future<void> updatePermissions({
    required String staffId,
    required String staffName,
    required bool canViewMoney,
    required bool canEditStudents,
    required bool canMarkAttendance,
    required bool canManageInventory,
  }) async {
    _localNotifier.updatePermissions(
      staffId,
      canViewMoney: canViewMoney,
      canEditStudents: canEditStudents,
      canMarkAttendance: canMarkAttendance,
      canManageInventory: canManageInventory,
    );
    await _logger.log(
      actorName: 'Admin',
      action: 'Updated permission toggles for "$staffName"',
      category: 'Admin',
    );
    if (_collection != null) {
      await _collection!.doc(staffId).update({
        'canViewMoney': canViewMoney,
        'canEditStudents': canEditStudents,
        'canMarkAttendance': canMarkAttendance,
        'canManageInventory': canManageInventory,
      });
    }
  }
}
