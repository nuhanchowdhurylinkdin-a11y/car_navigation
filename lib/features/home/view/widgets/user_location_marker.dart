import 'package:flutter/material.dart';

class UserLocationMarker extends StatefulWidget {
  const UserLocationMarker({super.key});

  static const double size = 72;
  static const double dotSize = 22;
  static const Color color = Color(0xFF1E88E5);

  @override
  State<UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<UserLocationMarker>
    with SingleTickerProviderStateMixin {
  static const _rippleCount = 2;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        for (var i = 0; i < _rippleCount; i++)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = (_controller.value + i / _rippleCount) % 1.0;
              final diameter = UserLocationMarker.dotSize +
                  (UserLocationMarker.size - UserLocationMarker.dotSize) * t;
              return Container(
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: UserLocationMarker.color.withValues(alpha: 0.35 * (1 - t)),
                ),
              );
            },
          ),
        const _Dot(),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: UserLocationMarker.dotSize,
      height: UserLocationMarker.dotSize,
      decoration: BoxDecoration(
        color: UserLocationMarker.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
    );
  }
}
