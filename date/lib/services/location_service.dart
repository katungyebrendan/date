import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  final _geocoding = Geocoding();

  /// Returns a human-readable city string derived from the device's current
  /// GPS position, or null if permission was denied or lookup failed. This
  /// is an optional autofill convenience — the city text field itself always
  /// works without it.
  Future<String?> currentCity() async {
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
      if (placemarks.isEmpty) return null;
      final place = placemarks.first;
      return place.locality?.isNotEmpty == true ? place.locality : place.administrativeArea;
    } catch (_) {
      return null;
    }
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
