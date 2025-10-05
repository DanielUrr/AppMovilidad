import 'package:flutter/material.dart';
import 'package:transporte_app/services/bus_occupancy_service.dart';
import 'dart:async';
import '../services/bus_occupancy_service.dart';

class BusOccupancyScreen extends StatefulWidget {
  const BusOccupancyScreen({super.key});

  @override
  State<BusOccupancyScreen> createState() => _BusOccupancyScreenState();
}

class _BusOccupancyScreenState extends State<BusOccupancyScreen>
    with TickerProviderStateMixin {
  final BusOccupancyService _occupancyService = BusOccupancyService();
  late StreamSubscription<Map<String, BusData>> _occupancySubscription;

  Map<String, BusData> _busesData = {};
  String _selectedRoute = 'Todas';
  OccupancyStatistics? _statistics;
  List<String> _recommendations = [];

  // Animaciones
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _routes = [
    'Todas',
    'Ruta 1',
    'Ruta 2',
    'Ruta 3',
    'Ruta 4',
    'Ruta 5',
    'Ruta 6'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
    _subscribeToUpdates();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _loadData() {
    _busesData = _occupancyService.getAllBusesData();
    _statistics = _occupancyService.getStatistics();
    _recommendations = _occupancyService.getRecommendations();
    setState(() {});
  }

  void _subscribeToUpdates() {
    _occupancySubscription = _occupancyService.occupancyStream.listen((data) {
      if (mounted) {
        setState(() {
          _busesData = data;
          _statistics = _occupancyService.getStatistics();
          _recommendations = _occupancyService.getRecommendations();
        });
      }
    });
  }

  List<BusData> get _filteredBuses {
    if (_selectedRoute == 'Todas') {
      return _busesData.values.toList();
    }
    return _busesData.values
        .where((bus) => bus.routeName == _selectedRoute)
        .toList();
  }

  Color _getStatusColor(BusStatus status) {
    switch (status) {
      case BusStatus.libre:
        return Colors.green;
      case BusStatus.moderado:
        return Colors.orange;
      case BusStatus.lleno:
        return Colors.deepOrange;
      case BusStatus.completo:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(BusStatus status) {
    switch (status) {
      case BusStatus.libre:
        return Icons.check_circle;
      case BusStatus.moderado:
        return Icons.info;
      case BusStatus.lleno:
        return Icons.warning;
      case BusStatus.completo:
        return Icons.error;
    }
  }

  String _getStatusText(BusStatus status) {
    switch (status) {
      case BusStatus.libre:
        return 'Libre';
      case BusStatus.moderado:
        return 'Moderado';
      case BusStatus.lleno:
        return 'Lleno';
      case BusStatus.completo:
        return 'Completo';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Ocupación en Tiempo Real'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.white),
                      const SizedBox(width: 4),
                      const Text(
                        'EN VIVO',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Estadísticas generales
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.teal, Colors.teal.shade700],
              ),
            ),
            child: Column(
              children: [
                if (_statistics != null) _buildStatisticsCard(),
                _buildRouteFilter(),
              ],
            ),
          ),

          // Recomendaciones
          if (_recommendations.isNotEmpty) _buildRecommendations(),

          // Lista de buses
          Expanded(
            child: _filteredBuses.isEmpty
                ? const Center(
                    child: Text(
                      'No hay buses disponibles',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredBuses.length,
                    itemBuilder: (context, index) {
                      final bus = _filteredBuses[index];
                      return _buildBusCard(bus);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                Icons.directions_bus,
                _statistics!.totalBuses.toString(),
                'Buses Activos',
                Colors.blue,
              ),
              _buildStatItem(
                Icons.people,
                _statistics!.totalPassengers.toString(),
                'Pasajeros',
                Colors.orange,
              ),
              _buildStatItem(
                Icons.analytics,
                '${_statistics!.averageOccupancy}%',
                'Ocupación',
                _getOccupancyColor(_statistics!.averageOccupancy),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOccupancyBar(),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildOccupancyBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distribución de Ocupación',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildOccupancySegment(
              'Libre',
              _statistics!.busesLibres,
              Colors.green,
            ),
            _buildOccupancySegment(
              'Moderado',
              _statistics!.busesModerados,
              Colors.orange,
            ),
            _buildOccupancySegment(
              'Lleno',
              _statistics!.busesLlenos,
              Colors.deepOrange,
            ),
            _buildOccupancySegment(
              'Completo',
              _statistics!.busesCompletos,
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOccupancySegment(String label, int count, Color color) {
    final percentage =
        _statistics!.totalBuses > 0 ? (count / _statistics!.totalBuses) : 0.0;

    if (count == 0) return const SizedBox();

    return Expanded(
      flex: count,
      child: Container(
        height: 30,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.horizontal(
            left: label == 'Libre' ? const Radius.circular(8) : Radius.zero,
            right: label == 'Completo' ? const Radius.circular(8) : Radius.zero,
          ),
        ),
        child: Center(
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _routes.length,
        itemBuilder: (context, index) {
          final route = _routes[index];
          final isSelected = route == _selectedRoute;

          return GestureDetector(
            onTap: () => setState(() => _selectedRoute = route),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? Colors.teal : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  route,
                  style: TextStyle(
                    color: isSelected ? Colors.teal : Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendations() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Recomendaciones',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._recommendations.map((rec) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(rec, style: const TextStyle(fontSize: 13)),
              )),
        ],
      ),
    );
  }

  Widget _buildBusCard(BusData bus) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showBusDetails(bus),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Encabezado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(bus.status).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      color: _getStatusColor(bus.status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              bus.busId,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.teal,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                bus.routeName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Placa: ${bus.plateNumber} • ${bus.busType}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(bus.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(bus.status),
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(bus.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Barra de ocupación
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ocupación: ${bus.currentPassengers}/${bus.capacity} pasajeros',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        '${bus.occupancyPercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(bus.status),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: bus.occupancyPercentage / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStatusColor(bus.status),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Información adicional
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Próxima: ${bus.nextStop}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${bus.estimatedArrival} min',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Iconos de servicios
              Row(
                children: [
                  if (bus.hasAirConditioning)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.ac_unit,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  if (bus.hasWifi)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.wifi,
                        size: 16,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  if (bus.isAccessible)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.accessible,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                    ),
                  const Spacer(),
                  Text(
                    '${bus.availableSeats} asientos libres',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: bus.availableSeats > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBusDetails(BusData bus) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Encabezado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(bus.status).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      color: _getStatusColor(bus.status),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${bus.busId} - ${bus.plateNumber}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${bus.routeName} • ${bus.busType}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Visualización de asientos
              const Text(
                'Distribución de Asientos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildSeatMap(bus),

              const SizedBox(height: 24),

              // Información ambiental
              const Text(
                'Condiciones Ambientales',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildEnvironmentCard(
                      Icons.thermostat,
                      'Temperatura',
                      '${bus.temperature.toStringAsFixed(1)}°C',
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildEnvironmentCard(
                      Icons.air,
                      'CO₂',
                      '${bus.co2Level.toStringAsFixed(0)} ppm',
                      Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Predicción
              const Text(
                'Predicción de Ocupación',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildPrediction(bus),

              const SizedBox(height: 24),

              // Última actualización
              Center(
                child: Text(
                  'Última actualización: ${_formatTime(bus.lastUpdate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeatMap(BusData bus) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Leyenda
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSeatLegend(Colors.green, 'Libre'),
              const SizedBox(width: 20),
              _buildSeatLegend(Colors.red, 'Ocupado'),
            ],
          ),
          const SizedBox(height: 16),

          // Mapa de asientos
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.2,
            ),
            itemCount: bus.seatsTaken.length,
            itemBuilder: (context, index) {
              final isOccupied = bus.seatsTaken[index];
              return Container(
                decoration: BoxDecoration(
                  color: isOccupied ? Colors.red : Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.event_seat,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSeatLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildEnvironmentCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrediction(BusData bus) {
    final prediction = _occupancyService.predictOccupancy(bus.busId, 30);

    if (prediction.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ahora',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '${prediction['current']} pasajeros',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.arrow_forward,
                color: Colors.blue.shade700,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'En 30 min',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '${prediction['predicted']} pasajeros',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getOccupancyColor(int percentage) {
    if (percentage < 40) return Colors.green;
    if (percentage < 70) return Colors.orange;
    if (percentage < 90) return Colors.deepOrange;
    return Colors.red;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _occupancySubscription.cancel();
    _occupancyService.dispose();
    super.dispose();
  }
}
