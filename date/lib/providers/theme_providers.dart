import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'policy_providers.dart';

const _kThemeModeKey = 'theme_mode_dark';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_kThemeModeKey) ?? false ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setDarkModeEnabled(bool enabled) async {
    await ref.read(sharedPreferencesProvider).setBool(_kThemeModeKey, enabled);
    state = enabled ? ThemeMode.dark : ThemeMode.light;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);