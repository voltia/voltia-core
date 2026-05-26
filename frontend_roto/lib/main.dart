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
      title: 'VOLTIA MAP PRO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const VoltiaMapScreen(),
    );
  }
}

class MarkerData {
  final int id;
  final double lat;
  final double lng;
  final String title;
  final String type;

  const MarkerData({
    required this.id,
    required this.lat,
    required this.lng,
    required this.title,
    required this.type,
  });

  factory MarkerData.fromJson(Map<String, dynamic> json) {
    return MarkerData(
      id: (json['id'] as num?)?.toInt() ?? 0,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      title: (json['title'] ?? 'Evento VOLTIA').toString(),
      type: (json['type'] ?? 'USER').toString(),
    );
  }
}

class VoltiaMapScreen extends StatefulWidget {
  const VoltiaMapScreen({super.key});

  @override
  State<VoltiaMapScreen> createState() => _VoltiaMapScreenState();
}

class _VoltiaMapScreenState extends State<VoltiaMapScreen> {
  bool loading = true;
  String error = '';
  List<MarkerData> markers = [];

  @override
  void initState() {
    super.initState();
    loadMarkers();
  }

  Future<void> loadMarkers() async {
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
        error = 'Error conectando con backend: $e';
      });
    }
  }

  Color markerColor(String type) {
    switch (type.toUpperCase()) {
      case 'SOS':
        return Colors.redAccent;
      case 'RISK':
        return Colors.orangeAccent;
      case 'PATROL':
        return Colors.purpleAccent;
      case 'SAFE_ZONE':
      case 'SAFE':
        return Colors.greenAccent;
      default:
        return Colors.blueAccent;
    }
  }

  IconData markerIcon(String type) {
    switch (type.toUpperCase()) {
      case 'SOS':
        return Icons.sos_rounded;
      case 'RISK':
        return Icons.warning_amber_rounded;
      case 'PATROL':
        return Icons.shield_rounded;
      case 'SAFE_ZONE':
      case 'SAFE':
        return Icons.verified_user_rounded;
      default:
        return Icons.person_pin_circle_rounded;
    }
  }

  String markerLabel(String type) {
    switch (type.toUpperCase()) {
      case 'SOS':
        return 'SOS';
      case 'RISK':
        return 'RIESGO';
      case 'PATROL':
        return 'PATRULLA';
      case 'SAFE_ZONE':
      case 'SAFE':
        return 'ZONA SEGURA';
      default:
        return 'USUARIO';
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng center = markers.isNotEmpty
        ? LatLng(markers.first.lat, markers.first.lng)
        : const LatLng(18.4861, -69.9312);

    return Scaffold(
      backgroundColor: const Color(0xFF05070A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080D14),
        centerTitle: true,
        title: const Text(
          'VOLTIA MAP PRO',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                loading = true;
              });
              loadMarkers();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: center,
                          initialZoom: 12,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.voltia.core',
                          ),
                          CircleLayer(
                            circles: markers.map((marker) {
                              return CircleMarker(
                                point: LatLng(marker.lat, marker.lng),
                                radius: 300,
                                useRadiusInMeter: true,
                                color: markerColor(marker.type)
                                    .withValues(alpha: 0.18),
                                borderColor: markerColor(marker.type),
                                borderStrokeWidth: 2,
                              );
                            }).toList(),
                          ),
                          MarkerLayer(
                            markers: markers.map((marker) {
                              return Marker(
                                point: LatLng(marker.lat, marker.lng),
                                width: 78,
                                height: 78,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      markerIcon(marker.type),
                                      color: markerColor(marker.type),
                                      size: 36,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: markerColor(marker.type),
                                        ),
                                      ),
                                      child: Text(
                                        markerLabel(marker.type),
                                        style: TextStyle(
                                          color: markerColor(marker.type),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: ListView.separated(
                        itemCount: markers.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: Color(0xFF1B2430),
                        ),
                        itemBuilder: (context, index) {
                          final marker = markers[index];

                          return ListTile(
                            leading: Icon(
                              markerIcon(marker.type),
                              color: markerColor(marker.type),
                            ),
                            title: Text(
                              marker.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Lat: ${marker.lat} | Lng: ${marker.lng}',
                              style: const TextStyle(color: Colors.white60),
                            ),
                            trailing: Text(
                              markerLabel(marker.type),
                              style: TextStyle(
                                color: markerColor(marker.type),
                                fontWeight: FontWeight.bold,
                              ),
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