import 'package:flutter/material.dart';

/// Custom painter for rendering a control stick indicating head movement
/// Shows the current head position relative to control thresholds
class ControlStickPainter extends CustomPainter {
  /// Head roll angle (in radians)
  final double roll;
  /// Head pitch angle (in radians)
  final double pitch;
  /// Threshold for roll activation
  final double rollThreshold;
  /// Threshold for pitch activation
  final double pitchThreshold;
  ControlStickPainter({required this.roll, required this.pitch, this.rollThreshold = 0.4, this.pitchThreshold = 0.16});

  @override
  void paint(Canvas canvas, Size size) {
    // Create the stick paint with white color
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Calculate center position and radius of the control stick
    final center = Offset(size.width / 2, size.height / 2);
    final stickRadius = size.width * 0.3;
    Offset stickOffset;

    // Check if head movement exceeds threshold for activation
    if(roll.abs() > rollThreshold || pitch.abs() > pitchThreshold) {
      // Change stick color to gray when threshold is exceeded
      paint.color = Color(0xFF606060);
      // Scale stick offset based on threshold ratios for magnified response
      stickOffset = Offset(
        (roll/rollThreshold).clamp(-1, 1) * (size.width / 2 - stickRadius),
        (pitch/pitchThreshold).clamp(-1, 1) * (size.height / 2 - stickRadius),
      );
    } else {
      // Movements below threshold
      stickOffset = Offset(
      (roll).clamp(-1, 1) * (size.width / 2 - stickRadius),
      (pitch).clamp(-1, 1) * (size.height / 2 - stickRadius),
    );
    }

    // Create background circle paint
    final background = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;
    // Draw the background circle
    canvas.drawCircle(center, size.width/2, background);
    // Draw the stick circle at the calculated offset position
    canvas.drawCircle(center + stickOffset, stickRadius, paint);
  }

  @override
  bool shouldRepaint(covariant ControlStickPainter oldDelegate) {
    return oldDelegate.roll != roll || oldDelegate.pitch != pitch;
  }
}
