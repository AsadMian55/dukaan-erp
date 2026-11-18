import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/app_state.dart';
import '../../core/i18n/strings.dart';
import '../../core/models/ledger_entry.dart';
import '../../core/models/party.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';

class PartiesScreen extends ConsumerStatefulWidget {
  const PartiesScreen({super.key});

  @override
  ConsumerState<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends ConsumerState<PartiesScreen> {
  String _query = '';
  PartyType _tab = PartyType.customer;
  Party? _selected;

  Future<void> _showForm([Party? existing]) async {
    final saved = await showDialog<Party>(
      context: context,
      builder: (_) => _PartyForm(existing: existing, defaultType: _tab),
    );
    if (saved != null) {
      ref.read(shopProvider.notifier).upsertParty(saved);
      setState(() => _selected = saved);
    }
  }

  Future<void> _recordPayment(Party party) async {
    final state = ref.read(shopProvider);
    final amount = TextEditingController();
    var method = 'Cash';
    final done = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          state.partyById(party.id)?.type == PartyType.customer
              ? 'Payment received - ${party.name}'
              : 'Payment made - ${party.name}',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current balance: ${money(state.profile, state.balanceOf(party.id))}',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: method,
              decoration: const InputDecoration(labelText: 'Method'),
              items: paymentMethods
                  .where((m) => m != 'Udhaar')
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => method = v ?? 'Cash',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save payment'),
          ),
        ],
      ),
    );
    if (done == true && parseAmount(amount.text) > 0) {
      ref
          .read(shopProvider.notifier)
          .recordPayment(
            party: party,
            amount: parseAmount(amount.text),
            method: method,
          );
      if (mounted) showMsg(context, 'Payment recorded.');
    }
  }

  Future<void> _manualEntry(Party party) async {
    final amount = TextEditingController();
    final note = TextEditingController();
    var increases = true;
    final done = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Khata entry - ${party.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                decoration: const InputDecoration(
                  labelText: 'Note (e.g. previous udhaar, stock on credit)',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<bool>(
                initialValue: true,
                decoration: const InputDecoration(labelText: 'Effect'),
                items: [
                  DropdownMenuItem(
                    value: true,
                    child: Text(
                      party.type == PartyType.customer
                          ? 'Balance increases (they took udhaar)'
                          : 'Balance increases (we took stock on credit)',
                    ),
                  ),
                  const DropdownMenuItem(
                    value: false,
                    child: Text('Balance decreases'),
                  ),
                ],
                onChanged: (v) => setLocal(() => increases = v ?? true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save entry'),
            ),
          ],
        ),
      ),
    );
    if (done == true && parseAmount(amount.text) > 0) {
      ref
          .read(shopProvider.notifier)
          .addLedgerEntry(
            // Manual entries cover the paper-khata opening balances and
            // supplier credit purchases that never pass through the POS.
            _entryFor(party, amount.text, note.text, increases),
          );
      if (mounted) showMsg(context, 'Khata entry saved.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopProvider);
    final p = state.profile;
    final s = Strings(p.isUrdu);
    final parties =
        state.parties.where((x) {
          return x.type == _tab &&
              (_query.isEmpty ||
                  x.name.toLowerCase().contains(_query) ||
                  x.phone.contains(_query));
        }).toList()..sort(
          (a, b) => state.balanceOf(b.id).compareTo(state.balanceOf(a.id)),
        );

    final listPane = Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SegmentedButton<PartyType>(
                segments: const [
                  ButtonSegment(
                    value: PartyType.customer,
                    icon: Icon(Icons.people_outline, size: 17),
                    label: Text('Customers'),
                  ),
                  ButtonSegment(
                    value: PartyType.supplier,
                    icon: Icon(Icons.local_shipping_outlined, size: 17),
                    label: Text('Suppliers'),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (v) => setState(() {
                  _tab = v.first;
                  _selected = null;
                }),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add, size: 18),
              label: Text(s.addParty),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search name or phone...',
            prefixIcon: Icon(Icons.search, size: 20),
          ),
          onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _tab == PartyType.customer
                ? 'Total to receive: ${money(p, state.totalReceivables)}'
                : 'Total to pay: ${money(p, state.totalPayables)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: parties.isEmpty
              ? const EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'No names yet',
                  message:
                      'Add a customer or supplier to start their khata. Every udhaar bill and payment lands here automatically.',
                )
              : ListView.separated(
                  itemCount: parties.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final party = parties[i];
                    final balance = state.balanceOf(party.id);
                    final since = state.oldestDueDate(party.id);
                    final age = since == null
                        ? 0
                        : daysBetween(since, DateTime.now());
                    return ListTile(
                      selected: _selected?.id == party.id,
                      title: Text(party.name),
                      subtitle: Text(
                        [
                          if (party.phone.isNotEmpty) party.phone,
                          if (since != null)
                            'due since ${dateFmt(since)} ($age days)',
                          if (party.creditLimit > 0)
                            'limit ${moneyShort(p, party.creditLimit)}',
                        ].join(' - '),
                      ),
                      trailing: Text(
                        balance > 0.009
                            ? money(p, balance)
                            : balance < -0.009
                            ? '${money(p, balance)} adv.'
                            : 'Clear',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: balance > 0.009
                              ? (age > 60 ? AppTheme.danger : AppTheme.warning)
                              : AppTheme.primary,
                        ),
                      ),
                      onTap: () => setState(() => _selected = party),
                    );
                  },
                ),
        ),
      ],
    );

    final detailPane = _selected == null
        ? const EmptyState(
            icon: Icons.touch_app_outlined,
            title: 'Select a name',
            message:
                'Pick a customer or supplier to see their full khata, record a payment, or send a WhatsApp reminder.',
          )
        : _PartyDetail(
            party: state.partyById(_selected!.id) ?? _selected!,
            onPayment: () =>
                _recordPayment(state.partyById(_selected!.id) ?? _selected!),
            onEntry: () =>
                _manualEntry(state.partyById(_selected!.id) ?? _selected!),
            onEdit: () =>
                _showForm(state.partyById(_selected!.id) ?? _selected!),
          );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth < 860) {
            return Column(
              children: [
                Expanded(child: listPane),
                if (_selected != null) ...[
                  const SizedBox(height: 12),
                  Expanded(child: Card(child: detailPane)),
                ],
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: listPane),
              const SizedBox(width: 14),
              Expanded(flex: 6, child: Card(child: detailPane)),
            ],
          );
        },
      ),
    );
  }
}

