import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPolicyAcceptedKey = 'data_usage_policy_accepted';

/// Overridden in main.dart once the app has awaited [SharedPreferences.getInstance].
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main.dart');
});

class PolicyAcceptedNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(sharedPreferencesProvider).getBool(_kPolicyAcceptedKey) ?? false;
  }

  Future<void> accept() async {
    await ref.read(sharedPreferencesProvider).setBool(_kPolicyAcceptedKey, true);
    state = true;
  }
}

/// Whether this device has accepted the data usage policy shown on first
/// launch. Local/per-device by design — it must be gate-able before a user
/// has signed in or created a profile.
final policyAcceptedProvider = NotifierProvider<PolicyAcceptedNotifier, bool>(
  PolicyAcceptedNotifier.new,
);
