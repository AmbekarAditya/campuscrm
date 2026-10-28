import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/staff_repository.dart';
import '../domain/staff_model.dart';

class AddStaffForm extends ConsumerStatefulWidget {
  const AddStaffForm({super.key});

  @override
  ConsumerState<AddStaffForm> createState() => _AddStaffFormState();
}

class _AddStaffFormState extends ConsumerState<AddStaffForm> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _roleCtrl = TextEditingController(text: 'Front Desk');
  final _loginIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _pinCtrl = TextEditingController(text: '1234');

  bool _obscurePassword = true;
  bool _canViewMoney = false;
  bool _canEditStudents = true;
  bool _canMarkAttendance = true;
  bool _canManageInventory = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _roleCtrl.dispose();
    _loginIdCtrl.dispose();
    _passwordCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final role = _roleCtrl.text.trim().isEmpty ? 'Staff Member' : _roleCtrl.text.trim();
    final loginId = _loginIdCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Staff Name.')),
      );
      return;
    }

    if (loginId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Login ID / Username.')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Password for staff login.')),
      );
      return;
    }

    final newStaff = StaffMember(
      id: '',
      name: name,
      role: role,
      phone: _phoneCtrl.text.trim(),
      loginId: loginId,
      password: password,
      pin: _pinCtrl.text.trim().isEmpty ? '1234' : _pinCtrl.text.trim(),
      canViewMoney: _canViewMoney,
      canEditStudents: _canEditStudents,
      canMarkAttendance: _canMarkAttendance,
      canManageInventory: _canManageInventory,
      createdAt: DateTime.now(),
    );

    await ref.read(staffRepositoryProvider).createStaff(newStaff);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Staff account created for $name (Login: @$loginId).'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF15803D),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Staff & Login Credentials')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile & Role Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Basic Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Staff Full Name *',
                      hintText: 'E.g. Neha Deshmukh',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _roleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Staff Role / Designation *',
                      hintText: 'E.g. Front Desk, Senior Trainer, Counselor',
                      prefixIcon: Icon(Icons.work_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'E.g. +91 98200 12345',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Login & Credentials Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lock_person_outlined,
                        color: Color(0xFF1E40AF),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Staff Login Credentials',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Staff will use this Login ID & Password to access the system.',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),

                  // Login ID / Username
                  TextField(
                    controller: _loginIdCtrl,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Login ID / Username *',
                      hintText: 'E.g. neha.desk or staff@campuscrm.com',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                      helperText: 'Unique identifier for staff login',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Password
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Login Password *',
                      hintText: 'Enter staff password',
                      prefixIcon: const Icon(Icons.key_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      helperText: 'Minimum 6 characters recommended',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4-Digit Quick PIN
                  TextField(
                    controller: _pinCtrl,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '4-Digit Quick PIN',
                      hintText: 'E.g. 1234',
                      prefixIcon: Icon(Icons.pin_outlined),
                      helperText: 'Optional quick PIN for instant terminal access',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Permissions Switches
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Role Permissions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Can View Money & Payments'),
                    subtitle: const Text('Allow viewing collections & fees ledger'),
                    value: _canViewMoney,
                    onChanged: (val) => setState(() => _canViewMoney = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Can Edit Students & Leads'),
                    subtitle: const Text('Allow modifying inquiries & batches'),
                    value: _canEditStudents,
                    onChanged: (val) => setState(() => _canEditStudents = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Can Mark Attendance'),
                    subtitle: const Text('Allow taking daily student attendance'),
                    value: _canMarkAttendance,
                    onChanged: (val) => setState(() => _canMarkAttendance = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Can Manage Inventory'),
                    subtitle: const Text('Allow updating stock & kits'),
                    value: _canManageInventory,
                    onChanged: (val) => setState(() => _canManageInventory = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 52),
              ),
              onPressed: _submit,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text(
                'Create Staff Account & Save Credentials',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
