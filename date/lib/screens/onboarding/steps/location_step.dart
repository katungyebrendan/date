import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  GeoPoint? _pickedGeoPoint;
  String? _pickedCityKey;
  bool _locating = false;
  String? _error;

  String _cityKey(String city) => city.trim().toLowerCase();

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    final resolved = await _locationService.currentLocation();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (resolved != null && resolved.city.isNotEmpty) {
        _cityController.text = resolved.city;
        _pickedGeoPoint = resolved.geoPoint;
        _pickedCityKey = _cityKey(resolved.city);
        _error = null;
      } else {
        _pickedGeoPoint = null;
        _pickedCityKey = null;
        _error = "Couldn't detect your location. Enter your city manually.";
      }
    });
  }

  Future<void> _submit() async {
    final city = _cityController.text.trim();
    if (city.isEmpty) {
      setState(() => _error = 'City is required');
      return;
    }

    setState(() {
      _locating = true;
      _error = null;
    });

    GeoPoint? location;
    final cityKey = _cityKey(city);
    if (_pickedGeoPoint != null && _pickedCityKey == cityKey) {
      location = _pickedGeoPoint;
    } else {
      location = await _locationService.geoPointForCity(city);
    }

    if (!mounted) return;

    widget.draft.city = city;
    widget.draft.location = location;

    setState(() => _locating = false);
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
        PrimaryButton(label: 'Finish', onPressed: _submit, loading: widget.loading || _locating),
      ],
    );
  }
}
