import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_preferences.dart';
import 'package:unidocs_mobile/core/theme/app_tokens.dart';

class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('المظهر', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, label: Text('فاتح'), icon: Icon(Icons.light_mode_outlined)),
              ButtonSegment(value: ThemeMode.dark, label: Text('داكن'), icon: Icon(Icons.dark_mode_outlined)),
              ButtonSegment(value: ThemeMode.system, label: Text('النظام'), icon: Icon(Icons.settings_suggest_outlined)),
            ],
            selected: {themeMode},
            onSelectionChanged: (selection) => ref.read(themeModeProvider.notifier).state = selection.first,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('اللغة', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<Locale>(
            segments: const [
              ButtonSegment(value: Locale('ar'), label: Text('العربية')),
              ButtonSegment(value: Locale('en'), label: Text('English')),
            ],
            selected: {locale},
            onSelectionChanged: (selection) => ref.read(localeProvider.notifier).state = selection.first,
          ),
        ],
      ),
    );
  }
}
