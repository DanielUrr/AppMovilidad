import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';

class BusOccupancyService {
  final Random _random = Random();
  Timer? _updateTimer;

  // Datos simulados de buses
  final Map<String, BusData> _busesData = {};

  // Stream controller para actualizaciones en tiempo real
  final StreamController<Map<String, BusData>> _occupancyController =
      StreamController<Map<String, BusData>>.broadcast();

  // Getter para el stream
  Stream<Map<String, BusData>> get occupancyStream =>
      _occupancyController.stream;

  // Capacidades máximas por tipo de bus
  final Map<String, int> _busCapacities = {
    'pequeño': 25,
    'mediano': 35,
    'grande': 45,
    'articulado': 60,
  };

  BusOccupancyService() {
    _initializeBuses();
    _startSimulation();
  }

  // Inicializar buses con datos iniciales
  void _initializeBuses() {
    final buses = [
      {'id': 'B101', 'ruta': 'Ruta 1', 'tipo': 'grande', 'placa': 'ABC-123'},
      {'id': 'B102', 'ruta': 'Ruta 1', 'tipo': 'mediano', 'placa': 'DEF-456'},
      {'id': 'B103', 'ruta': 'Ruta 1', 'tipo': 'grande', 'placa': 'GHI-789'},
      {
        'id': 'B201',
        'ruta': 'Ruta 2',
        'tipo': 'articulado',
        'placa': 'JKL-012'
      },
      {'id': 'B202', 'ruta': 'Ruta 2', 'tipo': 'grande', 'placa': 'MNO-345'},
      {'id': 'B301', 'ruta': 'Ruta 3', 'tipo': 'mediano', 'placa': 'PQR-678'},
      {'id': 'B302', 'ruta': 'Ruta 3', 'tipo': 'pequeño', 'placa': 'STU-901'},
      {'id': 'B303', 'ruta': 'Ruta 3', 'tipo': 'grande', 'placa': 'VWX-234'},
      {'id': 'B401', 'ruta': 'Ruta 4', 'tipo': 'grande', 'placa': 'YZA-567'},
      {'id': 'B402', 'ruta': 'Ruta 4', 'tipo': 'mediano', 'placa': 'BCD-890'},
      {
        'id': 'B501',
        'ruta': 'Ruta 5',
        'tipo': 'articulado',
        'placa': 'EFG-123'
      },
      {'id': 'B502', 'ruta': 'Ruta 5', 'tipo': 'grande', 'placa': 'HIJ-456'},
      {'id': 'B601', 'ruta': 'Ruta 6', 'tipo': 'mediano', 'placa': 'KLM-789'},
      {'id': 'B602', 'ruta': 'Ruta 6', 'tipo': 'pequeño', 'placa': 'NOP-012'},
    ];

    for (var bus in buses) {
      final capacity = _busCapacities[bus['tipo']] ?? 35;
      final currentPassengers = _random.nextInt(capacity);

      _busesData[bus['id']!] = BusData(
        busId: bus['id']!,
        routeName: bus['ruta']!,
        busType: bus['tipo']!,
        plateNumber: bus['placa']!,
        capacity: capacity,
        currentPassengers: currentPassengers,
        seatsTaken: _generateSeatOccupancy(capacity, currentPassengers),
        temperature: 20 + _random.nextInt(8).toDouble(),
        co2Level: 400 + _random.nextInt(200).toDouble(),
        lastUpdate: DateTime.now(),
        status: _determineStatus(currentPassengers, capacity),
        nextStop: _getRandomStop(),
        estimatedArrival: _random.nextInt(15) + 1,
        hasAirConditioning: _random.nextBool(),
        hasWifi: _random.nextBool(),
        isAccessible: bus['tipo'] != 'pequeño',
      );
    }
  }

  // Generar ocupación de asientos
  List<bool> _generateSeatOccupancy(int capacity, int occupied) {
    List<bool> seats = List.filled(capacity, false);
    List<int> indices = List.generate(capacity, (i) => i);
    indices.shuffle();

    for (int i = 0; i < occupied && i < indices.length; i++) {
      seats[indices[i]] = true;
    }

    return seats;
  }

  // Determinar estado basado en ocupación
  BusStatus _determineStatus(int passengers, int capacity) {
    double percentage = (passengers / capacity) * 100;

    if (percentage < 40) return BusStatus.libre;
    if (percentage < 70) return BusStatus.moderado;
    if (percentage < 90) return BusStatus.lleno;
    return BusStatus.completo;
  }

