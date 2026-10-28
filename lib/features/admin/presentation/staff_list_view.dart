import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/staff_repository.dart';
import '../domain/staff_model.dart';
import 'activity_feed_view.dart';
import 'add_staff_form.dart';
import 'permissions_toggle_screen.dart';

class StaffListView extends ConsumerStatefulWidget {
  const StaffListView({super.key});

  @override
  ConsumerState<StaffListView> createState() => _StaffListViewState();
}

class _StaffListViewState extends ConsumerState<StaffListView> {
  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Staff Login Modal where staff can authenticate using their Login ID & Password
  Future<void> _showStaffLoginDialog(
    BuildContext context,
    List<StaffMember> staffList,
  ) async {
    final loginCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool obscure = true;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: Color(0xFF1E40AF)),
                  SizedBox(width: 8),
                  Text('Staff Member Login'),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter your staff login credentials created by the institute admin.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: loginCtrl,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Login ID / Username',
                        hintText: 'E.g. neha.desk',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter password',
                        prefixIcon: const Icon(Icons.key_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setDialogState(() => obscure = !obscure),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final loginId = loginCtrl.text.trim();
                    final password = passwordCtrl.text.trim();

                    if (loginId.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Please enter both Login ID and Password.'),
                        ),
                      );
                      return;
                    }

                    final staff = await ref
                        .read(staffRepositoryProvider)
                        .loginStaff(
                          loginId: loginId,
                          password: password,
                          allStaff: staffList,
                        );

                    if (staff != null) {
                      if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Welcome back, ${staff.name}! Logged in as ${staff.role}.',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF15803D),
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Invalid Login ID or Password. Please try again.',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Color(0xFFDC2626),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Log In'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Delete Staff Member Confirmation Dialog
  Future<void> _confirmDeleteStaff(
    BuildContext context,
    StaffMember staff,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFDC2626), size: 26),
            SizedBox(width: 8),
            Text('Delete Staff Member?'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${staff.name}" (${staff.role})? Their login account (@${staff.loginId}) and all system permissions will be revoked.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ref
                  .read(staffRepositoryProvider)
                  .deleteStaff(staff.id, staff.name);
              if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Staff member "${staff.name}" has been deleted.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete Staff'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffMembers = ref.watch(localStaffProvider);
    final activeSession = ref.watch(activeStaffSessionProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 640;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin & Staff Permissions'),
        centerTitle: false,
        actions: [
          // Staff Login button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
              ),
              onPressed: () => _showStaffLoginDialog(context, staffMembers),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: Text(isMobile ? 'Login' : 'Staff Login'),
            ),
          ),
          // Add Staff button
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddStaffForm()),
                );
              },
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(isMobile ? 'Add' : 'Add Staff'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 20,
          vertical: 16,
        ),
        children: [
          // Active Session Banner
          if (activeSession != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded,
                      color: Color(0xFF1E40AF), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Currently Logged In as: ${activeSession.name} (${activeSession.role})',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(activeStaffSessionProvider.notifier).state = null;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Switched back to Admin Owner session.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('Switch to Admin'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Staff Members Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Staff Members & Logins',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: isMobile ? 18 : 22,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${staffMembers.length} Staff Accounts',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Manage staff accounts, login credentials, passwords, and module permissions.',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),

          if (staffMembers.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.people_outline_rounded,
                          size: 40, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 8),
                      const Text(
                        'No staff accounts created yet.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Click "+ Add Staff" to create accounts with login IDs & passwords.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...staffMembers.map((staff) {
              return Card(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Avatar, Name, Role, Login ID & Delete Button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: isMobile ? 18 : 22,
                            backgroundColor: const Color(0xFFEFF6FF),
                            foregroundColor: const Color(0xFF1E40AF),
                            child: Text(
                              _getInitials(staff.name),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: isMobile ? 12 : 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  staff.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontSize: isMobile ? 15 : 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  staff.role,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Login ID & Phone Tags
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.alternate_email_rounded,
                                            size: 13,
                                            color: Color(0xFF1E40AF),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            staff.loginId,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.key_rounded,
                                            size: 13,
                                            color: Color(0xFF64748B),
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'Password Protected',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (staff.phone.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          staff.phone,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          // DELETE STAFF BUTTON (with confirmation)
                          IconButton(
                            iconSize: 20,
                            tooltip: 'Delete Staff Member',
                            onPressed: () => _confirmDeleteStaff(context, staff),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Permissions summary chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _PermissionChip(
                            label: 'Payments',
                            isEnabled: staff.canViewMoney,
                            icon: Icons.payments_outlined,
                          ),
                          _PermissionChip(
                            label: 'Students',
                            isEnabled: staff.canEditStudents,
                            icon: Icons.people_outline_rounded,
                          ),
                          _PermissionChip(
                            label: 'Attendance',
                            isEnabled: staff.canMarkAttendance,
                            icon: Icons.fact_check_outlined,
                          ),
                          _PermissionChip(
                            label: 'Inventory',
                            isEnabled: staff.canManageInventory,
                            icon: Icons.inventory_2_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Action Row: Permissions button & Quick Login test
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final repo = ref.read(staffRepositoryProvider);
                              await repo.loginStaff(
                                loginId: staff.loginId,
                                password: staff.password,
                                allStaff: staffMembers,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Switched active session to ${staff.name} (@${staff.loginId}).',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                            label: const Text(
                              'Test Login',
                              style: TextStyle(fontSize: 12.5),
                            ),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              minimumSize: const Size(0, 32),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PermissionsToggleScreen(
                                    staffId: staff.id,
                                    staffName: staff.name,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.admin_panel_settings_outlined,
                              size: 15,
                            ),
                            label: const Text(
                              'Edit Permissions',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 28),

          // -------------------------------------------------------------
          // SECTION 2: CENTRAL ACTIVITY FEED (REST ACTIVITY REMAINS SAME)
          // -------------------------------------------------------------
          Text(
            'Central Activity Feed',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: isMobile ? 18 : 22,
                ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Audit log recording all front desk, batch, inventory and admin operations.',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(
            height: 340,
            child: ActivityFeedView(),
          ),
        ],
      ),
    );
  }
}

class _PermissionChip extends StatelessWidget {
  final String label;
  final bool isEnabled;
  final IconData icon;

  const _PermissionChip({
    required this.label,
    required this.isEnabled,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isEnabled ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isEnabled ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isEnabled ? const Color(0xFF15803D) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isEnabled
                  ? const Color(0xFF14532D)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