LedgerEntry _entryFor(
  Party party,
  String amountText,
  String note,
  bool increases,
) {
  return LedgerEntry(
    id: newId(),
    partyId: party.id,
    date: DateTime.now(),
    kind: note.trim().isEmpty ? 'Manual khata entry' : note.trim(),
    delta: (increases ? 1 : -1) * parseAmount(amountText),
    paymentMethod: 'Udhaar',
    note: note.trim(),
  );
}

class _PartyDetail extends ConsumerWidget {
  final Party party;
  final VoidCallback onPayment;
  final VoidCallback onEntry;
  final VoidCallback onEdit;

  const _PartyDetail({
    required this.party,
    required this.onPayment,
    required this.onEntry,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shopProvider);
    final p = state.profile;
    final balance = state.balanceOf(party.id);
    final entries = state.ledgerOf(party.id).reversed.toList();
    var running = party.openingBalance;
    final runningById = <String, double>{};
    for (final e in state.ledgerOf(party.id)) {
      running += e.delta;
      runningById[e.id] = running;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      party.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (party.phone.isNotEmpty || party.address.isNotEmpty)
                      Text(
                        [
                          party.phone,
                          party.address,
                        ].where((x) => x.isNotEmpty).join(' - '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 19),
                tooltip: 'Edit',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current balance'),
                Text(
                  money(p, balance),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onPayment,
                icon: const Icon(Icons.payments_outlined, size: 17),
                label: const Text('Record payment'),
              ),
              OutlinedButton.icon(
                onPressed: onEntry,
                icon: const Icon(Icons.post_add_outlined, size: 17),
                label: const Text('Khata entry'),
              ),
              if (party.phone.isNotEmpty && balance > 0.009)
                OutlinedButton.icon(
                  onPressed: () => openWhatsApp(
                    party.phone,
                    reminderMessage(
                      p,
                      party.name,
                      balance,
                      state.oldestDueDate(party.id),
                    ),
                  ),
                  icon: const Icon(Icons.chat_outlined, size: 17),
                  label: const Text('WhatsApp reminder'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          Expanded(
            child: entries.isEmpty && party.openingBalance == 0
                ? const Center(
                    child: Text(
                      'No khata entries yet.',
                      style: TextStyle(color: AppTheme.muted),
                    ),
                  )
                : ListView(
                    children: [
                      if (party.openingBalance != 0)
                        ListTile(
                          dense: true,
                          title: const Text('Opening balance'),
                          subtitle: Text(dateFmt(party.createdAt)),
                          trailing: Text(
                            money(p, party.openingBalance),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      for (final e in entries)
                        ListTile(
                          dense: true,
                          title: Text(e.kind),
                          subtitle: Text(
                            '${dateFmt(e.date)} - ${e.paymentMethod}${e.note.isNotEmpty ? ' - ${e.note}' : ''}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${e.delta >= 0 ? '+' : '-'} ${money(p, e.delta.abs())}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: e.delta >= 0
                                      ? AppTheme.warning
                                      : AppTheme.primary,
                                ),
                              ),
                              Text(
                                'Bal ${money(p, runningById[e.id] ?? 0)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _PartyForm extends StatefulWidget {
  final Party? existing;
  final PartyType defaultType;
  const _PartyForm({this.existing, required this.defaultType});

  @override
  State<_PartyForm> createState() => _PartyFormState();
}

class _PartyFormState extends State<_PartyForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _opening;
  late final TextEditingController _limit;
  late PartyType _type;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? widget.defaultType;
    _name = TextEditingController(text: e?.name ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _address = TextEditingController(text: e?.address ?? '');
    _opening = TextEditingController(
      text: e == null ? '0' : e.openingBalance.toStringAsFixed(2),
    );
    _limit = TextEditingController(
      text: e == null ? '0' : e.creditLimit.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _opening, _limit]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add name' : 'Edit name'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<PartyType>(
                  segments: const [
                    ButtonSegment(
                      value: PartyType.customer,
                      label: Text('Customer'),
                    ),
                    ButtonSegment(
                      value: PartyType.supplier,
                      label: Text('Supplier'),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (v) => setState(() => _type = v.first),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: requiredText,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile / WhatsApp number',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _address,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _opening,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Opening balance (old khata)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _limit,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Credit limit (0 = no limit)',
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
              Party(
                id: widget.existing?.id ?? newId(),
                name: _name.text.trim(),
                phone: _phone.text.trim(),
                address: _address.text.trim(),
                type: _type,
                openingBalance: parseAmount(_opening.text),
                creditLimit: parseAmount(_limit.text),
                note: widget.existing?.note ?? '',
                createdAt: widget.existing?.createdAt ?? DateTime.now(),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
