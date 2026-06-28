import 'package:flutter/material.dart';

class VoltiaFloatingWindow extends StatefulWidget {
  final String id;
  final String title;
  final Widget child;
  final Offset initialOffset;
  final double initialWidth;
  final double initialHeight;
  final double minWidth;
  final double minHeight;
  final double maxWidth;
  final double maxHeight;
  final Color accentColor;
  final VoidCallback? onFocus;

  const VoltiaFloatingWindow({
    super.key,
    required this.id,
    required this.title,
    required this.child,
    required this.initialOffset,
    this.initialWidth = 340,
    this.initialHeight = 220,
    this.minWidth = 220,
    this.minHeight = 70,
    this.maxWidth = 1200,
    this.maxHeight = 760,
    this.accentColor = const Color(0xFF00E5FF),
    this.onFocus,
  });

  @override
  State<VoltiaFloatingWindow> createState() => _VoltiaFloatingWindowState();
}

class _VoltiaFloatingWindowState extends State<VoltiaFloatingWindow> {
  late Offset offset;
  late double width;
  late double height;

  bool minimized = false;
  bool maximized = false;

  Offset? previousOffset;
  double? previousWidth;
  double? previousHeight;

  @override
  void initState() {
    super.initState();
    offset = widget.initialOffset;
    width = widget.initialWidth;
    height = widget.initialHeight;
  }

  void _focus() {
    widget.onFocus?.call();
  }

  Offset _clampOffset(Size screen, Offset value) {
    final maxX = (screen.width - width).clamp(0.0, double.infinity);
    final maxY = (screen.height - height).clamp(0.0, double.infinity);

    return Offset(
      value.dx.clamp(0.0, maxX),
      value.dy.clamp(0.0, maxY),
    );
  }

  void _resize(double dw, double dh, Size screen) {
    setState(() {
      width = (width + dw).clamp(widget.minWidth, widget.maxWidth);
      height = (height + dh).clamp(widget.minHeight, widget.maxHeight);
      offset = _clampOffset(screen, offset);
    });
  }

  void _toggleMinimize() {
    setState(() {
      minimized = !minimized;
      if (minimized) {
        height = 48;
      } else {
        height = previousHeight ?? widget.initialHeight;
      }
    });
  }

  void _toggleMaximize(Size screen) {
    setState(() {
      if (!maximized) {
        previousOffset = offset;
        previousWidth = width;
        previousHeight = height;

        offset = const Offset(8, 8);
        width = screen.width - 16;
        height = screen.height - 16;
        maximized = true;
        minimized = false;
      } else {
        offset = previousOffset ?? widget.initialOffset;
        width = previousWidth ?? widget.initialWidth;
        height = previousHeight ?? widget.initialHeight;
        maximized = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      left: offset.dx,
      top: offset.dy,
      child: GestureDetector(
        onTap: _focus,
        onPanUpdate: maximized
            ? null
            : (details) {
                setState(() {
                  offset = _clampOffset(screen, offset + details.delta);
                });
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.55),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.24),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Column(
                  children: [
                    _Header(
                      title: widget.title,
                      accentColor: widget.accentColor,
                      minimized: minimized,
                      maximized: maximized,
                      onMinimize: _toggleMinimize,
                      onMaximize: () => _toggleMaximize(screen),
                      onZoomOut: () => _resize(-60, -30, screen),
                      onZoomIn: () => _resize(60, 30, screen),
                    ),
                    if (!minimized)
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: widget.child,
                        ),
                      ),
                  ],
                ),

                if (!minimized && !maximized)
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        _resize(details.delta.dx, details.delta.dy, screen);
                      },
                      child: Icon(
                        Icons.open_in_full,
                        color: widget.accentColor,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final Color accentColor;
  final bool minimized;
  final bool maximized;
  final VoidCallback onMinimize;
  final VoidCallback onMaximize;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;

  const _Header({
    required this.title,
    required this.accentColor,
    required this.minimized,
    required this.maximized,
    required this.onMinimize,
    required this.onMaximize,
    required this.onZoomOut,
    required this.onZoomIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.46),
        border: Border(
          bottom: BorderSide(
            color: accentColor.withValues(alpha: 0.25),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.radar, color: accentColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
          ),
          _Btn(icon: Icons.zoom_out, color: accentColor, onTap: onZoomOut),
          _Btn(icon: Icons.zoom_in, color: accentColor, onTap: onZoomIn),
          _Btn(
            icon: minimized ? Icons.add : Icons.remove,
            color: accentColor,
            onTap: onMinimize,
          ),
          _Btn(
            icon: maximized ? Icons.fullscreen_exit : Icons.fullscreen,
            color: accentColor,
            onTap: onMaximize,
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _Btn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }
}