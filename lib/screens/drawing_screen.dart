import 'package:flutter/material.dart';
import 'dart:convert';

class DrawingScreen extends StatefulWidget {
  final String? initialData;
  
  const DrawingScreen({super.key, this.initialData});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final List<DrawingPoint> _points = [];
  final List<List<DrawingPoint>> _strokes = [];
  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      try {
        _loadDrawing(widget.initialData!);
      } catch (e) {
        print('Error loading drawing: $e');
      }
    }
  }

  void _loadDrawing(String jsonData) {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      final pointsData = data['points'] as List<dynamic>;
      
      _points.clear();
      for (var pointData in pointsData) {
        if (pointData == null) {
          _points.add(DrawingPoint(offset: null, paint: Paint()));
        } else {
          final point = pointData as Map<String, dynamic>;
          _points.add(DrawingPoint(
            offset: Offset(point['x'] as double, point['y'] as double),
            paint: Paint()
              ..color = Color(point['color'] as int)
              ..strokeWidth = point['width'] as double
              ..strokeCap = StrokeCap.round
              ..isAntiAlias = true,
          ));
        }
      }
      
      // Rebuild strokes from points
      _strokes.clear();
      List<DrawingPoint> currentStroke = [];
      for (var point in _points) {
        if (point.offset == null) {
          if (currentStroke.isNotEmpty) {
            _strokes.add(List.from(currentStroke));
            currentStroke.clear();
          }
        } else {
          currentStroke.add(point);
        }
      }
      
      setState(() {});
    } catch (e) {
      print('Error parsing drawing data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Çizim', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.undo),
            onPressed: _undo,
            tooltip: 'Geri Al',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: _clear,
            tooltip: 'Temizle',
          ),
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _save,
            tooltip: 'Kaydet',
          ),
        ],
      ),
      body: Column(
        children: [
          // Color picker
          Container(
            height: 70,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Text('Renk: ', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(width: 8),
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Colors.black,
                      Colors.red,
                      Colors.blue,
                      Colors.green,
                      Colors.yellow,
                      Colors.orange,
                      Colors.purple,
                      Colors.pink,
                      Colors.brown,
                      Colors.grey,
                      Colors.teal,
                      Colors.indigo,
                    ].map((color) => GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: _selectedColor == color
                              ? Border.all(color: Colors.white, width: 3)
                              : Border.all(color: Colors.grey.shade300, width: 1),
                          boxShadow: _selectedColor == color ? [
                            BoxShadow(
                              color: color.withAlpha(100),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ] : [],
                        ),
                        child: _selectedColor == color 
                          ? Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Stroke width
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: Row(
              children: [
                Text('Kalınlık: ', style: TextStyle(fontWeight: FontWeight.w600)),
                Expanded(
                  child: Slider(
                    value: _strokeWidth,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: _strokeWidth.round().toString(),
                    activeColor: _selectedColor,
                    onChanged: (value) {
                      setState(() {
                        _strokeWidth = value;
                      });
                    },
                  ),
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    '${_strokeWidth.round()}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          Divider(height: 1),
          
          // Drawing canvas
          Expanded(
            child: Container(
              color: Colors.white,
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _points.add(
                      DrawingPoint(
                        offset: details.localPosition,
                        paint: Paint()
                          ..color = _selectedColor
                          ..strokeWidth = _strokeWidth
                          ..strokeCap = StrokeCap.round
                          ..isAntiAlias = true,
                      ),
                    );
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _points.add(
                      DrawingPoint(
                        offset: details.localPosition,
                        paint: Paint()
                          ..color = _selectedColor
                          ..strokeWidth = _strokeWidth
                          ..strokeCap = StrokeCap.round
                          ..isAntiAlias = true,
                      ),
                    );
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    _strokes.add(List.from(_points));
                    _points.add(DrawingPoint(offset: null, paint: Paint()));
                  });
                },
                child: CustomPaint(
                  painter: DrawingPainter(points: _points),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _undo() {
    setState(() {
      if (_strokes.isNotEmpty) {
        _strokes.removeLast();
        _points.clear();
        for (var stroke in _strokes) {
          _points.addAll(stroke);
        }
      }
    });
  }

  void _clear() {
    setState(() {
      _points.clear();
      _strokes.clear();
    });
  }

  void _save() {
    if (_points.isEmpty) {
      Navigator.pop(context);
      return;
    }
    
    // Serialize drawing points to JSON
    final pointsData = _points.map((point) {
      if (point.offset == null) {
        return null;
      }
      return {
        'x': point.offset!.dx,
        'y': point.offset!.dy,
        'color': point.paint.color.value,
        'width': point.paint.strokeWidth,
      };
    }).toList();
    
    final data = jsonEncode({
      'points': pointsData,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    Navigator.pop(context, data);
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class DrawingPoint {
  final Offset? offset;
  final Paint paint;

  DrawingPoint({required this.offset, required this.paint});
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint> points;

  DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].offset != null && points[i + 1].offset != null) {
        canvas.drawLine(
          points[i].offset!,
          points[i + 1].offset!,
          points[i].paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
