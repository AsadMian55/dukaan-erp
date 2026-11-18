import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/app_state.dart';
import '../../core/i18n/strings.dart';
import '../../core/models/party.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';

class DashboardScreen extends ConsumerWidget {
  final void Function(int index) onJump;
  const DashboardScreen({super.key, required this.onJump});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shopProvider);
    final p = state.profile;
    final s = Strings(p.isUrdu);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthSales = state.invoices
        .where((i) => !i.date.isBefore(monthStart))
        .fold(0.0, (sum, i) => sum + i.total);
    final dueParties =
        state.parties
            .where(
              (x) => x.type == PartyType.customer && state.balanceOf(x.id) > 0,
            )
            .toList()
          ..sort(
            (a, b) => state.balanceOf(b.id).compareTo(state.balanceOf(a.id)),
          );

    if (state.isEmpty) {
      return EmptyState(
        icon: Icons.storefront_outlined,
        title: 'Welcome to ${p.shopName}',
        message:
            'Start with sample data to see a full Pakistani kiryana shop running in DukaanERP, or add your first product and bill.',
        action: Wrap(
          spacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () => ref.read(shopProvider.notifier).loadSampleData(),
              icon: const Icon(Icons.dataset_outlined, size: 18),
              label: Text(s.loadSample),
            ),
            OutlinedButton.icon(
              onPressed: () => onJump(2),
              icon: const Icon(Icons.inventory_2_outlined, size: 18),
              label: Text(s.addProduct),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth > 1000
                ? 4
                : c.maxWidth > 620
                ? 3
                : 2;
            final cards = [
              KpiCard(
                label: s.todaySales,
                value: money(p, state.salesOn(now)),
                icon: Icons.today_outlined,
                sub:
                    '${state.invoices.where((i) => isSameDay(i.date, now)).length} bills',
              ),
              KpiCard(
                label: s.monthSales,
                value: money(p, monthSales),
                icon: Icons.calendar_month_outlined,
              ),
              KpiCard(
                label: s.totalUdhaar,
                value: money(p, state.totalReceivables),
                icon: Icons.menu_book_outlined,
                accent: AppTheme.warning,
                sub: '${dueParties.length} customers',
              ),
              KpiCard(
                label: s.cashReceivedToday,
                value: money(p, state.receivedOn(now)),
                icon: Icons.payments_outlined,
              ),
              KpiCard(
                label: s.payables,
                value: money(p, state.totalPayables),
                icon: Icons.outbox_outlined,
                accent: AppTheme.danger,
              ),
              KpiCard(
                label: s.stockValue,
                value: money(p, state.stockValueCost),
                icon: Icons.warehouse_outlined,
                sub: '${state.products.length} products',
              ),
            ];
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: cols == 2 ? 1.55 : 1.45,
              ),
              itemCount: cards.length,
              itemBuilder: (_, i) => cards[i],
            );
          },
        ),
        if (state.lowStock.isNotEmpty) ...[
          SectionTitle(
            s.lowStock,
            trailing: TextButton(
              onPressed: () => onJump(2),
              child: const Text('Open inventory'),
            ),
          ),
          Card(
            child: Column(
              children: [
                for (final prod in state.lowStock.take(6))
                  ListTile(
                    dense: true,
                    leading: Icon(
                      prod.isOutOfStock
                          ? Icons.error_outline
                          : Icons.warning_amber_outlined,
                      color: prod.isOutOfStock
                          ? AppTheme.danger
                          : AppTheme.warning,
                      size: 20,
                    ),
                    title: Text(prod.name),
                    trailing: Text(
                      '${qty(prod.stock)} ${prod.unit} left',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: prod.isOutOfStock
                            ? AppTheme.danger
                            : AppTheme.warning,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        SectionTitle(
          s.recentInvoices,
          trailing: TextButton(
            onPressed: () => onJump(5),
            child: const Text('All reports'),
          ),
        ),
        Card(
          child: state.invoices.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No bills yet. Open POS Billing to make one.'),
                )
              : Column(
                  children: [
                    for (final inv in state.invoices.take(6))
                      ListTile(
                        dense: true,
                        title: Text('${inv.number} - ${inv.partyName}'),
                        subtitle: Text(dateFmt(inv.date)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              money(p, inv.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              inv.status,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: inv.isPaid
                                    ? AppTheme.primary
                                    : AppTheme.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        if (dueParties.isNotEmpty) ...[
          SectionTitle(s.outstandingKhata),
          Card(
            child: Column(
              children: [
                for (final party in dueParties.take(5))
                  ListTile(
                    dense: true,
                    title: Text(party.name),
                    subtitle: Text(
                      state.oldestDueDate(party.id) != null
                          ? 'Due since ${dateFmt(state.oldestDueDate(party.id)!)}'
                          : '',
                    ),
                    trailing: Text(
                      money(p, state.balanceOf(party.id)),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
