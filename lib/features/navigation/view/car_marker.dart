import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/constants/colors.dart';

class CarMarker extends StatelessWidget {
  const CarMarker({super.key, required this.bearing});

  static const double size = 46;

  final double bearing;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: bearing * math.pi / 180,
      child: const CustomPaint(size: Size.square(size), painter: _CarPainter()),
    );
  }
}

class _CarPainter extends CustomPainter {
  const _CarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w / 2, h / 2), width: w * 0.46, height: h * 0.84),
      Radius.circular(w * 0.13),
    );

    canvas.drawRRect(
      body.shift(const Offset(0, 1.5)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRRect(body, Paint()..color = AppColors.white);
    canvas.drawRRect(
      body,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final glass = Paint()..color = AppColors.primary;
    final left = body.left + w * 0.05;
    final right = body.right - w * 0.05;
    final windshield = Path()
      ..moveTo(left, body.top + h * 0.26)
      ..quadraticBezierTo(w / 2, body.top + h * 0.15, right, body.top + h * 0.26)
      ..lineTo(right - w * 0.02, body.top + h * 0.36)
      ..lineTo(left + w * 0.02, body.top + h * 0.36)
      ..close();
    canvas.drawPath(windshield, glass);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left + w * 0.02, body.top + h * 0.40, right - w * 0.02, body.bottom - h * 0.20),
        Radius.circular(w * 0.05),
      ),
      Paint()..color = AppColors.primary.withValues(alpha: 0.85),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left + w * 0.03, body.bottom - h * 0.16, right - w * 0.03, body.bottom - h * 0.09),
        Radius.circular(w * 0.03),
      ),
      glass,
    );

    final lights = Paint()..color = AppColors.warning;
    canvas.drawCircle(Offset(left + w * 0.03, body.top + h * 0.05), w * 0.03, lights);
    canvas.drawCircle(Offset(right - w * 0.03, body.top + h * 0.05), w * 0.03, lights);
  }

  @override
  bool shouldRepaint(covariant _CarPainter oldDelegate) => false;
}
