import 'package:flutter/material.dart';
import 'dart:convert';

class DrawingPreview extends StatelessWidget {
  final String drawingData;
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const DrawingPreview({
    super.key,
    required this.drawingData,
    this.width = 120,
    this.height = 120,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    List<DrawingPoint> points = [];
    
    try {
      final data = jsonDecode(drawingData) as Map<String, dynamic>;
      final pointsData = data['points'] as List<dynamic>;
      
      for (var pointData in pointsData) {
        if (pointData == null) {
          points.add(DrawingPoint(offset: null, paint: Paint()));
        } else {
          final point = pointData as Map<String, dynamic>;
          points.add(DrawingPoint(
            offset: Offset(point['x'] as double, point['y'] as double),
            paint: Paint()
              ..color = Color(point['color'] as int)
              ..strokeWidth = point['width'] as double
              ..strokeCap = StrokeCap.round
              ..isAntiAlias = true,
          ));
        }
      }
    } catch (e) {
      // If parsing fails, show empty preview
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
        child: points.isEmpty
            ? Center(
                child: Icon(Icons.draw, color: Colors.grey[400], size: 32),
              )
            : CustomPaint(
                painter: _DrawingPreviewPainter(points: points),
                size: Size(width, height),
              ),
      ),
    );
  }
}

class DrawingPoint {
  final Offset? offset;
  final Paint paint;

  DrawingPoint({required this.offset, required this.paint});
}

class _DrawingPreviewPainter extends CustomPainter {
  final List<DrawingPoint> points;

  _DrawingPreviewPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Calculate bounds of the drawing
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (var point in points) {
      if (point.offset != null) {
        minX = minX < point.offset!.dx ? minX : point.offset!.dx;
        minY = minY < point.offset!.dy ? minY : point.offset!.dy;
        maxX = maxX > point.offset!.dx ? maxX : point.offset!.dx;
        maxY = maxY > point.offset!.dy ? maxY : point.offset!.dy;
      }
    }

    if (minX == double.infinity) return;

    // Calculate scale to fit the drawing in the preview
    final drawingWidth = maxX - minX;
    final drawingHeight = maxY - minY;
    
    if (drawingWidth == 0 || drawingHeight == 0) return;

    final scaleX = (size.width * 0.9) / drawingWidth;
    final scaleY = (size.height * 0.9) / drawingHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    // Center the drawing
    final offsetX = (size.width - drawingWidth * scale) / 2 - minX * scale;
    final offsetY = (size.height - drawingHeight * scale) / 2 - minY * scale;

    // Draw the scaled and centered drawing
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].offset != null && points[i + 1].offset != null) {
        final p1 = Offset(
          points[i].offset!.dx * scale + offsetX,
          points[i].offset!.dy * scale + offsetY,
        );
        final p2 = Offset(
          points[i + 1].offset!.dx * scale + offsetX,
          points[i + 1].offset!.dy * scale + offsetY,
        );
        
        // Scale stroke width too
        final scaledPaint = Paint()
          ..color = points[i].paint.color
          ..strokeWidth = points[i].paint.strokeWidth * scale
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true;
        
        canvas.drawLine(p1, p2, scaledPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_DrawingPreviewPainter oldDelegate) => true;
}
