class Expense {
  final String id;
  final DateTime date;
  final String category;
  final String title;
  final double amount;
  final String paymentMethod;
  final String note;

  const Expense({
    required this.id,
    required this.date,
    this.category = 'General',
    required this.title,
    required this.amount,
    this.paymentMethod = 'Cash',
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'category': category,
    'title': title,
    'amount': amount,
    'paymentMethod': paymentMethod,
    'note': note,
  };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
    id: j['id'] as String,
    date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
    category: j['category'] as String? ?? 'General',
    title: j['title'] as String? ?? '',
    amount: (j['amount'] as num? ?? 0).toDouble(),
    paymentMethod: j['paymentMethod'] as String? ?? 'Cash',
    note: j['note'] as String? ?? '',
  );
}
