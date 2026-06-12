import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' as math;

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
      title: 'VOLTIA MAP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Arial',
      ),
      home: const VoltiaMapScreen(),
    );
  }
}

class VoltiaMapScreen extends StatefulWidget {
  const VoltiaMapScreen({super.key});

  @override
  State<VoltiaMapScreen> createState() => _VoltiaMapScreenState();
}

class _VoltiaMapScreenState extends State<VoltiaMapScreen>
    with SingleTickerProviderStateMixin {

  final MapController _mapController = MapController();
  final math.Random _random = math.Random();

  final SocketService _socketService = SocketService();

  late final AnimationController _pulseController;

Timer? _engineTimer;
StreamSubscription<Position>? _gpsSubscription;
bool _gpsEnabled = false;

LatLng _currentPosition = const LatLng(
  37.4219983,
  -122.084,
);
  double _speed = 4.8;
  double _heading = 52;

  int _grid = 8;
  int _riskScore = 35;
  int _dangerZones = 4;
  int _sentinelLock = 61;
  int _trackingScore = 48;
  int _threatPings = 5;
  int _responseReadiness = 72;
  int _orbitLock = 68;
  int _orbitalNodes = 5;

  String _riskLevel = 'LOW';
  String _sentinelStatus = 'TRACKING';
  String _responseMode = 'NORMAL';
  String _responseAction = 'Vigilancia activa. Sin intervención.';
  bool _sentinelMode = true;

  final List<LatLng> _movementTrail = [];
  final List<LatLng> _dangerPoints = [];
  final List<LatLng> _sentinelPoints = [];
  final List<LatLng> _orbitPoints = [];

  final Map<String,LatLng> _familyDevices = {
  'Padre': const LatLng(39.9420, -75.2520),
  'Madre': const LatLng(39.9320, -75.2620),
  'Hijo': const LatLng(39.9390, -75.2480),
  'Ford Edge': const LatLng(39.9280, -75.2550),
};

  final Map<String, LatLng> _activeSosMarkers = {};

  String? _lastSosMessage;
  
  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _seedPoints();
    _initGps();
    _startEngine();

    _socketService.connect((data) {
      if (!mounted) return;

      if (data['type'] == 'LOCATION_UPDATE') {
       final String name = data['deviceId'] ?? 'Device';
       final double lat = (data['latitude'] as num).toDouble();
       final double lng = (data['longitude'] as num).toDouble();

       setState(() {
        _familyDevices[name] = LatLng(lat, lng);
      });
    }
  });
}
 
  @override
void dispose() {
  _gpsSubscription?.cancel();
  _engineTimer?.cancel();
  _pulseController.dispose();
  _socketService.dispose();
  super.dispose();
}

