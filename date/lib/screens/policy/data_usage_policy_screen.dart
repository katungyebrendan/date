import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/policy_providers.dart';
import '../../widgets/primary_button.dart';

class _PolicyItem {
  const _PolicyItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

const _policyItems = [
  _PolicyItem(Icons.person_outline, 'Your name and age'),
  _PolicyItem(Icons.camera_alt_outlined, 'Your profile photos'),
  _PolicyItem(Icons.phone_outlined, 'Your WhatsApp number'),
  _PolicyItem(Icons.location_on_outlined, 'Your location'),
  _PolicyItem(Icons.info_outline, 'Your bio and interests'),
];

/// Shown once, before sign-in, the first time the app is opened on a device.
class DataUsagePolicyScreen extends ConsumerStatefulWidget {
  const DataUsagePolicyScreen({super.key});

  @override
  ConsumerState<DataUsagePolicyScreen> createState() => _DataUsagePolicyScreenState();
}

class _DataUsagePolicyScreenState extends ConsumerState<DataUsagePolicyScreen> {
  bool _agreed = false;

  void _decline() => SystemNavigator.pop();

  Future<void> _accept() async {
    await ref.read(policyAcceptedProvider.notifier).accept();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(Icons.shield_outlined, color: colorScheme.primary, size: 32),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Data Usage Policy',
                        style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Velo collects and displays your registration profile '
                        'information to help other users find and connect with you:',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      ..._policyItems.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: colorScheme.primaryContainer,
                                child: Icon(item.icon, color: colorScheme.primary, size: 18),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(item.label, style: textTheme.bodyLarge),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: colorScheme.tertiary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'The above profile information will be visible to other '
                                'Velo users once your profile is complete.',
                                style: textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _agreed = !_agreed),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _agreed,
                                onChanged: (value) => setState(() => _agreed = value ?? false),
                              ),
                              Expanded(
                                child: Text(
                                  'I understand and agree to the data usage policy',
                                  style: textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _decline,
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Accept & Continue',
                      onPressed: _agreed ? _accept : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
