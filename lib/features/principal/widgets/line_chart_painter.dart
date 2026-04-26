import 'dart:math' show min, max;
import 'package:flutter/material.dart';

Widget buildLineChart(
    List<Map<String, dynamic>> data, String key, Color color) {
  return SizedBox(
      height: 80,
      child: CustomPaint(
          painter: LineChartPainter(data, key, color), size: Size.infinite));
}

Widget buildMiniLineChart(
    List<Map<String, dynamic>> data, String key, Color color) {
  return SizedBox(
      height: 60,
      child: CustomPaint(
          painter: LineChartPainter(data, key, color), size: Size.infinite));
}

class LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final String key;
  final Color color;

  LineChartPainter(this.data, this.key, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final values = data.map((d) => (d[key] as num).toDouble()).toList();
    final minVal = values.reduce(min) - 2;
    final maxVal = values.reduce(max) + 2;
    final range = maxVal - minVal;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - ((values[i] - minVal) / range * size.height);
      points.add(Offset(x, y));
    }

    final fillPath = Path();
    fillPath.moveTo(points.first.dx, size.height);
    for (final p in points) fillPath.lineTo(p.dx, p.dy);
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final controlX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(
          controlX, prev.dy, controlX, curr.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final dotBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final p in points) {
      canvas.drawCircle(p, 5, dotPaint);
      canvas.drawCircle(p, 5, dotBorder);
    }
  }

  @override
  bool shouldRepaint(LineChartPainter old) => true;
}
