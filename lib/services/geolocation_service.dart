import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class GeoLocationService {
  // Stream para la ubicación en tiempo real
  Stream<Position>? _positionStream;

  // Configuración del servicio de ubicación
  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // Actualiza cada 10 metros
  );

  // Verificar si el GPS está habilitado
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Solicitar permisos de ubicación
  Future<bool> requestLocationPermission() async {
    // Primero verificar si el servicio de ubicación está habilitado
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // El servicio de ubicación no está habilitado
      return false;
    }

    // Verificar permisos
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permisos denegados
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Los permisos están permanentemente denegados
      // Abrir configuración del dispositivo
      await openAppSettings();
      return false;
    }

    // Permisos concedidos
    return true;
  }

  // Obtener ubicación actual (una sola vez)
  Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        throw Exception('No se tienen permisos de ubicación');
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error obteniendo ubicación: $e');
      return null;
    }
  }

  // Obtener stream de ubicación en tiempo real
  Stream<Position>? getLocationStream() {
    _positionStream ??= Geolocator.getPositionStream(
      locationSettings: locationSettings,
    );
    return _positionStream;
  }

  // Calcular distancia entre dos puntos
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Obtener la dirección aproximada (bearing) entre dos puntos
  double calculateBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Cancelar el stream de ubicación
  void dispose() {
    _positionStream = null;
  }

  // Abrir configuración de ubicación del dispositivo
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}
