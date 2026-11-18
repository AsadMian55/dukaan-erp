import 'package:intl/intl.dart';

import '../models/company_profile.dart';

double round2(double v) => (v * 100).round() / 100;

String money(CompanyProfile p, double amount) {
  final f = NumberFormat('#,##0.00');
  final sign = amount < 0 ? '-' : '';
  return '$sign${p.currencySymbol}${f.format(amount.abs())}';
}

String moneyShort(CompanyProfile p, double amount) {
  if (amount.abs() >= 100000) {
    return '${p.currencySymbol}${(amount / 1000).toStringAsFixed(1)}k';
  }
  return money(p, amount);
}

String qty(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(2);
}

String dateFmt(DateTime d) => DateFormat('dd MMM yyyy').format(d);
String dateTimeFmt(DateTime d) => DateFormat('dd MMM yyyy, h:mm a').format(d);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

int daysBetween(DateTime from, DateTime to) => DateTime(
  to.year,
  to.month,
  to.day,
).difference(DateTime(from.year, from.month, from.day)).inDays;

const paymentMethods = [
  'Cash',
  'JazzCash',
  'EasyPaisa',
  'Bank Transfer',
  'Card',
  'Udhaar',
];
