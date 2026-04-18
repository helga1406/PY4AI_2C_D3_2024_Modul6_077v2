import 'package:flutter/material.dart';

class DamagePainter extends CustomPainter {
  final double normalizedX;
  final double normalizedY;
  final String label;

  DamagePainter({
    required this.normalizedX,
    required this.normalizedY,
    required this.label,
  });

  @override
  void paint(Canvas canvas, Size size) {

    final isPothole = (label == "D40");
    
    final Color damageColor = isPothole 
        ? Colors.redAccent 
        : Colors.amberAccent;
        
    final String damageName = isPothole 
        ? "POTHOLE" 
        : "LONGITUDINAL CRACK";

    final paint = Paint()
      ..color = damageColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    // Kalkulasi Dimensi (Responsive)
    final boxSize = size.width * 0.4;
    final finalX = normalizedX * size.width;
    final finalY = normalizedY * size.height;

    // Hitung posisi sisi (Edge)
    final left = finalX - (boxSize / 2);
    final top = finalY - (boxSize / 2);

    final rect = Rect.fromLTWH(
      left, 
      top, 
      boxSize, 
      boxSize,
    );

    canvas.drawRect(rect, paint);
    
    canvas.drawLine(
      Offset(finalX - 10, finalY), 
      Offset(finalX + 10, finalY), 
      paint,
    );
    // Garis Vertikal
    canvas.drawLine(
      Offset(finalX, finalY - 10), 
      Offset(finalX, finalY + 10), 
      paint,
    );

    // Konfigurasi Label Teks
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
      backgroundColor: damageColor.withValues(alpha: 0.8),
      shadows: const [
        Shadow(
          blurRadius: 4.0, 
          color: Colors.black, 
          offset: Offset(1, 1),
        ),
      ],
    );

    final textSpan = TextSpan(
      text: " [$label] $damageName - 92% ",
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    
    textPainter.paint(
      canvas, 
      Offset(left, top - 20),
    );
  }

  @override
  bool shouldRepaint(covariant DamagePainter oldDelegate) {
    return oldDelegate.normalizedX != normalizedX ||
           oldDelegate.normalizedY != normalizedY ||
           oldDelegate.label != label;
  }
}