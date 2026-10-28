import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/activity_logger.dart';

class AddStaffForm extends ConsumerStatefulWidget {
  const AddStaffForm({super.key});

  @override
  ConsumerState<AddStaffForm> createState() => _AddStaffFormState();
}

class _AddStaffFormState extends ConsumerState<AddStaffForm> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _roleCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final role = _roleCtrl.text.trim().isEmpty
        ? 'Staff Member'
        : _roleCtrl.text.trim();
    if (name.isEmpty) return;

    await ref.read(activityLoggerProvider).log(
          actorName: 'Admin',
          action: 'Created staff account for $name ($role)',
          category: 'Admin',
        );

    if (mounted) {
      Navigator.of(context).pop((name: name, role: role));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Staff Member')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Staff Name *'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _roleCtrl,
              decoration: const InputDecoration(
                labelText: 'Role (e.g. Trainer, Front Desk)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pinCtrl,
              maxLength: 4,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '4-Digit Login PIN',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Create Staff Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
