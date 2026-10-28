import 'package:flutter/material.dart';
import 'add_staff_form.dart';
import 'activity_feed_view.dart';
import 'permissions_toggle_screen.dart';

class StaffListView extends StatefulWidget {
  const StaffListView({super.key});

  @override
  State<StaffListView> createState() => _StaffListViewState();
}

class _StaffListViewState extends State<StaffListView> {
  final List<({String name, String role})> _staffMembers = [
    (name: 'Neha Deshmukh', role: 'Front Desk Coordinator'),
    (name: 'Vikram Joshi', role: 'Senior Trainer'),
    (name: 'Pooja Iyer', role: 'Admissions Counselor'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin & Staff Permissions'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () async {
                final newStaff =
                    await Navigator.of(context).push<({String name, String role})>(
                  MaterialPageRoute(builder: (_) => const AddStaffForm()),
                );
                if (newStaff != null) {
                  setState(() => _staffMembers.add(newStaff));
                }
              },
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add Staff'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Staff Members',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          ..._staffMembers.map((staff) {
            return Card(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                title: Text(
                  staff.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(staff.role),
                trailing: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PermissionsToggleScreen(
                          staffName: staff.name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Permissions'),
                ),
              ),
            );
          }),
          const SizedBox(height: 28),
          Text(
            'Central Activity Feed',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const SizedBox(
            height: 320,
            child: ActivityFeedView(),
          ),
        ],
      ),
    );
  }
}
