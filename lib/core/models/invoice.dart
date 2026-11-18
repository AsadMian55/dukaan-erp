class InvoiceLine {
  final String productId;
  final String productName;
  final String unit;
  final double qty;
  final double unitPrice;
  final double costPrice;

  const InvoiceLine({
    required this.productId,
    required this.productName,
    this.unit = 'pcs',
    required this.qty,
    required this.unitPrice,
    this.costPrice = 0,
  });

  double get amount => qty * unitPrice;
  double get margin => (unitPrice - costPrice) * qty;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'unit': unit,
    'qty': qty,
    'unitPrice': unitPrice,
    'costPrice': costPrice,
  };

  factory InvoiceLine.fromJson(Map<String, dynamic> j) => InvoiceLine(
    productId: j['productId'] as String? ?? '',
    productName: j['productName'] as String? ?? '',
    unit: j['unit'] as String? ?? 'pcs',
    qty: (j['qty'] as num? ?? 0).toDouble(),
    unitPrice: (j['unitPrice'] as num? ?? 0).toDouble(),
    costPrice: (j['costPrice'] as num? ?? 0).toDouble(),
  );
}

class Invoice {
  final String id;
  final String number;
  final DateTime date;
  final String? partyId;
  final String partyName;
  final List<InvoiceLine> lines;
  final double discount;
  final double taxRate;
  final double paidAmount;
  final String paymentMethod;
  final String note;

  const Invoice({
    required this.id,
    required this.number,
    required this.date,
    this.partyId,
    this.partyName = 'Walk-in Customer',
    required this.lines,
    this.discount = 0,
    this.taxRate = 0,
    this.paidAmount = 0,
    this.paymentMethod = 'Cash',
    this.note = '',
  });

  double get subtotal => lines.fold(0, (sum, l) => sum + l.amount);
  double get taxable => subtotal - discount;
  double get taxAmount => taxable * taxRate / 100;
  double get total => taxable + taxAmount;
  double get balanceDue => total - paidAmount;
  double get grossMargin =>
      lines.fold(0.0, (sum, l) => sum + l.margin) - discount;

  bool get isPaid => balanceDue <= 0.009;
  String get status =>
      isPaid ? 'Paid' : (paidAmount > 0 ? 'Partial' : 'Udhaar');

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'date': date.toIso8601String(),
    'partyId': partyId,
    'partyName': partyName,
    'lines': lines.map((l) => l.toJson()).toList(),
    'discount': discount,
    'taxRate': taxRate,
    'paidAmount': paidAmount,
    'paymentMethod': paymentMethod,
    'note': note,
  };

  factory Invoice.fromJson(Map<String, dynamic> j) => Invoice(
    id: j['id'] as String,
    number: j['number'] as String? ?? '',
    date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
    partyId: j['partyId'] as String?,
    partyName: j['partyName'] as String? ?? 'Walk-in Customer',
    lines: ((j['lines'] as List?) ?? [])
        .map((e) => InvoiceLine.fromJson(e as Map<String, dynamic>))
        .toList(),
    discount: (j['discount'] as num? ?? 0).toDouble(),
    taxRate: (j['taxRate'] as num? ?? 0).toDouble(),
    paidAmount: (j['paidAmount'] as num? ?? 0).toDouble(),
    paymentMethod: j['paymentMethod'] as String? ?? 'Cash',
    note: j['note'] as String? ?? '',
  );
}