  // Obtener paradero aleatorio
  String _getRandomStop() {
    final stops = [
      'Centro',
      'Terminal',
      'Hospital',
      'Unillanos',
      'Catama',
      'Alborada',
      'La Esperanza',
      'Barzal',
      'Parque Banderas',
      'Siete de Agosto',
      'Postobón',
      'Macarena'
    ];
    return stops[_random.nextInt(stops.length)];
  }

  // Iniciar simulación
  void _startSimulation() {
    _updateTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _updateBusData();
    });
  }

  // Actualizar datos de buses (simular sensores)
  void _updateBusData() {
    final hour = DateTime.now().hour;
    bool isRushHour = (hour >= 6 && hour <= 9) || (hour >= 17 && hour <= 19);

    _busesData.forEach((id, bus) {
      // Simular entrada/salida de pasajeros
      int change = _random.nextInt(7) - 3; // -3 a +3 pasajeros

      // En hora pico, más probabilidad de subir pasajeros
      if (isRushHour) {
        change = _random.nextInt(5) - 1; // -1 a +3 pasajeros
      }

      int newPassengers = bus.currentPassengers + change;
      newPassengers = newPassengers.clamp(0, bus.capacity);

      // Actualizar datos del bus
      bus.currentPassengers = newPassengers;
      bus.seatsTaken = _generateSeatOccupancy(bus.capacity, newPassengers);
      bus.temperature = 20 + _random.nextInt(8).toDouble();
      bus.co2Level =
          400 + (newPassengers * 10) + _random.nextInt(100).toDouble();
      bus.lastUpdate = DateTime.now();
      bus.status = _determineStatus(newPassengers, bus.capacity);
      bus.estimatedArrival = _random.nextInt(15) + 1;

      // Cambiar paradero ocasionalmente
      if (_random.nextInt(10) > 7) {
        bus.nextStop = _getRandomStop();
      }
    });

    // Emitir actualización
    _occupancyController.add(Map.from(_busesData));
  }

  // Obtener datos actuales de todos los buses
  Map<String, BusData> getAllBusesData() {
    return Map.from(_busesData);
  }

  // Obtener datos de buses por ruta
  List<BusData> getBusesByRoute(String routeName) {
    return _busesData.values
        .where((bus) => bus.routeName == routeName)
        .toList();
  }

  // Obtener un bus específico
  BusData? getBusById(String busId) {
    return _busesData[busId];
  }

  // Obtener estadísticas generales
  OccupancyStatistics getStatistics() {
    if (_busesData.isEmpty) {
      return OccupancyStatistics(
        totalBuses: 0,
        totalPassengers: 0,
        averageOccupancy: 0,
        busesLibres: 0,
        busesModerados: 0,
        busesLlenos: 0,
        busesCompletos: 0,
      );
    }

    int totalPassengers = 0;
    int totalCapacity = 0;
    int busesLibres = 0;
    int busesModerados = 0;
    int busesLlenos = 0;
    int busesCompletos = 0;

    _busesData.forEach((_, bus) {
      totalPassengers += bus.currentPassengers;
      totalCapacity += bus.capacity;

      switch (bus.status) {
        case BusStatus.libre:
          busesLibres++;
          break;
        case BusStatus.moderado:
          busesModerados++;
          break;
        case BusStatus.lleno:
          busesLlenos++;
          break;
        case BusStatus.completo:
          busesCompletos++;
          break;
      }
    });

    return OccupancyStatistics(
      totalBuses: _busesData.length,
      totalPassengers: totalPassengers,
      averageOccupancy: totalCapacity > 0
          ? (totalPassengers / totalCapacity * 100).round()
          : 0,
      busesLibres: busesLibres,
      busesModerados: busesModerados,
      busesLlenos: busesLlenos,
      busesCompletos: busesCompletos,
    );
  }

  // Obtener recomendaciones basadas en ocupación
  List<String> getRecommendations() {
    final stats = getStatistics();
    List<String> recommendations = [];

    if (stats.averageOccupancy > 70) {
      recommendations
          .add('🚌 Alta demanda detectada. Considera salir 10 minutos antes.');
    }

    // Buscar rutas menos congestionadas
    Map<String, double> routeOccupancy = {};
    _busesData.forEach((_, bus) {
      if (!routeOccupancy.containsKey(bus.routeName)) {
        routeOccupancy[bus.routeName] = 0;
      }
      routeOccupancy[bus.routeName] = routeOccupancy[bus.routeName]! +
          (bus.currentPassengers / bus.capacity);
    });

    String? leastCrowded;
    double minOccupancy = double.infinity;

    routeOccupancy.forEach((route, occupancy) {
      if (occupancy < minOccupancy) {
        minOccupancy = occupancy;
        leastCrowded = route;
      }
    });

    if (leastCrowded != null) {
      recommendations.add('✅ $leastCrowded tiene menor ocupación ahora mismo.');
    }

    // Recomendación por hora
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour <= 9) {
      recommendations.add('⏰ Hora pico matutina. Espera mayor ocupación.');
    } else if (hour >= 17 && hour <= 19) {
      recommendations
          .add('⏰ Hora pico vespertina. Los buses están más llenos.');
    } else if (hour >= 10 && hour <= 16) {
      recommendations.add('😊 Hora valle. Buen momento para viajar cómodo.');
    }

    return recommendations;
  }

  // Buscar buses con asientos disponibles
  List<BusData> findAvailableBuses({int minSeats = 1}) {
    return _busesData.values.where((bus) {
      int availableSeats = bus.capacity - bus.currentPassengers;
      return availableSeats >= minSeats;
    }).toList()
      ..sort((a, b) {
        int seatsA = a.capacity - a.currentPassengers;
        int seatsB = b.capacity - b.currentPassengers;
        return seatsB.compareTo(seatsA);
      });
  }

  // Predecir ocupación futura (simulado)
  Map<String, int> predictOccupancy(String busId, int minutesAhead) {
    final bus = _busesData[busId];
    if (bus == null) return {};

    final hour = DateTime.now().add(Duration(minutes: minutesAhead)).hour;
    int predictedPassengers = bus.currentPassengers;

    // Lógica simple de predicción basada en hora
    if (hour >= 6 && hour <= 9) {
      predictedPassengers =
          (bus.capacity * 0.85).round(); // 85% en hora pico AM
    } else if (hour >= 17 && hour <= 19) {
      predictedPassengers =
          (bus.capacity * 0.90).round(); // 90% en hora pico PM
    } else if (hour >= 10 && hour <= 16) {
      predictedPassengers = (bus.capacity * 0.50).round(); // 50% en hora valle
    } else {
      predictedPassengers = (bus.capacity * 0.30).round(); // 30% en otras horas
    }

    return {
      'current': bus.currentPassengers,
      'predicted': predictedPassengers,
      'capacity': bus.capacity,
    };
  }

  // Limpiar recursos
  void dispose() {
    _updateTimer?.cancel();
    _occupancyController.close();
  }
}

