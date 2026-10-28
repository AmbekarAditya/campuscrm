import 'package:flutter/material.dart';

class PermissionsToggleScreen extends StatefulWidget {
  final String staffName;

  const PermissionsToggleScreen({
    super.key,
    required this.staffName,
  });

  @override
  State<PermissionsToggleScreen> createState() =>
      _PermissionsToggleScreenState();
}

class _PermissionsToggleScreenState extends State<PermissionsToggleScreen> {
  bool canViewMoney = false;
  bool canEditStudents = true;
  bool canMarkAttendance = true;
  bool canManageInventory = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Permissions • ${widget.staffName}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Can View Money (Payments Ledger)'),
                  subtitle: const Text('Allow viewing fee collections and dues'),
                  value: canViewMoney,
                  onChanged: (val) => setState(() => canViewMoney = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Can Edit Students'),
                  subtitle: const Text('Allow modifying student profiles & batches'),
                  value: canEditStudents,
                  onChanged: (val) => setState(() => canEditStudents = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Can Mark Attendance'),
                  subtitle: const Text('Allow marking daily batch attendance'),
                  value: canMarkAttendance,
                  onChanged: (val) => setState(() => canMarkAttendance = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Can Manage Inventory'),
                  subtitle: const Text('Allow updating stock and assigning kits'),
                  value: canManageInventory,
                  onChanged: (val) => setState(() => canManageInventory = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