Future<void> _initGps() async {

  bool serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

  if (!serviceEnabled) {
    return;
  }

  LocationPermission permission =
    await Geolocator.checkPermission();

if (permission == LocationPermission.denied) {
  permission =
      await Geolocator.requestPermission();
}

if (permission == LocationPermission.deniedForever) {
  return;
}

Position position =
    await Geolocator.getCurrentPosition();

setState(() {
  _currentPosition = LatLng(
    position.latitude,
    position.longitude,
  );
});
}

  void _seedPoints() {
    _movementTrail.clear();
    _dangerPoints.clear();
    _sentinelPoints.clear();
    _orbitPoints.clear();

    for (int i = 0; i < 8; i++) {
      _movementTrail.add(
        LatLng(
          _currentPosition.latitude + (i * 0.00018),
          _currentPosition.longitude - (i * 0.00012),
        ),
      );
    }

    for (int i = 0; i < 7; i++) {
      _dangerPoints.add(_randomNearbyPoint(0.004));
    }

    for (int i = 0; i < 6; i++) {
      _sentinelPoints.add(_randomNearbyPoint(0.003));
    }

    _updateOrbitPoints();
  }

  LatLng _randomNearbyPoint(double spread) {
    return LatLng(
      _currentPosition.latitude + ((_random.nextDouble() - 0.5) * spread),
      _currentPosition.longitude + ((_random.nextDouble() - 0.5) * spread),
    );
  }

  void _updateOrbitPoints() {
    _orbitPoints.clear();

    final double phase = _pulseController.value * math.pi * 2;
    const double radiusLat = 0.00125;
    const double radiusLng = 0.00165;

    for (int i = 0; i < _orbitalNodes; i++) {
      final double angle = phase + ((math.pi * 2) / _orbitalNodes) * i;

      _orbitPoints.add(
        LatLng(
          _currentPosition.latitude + math.sin(angle) * radiusLat,
          _currentPosition.longitude + math.cos(angle) * radiusLng,
        ),
      );
    }
  }

  void _startEngine() {
    _engineTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final LatLng nextPosition = LatLng(
        _currentPosition.latitude + ((_random.nextDouble() - 0.5) * 0.00045),
        _currentPosition.longitude + ((_random.nextDouble() - 0.5) * 0.00045),
      );

      _movementTrail.add(nextPosition);
      if (_movementTrail.length > 18) _movementTrail.removeAt(0);

      if (_random.nextBool()) {
        _dangerPoints.add(_randomNearbyPoint(0.004));
        if (_dangerPoints.length > 8) _dangerPoints.removeAt(0);
      }

      if (_random.nextBool()) {
        _sentinelPoints.add(_randomNearbyPoint(0.003));
        if (_sentinelPoints.length > 7) _sentinelPoints.removeAt(0);
      }

      final int nextRisk = 18 + _random.nextInt(82);

      setState(() {
        _currentPosition = nextPosition;
        _speed = 1.2 + _random.nextDouble() * 7.5;
        _heading = _random.nextInt(360).toDouble();
        _grid = 6 + _random.nextInt(6);
        _riskScore = nextRisk;
        _dangerZones = 2 + _random.nextInt(6);
        _sentinelLock = 50 + _random.nextInt(50);
        _trackingScore = 40 + _random.nextInt(60);
        _threatPings = 2 + _random.nextInt(8);
        _responseReadiness = 55 + _random.nextInt(45);
        _orbitLock = 58 + _random.nextInt(42);
        _orbitalNodes = 4 + _random.nextInt(5);

        _updateRiskAndResponse();
        _updateOrbitPoints();
      });
    });
  }

  void _updateRiskAndResponse() {
    if (_riskScore >= 88) {
      _riskLevel = 'CRITICAL';
      _sentinelStatus = 'CRITICAL';
      _responseMode = 'CRITICAL';
      _responseAction = 'Pre-SOS preparado. Ruta segura priorizada.';
    } else if (_riskScore >= 72) {
      _riskLevel = 'HIGH';
      _sentinelStatus = 'DEFENSE';
      _responseMode = 'DEFENSE';
      _responseAction = 'Defensa autónoma activa. Amenaza monitoreada.';
    } else if (_riskScore >= 45) {
      _riskLevel = 'MEDIUM';
      _sentinelStatus = 'WATCH';
      _responseMode = 'WATCH';
      _responseAction = 'Vigilancia reforzada. Sentinel ajusta seguimiento.';
    } else {
      _riskLevel = 'LOW';
      _sentinelStatus = 'TRACKING';
      _responseMode = 'NORMAL';
      _responseAction = 'Vigilancia activa. Sin intervención.';
    }
  }

  Color get _mainColor {
    switch (_riskLevel) {
      case 'CRITICAL':
        return const Color(0xFFFF003C);
      case 'HIGH':
        return const Color(0xFFFF174F);
      case 'MEDIUM':
        return const Color(0xFFFFA726);
      default:
        return const Color(0xFF00F5D4);
    }
  }

  Color get _safeColor {
    if (_riskLevel == 'LOW') return const Color(0xFF00F5D4);
    if (_riskLevel == 'MEDIUM') return const Color(0xFFFFA726);
    return const Color(0xFFFF174F);
  }

  String get _safeMessage {
    switch (_riskLevel) {
      case 'CRITICAL':
        return 'Riesgo crítico. Sistema prepara respuesta prioritaria.';
      case 'HIGH':
        return 'Modo defensa activo. Amenazas detectadas.';
      case 'MEDIUM':
        return 'Vigilancia territorial reforzada.';
      default:
        return 'Corredor seguro activo. Ruta protegida estable.';
    }
  }

  IconData get _responseIcon {
    switch (_responseMode) {
      case 'CRITICAL':
        return Icons.emergency_rounded;
      case 'DEFENSE':
        return Icons.security_rounded;
      case 'WATCH':
        return Icons.visibility_rounded;
      default:
        return Icons.shield_rounded;
    }
  }

  void _centerMap() {
    _mapController.move(_currentPosition, 16.2);
  }

  void _toggleSentinel() {
    setState(() {
      _sentinelMode = !_sentinelMode;
    });
  }

  void _forceCritical() {
    setState(() {
      _riskScore = 92 + _random.nextInt(8);
      _updateRiskAndResponse();
    });
  }

  void _resetSafe() {
    setState(() {
      _riskScore = 18 + _random.nextInt(20);
      _updateRiskAndResponse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxHeight < 760;

          return AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              _updateOrbitPoints();

              return Stack(
                children: [
                  _buildMap(),
                  _buildDarkOverlay(),
                  _buildRadarGrid(),
                  _buildThreatLines(),
                  _buildOrbitOverlay(),
                  _buildScreenContent(compact),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition,
        initialZoom: 16.1,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.voltia.map',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: _movementTrail,
              strokeWidth: 4,
              color: _mainColor.withValues(alpha: 0.80),
            ),
            if (_sentinelMode)
              Polyline(
                points: _sentinelPoints,
                strokeWidth: 2,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            if (_orbitPoints.length >= 3)
              Polyline(
                points: [..._orbitPoints, _orbitPoints.first],
                strokeWidth: 2.5,
                color: _mainColor.withValues(alpha: 0.62),
              ),
            ..._orbitPoints.map(
              (point) => Polyline(
                points: [_currentPosition, point],
                strokeWidth: 1.2,
                color: _mainColor.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
        CircleLayer(
          circles: [
            CircleMarker(
              point: _currentPosition,
              radius: _riskLevel == 'CRITICAL' ? 120 : 90,
              color: _mainColor.withValues(alpha: 0.20),
              borderColor: _mainColor.withValues(alpha: 0.55),
              borderStrokeWidth: 1.2,
            ),
            CircleMarker(
              point: _currentPosition,
              radius: 150 + (_pulseController.value * 34),
              color: _mainColor.withValues(alpha: 0.05),
              borderColor: _mainColor.withValues(alpha: 0.22),
              borderStrokeWidth: 1.1,
            ),
            ..._dangerPoints.map(
              (point) => CircleMarker(
                point: point,
                radius: _riskLevel == 'LOW' ? 11 : 18,
                color: _mainColor.withValues(alpha: 0.32),
                borderColor: _mainColor.withValues(alpha: 0.80),
                borderStrokeWidth: 1,
              ),
            ),
            if (_sentinelMode)
              ..._sentinelPoints.map(
                (point) => CircleMarker(
                  point: point,
                  radius: 7,
                  color: Colors.white.withValues(alpha: 0.28),
                  borderColor: _mainColor.withValues(alpha: 0.75),
                  borderStrokeWidth: 1,
                ),
              ),
            ..._orbitPoints.map(
              (point) => CircleMarker(
                point: point,
                radius: 13 + (_pulseController.value * 7),
                color: _mainColor.withValues(alpha: 0.25),
                borderColor: _mainColor.withValues(alpha: 0.85),
                borderStrokeWidth: 1.4,
              ),
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _currentPosition,
              width: 90,
              height: 90,
              child: _buildMainMarker(),
            ),

            ..._familyDevices.entries.map(
              (entry) => Marker(
                point: entry.value,
                width: 56,
                height: 56,
                child: _buildFamilyDeviceMarker(entry.key),
              ),
            ),

            ..._orbitPoints.map(
              (point) => Marker(
                point: point,
                width: 30,
                height: 30,
                child: Icon(
                  Icons.satellite_alt_rounded,
                  color: _mainColor.withValues(alpha: 0.92),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

Widget _buildMainMarker() {
  final double scale = 1 + (_pulseController.value * 0.12);

  return Transform.scale(
    scale: scale,
    child: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.90),
        border: Border.all(
          color: _mainColor.withValues(alpha: 0.95),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _mainColor.withValues(alpha: 0.65),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(
        _responseIcon,
        color: _mainColor,
        size: 34,
      ),
    ),
  );
}

Widget _buildFamilyDeviceMarker(String name) {
  return Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.black.withValues(alpha: 0.85),
      border: Border.all(
        color: _mainColor.withValues(alpha: 0.95),
        width: 2,
      ),
    ),
    child: Center(
      child: Text(
        name.substring(0, 1),
        style: TextStyle(
          color: _mainColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    ),
  );
}

Widget _buildDarkOverlay() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.12),
              Colors.black.withValues(alpha: 0.03),
              Colors.black.withValues(alpha: 0.24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadarGrid() {
    return IgnorePointer(
      child: CustomPaint(
        painter: _RadarGridPainter(
          color: _mainColor.withValues(alpha: 0.16),
        ),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildThreatLines() {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ThreatLinePainter(
          color: _mainColor.withValues(
            alpha: _riskLevel == 'LOW' ? 0.15 : 0.36,
          ),
          seed: _riskScore,
        ),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildOrbitOverlay() {
    return IgnorePointer(
      child: CustomPaint(
        painter: _OrbitPainter(
          color: _mainColor,
          progress: _pulseController.value,
          nodes: _orbitalNodes,
        ),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildScreenContent(bool compact) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, compact ? 10 : 16, 14, 8),
        child: Column(
          children: [
            _buildHeaderCard(compact),
            SizedBox(height: compact ? 8 : 10),
            _buildCompassCard(compact),
            const Spacer(),
            _buildOrbitCard(compact),
            SizedBox(height: compact ? 8 : 10),
            _buildResponseCard(compact),
            SizedBox(height: compact ? 8 : 10),
            _buildBottomButtons(compact),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(bool compact) {
    return _glassPanel(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 18,
        compact ? 12 : 16,
        compact ? 14 : 18,
        compact ? 12 : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_rounded,
                color: _mainColor,
                size: compact ? 28 : 34,
              ),
              SizedBox(width: compact ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VOLTIA MAP',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 28 : 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 5,
                      ),
                    ),
                    SizedBox(height: compact ? 3 : 5),
                    Text(
                      'Live AI Threat Orbit Engine',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: compact ? 12 : 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.satellite_alt_rounded,
                color: _mainColor,
                size: compact ? 27 : 31,
              ),
            ],
          ),
          SizedBox(height: compact ? 14 : 18),
          Row(
            children: [
              Expanded(
                child: _metricItem(
                  'Velocidad',
                  '${_speed.toStringAsFixed(1)} km/h',
                  compact,
                ),
              ),
              Expanded(
                child: _metricItem(
                  'Rumbo',
                  '${_heading.toStringAsFixed(0)}°',
                  compact,
                ),
              ),
              Expanded(
                child: _metricItem(
                  'Orbit',
                  '$_orbitLock%',
                  compact,
                ),
              ),
              Expanded(
                child: _metricItem(
                  'Riesgo',
                  _riskLevel,
                  compact,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 13 : 16),
          Center(
            child: Text(
              'LAT ${_currentPosition.latitude.toStringAsFixed(4)}   LNG ${_currentPosition.longitude.toStringAsFixed(4)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _mainColor,
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.2,
              ),
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          Center(
            child: Text(
              'LIVE AI THREAT ORBIT ONLINE',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _mainColor,
                fontSize: compact ? 12 : 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompassCard(bool compact) {
    return _glassPanel(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 18,
        vertical: compact ? 10 : 13,
      ),
      child: Row(
        children: [
          Transform.rotate(
            angle: _heading * math.pi / 180,
            child: Icon(
              Icons.navigation_rounded,
              color: _mainColor,
              size: compact ? 25 : 30,
            ),
          ),
          SizedBox(width: compact ? 12 : 16),
          Expanded(
            child: Text(
              'TACTICAL COMPASS',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 16 : 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
              ),
            ),
          ),
          Text(
            '${_heading.toStringAsFixed(0)}°',
            style: TextStyle(
              color: _mainColor,
              fontSize: compact ? 17 : 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbitCard(bool compact) {
    return _glassPanel(
      padding: EdgeInsets.fromLTRB(14, compact ? 11 : 14, 14, compact ? 11 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LIVE AI THREAT ORBIT',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _mainColor,
              fontSize: compact ? 16 : 19,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.8,
            ),
          ),
          SizedBox(height: compact ? 7 : 9),
          Text(
            'Orbit Lock: $_orbitLock% | Nodes: $_orbitalNodes | Threat Pings: $_threatPings',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          SizedBox(height: compact ? 7 : 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _orbitLock / 100,
              minHeight: compact ? 5 : 7,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation<Color>(_mainColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseCard(bool compact) {
    return _glassPanel(
      padding: EdgeInsets.fromLTRB(14, compact ? 11 : 14, 14, compact ? 11 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AUTONOMOUS THREAT RESPONSE',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _mainColor,
              fontSize: compact ? 16 : 19,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.8,
            ),
          ),
          SizedBox(height: compact ? 7 : 9),
          Text(
            'Modo: $_responseMode | Readiness: $_responseReadiness% | Sentinel: $_sentinelStatus',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          SizedBox(height: compact ? 7 : 9),
          Text(
            _responseAction,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _mainColor,
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(bool compact) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: Icons.my_location_rounded,
            label: 'Centrar',
            onTap: _centerMap,
            compact: compact,
          ),
        ),
        SizedBox(width: compact ? 8 : 10),
        Expanded(
          child: _actionButton(
            icon: Icons.satellite_alt_rounded,
            label: 'Orbit',
            onTap: _seedPoints,
            compact: compact,
          ),
        ),
        SizedBox(width: compact ? 8 : 10),
        Expanded(
          child: _actionButton(
            icon: Icons.emergency_rounded,
            label: 'Critical',
            onTap: _forceCritical,
            compact: compact,
          ),
        ),
        SizedBox(width: compact ? 8 : 10),
        Expanded(
          child: _actionButton(
            icon: _sentinelMode ? Icons.radar_rounded : Icons.radar_outlined,
            label: 'Sentinel',
            onTap: _toggleSentinel,
            compact: compact,
          ),
        ),
      ],
    );
  }

  Widget _metricItem(String title, String value, bool compact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.74),
            fontSize: compact ? 10 : 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: compact ? 4 : 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _mainColor,
            fontSize: compact ? 12 : 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool compact,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: compact ? 60 : 68,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _mainColor.withValues(alpha: 0.70),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _mainColor.withValues(alpha: 0.20),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _mainColor, size: compact ? 22 : 25),
            SizedBox(height: compact ? 4 : 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: compact ? 9.5 : 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassPanel({
    required Widget child,
    required EdgeInsets padding,
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _mainColor.withValues(alpha: 0.62),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _mainColor.withValues(alpha: 0.20),
            blurRadius: 24,
            spreadRadius: 1.5,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RadarGridPainter extends CustomPainter {
  final Color color;

  _RadarGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 0.8;

    const double spacing = 42;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final Offset center = Offset(size.width / 2, size.height / 2);
    final Paint circlePaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    canvas.drawCircle(center, 80, circlePaint);
    canvas.drawCircle(center, 145, circlePaint);
    canvas.drawCircle(center, 215, circlePaint);
  }

  @override
  bool shouldRepaint(covariant _RadarGridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _ThreatLinePainter extends CustomPainter {
  final Color color;
  final int seed;

  _ThreatLinePainter({
    required this.color,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final math.Random random = math.Random(seed);
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final Offset center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 8; i++) {
      final Offset point = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );

      canvas.drawLine(center, point, paint);

      final Paint dotPaint = Paint()
        ..color = color.withValues(alpha: 0.75)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(point, 4 + random.nextDouble() * 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ThreatLinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.seed != seed;
  }
}

class _OrbitPainter extends CustomPainter {
  final Color color;
  final double progress;
  final int nodes;

  _OrbitPainter({
    required this.color,
    required this.progress,
    required this.nodes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Paint orbitPaint = Paint()
      ..color = color.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final Paint nodePaint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 110, orbitPaint);
    canvas.drawCircle(center, 172, orbitPaint);

    for (int i = 0; i < nodes; i++) {
      final double angle = (progress * math.pi * 2) + ((math.pi * 2) / nodes * i);
      final Offset node = Offset(
        center.dx + math.cos(angle) * 172,
        center.dy + math.sin(angle) * 172,
      );

      canvas.drawCircle(node, 4.5, nodePaint);
      canvas.drawLine(
        center,
        node,
        Paint()
          ..color = color.withValues(alpha: 0.12)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.progress != progress ||
        oldDelegate.nodes != nodes;
  }
}