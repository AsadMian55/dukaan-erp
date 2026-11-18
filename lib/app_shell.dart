import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/data/app_state.dart';
import 'core/i18n/strings.dart';
import 'features/cashbook/cashbook_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/inventory/inventory_screen.dart';
import 'features/parties/parties_screen.dart';
import 'features/pos/pos_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/settings/settings_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  void _jump(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(shopProvider.select((s) => s.profile));
    final s = Strings(profile.isUrdu);

    final destinations = [
      (Icons.dashboard_outlined, Icons.dashboard, s.dashboard),
      (Icons.point_of_sale_outlined, Icons.point_of_sale, s.pos),
      (Icons.inventory_2_outlined, Icons.inventory_2, s.inventory),
      (Icons.menu_book_outlined, Icons.menu_book, s.khata),
      (
        Icons.account_balance_wallet_outlined,
        Icons.account_balance_wallet,
        s.cashbook,
      ),
      (Icons.bar_chart_outlined, Icons.bar_chart, s.reports),
      (Icons.settings_outlined, Icons.settings, s.settings),
    ];

    final screens = [
      DashboardScreen(onJump: _jump),
      const PosScreen(),
      const InventoryScreen(),
      const PartiesScreen(),
      const CashbookScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    final wide = MediaQuery.sizeOf(context).width >= 860;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.storefront, size: 21),
            const SizedBox(width: 9),
            Flexible(
              child: Text(profile.shopName, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F3EE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Offline - data on this device',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B6E4F),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _jump,
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'DukaanERP',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                ),
              ),
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.$1),
                    selectedIcon: Icon(d.$2),
                    label: Text(d.$3),
                  ),
              ],
            ),
          if (wide) const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(index: _index, children: screens),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _jump,
              destinations: [
                for (final d in destinations)
                  NavigationDestination(
                    icon: Icon(d.$1),
                    selectedIcon: Icon(d.$2),
                    label: d.$3,
                  ),
              ],
            ),
    );
  }
}
