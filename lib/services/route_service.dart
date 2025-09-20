import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

class RouteService {
  Map<String, dynamic> _rutasData = {};

  // Cargar datos de rutas desde el JSON
  Future<Map<String, dynamic>> loadRoutes() async {
    if (_rutasData.isEmpty) {
      try {
        final String jsonString =
            await rootBundle.loadString('assets/data/rutas.json');
        _rutasData = json.decode(jsonString);
      } catch (e) {
        print('Error cargando rutas: $e');
        _rutasData = {};
      }
    }
    return _rutasData;
  }

  // Obtener todas las rutas con sus coordenadas
  Future<List<RouteInfo>> getAllRoutes() async {
    await loadRoutes();
    List<RouteInfo> routes = [];

    _rutasData.forEach((routeName, routeData) {
      List<LatLng> points = [];
      List<BusStop> stops = [];

      for (var paradero in routeData['paraderos']) {
        LatLng point = LatLng(
          paradero['lat'].toDouble(),
          paradero['lng'].toDouble(),
        );
        points.add(point);
        stops.add(BusStop(
          name: paradero['nombre'],
          position: point,
          routeName: routeName,
        ));
      }

      routes.add(RouteInfo(
        name: routeName,
        color: _hexToColor(routeData['color'] ?? '#0000FF'),
        points: points,
        stops: stops,
        fare: routeData['tarifa'],
        schedule: routeData['horario'],
        frequency: routeData['frecuencia'] ?? 'Cada 15 minutos',
      ));
    });

    return routes;
  }

  // Encontrar la ruta más cercana a una ubicación
  Future<NearestRouteResult?> findNearestRoute(LatLng userLocation) async {
    List<RouteInfo> routes = await getAllRoutes();
    if (routes.isEmpty) return null;

    double minDistance = double.infinity;
    RouteInfo? nearestRoute;
    BusStop? nearestStop;

    for (var route in routes) {
      for (var stop in route.stops) {
        double distance = _calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          stop.position.latitude,
          stop.position.longitude,
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearestRoute = route;
          nearestStop = stop;
        }
      }
    }

    if (nearestRoute != null && nearestStop != null) {
      return NearestRouteResult(
        route: nearestRoute,
        nearestStop: nearestStop,
        distance: minDistance,
      );
    }

    return null;
  }

  // Encontrar todas las rutas dentro de un radio
  Future<List<RouteWithDistance>> findRoutesNearby(
      LatLng userLocation, double radiusInMeters) async {
    List<RouteInfo> routes = await getAllRoutes();
    List<RouteWithDistance> nearbyRoutes = [];

    for (var route in routes) {
      double minDistance = double.infinity;
      BusStop? closestStop;

      for (var stop in route.stops) {
        double distance = _calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          stop.position.latitude,
          stop.position.longitude,
        );

        if (distance < minDistance) {
          minDistance = distance;
          closestStop = stop;
        }
      }

      if (minDistance <= radiusInMeters && closestStop != null) {
        nearbyRoutes.add(RouteWithDistance(
          route: route,
          distance: minDistance,
          closestStop: closestStop,
        ));
      }
    }

    // Ordenar por distancia
    nearbyRoutes.sort((a, b) => a.distance.compareTo(b.distance));

    return nearbyRoutes;
  }

  // Calcular distancia entre dos puntos (Haversine formula)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // metros
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  int _hexToColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF' + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }

  // Obtener información detallada de una ruta
  Future<RouteInfo?> getRouteInfo(String routeName) async {
    await loadRoutes();

    if (!_rutasData.containsKey(routeName)) {
      return null;
    }

    var routeData = _rutasData[routeName];
    List<LatLng> points = [];
    List<BusStop> stops = [];

    for (var paradero in routeData['paraderos']) {
      LatLng point = LatLng(
        paradero['lat'].toDouble(),
        paradero['lng'].toDouble(),
      );
      points.add(point);
      stops.add(BusStop(
        name: paradero['nombre'],
        position: point,
        routeName: routeName,
      ));
    }

    return RouteInfo(
      name: routeName,
      color: _hexToColor(routeData['color'] ?? '#0000FF'),
      points: points,
      stops: stops,
      fare: routeData['tarifa'],
      schedule: routeData['horario'],
      frequency: routeData['frecuencia'] ?? 'Cada 15 minutos',
    );
  }
}

// Clases de modelo
class RouteInfo {
  final String name;
  final int color;
  final List<LatLng> points;
  final List<BusStop> stops;
  final int fare;
  final String schedule;
  final String frequency;

  RouteInfo({
    required this.name,
    required this.color,
    required this.points,
    required this.stops,
    required this.fare,
    required this.schedule,
    required this.frequency,
  });
}

class BusStop {
  final String name;
  final LatLng position;
  final String routeName;

  BusStop({
    required this.name,
    required this.position,
    required this.routeName,
  });
}

class NearestRouteResult {
  final RouteInfo route;
  final BusStop nearestStop;
  final double distance;

  NearestRouteResult({
    required this.route,
    required this.nearestStop,
    required this.distance,
  });
}

class RouteWithDistance {
  final RouteInfo route;
  final double distance;
  final BusStop closestStop;

  RouteWithDistance({
    required this.route,
    required this.distance,
    required this.closestStop,
  });
}
