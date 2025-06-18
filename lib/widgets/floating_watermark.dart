import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'dart:math' as math;

class FloatingWatermark extends StatefulWidget {
  final String text;
  final double opacity;
  final bool constrainToPlayer;

  const FloatingWatermark({
    super.key,
    required this.text,
    this.opacity = 0.35, // Increased transparency
    this.constrainToPlayer = true,
  });

  @override
  _FloatingWatermarkState createState() => _FloatingWatermarkState();
}

class _FloatingWatermarkState extends State<FloatingWatermark> {
  late Timer _timer;
  double _positionX = 0.1;
  double _positionY = 0.1;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _startMoving();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startMoving() {
    // Initial position
    _updatePosition();

    // Update position every few seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updatePosition();
    });
  }

  void _updatePosition() {
    setState(() {
      // Generate random positions within the container
      _positionX = 0.1 + _random.nextDouble() * 0.8;
      _positionY = 0.1 + _random.nextDouble() * 0.8;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If not constraining to player (e.g., full-screen mode), use full-screen size
    final size = widget.constrainToPlayer
        ? Size(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.width * (9 / 16), // Respect 16:9 aspect ratio
    )
        : MediaQuery.of(context).size;

    return IgnorePointer(
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Align(
          alignment: Alignment(_positionX * 2 - 1, _positionY * 2 - 1),
          child: Transform.rotate(
            angle: -15 * (math.pi / 180),
            child: Opacity(
              opacity: widget.opacity,
              child: Text(
                widget.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: Platform.isWindows ? 20 : 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto', // Explicitly set font to ensure consistency
                  decoration: TextDecoration.none, // Prevent any underlines
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}