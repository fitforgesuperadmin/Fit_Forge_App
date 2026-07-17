import 'dart:math';
import 'package:flutter/material.dart';

class Particle {
  double x;
  double y;
  double radius;
  double speedY;
  double speedX;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speedY,
    required this.speedX,
    required this.opacity,
  });
}

class AtmosphericBackground extends StatefulWidget {
  final Animation<double>? beamIntensity;

  const AtmosphericBackground({Key? key, this.beamIntensity}) : super(key: key);

  @override
  State<AtmosphericBackground> createState() => _AtmosphericBackgroundState();
}

class _AtmosphericBackgroundState extends State<AtmosphericBackground> with SingleTickerProviderStateMixin {
  late AnimationController _particleController;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initParticles();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        _updateParticles();
      })..repeat();
  }

  void _initParticles() {
    for (int i = 0; i < 20; i++) {
      _particles.add(
        Particle(
          x: _random.nextDouble(), // 0.0 to 1.0 (relative to beam width)
          y: _random.nextDouble(), // 0.0 to 1.0 (relative to beam height)
          radius: 1.5 + _random.nextDouble() * 1.5, // 1.5 to 3.0 dp
          speedY: 0.001 + _random.nextDouble() * 0.002, // upward drift
          speedX: -0.001 + _random.nextDouble() * 0.002, // slight horizontal drift
          opacity: 0.15 + _random.nextDouble() * 0.25, // 0.15 to 0.4
        ),
      );
    }
  }

  void _updateParticles() {
    for (var particle in _particles) {
      particle.y -= particle.speedY;
      particle.x += particle.speedX;

      // Reset particle if it drifts too high or out of bounds
      if (particle.y < 0) {
        particle.y = 1.0;
        particle.x = _random.nextDouble();
      }
      if (particle.x < 0 || particle.x > 1.0) {
        particle.x = _random.nextDouble();
        particle.y = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Iron Mesh Texture with Dark Overlay
        Container(
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('Images/app background mesh.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Color(0x99000000),
                BlendMode.darken,
              ),
            ),
          ),
        ),
        // Spotlight, Beam, and Particles Layer
        AnimatedBuilder(
          animation: Listenable.merge([_particleController, widget.beamIntensity]),
          builder: (context, child) {
            double intensity = widget.beamIntensity?.value ?? 1.0;
            return CustomPaint(
              size: Size.infinite,
              painter: SpotlightBackgroundPainter(
                particles: _particles,
                beamIntensity: intensity,
              ),
            );
          },
        ),
      ],
    );
  }
}

class SpotlightBackgroundPainter extends CustomPainter {
  final List<Particle> particles;
  final double beamIntensity;

  SpotlightBackgroundPainter({
    required this.particles,
    required this.beamIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Spotlight source positioning
    final sourceCenter = Offset(size.width / 2, 70.0);
    
    // Ambient Glow around source
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.fromRGBO(255, 255, 255, 0.35 * beamIntensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: sourceCenter, radius: 50.0 * (beamIntensity > 1.0 ? 1.2 : 1.0)));
    canvas.drawCircle(sourceCenter, 50.0 * (beamIntensity > 1.0 ? 1.2 : 1.0), glowPaint);

    // Glowing Emitter (the fixture itself)
    final emitterPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFE0E0E0),
        ],
      ).createShader(Rect.fromCircle(center: sourceCenter, radius: 6.0));
    canvas.drawCircle(sourceCenter, 6.0, emitterPaint);

    // Light Beam Cone
    final beamHeight = size.height * 0.6;
    // Base width: 70% of screen width normally. Wider if intensity > 1.0.
    final beamWidth = size.width * 0.7 * (beamIntensity > 1.0 ? 1.1 : 1.0);
    
    final Path beamPath = Path();
    beamPath.moveTo(sourceCenter.dx, sourceCenter.dy);
    beamPath.lineTo(size.width / 2 - beamWidth / 2, sourceCenter.dy + beamHeight);
    beamPath.lineTo(size.width / 2 + beamWidth / 2, sourceCenter.dy + beamHeight);
    beamPath.close();

    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.fromRGBO(255, 255, 255, 0.18 * beamIntensity).withOpacity((0.18 * beamIntensity).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, sourceCenter.dy, size.width, beamHeight))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20.0);
    
    canvas.drawPath(beamPath, beamPaint);

    // Draw Particles within the beam
    final particlePaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);
    
    for (var p in particles) {
      // Calculate actual X and Y inside the beam
      double py = sourceCenter.dy + (beamHeight * p.y);
      // Width of the beam at this specific Y level
      double currentBeamWidth = (p.y) * beamWidth;
      // Actual X
      double px = (size.width / 2) - (currentBeamWidth / 2) + (currentBeamWidth * p.x);
      
      // Calculate distance from center to fade edges softly
      double distanceFromCenter = (p.x - 0.5).abs() * 2.0; // 0.0 at center, 1.0 at edges
      double edgeFade = 1.0 - distanceFromCenter;
      if (edgeFade < 0) edgeFade = 0;

      // Bottom fade so they don't pop out abruptly
      double bottomFade = p.y < 0.9 ? 1.0 : (1.0 - p.y) * 10.0;
      // Top fade
      double topFade = p.y > 0.1 ? 1.0 : p.y * 10.0;
      
      double finalOpacity = p.opacity * edgeFade * bottomFade * topFade * beamIntensity;
      
      if (finalOpacity > 0.01) {
        particlePaint.color = Color.fromRGBO(255, 255, 255, finalOpacity.clamp(0.0, 1.0));
        canvas.drawCircle(Offset(px, py), p.radius, particlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SpotlightBackgroundPainter oldDelegate) {
    return true; // We want to repaint every tick
  }
}
