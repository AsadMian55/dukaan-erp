import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/company_profile.dart';
import '../models/expense.dart';
import '../models/invoice.dart';
import '../models/ledger_entry.dart';
import '../models/party.dart';
import '../models/product.dart';
import '../utils/format.dart';
import 'sample_data.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();

class ShopState {
  final List<Product> products;
  final List<Party> parties;
  final List<Invoice> invoices;
  final List<LedgerEntry> ledger;
  final List<Expense> expenses;
  final CompanyProfile profile;
  final int invoiceSeq;

  const ShopState({
    this.products = const [],
    this.parties = const [],
    this.invoices = const [],
    this.ledger = const [],
    this.expenses = const [],
    this.profile = const CompanyProfile(),
    this.invoiceSeq = 0,
  });

  bool get isEmpty => products.isEmpty && invoices.isEmpty && parties.isEmpty;

  ShopState copyWith({
    List<Product>? products,
    List<Party>? parties,
    List<Invoice>? invoices,
    List<LedgerEntry>? ledger,
    List<Expense>? expenses,
    CompanyProfile? profile,
    int? invoiceSeq,
  }) {
    return ShopState(
      products: products ?? this.products,
      parties: parties ?? this.parties,
      invoices: invoices ?? this.invoices,
      ledger: ledger ?? this.ledger,
      expenses: expenses ?? this.expenses,
      profile: profile ?? this.profile,
      invoiceSeq: invoiceSeq ?? this.invoiceSeq,
    );
  }

  Party? partyById(String partyId) {
    for (final p in parties) {
      if (p.id == partyId) return p;
    }
    return null;
  }

  double balanceOf(String partyId) {
    var total = partyById(partyId)?.openingBalance ?? 0;
    for (final e in ledger.where((e) => e.partyId == partyId)) {
      total += e.delta;
    }
    return round2(total);
  }

