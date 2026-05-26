import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  late final AnimationController _pulseController;
  Timer? _engineTimer;

  final math.Random _random = math.Random();

  LatLng _currentPosition = const LatLng(37.4219983, -122.084);
  double _speed = 4.8;
  double _heading = 52;
  int _grid = 8;
  int _defense = 44;
  int _dangerZones = 4;
  int _riskScore = 35;
  int _sentinelLock = 61;
  int _trackingScore = 48;
  int _threatPings = 5;

  String _riskLevel = 'LOW';
  String _sentinelStatus = 'TRACKING';
  bool _sentinelMode = true;

  final List<LatLng> _movementTrail = [];
  final List<LatLng> _dangerPoints = [];
  final List<LatLng> _sentinelPoints = [];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _seedPoints();
    _startEngine();
  }

  @override
  void dispose() {
    _engineTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _seedPoints() {
    _movementTrail.clear();
    _dangerPoints.clear();
    _sentinelPoints.clear();

    for (int i = 0; i < 8; i++) {
      _movementTrail.add(
        LatLng(
          _currentPosition.latitude + (i * 0.00018),
          _currentPosition.longitude - (i * 0.00012),
        ),
      );
    }

    for (int i = 0; i < 7; i++) {
      _dangerPoints.add(
        LatLng(
          _currentPosition.latitude + ((_random.nextDouble() - 0.5) * 0.004),
          _currentPosition.longitude + ((_random.nextDouble() - 0.5) * 0.004),
        ),
      );
    }

    for (int i = 0; i < 6; i++) {
      _sentinelPoints.add(
        LatLng(
          _currentPosition.latitude + ((_random.nextDouble() - 0.5) * 0.003),
          _currentPosition.longitude + ((_random.nextDouble() - 0.5) * 0.003),
        ),
      );
    }
  }

  void _startEngine() {
    _engineTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final latShift = (_random.nextDouble() - 0.5) * 0.00045;
      final lngShift = (_random.nextDouble() - 0.5) * 0.00045;

      final nextPosition = LatLng(
        _currentPosition.latitude + latShift,
        _currentPosition.longitude + lngShift,
      );

      _movementTrail.add(nextPosition);
      if (_movementTrail.length > 18) {
        _movementTrail.removeAt(0);
      }

      if (_random.nextBool()) {
        _dangerPoints.add(
          LatLng(
            _currentPosition.latitude + ((_random.nextDouble() - 0.5) * 0.004),
            _currentPosition.longitude + ((_random.nextDouble() - 0.5) * 0.004),
          ),
        );

        if (_dangerPoints.length > 8) {
          _dangerPoints.removeAt(0);
        }
      }

      if (_random.nextBool()) {
        _sentinelPoints.add(
          LatLng(
            _currentPosition.latitude + ((_random.nextDouble() - 0.5) * 0.003),
            _currentPosition.longitude + ((_random.nextDouble() - 0.5) * 0.003),
          ),
        );

        if (_sentinelPoints.length > 7) {
          _sentinelPoints.removeAt(0);
        }
      }

      setState(() {
        _currentPosition = nextPosition;
        _speed = 1.2 + _random.nextDouble() * 7.5;
        _heading = _random.nextInt(360).toDouble();
        _grid = 6 + _random.nextInt(6);
        _defense = 35 + _random.nextInt(65);
        _dangerZones = 2 + _random.nextInt(6);
        _riskScore = 18 + _random.nextInt(82);
        _sentinelLock = 50 + _random.nextInt(50);
        _trackingScore = 40 + _random.nextInt(60);
        _threatPings = 2 + _random.nextInt(8);

        if (_riskScore >= 72) {
          _riskLevel = 'HIGH';
          _sentinelStatus = 'DEFENSE';
        } else if (_riskScore >= 45) {
          _riskLevel = 'MEDIUM';
          _sentinelStatus = 'WATCH';
        } else {
          _riskLevel = 'LOW';
          _sentinelStatus = 'TRACKING';
        }
      });
    });
  }

  Color get _mainColor {
    switch (_riskLevel) {
      case 'HIGH':
        return const Color(0xFFFF174F);
      case 'MEDIUM':
        return const Color(0xFFFFA726);
      default:
        return const Color(0xFF00F5D4);
    }
  }

  Color get _softColor {
    switch (_riskLevel) {
      case 'HIGH':
        return const Color(0xFFFF174F).withValues(alpha: 0.28);
      case 'MEDIUM':
        return const Color(0xFFFFA726).withValues(alpha: 0.25);
      default:
        return const Color(0xFF00F5D4).withValues(alpha: 0.22);
    }
  }

  String get _safeMessage {
    switch (_riskLevel) {
      case 'HIGH':
        return 'Modo defensa activo. Amenazas detectadas.';
      case 'MEDIUM':
        return 'Vigilancia territorial reforzada.';
      default:
        return 'Corredor seguro activo. Ruta protegida estable.';
    }
  }

  IconData get _riskIcon {
    switch (_riskLevel) {
      case 'HIGH':
        return Icons.warning_rounded;
      case 'MEDIUM':
        return Icons.grid_4x4_rounded;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxHeight < 760;

          return Stack(
            children: [
              _buildMap(),
              _buildDarkOverlay(),
              _buildRadarGrid(),
              _buildThreatLines(),
              _buildScreenContent(compact),
            ],
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
            Polyline(
              points: _sentinelPoints,
              strokeWidth: 2,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ],
        ),
        CircleLayer(
          circles: [
            CircleMarker(
              point: _currentPosition,
              radius: 88,
              color: _softColor,
              borderColor: _mainColor.withValues(alpha: 0.55),
              borderStrokeWidth: 1.2,
            ),
            ..._dangerPoints.map(
              (point) => CircleMarker(
                point: point,
                radius: _riskLevel == 'HIGH' ? 18 : 13,
                color: _mainColor.withValues(alpha: 0.32),
                borderColor: _mainColor.withValues(alpha: 0.80),
                borderStrokeWidth: 1,
              ),
            ),
            ..._sentinelPoints.map(
              (point) => CircleMarker(
                point: point,
                radius: 7,
                color: Colors.white.withValues(alpha: 0.28),
                borderColor: _mainColor.withValues(alpha: 0.75),
                borderStrokeWidth: 1,
              ),
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _currentPosition,
              width: 86,
              height: 86,
              child: _buildMainMarker(),
            ),
            ..._dangerPoints.map(
              (point) => Marker(
                point: point,
                width: 26,
                height: 26,
                child: Icon(
                  Icons.circle,
                  color: _mainColor.withValues(alpha: 0.75),
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainMarker() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final double scale = 1 + (_pulseController.value * 0.10);

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
              Icons.shield_rounded,
              color: _mainColor,
              size: 34,
            ),
          ),
        );
      },
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
              Colors.black.withValues(alpha: 0.22),
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
          color: _mainColor.withValues(alpha: 0.18),
        ),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildThreatLines() {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ThreatLinePainter(
          color: _mainColor.withValues(alpha: _riskLevel == 'HIGH' ? 0.40 : 0.22),
          seed: _riskScore,
        ),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildScreenContent(bool compact) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          14,
          compact ? 10 : 16,
          14,
          compact ? 8 : 12,
        ),
        child: Column(
          children: [
            _buildHeaderCard(compact),
            SizedBox(height: compact ? 8 : 10),
            _buildCompassCard(compact),
            const Spacer(),
            _buildSentinelCard(compact),
            SizedBox(height: compact ? 8 : 10),
            _buildSafeCorridorCard(compact),
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
      borderColor: _mainColor,
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
                      'Sentinel AI Tracking Mode',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: compact ? 13 : 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                _sentinelMode ? Icons.visibility_rounded : Icons.visibility_off_rounded,
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
                  title: 'Velocidad',
                  value: '${_speed.toStringAsFixed(1)} km/h',
                  compact: compact,
                ),
              ),
              Expanded(
                child: _metricItem(
                  title: 'Rumbo',
                  value: '${_heading.toStringAsFixed(0)}°',
                  compact: compact,
                ),
              ),
              Expanded(
                child: _metricItem(
                  title: 'Grid',
                  value: '$_grid',
                  compact: compact,
                ),
              ),
              Expanded(
                child: _metricItem(
                  title: 'Riesgo',
                  value: _riskLevel,
                  compact: compact,
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
              'SENTINEL AI TRACKING ONLINE',
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
      borderColor: _mainColor,
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

  Widget _buildSentinelCard(bool compact) {
    return _glassPanel(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 18,
        compact ? 12 : 16,
        compact ? 14 : 18,
        compact ? 12 : 16,
      ),
      borderColor: _mainColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SENTINEL AI TRACKING',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _mainColor,
              fontSize: compact ? 18 : 21,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.6,
            ),
          ),
          SizedBox(height: compact ? 8 : 11),
          Text(
            'Estado: $_sentinelStatus | Lock: $_sentinelLock% | Tracking: $_trackingScore% | Pings: $_threatPings',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _sentinelLock / 100,
              minHeight: compact ? 6 : 8,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation<Color>(_mainColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafeCorridorCard(bool compact) {
    return _glassPanel(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 18,
        compact ? 12 : 16,
        compact ? 14 : 18,
        compact ? 12 : 16,
      ),
      borderColor: _mainColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SAFE CORRIDOR + AI HEAT',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _riskLevel == 'HIGH' ? const Color(0xFFFF174F) : const Color(0xFF00F5D4),
              fontSize: compact ? 18 : 21,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.4,
            ),
          ),
          SizedBox(height: compact ? 8 : 11),
          Text(
            'Danger Zones: $_dangerZones | Score: $_riskScore% | Estado: $_riskLevel',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            _safeMessage,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _mainColor,
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w900,
              height: 1.25,
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
            icon: Icons.warning_amber_rounded,
            label: 'Danger',
            onTap: () {
              setState(() {
                _riskScore = 75 + _random.nextInt(25);
                _riskLevel = 'HIGH';
                _sentinelStatus = 'DEFENSE';
              });
            },
            compact: compact,
          ),
        ),
        SizedBox(width: compact ? 8 : 10),
        Expanded(
          child: _actionButton(
            icon: Icons.timeline_rounded,
            label: 'Trail',
            onTap: _seedPoints,
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

  Widget _metricItem({
    required String title,
    required String value,
    required bool compact,
  }) {
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
            fontSize: compact ? 13 : 16,
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
        height: compact ? 64 : 72,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _mainColor.withValues(alpha: 0.70),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: _mainColor.withValues(alpha: 0.22),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: _mainColor,
              size: compact ? 24 : 27,
            ),
            SizedBox(height: compact ? 5 : 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: compact ? 10 : 12,
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
    required Color borderColor,
    required EdgeInsets padding,
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.62),
          width: 1.25,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.22),
            blurRadius: 28,
            spreadRadius: 2,
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
      ..strokeWidth = 1.6
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