import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/data/app_state.dart';
import '../../core/models/invoice.dart';
import '../../core/models/party.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/invoice_pdf.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  Future<void> _exportCsv(
    BuildContext context,
    String name,
    List<List<Object?>> rows,
  ) async {
    final csv = BackupService.buildCsv(name, rows);
    await FileSaver.instance.saveFile(
      name: name,
      bytes: Uint8List.fromList(utf8.encode(csv)),
      ext: 'csv',
      mimeType: MimeType.csv,
    );
    if (context.mounted) showMsg(context, '$name.csv downloaded.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shopProvider);
    final p = state.profile;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthInvoices = state.invoices
        .where((i) => !i.date.isBefore(monthStart))
        .toList();
    final monthSales = monthInvoices.fold(0.0, (s, i) => s + i.total);
    final monthMargin = monthInvoices.fold(0.0, (s, i) => s + i.grossMargin);
    final monthExpenses = state.expenses
        .where((e) => !e.date.isBefore(monthStart))
        .fold(0.0, (s, e) => s + e.amount);

    final dueCustomers =
        state.parties
            .where(
              (x) => x.type == PartyType.customer && state.balanceOf(x.id) > 0,
            )
            .toList()
          ..sort(
            (a, b) => state.balanceOf(b.id).compareTo(state.balanceOf(a.id)),
          );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth > 900 ? 4 : 2;
            final cards = [
              KpiCard(
                label: 'Sales this month',
                value: money(p, monthSales),
                icon: Icons.trending_up_outlined,
                sub: '${monthInvoices.length} bills',
              ),
              KpiCard(
                label: 'Gross margin this month',
                value: money(p, monthMargin),
                icon: Icons.savings_outlined,
                sub: 'before expenses',
              ),
              KpiCard(
                label: 'Expenses this month',
                value: money(p, monthExpenses),
                icon: Icons.outbox_outlined,
                accent: AppTheme.danger,
              ),
              KpiCard(
                label: 'Margin after expenses',
                value: money(p, monthMargin - monthExpenses),
                icon: Icons.account_balance_outlined,
                accent: monthMargin - monthExpenses >= 0
                    ? AppTheme.primary
                    : AppTheme.danger,
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
          'Export data (CSV)',
          trailing: Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => _exportCsv(context, 'products', [
                  [
                    'Name',
                    'SKU',
                    'Category',
                    'Unit',
                    'Purchase Price',
                    'Sale Price',
                    'Stock',
                  ],
                  for (final x in state.products)
                    [
                      x.name,
                      x.sku,
                      x.category,
                      x.unit,
                      x.purchasePrice,
                      x.salePrice,
                      x.stock,
                    ],
                ]),
                child: const Text('Products'),
              ),
              OutlinedButton(
                onPressed: () => _exportCsv(context, 'khata-balances', [
                  ['Name', 'Type', 'Phone', 'Balance'],
                  for (final x in state.parties)
                    [x.name, x.type.name, x.phone, state.balanceOf(x.id)],
                ]),
                child: const Text('Khata balances'),
              ),
              OutlinedButton(
                onPressed: () => _exportCsv(context, 'sales', [
                  [
                    'Invoice',
                    'Date',
                    'Customer',
                    'Total',
                    'Paid',
                    'Balance',
                    'Status',
                  ],
                  for (final x in state.invoices)
                    [
                      x.number,
                      dateFmt(x.date),
                      x.partyName,
                      x.total,
                      x.paidAmount,
                      x.balanceDue,
                      x.status,
                    ],
                ]),
                child: const Text('Sales'),
              ),
            ],
          ),
        ),
        const SectionTitle('All invoices'),
        Card(
          child: state.invoices.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No invoices yet.'),
                )
              : Column(
                  children: [
                    for (final inv in state.invoices.take(40))
                      _InvoiceRow(invoice: inv),
                  ],
                ),
        ),
        const SectionTitle('Udhaar aging'),
        Card(
          child: dueCustomers.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nobody owes the shop right now.'),
                )
              : Column(
                  children: [
                    for (final party in dueCustomers)
                      Builder(
                        builder: (context) {
                          final since = state.oldestDueDate(party.id);
                          final age = since == null
                              ? 0
                              : daysBetween(since, DateTime.now());
                          final bucket = age <= 30
                              ? '0-30 days'
                              : age <= 60
                              ? '31-60 days'
                              : '60+ days';
                          return ListTile(
                            dense: true,
                            title: Text(party.name),
                            subtitle: Text(
                              '$bucket${since != null ? ' - since ${dateFmt(since)}' : ''}',
                            ),
                            trailing: Text(
                              money(p, state.balanceOf(party.id)),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: age > 60
                                    ? AppTheme.danger
                                    : AppTheme.warning,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _InvoiceRow extends ConsumerWidget {
  final Invoice invoice;
  const _InvoiceRow({required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shopProvider);
    final p = state.profile;
    final party = invoice.partyId == null
        ? null
        : state.partyById(invoice.partyId!);
    return ListTile(
      dense: true,
      title: Text('${invoice.number} - ${invoice.partyName}'),
      subtitle: Text(
        '${dateFmt(invoice.date)} - ${invoice.lines.length} items - ${invoice.paymentMethod}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money(p, invoice.total),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                invoice.status,
                style: TextStyle(
                  fontSize: 11.5,
                  color: invoice.isPaid ? AppTheme.primary : AppTheme.warning,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 19),
            tooltip: 'Open PDF',
            onPressed: () async {
              final bytes = await buildInvoicePdf(p, invoice);
              await Printing.layoutPdf(onLayout: (_) async => bytes);
            },
          ),
          if (party != null && party.phone.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.chat_outlined, size: 19),
              tooltip: 'Send on WhatsApp',
              onPressed: () =>
                  openWhatsApp(party.phone, billMessage(p, invoice)),
            ),
        ],
      ),
    );
  }
}
