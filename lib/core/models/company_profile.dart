class CompanyProfile {
  final String shopName;
  final String ownerName;
  final String phone;
  final String address;
  final String ntn;
  final String strn;
  final String currencyCode;
  final double defaultTaxRate;
  final String language;

  const CompanyProfile({
    this.shopName = 'My Dukaan',
    this.ownerName = '',
    this.phone = '',
    this.address = '',
    this.ntn = '',
    this.strn = '',
    this.currencyCode = 'PKR',
    this.defaultTaxRate = 0,
    this.language = 'en',
  });

  bool get isUrdu => language == 'ur';

  String get currencySymbol {
    switch (currencyCode) {
      case 'USD':
        return '\$';
      case 'AED':
        return 'AED ';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return 'Rs ';
    }
  }

  CompanyProfile copyWith({
    String? shopName,
    String? ownerName,
    String? phone,
    String? address,
    String? ntn,
    String? strn,
    String? currencyCode,
    double? defaultTaxRate,
    String? language,
  }) {
    return CompanyProfile(
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      ntn: ntn ?? this.ntn,
      strn: strn ?? this.strn,
      currencyCode: currencyCode ?? this.currencyCode,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() => {
    'shopName': shopName,
    'ownerName': ownerName,
    'phone': phone,
    'address': address,
    'ntn': ntn,
    'strn': strn,
    'currencyCode': currencyCode,
    'defaultTaxRate': defaultTaxRate,
    'language': language,
  };

  factory CompanyProfile.fromJson(Map<String, dynamic> j) => CompanyProfile(
    shopName: j['shopName'] as String? ?? 'My Dukaan',
    ownerName: j['ownerName'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    address: j['address'] as String? ?? '',
    ntn: j['ntn'] as String? ?? '',
    strn: j['strn'] as String? ?? '',
    currencyCode: j['currencyCode'] as String? ?? 'PKR',
    defaultTaxRate: (j['defaultTaxRate'] as num? ?? 0).toDouble(),
    language: j['language'] as String? ?? 'en',
  );
}
