import 'package:flutter/material.dart';
import '../../../services/location_service.dart';
import '../../../widgets/primary_button.dart';
import '../onboarding_draft.dart';

class LocationStep extends StatefulWidget {
  const LocationStep({super.key, required this.draft, required this.onFinish, this.loading = false});

  final OnboardingDraft draft;
  final Future<void> Function() onFinish;
  final bool loading;

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  final _locationService = LocationService();
  late final _cityController = TextEditingController(text: widget.draft.city);
  bool _locating = false;
  String? _error;

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    final city = await _locationService.currentCity();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (city != null && city.isNotEmpty) {
        _cityController.text = city;
      } else {
        _error = "Couldn't detect your location. Enter your city manually.";
      }
    });
  }

  Future<void> _submit() async {
    if (_cityController.text.trim().isEmpty) {
      setState(() => _error = 'City is required');
      return;
    }
    widget.draft.city = _cityController.text.trim();
    await widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Where are you based?', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cityController,
          decoration: const InputDecoration(labelText: 'City'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _locating ? null : _useCurrentLocation,
          icon: _locating
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.my_location),
          label: const Text('Use my current location'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 24),
        PrimaryButton(label: 'Finish', onPressed: _submit, loading: widget.loading),
      ],
    );
  }
}
