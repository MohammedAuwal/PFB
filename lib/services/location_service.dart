import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:pfb/services/geocoding_service.dart';

class CurrentLocationResult {
  final String displayName;
  final double latitude;
  final double longitude;

  const CurrentLocationResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}

class LocationService {
  final GeocodingService _geocodingService = GeocodingService();

  Future<bool> ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Please enable location service');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    return true;
  }

  Future<LatLng?> getCurrentLatLng() async {
    try {
      await ensureLocationPermission();
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<CurrentLocationResult> getCurrentResolvedLocation() async {
    await ensureLocationPermission();
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final resolved = await _geocodingService.reverseGeocode(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    return CurrentLocationResult(
      displayName: resolved.displayName,
      latitude: resolved.latitude,
      longitude: resolved.longitude,
    );
  }

  Stream<LatLng> watchCurrentLatLng() async* {
    await ensureLocationPermission();

    await for (final position in Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    )) {
      yield LatLng(position.latitude, position.longitude);
    }
  }
}
