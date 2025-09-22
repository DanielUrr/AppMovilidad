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

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final GeoLocationService _geoLocationService = GeoLocationService();
  final RouteService _routeService = RouteService();
  final MapController _mapController = MapController();

  // Animaciones
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

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
  bool _showBusStops = true;

  // Simulación de buses en tiempo real
  Map<String, LatLng> _busPositions = {};
  Timer? _busSimulationTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeMap();
    _startBusSimulation();
  }

  void _initializeAnimations() {
    // Animación de pulso para ubicación del usuario
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    ));

    // Animación de deslizamiento para paneles
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startBusSimulation() {
    // Simular movimiento de buses
    _busSimulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_routes.isNotEmpty && mounted) {
        setState(() {
          for (var route in _routes) {
            String busKey = 'bus_${route.name}';

            // Si el bus no existe, crear uno en un punto aleatorio de la ruta
            if (!_busPositions.containsKey(busKey)) {
              int randomIndex =
                  DateTime.now().millisecondsSinceEpoch % route.points.length;
              _busPositions[busKey] = route.points[randomIndex];
            } else {
              // Mover el bus al siguiente punto
              LatLng currentPos = _busPositions[busKey]!;
              int currentIndex = route.points.indexOf(currentPos);
              if (currentIndex == -1 ||
                  currentIndex >= route.points.length - 1) {
                _busPositions[busKey] = route.points[0];
              } else {
                _busPositions[busKey] = route.points[currentIndex + 1];
              }
            }
          }
        });
      }
    });
  }

  Future<void> _initializeMap() async {
    await _loadRoutes();
    await _startLocationTracking();
    _slideController.forward();

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
              backgroundColor: Colors.orange,
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

        _updateNearestRoute(LatLng(position.latitude, position.longitude));

        _mapController.move(
          LatLng(position.latitude, position.longitude),
          _currentZoom,
        );
      }

      _positionStreamSubscription =
          _geoLocationService.getLocationStream()?.listen(
        (Position position) {
          if (mounted) {
            setState(() {
              _currentPosition = position;
            });

            _updateNearestRoute(LatLng(position.latitude, position.longitude));

            if (_isTrackingUser) {
              _mapController.move(
                LatLng(position.latitude, position.longitude),
                _mapController.camera.zoom,
              );
            }
          }
        },
      );
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

    if (route != null) {
      // Centrar el mapa en la ruta seleccionada
      if (route.points.isNotEmpty) {
        double minLat = route.points.first.latitude;
        double maxLat = route.points.first.latitude;
        double minLng = route.points.first.longitude;
        double maxLng = route.points.first.longitude;

        for (var point in route.points) {
          minLat = point.latitude < minLat ? point.latitude : minLat;
          maxLat = point.latitude > maxLat ? point.latitude : maxLat;
          minLng = point.longitude < minLng ? point.longitude : minLng;
          maxLng = point.longitude > maxLng ? point.longitude : maxLng;
        }

        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds(
              LatLng(minLat, minLng),
              LatLng(maxLat, maxLng),
            ),
            padding: const EdgeInsets.all(50),
          ),
        );
      }
    }
  }

  // Construir polylines para las rutas
  List<Polyline> _buildPolylines() {
    List<Polyline> polylines = [];

    for (var route in _routes) {
      bool shouldShow = _showAllRoutes ||
          (_selectedRoute != null && _selectedRoute!.name == route.name) ||
          (_showNearestRoute &&
              _nearestRoute != null &&
              _nearestRoute!.route.name == route.name);

      if (!shouldShow) continue;

      double strokeWidth = 5.0;
      double opacity = 1.0;

      if (_selectedRoute != null) {
        if (_selectedRoute!.name == route.name) {
          strokeWidth = 8.0;
        } else {
          opacity = 0.2;
        }
      } else if (_nearestRoute != null &&
          _nearestRoute!.route.name == route.name) {
        strokeWidth = 6.0;
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

    // Marcadores de buses en tiempo real
    _busPositions.forEach((busId, position) {
      String routeName = busId.replaceAll('bus_', '');
      RouteInfo? route = _routes.firstWhere(
        (r) => r.name == routeName,
        orElse: () => _routes.first,
      );

      bool shouldShow = _showAllRoutes ||
          (_selectedRoute != null && _selectedRoute!.name == route.name);

      if (shouldShow) {
        markers.add(
          Marker(
            point: position,
            width: 40,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: Color(route.color),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_bus,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        );
      }
    });

    // Marcadores de paraderos
    if (_showBusStops) {
      for (var route in _routes) {
        bool shouldShow = _showAllRoutes ||
            (_selectedRoute != null && _selectedRoute!.name == route.name);

        if (!shouldShow) continue;

        for (var stop in route.stops) {
          markers.add(
            Marker(
              point: stop.position,
              width: 100,
              height: 60,
              child: GestureDetector(
                onTap: () => _showStopInfo(stop, route),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        stop.name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Color(route.color),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.circle,
                        color: Colors.white,
                        size: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    }

    // Marcador de ubicación del usuario con animación
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 100,
          height: 100,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Círculo de pulso
                  Container(
                    width: 60 * (1 + _pulseAnimation.value),
                    height: 60 * (1 + _pulseAnimation.value),
                    decoration: BoxDecoration(
                      color: Colors.blue
                          .withOpacity(0.3 * (1 - _pulseAnimation.value)),
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Punto central
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.navigation,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    return markers;
  }

  void _showStopInfo(BusStop stop, RouteInfo route) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(route.color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    color: Color(route.color),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(route.color),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          route.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(Icons.access_time, 'Horario', route.schedule),
            _buildInfoRow(Icons.timer, 'Frecuencia', route.frequency),
            _buildInfoRow(Icons.attach_money, 'Tarifa', '\$${route.fare}'),
            const SizedBox(height: 15),
            // Simulación de próximo bus
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.directions_bus, color: Colors.green.shade600),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Próximo bus',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'En ${(DateTime.now().minute % 15) + 1} minutos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.green.shade400),
                  ),
                  const SizedBox(height: 20),
                  const Text('Cargando mapa...'),
                ],
              ),
            )
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
                    minZoom: 11.0,
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
                    // Capa de tráfico simulada (removida por incompatibilidad)
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

                // Barra superior con gradiente
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: MediaQuery.of(context).padding.top + 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.green.shade400,
                          Colors.green.shade400.withOpacity(0.9),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Text(
                            'Mapa de Rutas',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_currentPosition != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: _isTrackingUser
                                    ? Colors.lightGreenAccent.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.gps_fixed,
                                    color: _isTrackingUser
                                        ? Colors.lightGreenAccent
                                        : Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isTrackingUser ? 'GPS ON' : 'GPS OFF',
                                    style: TextStyle(
                                      color: _isTrackingUser
                                          ? Colors.lightGreenAccent
                                          : Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Panel de información de ruta más cercana
                if (_nearestRoute != null && _showNearestRoute)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 70,
                    left: 10,
                    right: 10,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.blue.shade50,
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.near_me,
                                          color: Colors.blue.shade600,
                                          size: 16),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Ruta más cercana',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => setState(
                                        () => _showNearestRoute = false),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Color(_nearestRoute!.route.color),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _nearestRoute!.route.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${(_nearestRoute!.distance).toStringAsFixed(0)}m',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.location_on,
                                      size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Paradero: ${_nearestRoute!.nearestStop.name}',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.timer,
                                      size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    _nearestRoute!.route.frequency,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Lista de rutas (panel inferior)
                Positioned(
                  bottom: 20,
                  left: 10,
                  right: 10,
                  child: Container(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _routes.length,
                      itemBuilder: (context, index) {
                        final route = _routes[index];
                        final isSelected = _selectedRoute?.name == route.name;

                        return GestureDetector(
                          onTap: () => _selectRoute(isSelected ? null : route),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 140,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isSelected
                                    ? Color(route.color)
                                    : Colors.grey.shade300,
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? Color(route.color).withOpacity(0.3)
                                      : Colors.black.withOpacity(0.1),
                                  blurRadius: isSelected ? 8 : 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(15),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15),
                                onTap: () =>
                                    _selectRoute(isSelected ? null : route),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: Color(route.color),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        route.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isSelected
                                              ? Color(route.color)
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${route.stops.length} paradas',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
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
                              ),
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
          // Botón para mostrar/ocultar paraderos
          FloatingActionButton(
            heroTag: 'stops',
            onPressed: () {
              setState(() {
                _showBusStops = !_showBusStops;
              });
            },
            backgroundColor:
                _showBusStops ? Colors.orange : Colors.orange.shade300,
            mini: true,
            child: Icon(
              _showBusStops ? Icons.location_on : Icons.location_off,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 140), // Espacio para el panel de rutas
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _positionStreamSubscription?.cancel();
    _busSimulationTimer?.cancel();
    _geoLocationService.dispose();
    _mapController.dispose();
    super.dispose();
  }
}
