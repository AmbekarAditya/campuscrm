import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/firebase_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/academics/presentation/batch_list_view.dart';
import 'features/admin/presentation/staff_list_view.dart';
import 'features/bookings/presentation/bookings_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/inquiries/presentation/inquiries_screen.dart';
import 'features/inventory/presentation/inventory_screen.dart';
import 'features/payments/presentation/payments_ledger_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and enable offline-first Firestore persistence when configured
  final firebaseReady = await initOfflineFirebase();

  runApp(
    ProviderScope(
      overrides: [
        isFirebaseInitializedProvider.overrideWith((ref) => firebaseReady),
      ],
      child: const CampusCrmApp(),
    ),
  );
}

class CampusCrmApp extends StatelessWidget {
  const CampusCrmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'campusCRM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 1; // Defaults to Inquiries & Lead Management for quick access

  void _selectScreen(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.sizeOf(context).width >= 800;

    final screens = [
      const DashboardScreen(),
      const InquiriesScreen(),
      const BatchListView(),
      const PaymentsLedgerScreen(),
      const BookingsScreen(),
      const InventoryScreen(),
      const StaffListView(),
    ];

    // On mobile, if index is 7, show the More launcher screen
    Widget currentBody;
    if (!isWideScreen && _selectedIndex == 7) {
      currentBody = _MoreModulesScreen(onSelectModule: _selectScreen);
    } else {
      currentBody = screens[_selectedIndex.clamp(0, 6)];
    }

    // Determine which bottom bar item to highlight on mobile
    int mobileNavIndex;
    if (_selectedIndex < 4) {
      mobileNavIndex = _selectedIndex;
    } else {
      mobileNavIndex = 4; // Highlights "More" for Bookings (4), Inventory (5), Admin (6), or Launcher (7)
    }

    return Scaffold(
      body: Row(
        children: [
          if (isWideScreen)
            NavigationRail(
              extended: MediaQuery.sizeOf(context).width >= 1100,
              selectedIndex: _selectedIndex.clamp(0, 6),
              onDestinationSelected: _selectScreen,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.contact_phone_outlined),
                  selectedIcon: Icon(Icons.contact_phone_rounded),
                  label: Text('Inquiries'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.school_outlined),
                  selectedIcon: Icon(Icons.school_rounded),
                  label: Text('Batches'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                  label: Text('Payments'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: Text('Bookings'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2_rounded),
                  label: Text('Inventory'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.admin_panel_settings_outlined),
                  selectedIcon: Icon(Icons.admin_panel_settings_rounded),
                  label: Text('Admin'),
                ),
              ],
            ),
          Expanded(child: currentBody),
        ],
      ),
      bottomNavigationBar: isWideScreen
          ? null
          : NavigationBar(
              selectedIndex: mobileNavIndex,
              onDestinationSelected: (idx) {
                if (idx < 4) {
                  _selectScreen(idx);
                } else {
                  // User clicked "More" -> open More modules launcher
                  _selectScreen(7);
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined, size: 24),
                  selectedIcon: Icon(Icons.dashboard_rounded, size: 24),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.contact_phone_outlined, size: 24),
                  selectedIcon: Icon(Icons.contact_phone_rounded, size: 24),
                  label: 'Inquiries',
                ),
                NavigationDestination(
                  icon: Icon(Icons.school_outlined, size: 24),
                  selectedIcon: Icon(Icons.school_rounded, size: 24),
                  label: 'Batches',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined, size: 24),
                  selectedIcon:
                      Icon(Icons.account_balance_wallet_rounded, size: 24),
                  label: 'Payments',
                ),
                NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined, size: 24),
                  selectedIcon: Icon(Icons.grid_view_rounded, size: 24),
                  label: 'More',
                ),
              ],
            ),
    );
  }
}

class _MoreModulesScreen extends StatelessWidget {
  final ValueChanged<int> onSelectModule;

  const _MoreModulesScreen({required this.onSelectModule});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More Modules'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ModuleCard(
            title: 'Bookings & Appointments',
            subtitle: '1-on-1 sessions, shared rooms & model bookings',
            icon: Icons.calendar_month_rounded,
            iconColor: const Color(0xFF4F46E5),
            iconBg: const Color(0xFFEEF2FF),
            onTap: () => onSelectModule(4),
          ),
          _ModuleCard(
            title: 'Materials & Inventory',
            subtitle: 'Stock item tracking, reorder alerts & student kits',
            icon: Icons.inventory_2_rounded,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFEF3C7),
            onTap: () => onSelectModule(5),
          ),
          _ModuleCard(
            title: 'Admin & Staff Permissions',
            subtitle: 'Staff logins, 4-digit PINs & central activity feed',
            icon: Icons.admin_panel_settings_rounded,
            iconColor: const Color(0xFF7C3AED),
            iconBg: const Color(0xFFF3E8FF),
            onTap: () => onSelectModule(6),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            size: 16, color: Color(0xFF94A3B8)),
        onTap: onTap,
      ),
    );
  }
}
