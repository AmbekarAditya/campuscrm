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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWideScreen = screenWidth >= 800;
    final isExtended = screenWidth >= 960;

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
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                ),
              ),
              child: NavigationRail(
                minExtendedWidth: 260,
                minWidth: 76,
                extended: isExtended,
                selectedIndex: _selectedIndex.clamp(0, 6),
                onDestinationSelected: _selectScreen,
                leading: _buildRailBranding(isExtended),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined, size: 24),
                    selectedIcon: Icon(Icons.dashboard_rounded, size: 24),
                    label: Text('Dashboard'),
                    padding: EdgeInsets.symmetric(vertical: 4),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.contact_phone_outlined, size: 24),
                    selectedIcon: Icon(Icons.contact_phone_rounded, size: 24),
                    label: Text('Inquiries'),
                    padding: EdgeInsets.symmetric(vertical: 4),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.school_outlined, size: 24),
                    selectedIcon: Icon(Icons.school_rounded, size: 24),
                    label: Text('Batches'),
                    padding: EdgeInsets.symmetric(vertical: 4),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.account_balance_wallet_outlined, size: 24),
                    selectedIcon:
                        Icon(Icons.account_balance_wallet_rounded, size: 24),
                    label: Text('Payments'),
                    padding: EdgeInsets.symmetric(vertical: 4),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.calendar_month_outlined, size: 24),
                    selectedIcon: Icon(Icons.calendar_month_rounded, size: 24),
                    label: Text('Bookings'),
                    padding: EdgeInsets.symmetric(vertical: 4),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.inventory_2_outlined, size: 24),
                    selectedIcon: Icon(Icons.inventory_2_rounded, size: 24),
                    label: Text('Inventory'),
                    padding: EdgeInsets.symmetric(vertical: 4),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.admin_panel_settings_outlined, size: 24),
                    selectedIcon:
                        Icon(Icons.admin_panel_settings_rounded, size: 24),
                    label: Text('Admin'),
                    padding: EdgeInsets.symmetric(vertical: 4),
                  ),
                ],
              ),
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

  Widget _buildRailBranding(bool isExtended) {
    if (!isExtended) {
      return Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 16),
        child: Tooltip(
          message: 'campusCRM',
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                      children: [
                        TextSpan(text: 'campus'),
                        TextSpan(
                          text: 'CRM',
                          style: TextStyle(
                            color: Color(0xFF4F46E5),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Campus Management',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
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
