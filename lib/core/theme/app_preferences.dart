import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Defaults to system; a persisted user preference can be layered on top
/// via SharedPreferences without changing call sites.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Arabic is the base locale (RTL); English is LTR. Toggle from Settings.
final localeProvider = StateProvider<Locale>((ref) => const Locale('ar'));
