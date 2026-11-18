import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../data/app_state.dart';

class BackupPreview {
  final String shopName;
  final DateTime exportedAt;
  final Map<String, int> counts;
  final ShopState state;

  const BackupPreview({
    required this.shopName,
    required this.exportedAt,
    required this.counts,
    required this.state,
  });
}

class BackupService {
  static const appTag = 'dukaan-erp';
  static const backupVersion = 1;

  /// Key order in a decoded backup file is not guaranteed, so the checksum
  /// is taken over a canonical encoding with sorted keys on both sides.
  static String canonicalJson(dynamic value) {
    if (value is Map) {
      final keys = value.keys.map((k) => k.toString()).toList()..sort();
      return '{${keys.map((k) => '${jsonEncode(k)}:${canonicalJson(value[k])}').join(',')}}';
    }
    if (value is List) {
      return '[${value.map(canonicalJson).join(',')}]';
    }
    return jsonEncode(value);
  }

  static String checksumOf(Map<String, dynamic> payload) =>
      sha256.convert(utf8.encode(canonicalJson(payload))).toString();

  static String buildBackupFile(ShopState state) {
    final payload = state.toJson();
    final file = {
      'app': appTag,
      'backupVersion': backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'checksum': checksumOf(payload),
      'payload': payload,
    };
    return const JsonEncoder.withIndent('  ').convert(file);
  }

  static BackupPreview parseBackupFile(String text) {
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('This is not a DukaanERP backup file.');
    }
    if (decoded['app'] != appTag) {
      throw const FormatException('This backup belongs to a different app.');
    }
    final payload = decoded['payload'];
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Backup file is missing its data section.');
    }
    final expected = decoded['checksum'] as String? ?? '';
    if (expected.isEmpty || checksumOf(payload) != expected) {
      throw const FormatException(
        'Checksum mismatch. The file is corrupted or was edited by hand.',
      );
    }
    final state = ShopState.fromJson(payload);
    return BackupPreview(
      shopName: state.profile.shopName,
      exportedAt:
          DateTime.tryParse(decoded['exportedAt'] as String? ?? '') ??
          DateTime.now(),
      counts: {
        'Products': state.products.length,
        'Customers & suppliers': state.parties.length,
        'Invoices': state.invoices.length,
        'Khata entries': state.ledger.length,
        'Expenses': state.expenses.length,
      },
      state: state,
    );
  }

  static String buildCsv(String title, List<List<Object?>> rows) {
    String cell(Object? v) {
      final s = (v ?? '').toString();
      if (s.contains(',') || s.contains('"') || s.contains('\n')) {
        return '"${s.replaceAll('"', '""')}"';
      }
      return s;
    }

    return rows.map((r) => r.map(cell).join(',')).join('\n');
  }
}
