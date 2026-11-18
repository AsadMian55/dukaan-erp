import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/app_state.dart';
import '../../core/i18n/strings.dart';
import '../../core/models/company_profile.dart';
import '../../core/services/backup_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _shop = TextEditingController();
  final _owner = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _ntn = TextEditingController();
  final _strn = TextEditingController();
  final _tax = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    for (final c in [_shop, _owner, _phone, _address, _ntn, _strn, _tax]) {
      c.dispose();
    }
    super.dispose();
  }

  void _loadFrom(CompanyProfile p) {
    _shop.text = p.shopName;
    _owner.text = p.ownerName;
    _phone.text = p.phone;
    _address.text = p.address;
    _ntn.text = p.ntn;
    _strn.text = p.strn;
    _tax.text = p.defaultTaxRate.toString();
    _loaded = true;
  }

  CompanyProfile _currentProfile(CompanyProfile base) => base.copyWith(
    shopName: _shop.text.trim().isEmpty ? base.shopName : _shop.text.trim(),
    ownerName: _owner.text.trim(),
    phone: _phone.text.trim(),
    address: _address.text.trim(),
    ntn: _ntn.text.trim(),
    strn: _strn.text.trim(),
    defaultTaxRate: parseAmount(_tax.text),
  );

  Future<void> _exportBackup() async {
    final state = ref.read(shopProvider);
    final text = BackupService.buildBackupFile(state);
    final stamp = DateTime.now().toIso8601String().substring(0, 10);
    await FileSaver.instance.saveFile(
      name: 'dukaanerp-backup-$stamp',
      bytes: Uint8List.fromList(utf8.encode(text)),
      ext: 'erpbackup',
      mimeType: MimeType.other,
    );
    if (mounted) {
      showMsg(
        context,
        'Backup file downloaded. Keep it on your phone, USB or Google Drive - it holds your whole dukaan.',
      );
    }
  }

  Future<void> _importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['erpbackup', 'json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) {
      if (mounted) showMsg(context, 'Could not read that file.');
      return;
    }
    BackupPreview preview;
    try {
      preview = BackupService.parseBackupFile(utf8.decode(bytes));
    } on FormatException catch (e) {
      if (mounted) showMsg(context, e.message);
      return;
    } catch (_) {
      if (mounted) showMsg(context, 'That file could not be read as a backup.');
      return;
    }
    if (!mounted) return;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore this backup?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shop: ${preview.shopName}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text('Exported: ${dateTimeFmt(preview.exportedAt)}'),
            const SizedBox(height: 10),
            for (final e in preview.counts.entries)
              Text('${e.key}: ${e.value}'),
            const SizedBox(height: 12),
            const Text(
              'Replace wipes the data currently in this browser/app and restores the file. Merge keeps current data and adds or updates records from the file by ID.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'merge'),
            child: const Text('Merge'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'replace'),
            child: const Text('Replace all'),
          ),
        ],
      ),
    );
    if (choice == null) return;
    final notifier = ref.read(shopProvider.notifier);
    if (choice == 'replace') {
      notifier.replaceAll(preview.state);
    } else {
      notifier.mergeAll(preview.state);
    }
    setState(() => _loaded = false);
    if (mounted) showMsg(context, 'Backup restored.');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopProvider);
    final p = state.profile;
    final s = Strings(p.isUrdu);
    if (!_loaded) _loadFrom(p);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Shop profile', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _shop,
                        decoration: const InputDecoration(
                          labelText: 'Shop name',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _owner,
                        decoration: const InputDecoration(
                          labelText: 'Owner name',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone / WhatsApp',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _address,
                        decoration: const InputDecoration(labelText: 'Address'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ntn,
                        decoration: const InputDecoration(
                          labelText: 'NTN (optional)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _strn,
                        decoration: const InputDecoration(
                          labelText:
                              'STRN (fills the sales tax invoice format)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: p.currencyCode,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'PKR',
                            child: Text('PKR - Pakistani Rupee'),
                          ),
                          DropdownMenuItem(
                            value: 'USD',
                            child: Text('USD - US Dollar'),
                          ),
                          DropdownMenuItem(
                            value: 'AED',
                            child: Text('AED - UAE Dirham'),
                          ),
                          DropdownMenuItem(
                            value: 'EUR',
                            child: Text('EUR - Euro'),
                          ),
                          DropdownMenuItem(
                            value: 'GBP',
                            child: Text('GBP - British Pound'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          ref
                              .read(shopProvider.notifier)
                              .updateProfile(p.copyWith(currencyCode: v));
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _tax,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText:
                              'Default GST % on bills (0 if prices include tax)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: p.language,
                        decoration: const InputDecoration(
                          labelText: 'Interface language',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(
                            value: 'ur',
                            child: Text('Roman Urdu labels'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          ref
                              .read(shopProvider.notifier)
                              .updateProfile(
                                _currentProfile(p.copyWith(language: v)),
                              );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () {
                      ref
                          .read(shopProvider.notifier)
                          .updateProfile(_currentProfile(p));
                      showMsg(context, 'Shop profile saved.');
                    },
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Save profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
        SectionTitle(s.backup),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your data lives only on this device/browser. The backup file is the whole dukaan - products, khata, bills, expenses - in one checksum-checked file. Export it weekly, keep it anywhere, restore it on any device.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: _exportBackup,
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Export backup file'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _importBackup,
                      icon: const Icon(Icons.upload_outlined, size: 18),
                      label: const Text('Upload / restore backup'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await confirmDialog(
                          context,
                          'Load sample data?',
                          'This replaces the current data in this browser with the Al-Madina Kiryana demo shop.',
                        );
                        if (ok) {
                          ref.read(shopProvider.notifier).loadSampleData();
                          setState(() => _loaded = false);
                        }
                      },
                      icon: const Icon(Icons.dataset_outlined, size: 18),
                      label: Text(s.loadSample),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SectionTitle('Danger zone'),
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.delete_forever_outlined,
              color: AppTheme.danger,
            ),
            title: const Text('Erase all data in this browser/app'),
            subtitle: const Text(
              'Products, khata, bills and expenses are removed. Export a backup first if you might need them.',
            ),
            trailing: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.danger,
                side: const BorderSide(color: AppTheme.danger),
              ),
              onPressed: () async {
                final ok = await confirmDialog(
                  context,
                  'Erase everything?',
                  'This cannot be undone from inside the app.',
                );
                if (ok) {
                  ref.read(shopProvider.notifier).clearAll();
                  setState(() => _loaded = false);
                }
              },
              child: const Text('Erase'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'DukaanERP is free and open source (MIT). No account, no server, no subscription. Built by Asad Ullah.',
          style: TextStyle(color: AppTheme.muted, fontSize: 12.5),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
