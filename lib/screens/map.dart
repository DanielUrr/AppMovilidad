import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/geolocation_service.dart';
import '../services/route_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  final GeoLocationService _geoLocationService = GeoLocationService();
  final RouteService _routeService = RouteService();
  final MapController _mapController = MapController();

  // Estado del mapa
  bool _isLoading = true;
  List<RouteInfo> _routes = [];
  RouteInfo? _selectedRoute;
  NearestRouteResult? _nearestRoute;

  // Variables para la ubicación del usuario
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isTrackingUser = false;
  double _currentZoom = 14.0;

  // Control de visibilidad
  bool _showAllRoutes = true;
  bool _showNearestRoute = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    // Cargar rutas
    await _loadRoutes();

    // Iniciar seguimiento de ubicación
    await _startLocationTracking();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadRoutes() async {
    try {
      final routes = await _routeService.getAllRoutes();
      setState(() {
        _routes = routes;
      });
    } catch (e) {
      print('Error cargando rutas: $e');
    }
  }

  Future<void> _startLocationTracking() async {
    try {
      bool hasPermission =
          await _geoLocationService.requestLocationPermission();

      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Se necesitan permisos de ubicación'),
              action: SnackBarAction(
                label: 'Configuración',
                onPressed: () => _geoLocationService.openLocationSettings(),
              ),
            ),
          );
        }
        return;
      }

      Position? position = await _geoLocationService.getCurrentLocation();

      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
          _isTrackingUser = true;
        });

        // Buscar ruta más cercana
        _updateNearestRoute(LatLng(position.latitude, position.longitude));

        // Centrar mapa en la ubicación del usuario
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          _currentZoom,
        );
      }

      // Stream de ubicación en tiempo real
      _positionStreamSubscription =
          _geoLocationService.getLocationStream()?.listen((Position position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });

          // Actualizar ruta más cercana
          _updateNearestRoute(LatLng(position.latitude, position.longitude));

          if (_isTrackingUser) {
            _mapController.move(
              LatLng(position.latitude, position.longitude),
              _mapController.camera.zoom,
            );
          }
        }
      });
    } catch (e) {
      print('Error iniciando tracking: $e');
    }
  }

  Future<void> _updateNearestRoute(LatLng userLocation) async {
    final nearest = await _routeService.findNearestRoute(userLocation);
    if (mounted) {
      setState(() {
        _nearestRoute = nearest;
      });
    }
  }

  void _centerOnUserLocation() {
    if (_currentPosition != null) {
      setState(() {
        _isTrackingUser = true;
      });
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        16.0,
      );
    }
  }

  void _selectRoute(RouteInfo? route) {
    setState(() {
      _selectedRoute = route;
      _showAllRoutes = route == null;
    });
  }

  // Construir polylines para las rutas
  List<Polyline> _buildPolylines() {
    List<Polyline> polylines = [];

    for (var route in _routes) {
      // Determinar si mostrar esta ruta
      bool shouldShow = _showAllRoutes ||
          (_selectedRoute != null && _selectedRoute!.name == route.name) ||
          (_showNearestRoute &&
              _nearestRoute != null &&
              _nearestRoute!.route.name == route.name);

      if (!shouldShow) continue;

      // Determinar opacidad y grosor
      double strokeWidth = 4.0;
      double opacity = 1.0;

      if (_selectedRoute != null) {
        if (_selectedRoute!.name == route.name) {
          strokeWidth = 6.0;
        } else {
          opacity = 0.3;
        }
      } else if (_nearestRoute != null &&
          _nearestRoute!.route.name == route.name) {
        strokeWidth = 5.0;
      }

      polylines.add(
        Polyline(
          points: route.points,
          color: Color(route.color).withOpacity(opacity),
          strokeWidth: strokeWidth,
        ),
      );
    }

    return polylines;
  }

  // Construir marcadores
  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // Marcadores de paraderos
    for (var route in _routes) {
      bool shouldShow = _showAllRoutes ||
          (_selectedRoute != null && _selectedRoute!.name == route.name) ||
          (_showNearestRoute &&
              _nearestRoute != null &&
              _nearestRoute!.route.name == route.name);

      if (!shouldShow) continue;

      for (var stop in route.stops) {
        markers.add(
          Marker(
            point: stop.position,
            width: 100,
            height: 50,
            child: GestureDetector(
              onTap: () => _showStopInfo(stop, route),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      stop.name,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(route.color),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    // Marcador de ubicación del usuario
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  void _showStopInfo(BusStop stop, RouteInfo route) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stop.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(route.color),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                route.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18),
                const SizedBox(width: 8),
                Text('Horario: ${route.schedule}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer, size: 18),
                const SizedBox(width: 8),
                Text('Frecuencia: ${route.frequency}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 18),
                const SizedBox(width: 8),
                Text('Tarifa: \$${route.fare}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Rutas'),
        backgroundColor: Colors.green.shade400,
        foregroundColor: Colors.white,
        actions: [
          if (_currentPosition != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.gps_fixed,
                color:
                    _isTrackingUser ? Colors.lightGreenAccent : Colors.white70,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Mapa
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition != null
                        ? LatLng(_currentPosition!.latitude,
                            _currentPosition!.longitude)
                        : const LatLng(4.142, -73.626),
                    initialZoom: _currentZoom,
                    minZoom: 10.0,
                    maxZoom: 18.0,
                    onPositionChanged: (position, hasGesture) {
                      if (hasGesture && _isTrackingUser) {
                        setState(() {
                          _isTrackingUser = false;
                        });
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.transporte_app',
                      maxNativeZoom: 19,
                    ),
                    // Polylines de rutas
                    PolylineLayer(
                      polylines: _buildPolylines(),
                    ),
                    // Marcadores
                    MarkerLayer(
                      markers: _buildMarkers(),
                    ),
                  ],
                ),

                // Panel de información de ruta más cercana
                if (_nearestRoute != null && _showNearestRoute)
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Ruta más cercana:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () =>
                                      setState(() => _showNearestRoute = false),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(_nearestRoute!.route.color),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _nearestRoute!.route.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${(_nearestRoute!.distance).toStringAsFixed(0)}m',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Paradero más cercano: ${_nearestRoute!.nearestStop.name}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Frecuencia: ${_nearestRoute!.route.frequency}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Lista de rutas (panel lateral)
                Positioned(
                  bottom: 20,
                  left: 10,
                  right: 10,
                  child: Container(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _routes.length,
                      itemBuilder: (context, index) {
                        final route = _routes[index];
                        final isSelected = _selectedRoute?.name == route.name;

                        return GestureDetector(
                          onTap: () => _selectRoute(isSelected ? null : route),
                          child: Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Color(route.color)
                                    : Colors.grey.shade300,
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Color(route.color),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  route.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${route.stops.length} paradas',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  route.frequency,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Botón para mostrar/ocultar todas las rutas
          FloatingActionButton(
            heroTag: 'routes',
            onPressed: () {
              setState(() {
                _showAllRoutes = !_showAllRoutes;
                if (_showAllRoutes) _selectedRoute = null;
              });
            },
            backgroundColor:
                _showAllRoutes ? Colors.purple : Colors.purple.shade300,
            mini: true,
            child: Icon(
              _showAllRoutes ? Icons.route : Icons.alt_route,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          // Botón para centrar en ubicación actual
          FloatingActionButton(
            heroTag: 'location',
            onPressed: _currentPosition != null ? _centerOnUserLocation : null,
            backgroundColor:
                _isTrackingUser ? Colors.blue : Colors.blue.shade300,
            child: Icon(
              _isTrackingUser ? Icons.gps_fixed : Icons.gps_not_fixed,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 70), // Espacio para el panel de rutas
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_positionStreamSubscription == null ||
          _positionStreamSubscription!.isPaused) {
        _startLocationTracking();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionStreamSubscription?.cancel();
    _geoLocationService.dispose();
    _mapController.dispose();
    super.dispose();
  }
}
