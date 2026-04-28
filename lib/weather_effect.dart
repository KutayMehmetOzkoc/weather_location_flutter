import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

enum WeatherEffectType { none, rain, snow }

WeatherEffectType effectFromCode(int code) {
  if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82) || code >= 95) {
    return WeatherEffectType.rain;
  }
  if ((code >= 71 && code <= 77) || code == 85 || code == 86) {
    return WeatherEffectType.snow;
  }
  return WeatherEffectType.none;
}

class WeatherEffect extends StatefulWidget {
  final WeatherEffectType type;
  final Widget child;

  const WeatherEffect({super.key, required this.type, required this.child});

  @override
  State<WeatherEffect> createState() => _WeatherEffectState();
}

class _WeatherEffectState extends State<WeatherEffect>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<_Particle> _particles = [];
  final Random _rng = Random();
  Size _size = Size.zero;
  Duration _prev = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    if (_size == Size.zero) return;
    final dt = _prev == Duration.zero
        ? 0.016
        : (elapsed - _prev).inMicroseconds / 1e6;
    _prev = elapsed;

    if (_particles.isEmpty && widget.type != WeatherEffectType.none) {
      _spawnAll();
    }

    for (var i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      p.y += p.vy * dt;
      p.x += p.vx * dt;
      if (widget.type == WeatherEffectType.snow) {
        p.phase += p.phaseSpeed * dt;
        p.x += sin(p.phase) * 0.5;
      }
      if (p.y > _size.height + 30 ||
          p.x < -40 ||
          p.x > _size.width + 40) {
        _particles[i] = _spawn(reset: true);
      }
    }

    setState(() {});
  }

  void _spawnAll() {
    final n = widget.type == WeatherEffectType.rain ? 130 : 65;
    for (var i = 0; i < n; i++) {
      _particles.add(_spawn(reset: false));
    }
  }

  _Particle _spawn({required bool reset}) {
    if (widget.type == WeatherEffectType.rain) {
      return _Particle(
        x: _rng.nextDouble() * _size.width,
        y: reset ? -25.0 : _rng.nextDouble() * _size.height,
        vx: 55 + _rng.nextDouble() * 35,
        vy: 480 + _rng.nextDouble() * 280,
        size: 0.7 + _rng.nextDouble() * 0.8,
        alpha: 0.2 + _rng.nextDouble() * 0.35,
        length: 13 + _rng.nextDouble() * 17,
        phase: 0,
        phaseSpeed: 0,
      );
    } else {
      return _Particle(
        x: _rng.nextDouble() * _size.width,
        y: reset ? -10.0 : _rng.nextDouble() * _size.height,
        vx: (_rng.nextDouble() - 0.5) * 18,
        vy: 35 + _rng.nextDouble() * 55,
        size: 2.0 + _rng.nextDouble() * 3.8,
        alpha: 0.55 + _rng.nextDouble() * 0.45,
        length: 0,
        phase: _rng.nextDouble() * pi * 2,
        phaseSpeed: 1.2 + _rng.nextDouble() * 2.2,
      );
    }
  }

  @override
  void didUpdateWidget(WeatherEffect old) {
    super.didUpdateWidget(old);
    if (old.type != widget.type) {
      _particles.clear();
      _prev = Duration.zero;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == WeatherEffectType.none) return widget.child;

    return LayoutBuilder(builder: (context, constraints) {
      _size = Size(constraints.maxWidth, constraints.maxHeight);
      return Stack(children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _WeatherPainter(
                particles: List.unmodifiable(_particles),
                type: widget.type,
              ),
            ),
          ),
        ),
      ]);
    });
  }
}

class _Particle {
  double x, y, vx, vy, size, alpha, length, phase, phaseSpeed;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.alpha,
    required this.length,
    required this.phase,
    required this.phaseSpeed,
  });
}

class _WeatherPainter extends CustomPainter {
  final List<_Particle> particles;
  final WeatherEffectType type;

  _WeatherPainter({required this.particles, required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;
    for (final p in particles) {
      paint.color = Colors.white.withValues(alpha: p.alpha);
      if (type == WeatherEffectType.rain) {
        paint.strokeWidth = p.size;
        final angle = atan2(p.vy, p.vx);
        canvas.drawLine(
          Offset(p.x, p.y),
          Offset(p.x + cos(angle) * p.length, p.y + sin(angle) * p.length),
          paint,
        );
      } else {
        paint.style = PaintingStyle.fill;
        canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_WeatherPainter old) => true;
}
