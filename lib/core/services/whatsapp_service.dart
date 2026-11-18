import 'package:url_launcher/url_launcher.dart';

import '../models/company_profile.dart';
import '../models/invoice.dart';
import '../utils/format.dart';

String normalisePhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('00')) digits = digits.substring(2);
  if (digits.startsWith('0')) digits = '92${digits.substring(1)}';
  return digits;
}

Future<bool> openWhatsApp(String phone, String message) async {
  final number = normalisePhone(phone);
  if (number.length < 10) return false;
  final uri = Uri.parse(
    'https://wa.me/$number?text=${Uri.encodeComponent(message)}',
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

String billMessage(CompanyProfile profile, Invoice invoice) {
  final b = StringBuffer()
    ..writeln('${profile.shopName} - Bill ${invoice.number}')
    ..writeln('Date: ${dateFmt(invoice.date)}')
    ..writeln('--------------------------------');
  for (final l in invoice.lines) {
    b.writeln('${l.productName} x${qty(l.qty)} = ${money(profile, l.amount)}');
  }
  b
    ..writeln('--------------------------------')
    ..writeln('Total: ${money(profile, invoice.total)}')
    ..writeln('Paid: ${money(profile, invoice.paidAmount)}');
  if (invoice.balanceDue > 0.009) {
    b.writeln('Balance (udhaar): ${money(profile, invoice.balanceDue)}');
  }
  b.writeln('Shukriya!');
  return b.toString();
}

String reminderMessage(
  CompanyProfile profile,
  String partyName,
  double balance,
  DateTime? since,
) {
  final b = StringBuffer()
    ..writeln('Assalam-o-Alaikum $partyName,')
    ..writeln(
      'This is a reminder from ${profile.shopName}. Your outstanding khata balance is ${money(profile, balance)}.',
    );
  if (since != null) {
    b.writeln('This balance has been outstanding since ${dateFmt(since)}.');
  }
  b.writeln('Please clear it at your convenience. Shukriya!');
  return b.toString();
}
