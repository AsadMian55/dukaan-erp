/// UI labels in English or Roman Urdu. Business data is never translated,
/// only the chrome around it, so a shopkeeper can switch without relearning
/// where their numbers live.
class Strings {
  final bool urdu;
  const Strings(this.urdu);

  String get appName => 'DukaanERP';
  String get dashboard => urdu ? 'Khulasa' : 'Dashboard';
  String get pos => urdu ? 'Bikri (POS)' : 'POS Billing';
  String get inventory => urdu ? 'Stock' : 'Inventory';
  String get khata => urdu ? 'Khata' : 'Khata Ledger';
  String get cashbook => urdu ? 'Roznamcha' : 'Cashbook';
  String get reports => urdu ? 'Reports' : 'Reports';
  String get settings => urdu ? 'Settings' : 'Settings';

  String get todaySales => urdu ? 'Aaj ki bikri' : "Today's sales";
  String get monthSales => urdu ? 'Is mahine ki bikri' : 'This month';
  String get totalUdhaar => urdu ? 'Kul udhaar (lena)' : 'Total udhaar due';
  String get payables => urdu ? 'Dena hai (suppliers)' : 'Payable to suppliers';
  String get cashReceivedToday =>
      urdu ? 'Aaj wasool cash' : 'Cash received today';
  String get stockValue => urdu ? 'Stock ki qeemat' : 'Stock value (cost)';
  String get lowStock => urdu ? 'Kam stock' : 'Low stock';
  String get recentInvoices => urdu ? 'Haal ki bikri' : 'Recent invoices';
  String get outstandingKhata =>
      urdu ? 'Baaki udhaar wale' : 'Outstanding khata';

  String get newBill => urdu ? 'Naya bill' : 'New bill';
  String get searchProducts =>
      urdu ? 'Cheez talash karein...' : 'Search products...';
  String get customer => urdu ? 'Gahak' : 'Customer';
  String get walkIn => urdu ? 'Aam gahak' : 'Walk-in Customer';
  String get discount => urdu ? 'Riyayat' : 'Discount';
  String get tax => urdu ? 'Sales tax (GST %)' : 'Sales tax (GST %)';
  String get total => urdu ? 'Kul rakam' : 'Total';
  String get paid => urdu ? 'Ada shuda' : 'Paid now';
  String get balance => urdu ? 'Baaki' : 'Balance';
  String get saveBill => urdu ? 'Bill mehfooz karein' : 'Save bill';
  String get cart => urdu ? 'Bill ki tafseel' : 'Current bill';

  String get addProduct => urdu ? 'Nayi cheez' : 'Add product';
  String get addParty => urdu ? 'Naya naam' : 'Add name';
  String get recordPayment => urdu ? 'Adaigi likhein' : 'Record payment';
  String get addExpense => urdu ? 'Kharcha likhein' : 'Add expense';
  String get backup => urdu ? 'Backup file' : 'Backup & Restore';
  String get loadSample =>
      urdu ? 'Namuna data load karein' : 'Load sample data';
}
