import 'package:dukaan_erp/core/data/app_state.dart';
import 'package:dukaan_erp/core/models/invoice.dart';
import 'package:dukaan_erp/core/models/party.dart';
import 'package:dukaan_erp/core/models/product.dart';
import 'package:dukaan_erp/core/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('backup checksum', () {
    test('round trips a state and verifies', () {
      final state = ShopState(
        products: [
          Product(
            id: 'p1',
            name: 'Tea',
            salePrice: 850,
            stock: 10,
            updatedAt: DateTime(2026, 1, 1),
          ),
        ],
        invoiceSeq: 3,
      );
      final text = BackupService.buildBackupFile(state);
      final preview = BackupService.parseBackupFile(text);
      expect(preview.counts['Products'], 1);
      expect(preview.state.invoiceSeq, 3);
      expect(preview.state.products.first.name, 'Tea');
    });

    test('rejects a tampered file', () {
      final text = BackupService.buildBackupFile(const ShopState());
      final tampered = text.replaceFirst('"invoiceSeq": 0', '"invoiceSeq": 9');
      expect(
        () => BackupService.parseBackupFile(tampered),
        throwsFormatException,
      );
    });
  });

  group('khata balance', () {
    test('opening balance plus ledger deltas, minus payments', () async {
      Hive.init('./test/.hive_tmp');
      final box = await Hive.openBox<String>('test_box');
      await box.clear();
      final notifier = ShopNotifier(box, const ShopState());
      final party = Party(
        id: 'c1',
        name: 'Ahmed',
        type: PartyType.customer,
        openingBalance: 1000,
        createdAt: DateTime(2026, 1, 1),
      );
      notifier.upsertParty(party);
      notifier.createInvoice(
        lines: const [
          InvoiceLine(
            productId: 'x',
            productName: 'Rice',
            qty: 2,
            unitPrice: 380,
            costPrice: 310,
          ),
        ],
        party: party,
        discount: 0,
        taxRate: 0,
        paidAmount: 260,
        paymentMethod: 'Cash',
      );
      expect(notifier.state.balanceOf('c1'), 1500);
      notifier.recordPayment(party: party, amount: 500, method: 'Cash');
      expect(notifier.state.balanceOf('c1'), 1000);
      await box.close();
    });
  });

  group('invoice maths', () {
    test('discount applies before tax', () {
      final inv = Invoice(
        id: 'i1',
        number: 'INV-0001',
        date: DateTime(2026, 1, 1),
        lines: const [
          InvoiceLine(
            productId: 'x',
            productName: 'Oil',
            qty: 1,
            unitPrice: 1000,
          ),
        ],
        discount: 100,
        taxRate: 18,
        paidAmount: 0,
      );
      expect(inv.taxable, 900);
      expect(inv.taxAmount, 162);
      expect(inv.total, 1062);
      expect(inv.status, 'Udhaar');
    });
  });
}
