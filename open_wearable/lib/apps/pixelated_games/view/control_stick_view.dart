import 'package:flutter/material.dart';

class ControlStickPainter extends CustomPainter {
  final double roll;
  final double pitch;
  final double rollThreshold;
  final double pitchThreshold;
  ControlStickPainter({required this.roll, required this.pitch, this.rollThreshold = 0.4, this.pitchThreshold = 0.16});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final stickRadius = size.width * 0.3;
    Offset stickOffset;

    if(roll.abs() > rollThreshold || pitch.abs() > pitchThreshold) {
      paint.color = Color(0xFF606060);
      stickOffset = Offset(
        (roll/rollThreshold).clamp(-1, 1) * (size.width / 2 - stickRadius),
        (pitch/pitchThreshold).clamp(-1, 1) * (size.height / 2 - stickRadius),
      );
    } else {
      stickOffset = Offset(
      (roll).clamp(-1, 1) * (size.width / 2 - stickRadius),
      (pitch).clamp(-1, 1) * (size.height / 2 - stickRadius),
    );
    }

    final background = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width/2, background);
    canvas.drawCircle(center + stickOffset, stickRadius, paint);
  }

  @override
  bool shouldRepaint(covariant ControlStickPainter oldDelegate) {
    return oldDelegate.roll != roll || oldDelegate.pitch != pitch;
  }
}
