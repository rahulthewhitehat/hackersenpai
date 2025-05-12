import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class FloatingWatermark extends StatefulWidget {
  final String text;
  final double opacity;

  const FloatingWatermark({
    super.key,
    required this.text,
    this.opacity = 0.2,
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
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _positionX = 0.1 + _random.nextDouble() * 0.8;
        _positionY = 0.1 + _random.nextDouble() * 0.8;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment(_positionX * 2 - 1, _positionY * 2 - 1),
        child: Transform.rotate(
          angle: -15 * (math.pi / 180),
          child: Opacity(
            opacity: widget.opacity,
            child: Text(
              widget.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    offset: Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}