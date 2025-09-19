import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  List<Marker> _paraderos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParaderos();
  }

  Future<void> _loadParaderos() async {
    try {
      final paraderos = await _locationService.getParaderos();
      setState(() {
        _paraderos = paraderos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar paraderos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Rutas'),
        backgroundColor: Colors.green.shade400,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(4.142, -73.626), // Villavicencio
                initialZoom: 13.0,
                minZoom: 10.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.transporte_app',
                  maxNativeZoom: 19,
                ),
                MarkerLayer(
                  markers: _paraderos,
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadParaderos,
        backgroundColor: Colors.green.shade400,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}