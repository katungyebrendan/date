import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class ResolvedLocation {
  const ResolvedLocation({required this.city, required this.geoPoint});

  final String city;
  final GeoPoint geoPoint;
}

class LocationService {
  final _geocoding = Geocoding();

  /// Returns a human-readable city string derived from the device's current
  /// GPS position, or null if permission was denied or lookup failed. This
  /// is an optional autofill convenience — the city text field itself always
  /// works without it.
  Future<String?> currentCity() async {
    final resolved = await currentLocation();
    return resolved?.city;
  }

  /// Resolves current device coordinates and best-effort city label.
  Future<ResolvedLocation?> currentLocation() async {
    try {
      final permission = await _ensurePermission();
      if (!permission) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      final placemarks = await _geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final city = placemarks.isNotEmpty ? _cityFromPlacemark(placemarks.first) : null;
      if (city == null || city.isEmpty) return null;

      return ResolvedLocation(
        city: city,
        geoPoint: GeoPoint(position.latitude, position.longitude),
      );
    } catch (_) {
      return null;
    }
  }

  /// Forward-geocodes a city string into a coordinate point when possible.
  Future<GeoPoint?> geoPointForCity(String city) async {
    final query = city.trim();
    if (query.isEmpty) return null;

    try {
      final locations = await _geocoding.locationFromAddress(query);
      if (locations.isEmpty) return null;
      final first = locations.first;
      return GeoPoint(first.latitude, first.longitude);
    } catch (_) {
      return null;
    }
  }

  String? _cityFromPlacemark(Placemark place) {
    if (place.locality?.isNotEmpty == true) return place.locality;
    if (place.subAdministrativeArea?.isNotEmpty == true) return place.subAdministrativeArea;
    if (place.administrativeArea?.isNotEmpty == true) return place.administrativeArea;
    return null;
  }

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }
}
