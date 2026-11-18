# DukaanERP

Free, offline-first ERP, POS billing and udhaar khata for small shops.
No server. No account. No subscription. Your data never leaves your device.

**Live demo:** https://asadmian55.github.io/dukaan-erp/

Built for the way shops in Pakistan actually run: cash and JazzCash/EasyPaisa
payments, customers who buy on udhaar and settle at month end, a paper khata
that gets lost, and internet or electricity that cannot be relied on.
DukaanERP runs entirely in the browser or on an Android phone, keeps working
with no connection at all, and stores everything locally.

## Try it in 30 seconds

1. Open the live demo.
2. On the Dashboard, tap **Load sample data**. A full demo shop loads:
   Al-Madina Kiryana & General Store, Lahore, with 24 products, 6 khata
   customers, 2 suppliers, bills, payments and expenses.
3. Open **POS Billing**, tap a few products, save a bill, and download the PDF.
4. Open **Khata Ledger**, pick Ahmed Raza, and send him a WhatsApp reminder.

## What it does

- **Dashboard** - today's and this month's sales, cash received, total udhaar
  outstanding, supplier payables, stock value, low-stock warnings, recent bills.
- **POS Billing** - fast, keyboard-friendly billing (search, Enter to add,
  Ctrl+Enter to save, F2 for a new bill). Split payments across Cash,
  JazzCash, EasyPaisa, bank, card, or udhaar. Credit-limit warning when a
  customer's khata crosses the limit you set.
- **Inventory** - products with SKU/barcode, category, unit (pcs, kg, litre),
  purchase and sale price, stock adjustments and low-stock alerts.
- **Khata Ledger** - a proper digital replacement for the paper register.
  Every udhaar bill and payment posts automatically, with a running balance,
  the date the balance started, aging, and one-tap WhatsApp reminders.
  Opening balances from an existing paper khata can be entered directly.
  Suppliers get the same ledger for stock bought on credit.
- **Cashbook and Expenses** - a day view that closes honestly: sales,
  money actually received (including khata payments), expenses by category
  (rent, utilities, salary, transport), and the net cash movement.
- **Reports** - monthly sales, gross margin, margin after expenses, udhaar
  aging buckets (0-30, 31-60, 60+ days), full invoice history with PDF and
  WhatsApp resend, and CSV exports for products, khata balances and sales.
- **Invoices that look right in Pakistan** - a clean PDF with shop name,
  address, phone, NTN and STRN. If an STRN is set in Settings, the PDF is
  titled "Sales Tax Invoice" and shows GST as a separate line. Note: this
  produces the FBR invoice *format*; it does not connect to FBR's digital
  invoicing system, which requires a licensed integrator.
- **English / Roman Urdu** - switch the interface labels in Settings.
  PKR by default, with USD, AED, EUR and GBP display support.

## Your data: local-first, with a portable backup file

All data is stored on the device in a local Hive database (IndexedDB in the
browser). Refresh the page, close the tab, lose your internet - everything
is still there. Nothing is uploaded anywhere, because there is no backend.

**Export Backup File** (Settings) downloads the entire shop as one
`.erpbackup` file. Save it on your phone, a USB stick, Google Drive, or send
it to yourself on WhatsApp. On any other device or a fresh install, use
**Upload / Restore Backup**, check the preview (shop name, record counts,
export date), then choose:

- **Replace** - wipe what is here and restore the file exactly.
- **Merge** - keep current data, add or update records from the file by ID.

### Backup file format

The `.erpbackup` file is plain JSON, so it can be inspected in any text
editor:

| Field | Meaning |
| --- | --- |
| `app` | Always `dukaan-erp` |
| `backupVersion` | Format version, currently `1` |
| `exportedAt` | ISO-8601 export timestamp |
| `checksum` | SHA-256 of the payload, computed over a canonical (sorted-key) JSON encoding |
| `payload` | `products`, `parties`, `invoices`, `ledger`, `expenses`, `profile`, `invoiceSeq` |

A file whose checksum does not match its payload is refused on restore.

## Architecture

One Flutter codebase for web and Android, feature-first layout:

```
lib/
  main.dart               Hive setup, ProviderScope, MaterialApp
  app_shell.dart          Navigation rail / bottom bar, responsive shell
  core/
    models/               Product, Party, Invoice, LedgerEntry, Expense, CompanyProfile
    data/
      app_state.dart      ShopState + ShopNotifier (Riverpod StateNotifier, write-through to Hive)
      sample_data.dart    The demo shop
    services/
      backup_service.dart Backup build/parse, checksum, CSV
      invoice_pdf.dart    PDF invoice generation
      whatsapp_service.dart  wa.me bill and reminder messages
    i18n/strings.dart     English / Roman Urdu labels
    theme/  utils/  widgets/
  features/
    dashboard/  pos/  inventory/  parties/  cashbook/  reports/  settings/
test/
  shop_state_test.dart    Backup round-trip and tamper check, khata balance, invoice tax maths
```

State is a single immutable `ShopState`. Every mutation goes through
`ShopNotifier`, which writes the whole state back to Hive in the same call,
so the UI and the disk can never drift apart. A khata balance is never
stored: it is always opening balance plus the sum of signed ledger entries,
which keeps bills, payments and balances consistent by construction.

## Run it locally

Requires Flutter 3.50 (Dart 3.14). CI pins this version; see below.

```bash
flutter pub get
flutter run -d chrome        # web
flutter run                  # Android device or emulator
flutter test                 # unit tests
flutter build web --release --base-href /dukaan-erp/
```

## Deploy your own live copy (free)

1. Fork or push this repository to GitHub as `dukaan-erp`.
2. In the repository, go to **Settings, Pages** and set the source to
   **GitHub Actions**.
3. Push to `main`. The `Deploy web app to GitHub Pages` workflow builds the
   web app and publishes it at `https://<your-username>.github.io/dukaan-erp/`.

To build an Android APK instead, run the `Build Android APK` workflow from
the Actions tab (or push a `v*` tag) and download the artifact.

## Roadmap

- Barcode scanning with the phone camera in POS and Inventory
- Purchase orders that post supplier khata and stock in one step
- Optional encrypted backup files (passphrase-protected `.erpbackup`)
- Urdu (Nastaliq) interface alongside Roman Urdu labels
- Receipt-printer friendly 80mm PDF format

## Contributing

Issues and pull requests are welcome. Please run `flutter analyze` and
`flutter test` before opening a pull request, and keep new features behind
the same rule the rest of the app follows: it must work with no internet,
and it must survive a browser refresh.

## License

MIT - see [LICENSE](LICENSE). Copyright (c) 2026 Asad Ullah.
