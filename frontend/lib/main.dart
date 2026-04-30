import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'api_service.dart';

void main() {
  runApp(const VoltiaApp());
}

class VoltiaApp extends StatelessWidget {
  const VoltiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VOLTIA CORE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const HomePage(),
    );
  }
}

class MarkerData {
  final int id;
  final double lat;
  final double lng;
  final String title;

  MarkerData({
    required this.id,
    required this.lat,
    required this.lng,
    required this.title,
  });

  factory MarkerData.fromJson(Map<String, dynamic> json) {
    return MarkerData(
      id: json['id'],
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      title: json['title'],
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = true;
  String error = '';
  List<MarkerData> markers = [];

  @override
  void initState() {
    super.initState();
    cargarMarkers();
  }

  Future<void> cargarMarkers() async {
    try {
      final data = await ApiService.getMarkers();

      setState(() {
        markers = data
            .map((item) => MarkerData.fromJson(item as Map<String, dynamic>))
            .toList();
        loading = false;
        error = '';
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = 'Error de conexión: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng centro = markers.isNotEmpty
        ? LatLng(markers.first.lat, markers.first.lng)
        : const LatLng(18.4861, -69.9312);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VOLTIA CORE'),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(
                  child: Text(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: centro,
                          initialZoom: 12,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.voltia.app',
                          ),
                          MarkerLayer(
                            markers: markers.map((marker) {
                              return Marker(
                                point: LatLng(marker.lat, marker.lng),
                                width: 60,
                                height: 60,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: ListView.builder(
                        itemCount: markers.length,
                        itemBuilder: (context, index) {
                          final marker = markers[index];

                          return ListTile(
                            leading: const Icon(Icons.security),
                            title: Text(marker.title),
                            subtitle: Text(
                              'Lat: ${marker.lat} | Lng: ${marker.lng}',
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}