  List<LedgerEntry> ledgerOf(String partyId) {
    final list = ledger.where((e) => e.partyId == partyId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  DateTime? oldestDueDate(String partyId) {
    final entries = ledgerOf(partyId);
    var running = partyById(partyId)?.openingBalance ?? 0;
    DateTime? since;
    for (final e in entries) {
      running += e.delta;
      if (running > 0.009 && since == null) since = e.date;
      if (running <= 0.009) since = null;
    }
    return balanceOf(partyId) > 0.009 ? since : null;
  }

  double get totalReceivables => parties
      .where((p) => p.type == PartyType.customer)
      .fold(0.0, (s, p) => s + (balanceOf(p.id) > 0 ? balanceOf(p.id) : 0));

  double get totalPayables => parties
      .where((p) => p.type == PartyType.supplier)
      .fold(0.0, (s, p) => s + (balanceOf(p.id) > 0 ? balanceOf(p.id) : 0));

  double salesOn(DateTime day) => invoices
      .where((i) => isSameDay(i.date, day))
      .fold(0.0, (s, i) => s + i.total);

  double receivedOn(DateTime day) => invoices
      .where((i) => isSameDay(i.date, day))
      .fold(0.0, (s, i) => s + i.paidAmount);

  double get stockValueCost =>
      products.fold(0.0, (s, p) => s + p.stock * p.purchasePrice);

  List<Product> get lowStock =>
      products.where((p) => p.isLowStock).toList()
        ..sort((a, b) => a.stock.compareTo(b.stock));

  Map<String, dynamic> toJson() => {
    'products': products.map((e) => e.toJson()).toList(),
    'parties': parties.map((e) => e.toJson()).toList(),
    'invoices': invoices.map((e) => e.toJson()).toList(),
    'ledger': ledger.map((e) => e.toJson()).toList(),
    'expenses': expenses.map((e) => e.toJson()).toList(),
    'profile': profile.toJson(),
    'invoiceSeq': invoiceSeq,
  };

  factory ShopState.fromJson(Map<String, dynamic> j) => ShopState(
    products: ((j['products'] as List?) ?? [])
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList(),
    parties: ((j['parties'] as List?) ?? [])
        .map((e) => Party.fromJson(e as Map<String, dynamic>))
        .toList(),
    invoices: ((j['invoices'] as List?) ?? [])
        .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
        .toList(),
    ledger: ((j['ledger'] as List?) ?? [])
        .map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    expenses: ((j['expenses'] as List?) ?? [])
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList(),
    profile: CompanyProfile.fromJson(
      (j['profile'] as Map<String, dynamic>?) ?? {},
    ),
    invoiceSeq: (j['invoiceSeq'] as num? ?? 0).toInt(),
  );
}

class ShopNotifier extends StateNotifier<ShopState> {
  final Box<String> _box;
  ShopNotifier(this._box, ShopState initial) : super(initial);

  static const _key = 'shop_state_v1';

  static ShopState load(Box<String> box) {
    final raw = box.get(_key);
    if (raw == null || raw.isEmpty) return const ShopState();
    try {
      return ShopState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // A corrupted local snapshot should never lock the shop out of the app;
      // the backup file is the recovery path, so start clean instead.
      return const ShopState();
    }
  }

  void _commit(ShopState next) {
    state = next;
    _box.put(_key, jsonEncode(next.toJson()));
  }

  void updateProfile(CompanyProfile profile) =>
      _commit(state.copyWith(profile: profile));

  void upsertProduct(Product product) {
    final list = [...state.products];
    final i = list.indexWhere((p) => p.id == product.id);
    if (i >= 0) {
      list[i] = product;
    } else {
      list.add(product);
    }
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _commit(state.copyWith(products: list));
  }

  void deleteProduct(String id) => _commit(
    state.copyWith(products: state.products.where((p) => p.id != id).toList()),
  );

  void adjustStock(String id, double delta) {
    _commit(
      state.copyWith(
        products: state.products
            .map(
              (p) => p.id == id
                  ? p.copyWith(
                      stock: round2(p.stock + delta),
                      updatedAt: DateTime.now(),
                    )
                  : p,
            )
            .toList(),
      ),
    );
  }

  void upsertParty(Party party) {
    final list = [...state.parties];
    final i = list.indexWhere((p) => p.id == party.id);
    if (i >= 0) {
      list[i] = party;
    } else {
      list.add(party);
    }
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _commit(state.copyWith(parties: list));
  }

  void deleteParty(String id) {
    _commit(
      state.copyWith(
        parties: state.parties.where((p) => p.id != id).toList(),
        ledger: state.ledger.where((e) => e.partyId != id).toList(),
      ),
    );
  }

  void addLedgerEntry(LedgerEntry entry) =>
      _commit(state.copyWith(ledger: [...state.ledger, entry]));

  void recordPayment({
    required Party party,
    required double amount,
    required String method,
    String note = '',
    DateTime? date,
  }) {
    addLedgerEntry(
      LedgerEntry(
        id: newId(),
        partyId: party.id,
        date: date ?? DateTime.now(),
        kind: party.type == PartyType.customer
            ? 'Payment received'
            : 'Payment made',
        delta: -round2(amount),
        paymentMethod: method,
        note: note,
      ),
    );
  }

  Invoice createInvoice({
    required List<InvoiceLine> lines,
    required Party? party,
    required double discount,
    required double taxRate,
    required double paidAmount,
    required String paymentMethod,
    String note = '',
  }) {
    final seq = state.invoiceSeq + 1;
    final invoice = Invoice(
      id: newId(),
      number: 'INV-${seq.toString().padLeft(4, '0')}',
      date: DateTime.now(),
      partyId: party?.id,
      partyName: party?.name ?? 'Walk-in Customer',
      lines: lines,
      discount: round2(discount),
      taxRate: taxRate,
      paidAmount: round2(paidAmount),
      paymentMethod: paymentMethod,
      note: note,
    );

    var products = [...state.products];
    for (final line in lines) {
      final i = products.indexWhere((p) => p.id == line.productId);
      if (i >= 0) {
        products[i] = products[i].copyWith(
          stock: round2(products[i].stock - line.qty),
          updatedAt: DateTime.now(),
        );
      }
    }

    final ledger = [...state.ledger];
    final due = invoice.balanceDue;
    if (due > 0.009 && party != null) {
      ledger.add(
        LedgerEntry(
          id: newId(),
          partyId: party.id,
          date: invoice.date,
          kind: 'Udhaar sale ${invoice.number}',
          delta: round2(due),
          paymentMethod: 'Udhaar',
          invoiceId: invoice.id,
        ),
      );
    }

    _commit(
      state.copyWith(
        products: products,
        invoices: [invoice, ...state.invoices],
        ledger: ledger,
        invoiceSeq: seq,
      ),
    );
    return invoice;
  }

  void addExpense(Expense expense) =>
      _commit(state.copyWith(expenses: [expense, ...state.expenses]));

  void deleteExpense(String id) => _commit(
    state.copyWith(expenses: state.expenses.where((e) => e.id != id).toList()),
  );

  void loadSampleData() => _commit(buildSampleData(state.profile));

  void replaceAll(ShopState next) => _commit(next);

  void mergeAll(ShopState incoming) {
    List<T> mergeById<T>(List<T> base, List<T> extra, String Function(T) idOf) {
      final map = {for (final e in base) idOf(e): e};
      for (final e in extra) {
        map[idOf(e)] = e;
      }
      return map.values.toList();
    }

    _commit(
      ShopState(
        products: mergeById(state.products, incoming.products, (e) => e.id),
        parties: mergeById(state.parties, incoming.parties, (e) => e.id),
        invoices: mergeById(state.invoices, incoming.invoices, (e) => e.id),
        ledger: mergeById(state.ledger, incoming.ledger, (e) => e.id),
        expenses: mergeById(state.expenses, incoming.expenses, (e) => e.id),
        profile: state.profile,
        invoiceSeq: state.invoiceSeq > incoming.invoiceSeq
            ? state.invoiceSeq
            : incoming.invoiceSeq,
      ),
    );
  }

  void clearAll() => _commit(ShopState(profile: state.profile));
}

final shopBoxProvider = Provider<Box<String>>(
  (ref) => throw UnimplementedError('shop box not initialised'),
);

final shopProvider = StateNotifierProvider<ShopNotifier, ShopState>((ref) {
  final box = ref.watch(shopBoxProvider);
  return ShopNotifier(box, ShopNotifier.load(box));
});
