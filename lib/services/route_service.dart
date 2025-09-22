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

      // Usar waypoints si están disponibles para un trazado más suave
      if (routeData['waypoints'] != null && routeData['waypoints'].isNotEmpty) {
        // Usar waypoints para la línea de la ruta
        for (var waypoint in routeData['waypoints']) {
          points.add(LatLng(
            waypoint['lat'].toDouble(),
            waypoint['lng'].toDouble(),
          ));
        }
      } else {
        // Fallback: crear una ruta interpolada entre paraderos
        final paraderos = routeData['paraderos'] as List;
        for (int i = 0; i < paraderos.length - 1; i++) {
          // Agregar el paradero actual
          points.add(LatLng(
            paraderos[i]['lat'].toDouble(),
            paraderos[i]['lng'].toDouble(),
          ));

          // Interpolar puntos entre este paradero y el siguiente
          List<LatLng> interpolated = _interpolatePoints(
            LatLng(
                paraderos[i]['lat'].toDouble(), paraderos[i]['lng'].toDouble()),
            LatLng(paraderos[i + 1]['lat'].toDouble(),
                paraderos[i + 1]['lng'].toDouble()),
            10, // Número de puntos intermedios
          );
          points.addAll(interpolated);
        }

        // Agregar el último paradero
        points.add(LatLng(
          paraderos.last['lat'].toDouble(),
          paraderos.last['lng'].toDouble(),
        ));
      }

      // Agregar los paraderos como paradas
      for (var paradero in routeData['paraderos']) {
        stops.add(BusStop(
          name: paradero['nombre'],
          position: LatLng(
            paradero['lat'].toDouble(),
            paradero['lng'].toDouble(),
          ),
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

  // Interpolar puntos entre dos coordenadas para crear una ruta más suave
  List<LatLng> _interpolatePoints(LatLng start, LatLng end, int numPoints) {
    List<LatLng> interpolated = [];

    // Agregar algo de curvatura para simular calles reales
    double midLat = (start.latitude + end.latitude) / 2;
    double midLng = (start.longitude + end.longitude) / 2;

    // Crear una ligera curva agregando un desplazamiento perpendicular
    double perpOffset = 0.001 * (Random().nextDouble() - 0.5);
    double perpLat = midLat + perpOffset;
    double perpLng = midLng - perpOffset;

    for (int i = 1; i < numPoints; i++) {
      double t = i / numPoints.toDouble();

      // Usar interpolación cuadrática de Bézier para crear una curva suave
      double lat = pow(1 - t, 2) * start.latitude +
          2 * (1 - t) * t * perpLat +
          pow(t, 2) * end.latitude;

      double lng = pow(1 - t, 2) * start.longitude +
          2 * (1 - t) * t * perpLng +
          pow(t, 2) * end.longitude;

      interpolated.add(LatLng(lat, lng));
    }

    return interpolated;
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

  // Calcular la mejor ruta entre dos puntos
  Future<List<RouteInfo>> findBestRoute(
      LatLng origin, LatLng destination) async {
    List<RouteInfo> routes = await getAllRoutes();
    List<RouteInfo> possibleRoutes = [];

    for (var route in routes) {
      bool hasOrigin = false;
      bool hasDestination = false;

      // Verificar si la ruta pasa cerca del origen y destino
      for (var stop in route.stops) {
        double distToOrigin = _calculateDistance(
          origin.latitude,
          origin.longitude,
          stop.position.latitude,
          stop.position.longitude,
        );

        double distToDestination = _calculateDistance(
          destination.latitude,
          destination.longitude,
          stop.position.latitude,
          stop.position.longitude,
        );

        if (distToOrigin < 500) hasOrigin = true; // 500 metros de tolerancia
        if (distToDestination < 500) hasDestination = true;
      }

      if (hasOrigin && hasDestination) {
        possibleRoutes.add(route);
      }
    }

    // Ordenar por frecuencia (las más frecuentes primero)
    possibleRoutes.sort((a, b) {
      int freqA = _extractFrequency(a.frequency);
      int freqB = _extractFrequency(b.frequency);
      return freqA.compareTo(freqB);
    });

    return possibleRoutes;
  }

  // Extraer el número de minutos de la frecuencia
  int _extractFrequency(String frequency) {
    RegExp regex = RegExp(r'\d+');
    Match? match = regex.firstMatch(frequency);
    return match != null ? int.parse(match.group(0)!) : 999;
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

    // Usar waypoints si están disponibles
    if (routeData['waypoints'] != null && routeData['waypoints'].isNotEmpty) {
      for (var waypoint in routeData['waypoints']) {
        points.add(LatLng(
          waypoint['lat'].toDouble(),
          waypoint['lng'].toDouble(),
        ));
      }
    } else {
      // Fallback a paraderos
      for (var paradero in routeData['paraderos']) {
        LatLng point = LatLng(
          paradero['lat'].toDouble(),
          paradero['lng'].toDouble(),
        );
        points.add(point);
      }
    }

    // Agregar paraderos
    for (var paradero in routeData['paraderos']) {
      stops.add(BusStop(
        name: paradero['nombre'],
        position: LatLng(
          paradero['lat'].toDouble(),
          paradero['lng'].toDouble(),
        ),
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

  // Obtener estadísticas de las rutas
  Future<Map<String, dynamic>> getRouteStatistics() async {
    await loadRoutes();

    int totalRoutes = _rutasData.length;
    int totalStops = 0;
    double avgFare = 0;

    _rutasData.forEach((route, data) {
      totalStops += (data['paraderos'] as List).length;
      avgFare += data['tarifa'];
    });

    avgFare = avgFare / totalRoutes;

    return {
      'totalRoutes': totalRoutes,
      'totalStops': totalStops,
      'averageFare': avgFare,
      'coverage': 'Ciudad completa',
    };
  }

  // Buscar rutas por paradero
  Future<List<String>> getRoutesByStop(String stopName) async {
    await loadRoutes();
    List<String> routesAtStop = [];

    _rutasData.forEach((routeName, routeData) {
      final paraderos = routeData['paraderos'] as List;
      for (var paradero in paraderos) {
        if (paradero['nombre']
            .toString()
            .toLowerCase()
            .contains(stopName.toLowerCase())) {
          routesAtStop.add(routeName);
          break;
        }
      }
    });

    return routesAtStop;
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
