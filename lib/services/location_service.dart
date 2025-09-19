import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  // Coordenadas aproximadas para paraderos en Villavicencio
  final Map<String, LatLng> _paraderosCoords = {
    'Centro': const LatLng(4.1420, -73.6266),
    'Siete de Agosto': const LatLng(4.1450, -73.6280),
    'Postobón': const LatLng(4.1380, -73.6250),
    'La Esperanza': const LatLng(4.1500, -73.6300),
    'Unillanos': const LatLng(4.1350, -73.6200),
    'Catama': const LatLng(4.1400, -73.6180),
    'Alborada': const LatLng(4.1480, -73.6220),
    'Parque Banderas': const LatLng(4.1460, -73.6240),
    'Terminal': const LatLng(4.1520, -73.6320),
    'Hospital': const LatLng(4.1390, -73.6270),
    'Macarena': const LatLng(4.1440, -73.6290),
    'Barzal': const LatLng(4.1370, -73.6210),
  };

  Future<List<Marker>> getParaderos() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/rutas.json');
      final Map<String, dynamic> rutasData = json.decode(jsonString);
      
      Set<String> paraderosUnicos = {};
      Map<String, List<String>> paraderoRutas = {};
      
      // Recopilar todos los paraderos únicos y las rutas que pasan por cada uno
      rutasData.forEach((rutaName, rutaData) {
        final List<dynamic> paraderos = rutaData['paraderos'];
        for (String paradero in paraderos) {
          paraderosUnicos.add(paradero);
          if (!paraderoRutas.containsKey(paradero)) {
            paraderoRutas[paradero] = [];
          }
          paraderoRutas[paradero]!.add(rutaName);
        }
      });
      
      List<Marker> markers = [];
      
      for (String paradero in paraderosUnicos) {
        LatLng? coords = _paraderosCoords[paradero];
        
        // Si no tenemos coordenadas específicas, generar algunas cerca del centro
        coords ??= LatLng(
          4.142 + (paraderosUnicos.toList().indexOf(paradero) * 0.005) - 0.01,
          -73.626 + (paraderosUnicos.toList().indexOf(paradero) * 0.003) - 0.01,
        );
        
        final List<String> rutasQuePasan = paraderoRutas[paradero] ?? [];
        
        markers.add(
          Marker(
            point: coords,
            width: 80,
            height: 80,
            child: GestureDetector(
              onTap: () {
                // Aquí podrías mostrar más información del paradero
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      paradero,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _getParaderoColor(rutasQuePasan),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_bus,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      
      return markers;
    } catch (e) {
      // Si hay error cargando las rutas, devolver algunos paraderos de ejemplo
      return _getDefaultMarkers();
    }
  }

  Color _getParaderoColor(List<String> rutas) {
    // Asignar colores según el número de rutas que pasan
    if (rutas.length >= 3) {
      return Colors.red.shade600; // Paradero muy concurrido
    } else if (rutas.length == 2) {
      return Colors.orange.shade600; // Paradero medio
    } else {
      return Colors.green.shade600; // Una sola ruta
    }
  }

  List<Marker> _getDefaultMarkers() {
    // Marcadores de ejemplo si no se pueden cargar las rutas
    return [
      Marker(
        point: const LatLng(4.1420, -73.6266),
        width: 80,
        height: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Centro',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_bus,
                color: Colors.white,
                size: 12,
              ),
            ),
          ],
        ),
      ),
    ];
  }
}