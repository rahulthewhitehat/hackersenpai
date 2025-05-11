import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class FloatingWatermark extends StatefulWidget {
  final String text;
  final double opacity;

  const FloatingWatermark({
    Key? key,
    required this.text,
    this.opacity = 0.2,
  }) : super(key: key);

  @override
  _FloatingWatermarkState createState() => _FloatingWatermarkState();
}

class _FloatingWatermarkState extends State<FloatingWatermark> {
  late Timer _timer;
  Offset _position = const Offset(20, 20);
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
        // Generate a slightly different position each time
        final x = 20 + _random.nextInt(40) - 20;
        final y = 20 + _random.nextInt(40) - 20;
        _position = Offset(x.toDouble(), y.toDouble());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedPositioned(
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOut,
        left: _position.dx,
        top: _position.dy,
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-15 / 360),
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