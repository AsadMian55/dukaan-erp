import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/data/app_state.dart';
import '../../core/i18n/strings.dart';
import '../../core/models/invoice.dart';
import '../../core/models/party.dart';
import '../../core/models/product.dart';
import '../../core/services/invoice_pdf.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';

class _CartLine {
  final Product product;
  double qty;
  _CartLine(this.product, this.qty);
  double get amount => qty * product.salePrice;
}

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _search = TextEditingController();
  final _discount = TextEditingController(text: '0');
  final _taxCtrl = TextEditingController();
  final _paid = TextEditingController();
  final _searchFocus = FocusNode();
  final List<_CartLine> _cart = [];
  String _query = '';
  Party? _party;
  String _method = 'Cash';
  double? _taxRate;
  bool _paidTouched = false;

  @override
  void dispose() {
    _search.dispose();
    _discount.dispose();
    _taxCtrl.dispose();
    _paid.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  double get _subtotal => _cart.fold(0, (s, l) => s + l.amount);
  double get _discountVal => parseAmount(_discount.text);
  double get _tax => (_subtotal - _discountVal) * ((_taxRate ?? 0) / 100);
  double get _total => round2(_subtotal - _discountVal + _tax);
  double get _paidVal => parseAmount(_paid.text);
  double get _due => round2(_total - _paidVal);

  void _add(Product p) {
    setState(() {
      final i = _cart.indexWhere((l) => l.product.id == p.id);
      if (i >= 0) {
        _cart[i].qty += 1;
      } else {
        _cart.add(_CartLine(p, 1));
      }
      if (!_paidTouched) _paid.text = _total.toStringAsFixed(2);
    });
    _searchFocus.requestFocus();
  }

  void _reset() {
    setState(() {
      _cart.clear();
      _party = null;
      _method = 'Cash';
      _discount.text = '0';
      _paid.text = '';
      _paidTouched = false;
      _taxRate = null;
      _search.clear();
      _query = '';
    });
    _searchFocus.requestFocus();
  }

  Future<void> _save() async {
    if (_cart.isEmpty) {
      showMsg(context, 'Add at least one item to the bill.');
      return;
    }
    if (_due > 0.009 && _party == null) {
      showMsg(
        context,
        'This bill has a balance. Select a customer for the udhaar khata, or collect the full amount.',
      );
      return;
    }
    if (_party != null && _party!.creditLimit > 0) {
      final state = ref.read(shopProvider);
      final projected = state.balanceOf(_party!.id) + _due;
      if (_due > 0 && projected > _party!.creditLimit) {
        final ok = await confirmDialog(
          context,
          'Credit limit crossed',
          '${_party!.name} has a credit limit of ${money(state.profile, _party!.creditLimit)}. This bill takes their balance to ${money(state.profile, projected)}. Save anyway?',
        );
        if (!ok || !mounted) return;
      }
    }
    final notifier = ref.read(shopProvider.notifier);
    final invoice = notifier.createInvoice(
      lines: _cart
          .map(
            (l) => InvoiceLine(
              productId: l.product.id,
              productName: l.product.name,
              unit: l.product.unit,
              qty: l.qty,
              unitPrice: l.product.salePrice,
              costPrice: l.product.purchasePrice,
            ),
          )
          .toList(),
      party: _party,
      discount: _discountVal,
      taxRate: _taxRate ?? ref.read(shopProvider).profile.defaultTaxRate,
      paidAmount: _paidVal,
      paymentMethod: _method == 'Udhaar' ? 'Udhaar' : _method,
    );
    if (!mounted) return;
    final profile = ref.read(shopProvider).profile;
    final partyPhone = _party?.phone ?? '';
    _reset();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Bill ${invoice.number} saved'),
        content: Text(
          'Total ${money(profile, invoice.total)} - Paid ${money(profile, invoice.paidAmount)}${invoice.balanceDue > 0 ? '\nBalance on khata: ${money(profile, invoice.balanceDue)}' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
          if (partyPhone.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () async {
                await openWhatsApp(partyPhone, billMessage(profile, invoice));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              icon: const Icon(Icons.chat_outlined, size: 17),
              label: const Text('WhatsApp'),
            ),
          FilledButton.icon(
            onPressed: () async {
              final bytes = await buildInvoicePdf(profile, invoice);
              await Printing.layoutPdf(onLayout: (_) async => bytes);
            },
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
            label: const Text('PDF'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopProvider);
    final p = state.profile;
    final s = Strings(p.isUrdu);
    if (_taxRate == null) {
      _taxRate = p.defaultTaxRate;
      _taxCtrl.text = p.defaultTaxRate == 0
          ? '0'
          : p.defaultTaxRate.toStringAsFixed(2);
    }
    final products = state.products
        .where(
          (prod) =>
              _query.isEmpty ||
              prod.name.toLowerCase().contains(_query) ||
              prod.sku.toLowerCase().contains(_query) ||
              prod.category.toLowerCase().contains(_query),
        )
        .toList();
    final customers = state.parties
        .where((x) => x.type == PartyType.customer)
        .toList();

    final productPane = Column(
      children: [
        TextField(
          controller: _search,
          focusNode: _searchFocus,
          autofocus: true,
          decoration: InputDecoration(
            hintText: s.searchProducts,
            prefixIcon: const Icon(Icons.search, size: 20),
          ),
          onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
          onSubmitted: (v) {
            if (products.length == 1) _add(products.first);
          },
        ),
        const SizedBox(height: 10),
        Expanded(
          child: products.isEmpty
              ? EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No products found',
                  message: state.products.isEmpty
                      ? 'Add products in Inventory, or load sample data from the Dashboard.'
                      : 'Try a different name, SKU or category.',
                )
              : ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final prod = products[i];
                    return ListTile(
                      dense: true,
                      title: Text(prod.name),
                      subtitle: Text(
                        '${prod.category} - Stock ${qty(prod.stock)} ${prod.unit}${prod.sku.isNotEmpty ? ' - ${prod.sku}' : ''}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            money(p, prod.salePrice),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: AppTheme.primary,
                            ),
                            onPressed: () => _add(prod),
                            tooltip: 'Add to bill',
                          ),
                        ],
                      ),
                      onTap: () => _add(prod),
                    );
                  },
                ),
        ),
      ],
    );

    final cartPane = Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.cart,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: _cart.isEmpty ? null : _reset,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(s.newBill),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _cart.isEmpty
                  ? const Center(
                      child: Text(
                        'Tap a product to add it here.',
                        style: TextStyle(color: AppTheme.muted),
                      ),
                    )
                  : ListView(
                      children: [
                        for (final line in _cart)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        line.product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        money(p, line.product.salePrice),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  onPressed: () => setState(() {
                                    line.qty -= 1;
                                    if (line.qty <= 0) _cart.remove(line);
                                    if (!_paidTouched) {
                                      _paid.text = _total.toStringAsFixed(2);
                                    }
                                  }),
                                ),
                                SizedBox(
                                  width: 34,
                                  child: Text(
                                    qty(line.qty),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
                                  onPressed: () => setState(() {
                                    line.qty += 1;
                                    if (!_paidTouched) {
                                      _paid.text = _total.toStringAsFixed(2);
                                    }
                                  }),
                                ),
                                SizedBox(
                                  width: 76,
                                  child: Text(
                                    money(p, line.amount),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    size: 17,
                                    color: AppTheme.danger,
                                  ),
                                  onPressed: () =>
                                      setState(() => _cart.remove(line)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            const Divider(),
            DropdownButtonFormField<Party?>(
              initialValue: _party,
              isExpanded: true,
              decoration: InputDecoration(labelText: s.customer),
              items: [
                DropdownMenuItem<Party?>(value: null, child: Text(s.walkIn)),
                for (final c in customers)
                  DropdownMenuItem<Party?>(
                    value: c,
                    child: Text(
                      '${c.name}${state.balanceOf(c.id) > 0 ? ' (due ${moneyShort(p, state.balanceOf(c.id))})' : ''}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _party = v),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _discount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: s.discount),
                    onChanged: (_) => setState(() {
                      if (!_paidTouched) _paid.text = _total.toStringAsFixed(2);
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _taxCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: s.tax),
                    onChanged: (v) => setState(() => _taxRate = parseAmount(v)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _paid,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: s.paid),
                    onChanged: (_) => setState(() => _paidTouched = true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _method,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Method'),
                    items: paymentMethods
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _method = v ?? 'Cash';
                      if (_method == 'Udhaar') {
                        _paid.text = '0';
                        _paidTouched = true;
                      }
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${s.total}:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  money(p, _total),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (_due > 0.009)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${s.balance} (udhaar): ${money(p, _due)}',
                  style: const TextStyle(
                    color: AppTheme.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.f2): _reset,
                const SingleActivator(LogicalKeyboardKey.enter, control: true):
                    _save,
              },
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.receipt_long_outlined, size: 19),
                label: Text('${s.saveBill}  (Ctrl+Enter)'),
              ),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth < 860) {
            return Column(
              children: [
                Expanded(flex: 5, child: productPane),
                const SizedBox(height: 12),
                Expanded(flex: 6, child: cartPane),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 6, child: productPane),
              const SizedBox(width: 14),
              Expanded(flex: 5, child: cartPane),
            ],
          );
        },
      ),
    );
  }
}
