import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Painter that draws a clean, premium curved area line chart
class LineChartPainter extends CustomPainter {
  final List<double> spots;
  LineChartPainter(this.spots);

  @override
  void paint(Canvas canvas, Size size) {
    if (spots.isEmpty) return;

    final paintLine = Paint()
      ..color = const Color(0xFF2E7D5F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final stepX = size.width / (spots.length - 1);
    final minVal = spots.reduce(math.min);
    final maxVal = spots.reduce(math.max);
    final valueRange = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    double getY(double val) {
      // Scale to fit within size height, with padding
      final normalized = (val - minVal) / valueRange;
      return size.height - (normalized * (size.height - 12) + 6);
    }

    path.moveTo(0, getY(spots[0]));

    for (int i = 0; i < spots.length - 1; i++) {
      final x1 = i * stepX;
      final y1 = getY(spots[i]);
      final x2 = (i + 1) * stepX;
      final y2 = getY(spots[i + 1]);

      // Control points for a smooth cubic curve
      final cx1 = x1 + stepX / 2.0;
      final cy1 = y1;
      final cx2 = x1 + stepX / 2.0;
      final cy2 = y2;

      path.cubicTo(cx1, cy1, cx2, cy2, x2, y2);
    }

    // Prepare path for gradient fill
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2E7D5F).withOpacity(0.25),
          const Color(0xFF2E7D5F).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) =>
      oldDelegate.spots != spots;
}

/// Painter that draws a vector layout of farm fields and live IoT sensors.
/// Supports a regular blueprint mode and a lush, thermal heat map overlay.
class SensorMapPainter extends CustomPainter {
  final bool thermalMode;
  final double averageMoisture;
  SensorMapPainter({required this.thermalMode, required this.averageMoisture});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw farm boundaries background
    final bgPaint = Paint()..color = const Color(0xFFEDF5F1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ),
      bgPaint,
    );

    // Draw field sectors block boundaries
    final boundaryPaint = Paint()
      ..color = const Color(0xFFD4E6DC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Outer boundary
    canvas.drawRect(Rect.fromLTWH(8, 8, size.width - 16, size.height - 16), boundaryPaint);

    // Draw sector grid lines representing agricultural partitions
    final sectorAxisY = size.height * 0.45;
    final sectorAxisX = size.width * 0.55;
    
    // Horizontal partition
    canvas.drawLine(Offset(8, sectorAxisY), Offset(size.width - 8, sectorAxisY), boundaryPaint);
    // Vertical partition
    canvas.drawLine(Offset(sectorAxisX, 8), Offset(sectorAxisX, size.height - 8), boundaryPaint);

    // Labels can be drawn in widgets, let's draw some rivers or canal line vectors
    final canalPaint = Paint()
      ..color = const Color(0xFFB9D7EA).withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final canalPath = Path()
      ..moveTo(8, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.75, size.width * 0.5, size.height * 0.85)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.95, size.width - 8, size.height * 0.78);
    canvas.drawPath(canalPath, canalPaint);

    // Live IoT Sensor coordinates and their moisture levels fluctuated from averageMoisture
    final sensors = [
      _SensorData(0.20, 0.25, (averageMoisture * 0.95).round().clamp(0, 100)), // Sector B-4 (Ideal)
      _SensorData(0.40, 0.35, (averageMoisture * 1.02).round().clamp(0, 100)), // Sector B-4 (Ideal)
      _SensorData(0.18, 0.70, (averageMoisture * 0.40).round().clamp(0, 100)), // Sector C-2 (Low Moisture - RED area)
      _SensorData(0.75, 0.20, (averageMoisture * 1.20).round().clamp(0, 100)), // Sector A (High Moisture)
      _SensorData(0.85, 0.30, (averageMoisture * 1.10).round().clamp(0, 100)), // Sector A (Optimal)
      _SensorData(0.50, 0.15, (averageMoisture * 0.85).round().clamp(0, 100)), // Center
      _SensorData(0.70, 0.60, (averageMoisture * 0.98).round().clamp(0, 100)), // Sector D (Ideal)
      _SensorData(0.35, 0.80, (averageMoisture * 1.05).round().clamp(0, 100)), // Near canal (Ideal)
    ];

    if (thermalMode) {
      // Draw smooth radial gradients centered at sensors to represent moisture thermal heat mapping
      for (var s in sensors) {
        final x = s.rx * size.width;
        final y = s.ry * size.height;
        final double radius = s.val < 30 ? 30.0 : (s.val > 60 ? 55.0 : 45.0);

        // Map values to colors: under 30 = Red/Yellow (dry thermal), optimal = green, high = blue
        Color centerColor;
        if (s.val < 30) {
          centerColor = const Color(0xFFEF5350).withOpacity(0.55); // Dry red
        } else if (s.val > 60) {
          centerColor = const Color(0xFF42A5F5).withOpacity(0.6); // Watered blue
        } else {
          centerColor = const Color(0xFF66BB6A).withOpacity(0.55); // Balanced green
        }

        final thermalPaint = Paint()
          ..shader = RadialGradient(
            colors: [centerColor, centerColor.withOpacity(0.0)],
          ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius));

        canvas.drawCircle(Offset(x, y), radius, thermalPaint);
      }
    }

    // Now draw actual sensor nodes & value badges
    for (var s in sensors) {
      final x = s.rx * size.width;
      final y = s.ry * size.height;

      // Color coding matches indicator values
      Color indicatorColor;
      if (s.val < 30) {
        indicatorColor = const Color(0xFFE53935); // Dry error red
      } else if (s.val > 60) {
        indicatorColor = const Color(0xFF1E88E5); // High moisture blue
      } else {
        indicatorColor = const Color(0xFF4CAF50); // Steady ideal green
      }

      // Draw subtle node shadow
      canvas.drawCircle(
        Offset(x, y + 1),
        8.0,
        Paint()..color = Colors.black12,
      );

      // Outer core white ring
      canvas.drawCircle(
        Offset(x, y),
        7.0,
        Paint()..color = Colors.white,
      );

      // Inner color sensor core
      canvas.drawCircle(
        Offset(x, y),
        4.5,
        Paint()..color = indicatorColor,
      );

      // If thermal mode, display small textual telemetry badges next to key nodes
      if (thermalMode) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${s.val}%',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Color(0xFF123C32),
              backgroundColor: Colors.white70,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(x + 8, y - 6));
      }
    }
  }

  @override
  bool shouldRepaint(covariant SensorMapPainter oldDelegate) =>
      oldDelegate.thermalMode != thermalMode || oldDelegate.averageMoisture != averageMoisture;
}

class _SensorData {
  final double rx;
  final double ry;
  final int val;
  _SensorData(this.rx, this.ry, this.val);
}
