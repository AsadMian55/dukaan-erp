import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app_shell.dart';
import 'core/data/app_state.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final box = await Hive.openBox<String>('dukaan_erp_box');
  runApp(
    ProviderScope(
      overrides: [shopBoxProvider.overrideWithValue(box)],
      child: const DukaanApp(),
    ),
  );
}

class DukaanApp extends StatelessWidget {
  const DukaanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DukaanERP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AppShell(),
    );
  }
}
