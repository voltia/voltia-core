import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'services/socket_service.dart';

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
      home: const VoltiaMapPage(),
    );
  }
}

class VoltiaMapPage extends StatefulWidget {
  const VoltiaMapPage({super.key});

  @override
  State<VoltiaMapPage> createState() => _VoltiaMapPageState();
}

class _VoltiaMapPageState extends State<VoltiaMapPage> {
  final MapController _mapController = MapController();
  final SocketService socketService = SocketService();

  List<Marker> markers = [];

  @override
  void initState() {
    super.initState();

    socketService.connect((data) {
      final lat = data['lat'];
      final lng = data['lng'];

      setState(() {
        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 40,
            height: 40,
            child: const Icon(Icons.location_on, color: Colors.red),
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VOLTIA MAP PRO'),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(18.4861, -69.9312),
          initialZoom: 12,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}