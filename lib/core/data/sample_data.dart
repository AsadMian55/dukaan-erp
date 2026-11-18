import '../models/company_profile.dart';
import '../models/expense.dart';
import '../models/invoice.dart';
import '../models/ledger_entry.dart';
import '../models/party.dart';
import '../models/product.dart';
import 'app_state.dart';

/// Demo business used by the one-click sample load and by screenshots.
/// Stock figures are post-sale, so the seeded invoices are inserted as
/// history instead of going through createInvoice (which would deduct twice).
ShopState buildSampleData(CompanyProfile current) {
  final now = DateTime.now();
  DateTime daysAgo(int d, [int hour = 11]) =>
      DateTime(now.year, now.month, now.day, hour).subtract(Duration(days: d));

  final profile = current.copyWith(
    shopName: 'Al-Madina Kiryana & General Store',
    ownerName: 'Muhammad Asad',
    phone: '03205272752',
    address: 'Main Bazaar Road, Lahore',
    currencyCode: current.currencyCode,
  );

  var n = 0;
  String pid() => 'sample-product-${++n}';
  String qtyUnit(String name) {
    if (name.contains('Oil') ||
        name.contains('Milk') ||
        name.contains('Drink')) {
      return 'litre';
    }
    if (name.contains('Rice') ||
        name.contains('Flour') ||
        name.contains('Sugar') ||
        name.contains('Daal')) {
      return 'kg';
    }
    return 'pcs';
  }

  final raw = <List<Object>>[
    [
      'Tapal Danedar Tea 450g',
      '8991234500011',
      'Grocery',
      720.0,
      850.0,
      34.0,
      8.0,
    ],
    [
      'National Basmati Rice',
      '8991234500028',
      'Grocery',
      310.0,
      380.0,
      120.0,
      25.0,
    ],
    [
      'Sunridge Chakki Flour 10kg',
      '8991234500035',
      'Grocery',
      1180.0,
      1350.0,
      18.0,
      6.0,
    ],
    ['White Sugar', '8991234500042', 'Grocery', 148.0, 175.0, 85.0, 20.0],
    ['Daal Chana', '8991234500059', 'Grocery', 265.0, 320.0, 42.0, 10.0],
    [
      'Dalda Cooking Oil 1L',
      '8991234500066',
      'Grocery',
      540.0,
      620.0,
      4.0,
      10.0,
    ],
    ['Olpers Milk 1L', '8991234500073', 'Dairy', 245.0, 280.0, 26.0, 12.0],
    ['Dawn Bread Large', '8991234500080', 'Dairy', 105.0, 130.0, 14.0, 6.0],
    ['Eggs (Dozen)', '8991234500097', 'Dairy', 330.0, 390.0, 22.0, 8.0],
    ['Nestle Yogurt 400g', '8991234500103', 'Dairy', 150.0, 185.0, 9.0, 6.0],
    ['Pepsi 1.5L', '8991234500110', 'Beverages', 145.0, 180.0, 48.0, 12.0],
    ['Pakola 1.5L', '8991234500127', 'Beverages', 140.0, 175.0, 31.0, 12.0],
    [
      'Nestle Mineral Water 1.5L',
      '8991234500134',
      'Beverages',
      75.0,
      100.0,
      60.0,
      15.0,
    ],
    ['Surf Excel 1kg', '8991234500141', 'Household', 460.0, 540.0, 16.0, 5.0],
    ['Lux Soap 100g', '8991234500158', 'Household', 95.0, 120.0, 3.0, 10.0],
    [
      'Colgate Toothpaste 140g',
      '8991234500165',
      'Household',
      285.0,
      340.0,
      19.0,
      5.0,
    ],
    [
      'Shan Biryani Masala',
      '8991234500172',
      'Grocery',
      95.0,
      120.0,
      44.0,
      10.0,
    ],
    [
      'Knorr Noodles (Pack of 6)',
      '8991234500189',
      'Snacks',
      290.0,
      350.0,
      27.0,
      8.0,
    ],
    ['LU Prince Biscuits', '8991234500196', 'Snacks', 55.0, 70.0, 73.0, 20.0],
    ['Lays Masala 65g', '8991234500202', 'Snacks', 68.0, 90.0, 51.0, 15.0],
    [
      'Panadol Extra (Strip)',
      '8991234500219',
      'Pharmacy',
      42.0,
      55.0,
      38.0,
      10.0,
    ],
    [
      'Dettol Antiseptic 250ml',
      '8991234500226',
      'Pharmacy',
      310.0,
      375.0,
      11.0,
      4.0,
    ],
    ['Jazz Load Card 100', '8991234500233', 'Mobile', 97.0, 100.0, 25.0, 5.0],
    ['LED Bulb 12W', '8991234500240', 'Household', 220.0, 300.0, 13.0, 4.0],
  ];

  final products = raw.map((r) {
    final name = r[0] as String;
    return Product(
      id: pid(),
      name: name,
      sku: r[1] as String,
      category: r[2] as String,
      unit: qtyUnit(name),
      purchasePrice: r[3] as double,
      salePrice: r[4] as double,
      stock: r[5] as double,
      lowStockAt: r[6] as double,
      updatedAt: now,
    );
  }).toList();

  Product byName(String part) =>
      products.firstWhere((p) => p.name.contains(part));

  final customers = <Party>[
    Party(
      id: 'sample-cust-1',
      name: 'Ahmed Raza',
      phone: '03001234567',
      address: 'Street 4, Model Town',
      type: PartyType.customer,
      creditLimit: 30000,
      createdAt: daysAgo(40),
    ),
    Party(
      id: 'sample-cust-2',
      name: 'Fatima Bibi',
      phone: '03219876543',
      address: 'House 12, Block C',
      type: PartyType.customer,
      creditLimit: 15000,
      createdAt: daysAgo(35),
    ),
    Party(
      id: 'sample-cust-3',
      name: 'Bilal Hussain',
      phone: '03335557799',
      address: 'Main Bazaar, Shop 9',
      type: PartyType.customer,
      creditLimit: 20000,
      createdAt: daysAgo(28),
    ),
    Party(
      id: 'sample-cust-4',
      name: 'Ayesha Khan',
      phone: '03451112233',
      address: 'Street 9, Gulberg',
      type: PartyType.customer,
      creditLimit: 25000,
      createdAt: daysAgo(21),
    ),
    Party(
      id: 'sample-cust-5',
      name: 'Chacha Kareem',
      phone: '03007776655',
      address: 'Purani Gali, House 3',
      type: PartyType.customer,
      createdAt: daysAgo(18),
    ),
    Party(
      id: 'sample-cust-6',
      name: 'Usman Tariq',
      phone: '03224446688',
      address: 'Hostel Road',
      type: PartyType.customer,
      createdAt: daysAgo(9),
    ),
  ];
  final suppliers = <Party>[
    Party(
      id: 'sample-supp-1',
      name: 'Lahore Wholesale Traders',
      phone: '04235778899',
      address: 'Shah Alam Market',
      type: PartyType.supplier,
      createdAt: daysAgo(45),
    ),
    Party(
      id: 'sample-supp-2',
      name: 'Punjab Dairy Distributors',
      phone: '03008881122',
      address: 'Multan Road',
      type: PartyType.supplier,
      createdAt: daysAgo(30),
    ),
  ];

  Invoice inv(
    String id,
    String number,
    DateTime date,
    Party? party,
    List<InvoiceLine> lines, {
    double paid = 0,
    String method = 'Cash',
    double discount = 0,
  }) {
    return Invoice(
      id: id,
      number: number,
      date: date,
      partyId: party?.id,
      partyName: party?.name ?? 'Walk-in Customer',
      lines: lines,
      discount: discount,
      paidAmount: paid,
      paymentMethod: method,
    );
  }

  InvoiceLine line(Product p, double q) => InvoiceLine(
    productId: p.id,
    productName: p.name,
    unit: p.unit,
    qty: q,
    unitPrice: p.salePrice,
    costPrice: p.purchasePrice,
  );

  final tea = byName('Tea');
  final rice = byName('Rice');
  final oil = byName('Oil');
  final milk = byName('Milk');
  final sugar = byName('Sugar');
  final surf = byName('Surf');
  final pepsi = byName('Pepsi');

  final invoices = <Invoice>[
    inv(
      'sample-inv-1',
      'INV-0001',
      daysAgo(6),
      customers[0],
      [line(rice, 5), line(oil, 2), line(tea, 1)],
      paid: 2000,
      method: 'Cash',
    ),
    inv(
      'sample-inv-2',
      'INV-0002',
      daysAgo(5),
      customers[1],
      [line(milk, 4), line(sugar, 3)],
      paid: 0,
      method: 'Udhaar',
    ),
    inv(
      'sample-inv-3',
      'INV-0003',
      daysAgo(3),
      null,
      [line(pepsi, 6), line(surf, 1)],
      paid: 1620,
      method: 'JazzCash',
    ),
    inv(
      'sample-inv-4',
      'INV-0004',
      daysAgo(1),
      customers[2],
      [line(tea, 2), line(sugar, 5), line(milk, 2)],
      paid: 1000,
      method: 'Cash',
    ),
    inv(
      'sample-inv-5',
      'INV-0005',
      daysAgo(0, 10),
      customers[3],
      [line(rice, 2), line(oil, 1)],
      paid: 1380,
      method: 'EasyPaisa',
    ),
    inv(
      'sample-inv-6',
      'INV-0006',
      daysAgo(0, 12),
      null,
      [line(milk, 2)],
      paid: 560,
      method: 'Cash',
    ),
  ];
  // INV-0003 and INV-0006 are fully paid; fix paid amounts to their totals.
  invoices[2] = inv(
    'sample-inv-3',
    'INV-0003',
    daysAgo(3),
    null,
    [line(pepsi, 6), line(surf, 1)],
    paid: 6 * 180 + 540,
    method: 'JazzCash',
  );

  final ledger = <LedgerEntry>[];
  for (final i in invoices) {
    if (i.balanceDue > 0 && i.partyId != null) {
      ledger.add(
        LedgerEntry(
          id: 'sample-led-${i.id}',
          partyId: i.partyId!,
          date: i.date,
          kind: 'Udhaar sale ${i.number}',
          delta: i.balanceDue,
          paymentMethod: 'Udhaar',
          invoiceId: i.id,
        ),
      );
    }
  }
  ledger.addAll([
    LedgerEntry(
      id: 'sample-led-p1',
      partyId: customers[0].id,
      date: daysAgo(2),
      kind: 'Payment received',
      delta: -1500,
      paymentMethod: 'JazzCash',
      note: 'Part payment',
    ),
    LedgerEntry(
      id: 'sample-led-p2',
      partyId: customers[4].id,
      date: daysAgo(12),
      kind: 'Previous udhaar',
      delta: 4350,
      paymentMethod: 'Udhaar',
      note: 'Balance from paper khata',
    ),
    LedgerEntry(
      id: 'sample-led-p3',
      partyId: customers[5].id,
      date: daysAgo(4),
      kind: 'Previous udhaar',
      delta: 2100,
      paymentMethod: 'Udhaar',
      note: 'Balance from paper khata',
    ),
    LedgerEntry(
      id: 'sample-led-s1',
      partyId: suppliers[0].id,
      date: daysAgo(7),
      kind: 'Stock purchase on credit',
      delta: 48500,
      paymentMethod: 'Udhaar',
      note: 'Weekly stock',
    ),
    LedgerEntry(
      id: 'sample-led-s2',
      partyId: suppliers[0].id,
      date: daysAgo(3),
      kind: 'Payment made',
      delta: -30000,
      paymentMethod: 'Bank Transfer',
    ),
    LedgerEntry(
      id: 'sample-led-s3',
      partyId: suppliers[1].id,
      date: daysAgo(2),
      kind: 'Stock purchase on credit',
      delta: 12400,
      paymentMethod: 'Udhaar',
      note: 'Dairy supply',
    ),
  ]);

  final expenses = <Expense>[
    Expense(
      id: 'sample-exp-1',
      date: daysAgo(1),
      category: 'Utilities',
      title: 'Electricity bill (LESCO)',
      amount: 8650,
      paymentMethod: 'Bank Transfer',
    ),
    Expense(
      id: 'sample-exp-2',
      date: daysAgo(2),
      category: 'Rent',
      title: 'Shop rent - November',
      amount: 35000,
      paymentMethod: 'Cash',
    ),
    Expense(
      id: 'sample-exp-3',
      date: daysAgo(0, 9),
      category: 'General',
      title: 'Rickshaw fare for stock',
      amount: 600,
      paymentMethod: 'Cash',
    ),
    Expense(
      id: 'sample-exp-4',
      date: daysAgo(4),
      category: 'Salary',
      title: 'Helper salary advance',
      amount: 5000,
      paymentMethod: 'Cash',
    ),
  ];

  return ShopState(
    products: products,
    parties: [...customers, ...suppliers],
    invoices: invoices.reversed.toList(),
    ledger: ledger,
    expenses: expenses,
    profile: profile,
    invoiceSeq: 6,
  );
}