// Modelo de datos del bus
class BusData {
  String busId;
  String routeName;
  String busType;
  String plateNumber;
  int capacity;
  int currentPassengers;
  List<bool> seatsTaken;
  double temperature;
  double co2Level;
  DateTime lastUpdate;
  BusStatus status;
  String nextStop;
  int estimatedArrival;
  bool hasAirConditioning;
  bool hasWifi;
  bool isAccessible;

  BusData({
    required this.busId,
    required this.routeName,
    required this.busType,
    required this.plateNumber,
    required this.capacity,
    required this.currentPassengers,
    required this.seatsTaken,
    required this.temperature,
    required this.co2Level,
    required this.lastUpdate,
    required this.status,
    required this.nextStop,
    required this.estimatedArrival,
    required this.hasAirConditioning,
    required this.hasWifi,
    required this.isAccessible,
  });

  double get occupancyPercentage => (currentPassengers / capacity) * 100;
  int get availableSeats => capacity - currentPassengers;
}

// Estados del bus
enum BusStatus {
  libre, // < 40% ocupación
  moderado, // 40-70% ocupación
  lleno, // 70-90% ocupación
  completo // > 90% ocupación
}

// Estadísticas de ocupación
class OccupancyStatistics {
  final int totalBuses;
  final int totalPassengers;
  final int averageOccupancy;
  final int busesLibres;
  final int busesModerados;
  final int busesLlenos;
  final int busesCompletos;

  OccupancyStatistics({
    required this.totalBuses,
    required this.totalPassengers,
    required this.averageOccupancy,
    required this.busesLibres,
    required this.busesModerados,
    required this.busesLlenos,
    required this.busesCompletos,
  });
}
