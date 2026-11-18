import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/company_profile.dart';
import '../models/invoice.dart';
import '../utils/format.dart';

Future<Uint8List> buildInvoicePdf(
  CompanyProfile profile,
  Invoice invoice,
) async {
  final doc = pw.Document();
  final isTaxInvoice = profile.strn.isNotEmpty;
  final light = PdfColors.grey200;
  final muted = PdfColors.grey700;

  pw.Widget cell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
    double size = 9.5,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: size,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      profile.shopName,
                      style: pw.TextStyle(
                        fontSize: 19,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (profile.address.isNotEmpty)
                      pw.Text(
                        profile.address,
                        style: pw.TextStyle(fontSize: 9.5, color: muted),
                      ),
                    if (profile.phone.isNotEmpty)
                      pw.Text(
                        'Phone: ${profile.phone}',
                        style: pw.TextStyle(fontSize: 9.5, color: muted),
                      ),
                    if (profile.ntn.isNotEmpty)
                      pw.Text(
                        'NTN: ${profile.ntn}',
                        style: pw.TextStyle(fontSize: 9.5, color: muted),
                      ),
                    if (profile.strn.isNotEmpty)
                      pw.Text(
                        'STRN: ${profile.strn}',
                        style: pw.TextStyle(fontSize: 9.5, color: muted),
                      ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      isTaxInvoice ? 'SALES TAX INVOICE' : 'INVOICE',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'No: ${invoice.number}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Date: ${dateFmt(invoice.date)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: light,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                children: [
                  pw.Text(
                    'Bill to: ',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    invoice.partyName,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: light, width: 0.7),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.6),
                1: const pw.FlexColumnWidth(4.2),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1.4),
                4: const pw.FlexColumnWidth(1.6),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    cell('#', bold: true),
                    cell('Item', bold: true),
                    cell('Qty', bold: true, align: pw.TextAlign.right),
                    cell('Rate', bold: true, align: pw.TextAlign.right),
                    cell('Amount', bold: true, align: pw.TextAlign.right),
                  ],
                ),
                for (var i = 0; i < invoice.lines.length; i++)
                  pw.TableRow(
                    children: [
                      cell('${i + 1}'),
                      cell(invoice.lines[i].productName),
                      cell(
                        qty(invoice.lines[i].qty),
                        align: pw.TextAlign.right,
                      ),
                      cell(
                        money(profile, invoice.lines[i].unitPrice),
                        align: pw.TextAlign.right,
                      ),
                      cell(
                        money(profile, invoice.lines[i].amount),
                        align: pw.TextAlign.right,
                      ),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.SizedBox(
                  width: 220,
                  child: pw.Column(
                    children: [
                      _totalRow('Subtotal', money(profile, invoice.subtotal)),
                      if (invoice.discount > 0)
                        _totalRow(
                          'Discount',
                          '- ${money(profile, invoice.discount)}',
                        ),
                      if (invoice.taxRate > 0)
                        _totalRow(
                          'Sales tax (${qty(invoice.taxRate)}%)',
                          money(profile, invoice.taxAmount),
                        ),
                      _totalRow(
                        'Total',
                        money(profile, invoice.total),
                        bold: true,
                      ),
                      _totalRow(
                        'Paid (${invoice.paymentMethod})',
                        money(profile, invoice.paidAmount),
                      ),
                      if (invoice.balanceDue > 0.009)
                        _totalRow(
                          'Balance (udhaar)',
                          money(profile, invoice.balanceDue),
                          bold: true,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            pw.Spacer(),
            if (invoice.note.isNotEmpty)
              pw.Text(
                'Note: ${invoice.note}',
                style: pw.TextStyle(fontSize: 9, color: muted),
              ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Thank you for your business.',
              style: const pw.TextStyle(fontSize: 9.5),
            ),
            pw.Text(
              'Generated with DukaanERP - your data stays on your device.',
              style: pw.TextStyle(fontSize: 8, color: muted),
            ),
          ],
        );
      },
    ),
  );
  return doc.save();
}

pw.Widget _totalRow(String label, String value, {bool bold = false}) {
  final style = pw.TextStyle(
    fontSize: 10,
    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
  );
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(value, style: style),
      ],
    ),
  );
}
