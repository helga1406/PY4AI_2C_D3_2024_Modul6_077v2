import 'package:flutter/material.dart';

class DamagePainter extends CustomPainter {
  // Menerima koordinat yang selalu berubah dari Controller
  final double normalizedX;
  final double normalizedY;

  DamagePainter({required this.normalizedX, required this.normalizedY});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke; 
    
    // Ukuran kotak tetap, posisinya yang berubah
    double boxSize = size.width * 0.4; 
    
    // Konversi koordinat normalisasi ke posisi sebenarnya pada layar
    double finalX = normalizedX * size.width;
    double finalY = normalizedY * size.height;
    
    double left = finalX - (boxSize / 2);
    double top = finalY - (boxSize / 2);

    final rect = Rect.fromLTWH(left, top, boxSize, boxSize);

    // Menggambar Kotak dan Crosshair
    canvas.drawRect(rect, paint);
    canvas.drawLine(Offset(finalX - 10, finalY), Offset(finalX + 10, finalY), paint);
    canvas.drawLine(Offset(finalX, finalY - 10), Offset(finalX, finalY + 10), paint);

    // Label Pothole RDD-2022
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      backgroundColor: Colors.redAccent, 
    );

    const textSpan = TextSpan(
      text: " [D40] POTHOLE - 92% ", 
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset(left, top - 25));
  }

  @override
  bool shouldRepaint(covariant DamagePainter oldDelegate) {
    return oldDelegate.normalizedX != normalizedX || oldDelegate.normalizedY != normalizedY;
  }
}