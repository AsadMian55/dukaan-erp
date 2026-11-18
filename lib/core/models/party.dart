enum PartyType { customer, supplier }

class Party {
  final String id;
  final String name;
  final String phone;
  final String address;
  final PartyType type;
  final double openingBalance;
  final double creditLimit;
  final String note;
  final DateTime createdAt;

  const Party({
    required this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.type = PartyType.customer,
    this.openingBalance = 0,
    this.creditLimit = 0,
    this.note = '',
    required this.createdAt,
  });

  Party copyWith({
    String? name,
    String? phone,
    String? address,
    PartyType? type,
    double? openingBalance,
    double? creditLimit,
    String? note,
  }) {
    return Party(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      type: type ?? this.type,
      openingBalance: openingBalance ?? this.openingBalance,
      creditLimit: creditLimit ?? this.creditLimit,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'address': address,
    'type': type.name,
    'openingBalance': openingBalance,
    'creditLimit': creditLimit,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Party.fromJson(Map<String, dynamic> j) => Party(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    address: j['address'] as String? ?? '',
    type: PartyType.values.firstWhere(
      (t) => t.name == (j['type'] as String? ?? 'customer'),
      orElse: () => PartyType.customer,
    ),
    openingBalance: (j['openingBalance'] as num? ?? 0).toDouble(),
    creditLimit: (j['creditLimit'] as num? ?? 0).toDouble(),
    note: j['note'] as String? ?? '',
    createdAt:
        DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
}
