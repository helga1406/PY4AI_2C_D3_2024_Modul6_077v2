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

    final Color damageColor = (label == "D40") 
        ? Colors.redAccent 
        : Colors.amberAccent;
        
    final String damageName = (label == "D40") 
        ? "POTHOLE" 
        : "LONGITUDINAL CRACK";

    final paint = Paint()
      ..color = damageColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Kalkulasi Ukuran & Posisi
    double boxSize = size.width * 0.4;
    double finalX = normalizedX * size.width;
    double finalY = normalizedY * size.height;

    double left = finalX - (boxSize / 2);
    double top = finalY - (boxSize / 2);

    final rect = Rect.fromLTWH(
      left, 
      top, 
      boxSize, 
      boxSize,
    );

    // Gambar Kotak & Crosshair
    canvas.drawRect(rect, paint);
    
    canvas.drawLine(
      Offset(finalX - 10, finalY), 
      Offset(finalX + 10, finalY), 
      paint,
    );
    
    canvas.drawLine(
      Offset(finalX, finalY - 10), 
      Offset(finalX, finalY + 10), 
      paint,
    );

    // Konfigurasi Gaya Teks
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      backgroundColor: damageColor.withValues(alpha: 0.8),
      shadows: const [
        Shadow(
          blurRadius: 4.0, 
          color: Colors.black, 
          offset: Offset(2, 2),
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
      Offset(left, top - 25),
    );
  }

  @override
  bool shouldRepaint(covariant DamagePainter oldDelegate) {
    // Repaint jika ada perubahan koordinat atau label
    return oldDelegate.normalizedX != normalizedX ||
        oldDelegate.normalizedY != normalizedY ||
        oldDelegate.label != label;
  }
}