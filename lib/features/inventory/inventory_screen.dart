import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/app_state.dart';
import '../../core/i18n/strings.dart';
import '../../core/models/product.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _query = '';
  bool _lowOnly = false;

  Future<void> _showForm([Product? existing]) async {
    final saved = await showDialog<Product>(
      context: context,
      builder: (_) => _ProductForm(existing: existing),
    );
    if (saved != null) {
      ref.read(shopProvider.notifier).upsertProduct(saved);
      if (mounted) {
        showMsg(context, '${saved.name} saved.');
      }
    }
  }

  Future<void> _adjust(Product p) async {
    final controller = TextEditingController();
    final delta = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Adjust stock - ${p.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current stock: ${qty(p.stock)} ${p.unit}'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Add or remove (e.g. 10 or -2)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, parseAmount(controller.text)),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (delta != null && delta != 0) {
      ref.read(shopProvider.notifier).adjustStock(p.id, delta);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopProvider);
    final p = state.profile;
    final s = Strings(p.isUrdu);
    var products = state.products.where((prod) {
      final matches =
          _query.isEmpty ||
          prod.name.toLowerCase().contains(_query) ||
          prod.sku.toLowerCase().contains(_query) ||
          prod.category.toLowerCase().contains(_query);
      return matches && (!_lowOnly || prod.isLowStock);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search name, SKU or category...',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                  onChanged: (v) =>
                      setState(() => _query = v.toLowerCase().trim()),
                ),
              ),
              const SizedBox(width: 10),
              FilterChip(
                label: Text(s.lowStock),
                selected: _lowOnly,
                onSelected: (v) => setState(() => _lowOnly = v),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: () => _showForm(),
                icon: const Icon(Icons.add, size: 18),
                label: Text(s.addProduct),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${products.length} products - stock value ${money(p, state.stockValueCost)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: products.isEmpty
                ? EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Nothing here yet',
                    message:
                        'Add your first product with its purchase price, sale price and opening stock.',
                  )
                : Card(
                    child: SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Product')),
                            DataColumn(label: Text('Category')),
                            DataColumn(label: Text('SKU')),
                            DataColumn(label: Text('Buy'), numeric: true),
                            DataColumn(label: Text('Sell'), numeric: true),
                            DataColumn(label: Text('Stock'), numeric: true),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: [
                            for (final prod in products)
                              DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      prod.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(prod.category)),
                                  DataCell(Text(prod.sku)),
                                  DataCell(Text(money(p, prod.purchasePrice))),
                                  DataCell(Text(money(p, prod.salePrice))),
                                  DataCell(
                                    Text(
                                      '${qty(prod.stock)} ${prod.unit}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: prod.isOutOfStock
                                            ? AppTheme.danger
                                            : prod.isLowStock
                                            ? AppTheme.warning
                                            : AppTheme.ink,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.tune,
                                            size: 18,
                                          ),
                                          tooltip: 'Adjust stock',
                                          onPressed: () => _adjust(prod),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                          ),
                                          tooltip: 'Edit',
                                          onPressed: () => _showForm(prod),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color: AppTheme.danger,
                                          ),
                                          tooltip: 'Delete',
                                          onPressed: () async {
                                            final ok = await confirmDialog(
                                              context,
                                              'Delete product?',
                                              'Delete ${prod.name}? Past bills keep their own copy of the name and price.',
                                            );
                                            if (ok && mounted) {
                                              ref
                                                  .read(shopProvider.notifier)
                                                  .deleteProduct(prod.id);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProductForm extends StatefulWidget {
  final Product? existing;
  const _ProductForm({this.existing});

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _sku;
  late final TextEditingController _category;
  late final TextEditingController _unit;
  late final TextEditingController _buy;
  late final TextEditingController _sell;
  late final TextEditingController _stock;
  late final TextEditingController _lowAt;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _sku = TextEditingController(text: e?.sku ?? '');
    _category = TextEditingController(text: e?.category ?? 'General');
    _unit = TextEditingController(text: e?.unit ?? 'pcs');
    _buy = TextEditingController(
      text: e == null ? '' : e.purchasePrice.toStringAsFixed(2),
    );
    _sell = TextEditingController(
      text: e == null ? '' : e.salePrice.toStringAsFixed(2),
    );
    _stock = TextEditingController(text: e == null ? '0' : qty(e.stock));
    _lowAt = TextEditingController(text: e == null ? '5' : qty(e.lowStockAt));
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _sku,
      _category,
      _unit,
      _buy,
      _sell,
      _stock,
      _lowAt,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add product' : 'Edit product'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Product name'),
                  validator: requiredText,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sku,
                        decoration: const InputDecoration(
                          labelText: 'SKU / barcode',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _unit,
                        decoration: const InputDecoration(
                          labelText: 'Unit (pcs, kg, litre)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _buy,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Purchase price',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _sell,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Sale price',
                        ),
                        validator: requiredText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stock,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Current stock',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _lowAt,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Low stock alert at',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.pop(
              context,
              Product(
                id: widget.existing?.id ?? newId(),
                name: _name.text.trim(),
                sku: _sku.text.trim(),
                category: _category.text.trim().isEmpty
                    ? 'General'
                    : _category.text.trim(),
                unit: _unit.text.trim().isEmpty ? 'pcs' : _unit.text.trim(),
                purchasePrice: parseAmount(_buy.text),
                salePrice: parseAmount(_sell.text),
                stock: parseAmount(_stock.text),
                lowStockAt: parseAmount(_lowAt.text),
                updatedAt: DateTime.now(),
              ),
            );
          },
          child: const Text('Save product'),
        ),
      ],
    );
  }
}
