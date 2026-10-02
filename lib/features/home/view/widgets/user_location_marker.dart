import 'package:flutter/material.dart';

/// Blue "you are here" dot.
class UserLocationMarker extends StatelessWidget {
  const UserLocationMarker({super.key});

  static const double size = 22;
  static const Color color = Color(0xFF1E88E5);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
    );
  }
}
