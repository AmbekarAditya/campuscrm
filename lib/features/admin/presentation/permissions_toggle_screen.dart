import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/staff_repository.dart';
import '../domain/staff_model.dart';

class PermissionsToggleScreen extends ConsumerStatefulWidget {
  final String staffId;
  final String staffName;

  const PermissionsToggleScreen({
    super.key,
    required this.staffId,
    required this.staffName,
  });

  @override
  ConsumerState<PermissionsToggleScreen> createState() =>
      _PermissionsToggleScreenState();
}

class _PermissionsToggleScreenState
    extends ConsumerState<PermissionsToggleScreen> {
  late bool _canViewMoney;
  late bool _canEditStudents;
  late bool _canMarkAttendance;
  late bool _canManageInventory;
  bool _initialized = false;

  void _initFromStaff(StaffMember? staff) {
    if (!_initialized && staff != null) {
      _canViewMoney = staff.canViewMoney;
      _canEditStudents = staff.canEditStudents;
      _canMarkAttendance = staff.canMarkAttendance;
      _canManageInventory = staff.canManageInventory;
      _initialized = true;
    } else if (!_initialized) {
      _canViewMoney = false;
      _canEditStudents = true;
      _canMarkAttendance = true;
      _canManageInventory = false;
      _initialized = true;
    }
  }

  Future<void> _savePermissions() async {
    await ref.read(staffRepositoryProvider).updatePermissions(
          staffId: widget.staffId,
          staffName: widget.staffName,
          canViewMoney: _canViewMoney,
          canEditStudents: _canEditStudents,
          canMarkAttendance: _canMarkAttendance,
          canManageInventory: _canManageInventory,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Permissions updated for "${widget.staffName}".'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF15803D),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffList = ref.watch(localStaffProvider);
    final staff = staffList.where((s) => s.id == widget.staffId).firstOrNull;
    _initFromStaff(staff);

    return Scaffold(
      appBar: AppBar(
        title: Text('Permissions • ${widget.staffName}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: _savePermissions,
              icon: const Icon(Icons.check_rounded, color: Colors.white),
              label: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Access & Feature Controls',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Configure which screens and operations this staff account can view or edit.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Can View Money (Payments Ledger)'),
                    subtitle: const Text('Allow viewing fee collections and student balances'),
                    value: _canViewMoney,
                    onChanged: (val) => setState(() => _canViewMoney = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Can Edit Students & Leads'),
                    subtitle: const Text('Allow modifying student inquiries, leads & batches'),
                    value: _canEditStudents,
                    onChanged: (val) => setState(() => _canEditStudents = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Can Mark Attendance'),
                    subtitle: const Text('Allow taking daily student attendance for batches'),
                    value: _canMarkAttendance,
                    onChanged: (val) => setState(() => _canMarkAttendance = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Can Manage Inventory'),
                    subtitle: const Text('Allow adding, editing stock and assigning student kits'),
                    value: _canManageInventory,
                    onChanged: (val) => setState(() => _canManageInventory = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 50),
              ),
              onPressed: _savePermissions,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Save Permissions'),
            ),
          ),
        ],
      ),
    );
  }
}
