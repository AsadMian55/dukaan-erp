/// A single khata movement. [delta] is signed from the shop's point of view:
/// for a customer, + means the customer owes more, - means they paid.
/// For a supplier, + means the shop owes more, - means the shop paid.
class LedgerEntry {
  final String id;
  final String partyId;
  final DateTime date;
  final String kind;
  final double delta;
  final String paymentMethod;
  final String? invoiceId;
  final String note;

  const LedgerEntry({
    required this.id,
    required this.partyId,
    required this.date,
    required this.kind,
    required this.delta,
    this.paymentMethod = 'Cash',
    this.invoiceId,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'partyId': partyId,
    'date': date.toIso8601String(),
    'kind': kind,
    'delta': delta,
    'paymentMethod': paymentMethod,
    'invoiceId': invoiceId,
    'note': note,
  };

  factory LedgerEntry.fromJson(Map<String, dynamic> j) => LedgerEntry(
    id: j['id'] as String,
    partyId: j['partyId'] as String? ?? '',
    date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
    kind: j['kind'] as String? ?? 'Entry',
    delta: (j['delta'] as num? ?? 0).toDouble(),
    paymentMethod: j['paymentMethod'] as String? ?? 'Cash',
    invoiceId: j['invoiceId'] as String?,
    note: j['note'] as String? ?? '',
  );
}
