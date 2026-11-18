import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/app_state.dart';
import '../../core/i18n/strings.dart';
import '../../core/models/expense.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';

const expenseCategories = [
  'General',
  'Rent',
  'Utilities',
  'Salary',
  'Stock Purchase',
  'Transport',
  'Food',
  'Repair',
];

class CashbookScreen extends ConsumerStatefulWidget {
  const CashbookScreen({super.key});

  @override
  ConsumerState<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends ConsumerState<CashbookScreen> {
  DateTime _day = DateTime.now();

  Future<void> _addExpense() async {
    final title = TextEditingController();
    final amount = TextEditingController();
    var category = 'General';
    var method = 'Cash';
    final form = GlobalKey<FormState>();
    final done = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add expense'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: title,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'What was it for?',
                  ),
                  validator: requiredText,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Amount'),
                  validator: requiredText,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: expenseCategories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (v) => category = v ?? 'General',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: method,
                        decoration: const InputDecoration(
                          labelText: 'Paid from',
                        ),
                        items: paymentMethods
                            .where((m) => m != 'Udhaar')
                            .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)),
                            )
                            .toList(),
                        onChanged: (v) => method = v ?? 'Cash',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Save expense'),
          ),
        ],
      ),
    );
    if (done == true) {
      ref
          .read(shopProvider.notifier)
          .addExpense(
            Expense(
              id: newId(),
              date: DateTime.now(),
              category: category,
              title: title.text.trim(),
              amount: parseAmount(amount.text),
              paymentMethod: method,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopProvider);
    final p = state.profile;
    final s = Strings(p.isUrdu);

    final daySales = state.salesOn(_day);
    final dayReceived = state.receivedOn(_day);
    final dayExpenses = state.expenses
        .where((e) => isSameDay(e.date, _day))
        .fold(0.0, (sum, e) => sum + e.amount);
    final ledgerPaymentsIn = state.ledger
        .where((e) => isSameDay(e.date, _day) && e.kind == 'Payment received')
        .fold(0.0, (sum, e) => sum - e.delta);
    final cashNet = dayReceived + ledgerPaymentsIn - dayExpenses;

    final monthStart = DateTime(_day.year, _day.month, 1);
    final monthExpenses = state.expenses
        .where((e) => !e.date.isBefore(monthStart))
        .fold(0.0, (sum, e) => sum + e.amount);
    final byCategory = <String, double>{};
    for (final e in state.expenses) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }
    final categories = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () =>
                  setState(() => _day = _day.subtract(const Duration(days: 1))),
            ),
            Text(dateFmt(_day), style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () =>
                  setState(() => _day = _day.add(const Duration(days: 1))),
            ),
            if (!isSameDay(_day, DateTime.now()))
              TextButton(
                onPressed: () => setState(() => _day = DateTime.now()),
                child: const Text('Today'),
              ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _addExpense,
              icon: const Icon(Icons.add, size: 18),
              label: Text(s.addExpense),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth > 900 ? 4 : 2;
            final cards = [
              KpiCard(
                label: 'Sales on ${dateFmt(_day)}',
                value: money(p, daySales),
                icon: Icons.receipt_long_outlined,
              ),
              KpiCard(
                label: 'Money received',
                value: money(p, dayReceived + ledgerPaymentsIn),
                icon: Icons.payments_outlined,
                sub: ledgerPaymentsIn > 0
                    ? 'incl. khata payments ${money(p, ledgerPaymentsIn)}'
                    : null,
              ),
              KpiCard(
                label: 'Expenses',
                value: money(p, dayExpenses),
                icon: Icons.outbox_outlined,
                accent: AppTheme.danger,
              ),
              KpiCard(
                label: 'Net cash movement',
                value: money(p, cashNet),
                icon: Icons.account_balance_wallet_outlined,
                accent: cashNet >= 0 ? AppTheme.primary : AppTheme.danger,
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
        SectionTitle(
          'Expenses',
          trailing: Text(
            'This month: ${money(p, monthExpenses)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Card(
          child: state.expenses.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No expenses recorded yet. Rent, bijli, salary - write them here so the day closes honestly.',
                  ),
                )
              : Column(
                  children: [
                    for (final e in state.expenses.take(30))
                      ListTile(
                        dense: true,
                        title: Text(e.title),
                        subtitle: Text(
                          '${e.category} - ${dateFmt(e.date)} - ${e.paymentMethod}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '- ${money(p, e.amount)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.danger,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 17,
                                color: AppTheme.muted,
                              ),
                              onPressed: () => ref
                                  .read(shopProvider.notifier)
                                  .deleteExpense(e.id),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        if (categories.isNotEmpty) ...[
          const SectionTitle('Where the money goes (all time)'),
          Card(
            child: Column(
              children: [
                for (final c in categories)
                  ListTile(
                    dense: true,
                    title: Text(c.key),
                    trailing: Text(
                      money(p, c.value),
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
