import 'package:flutter/material.dart';

class DamagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Gambar kotak merah di tengah layar
    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke; 

    double boxSize = size.width * 0.5; 
    
    double finalX = size.width / 2;
    double finalY = size.height / 2;
    
    double left = finalX - (boxSize / 2);
    double top = finalY - (boxSize / 2);

    final rect = Rect.fromLTWH(left, top, boxSize, boxSize);

    canvas.drawRect(rect, paint);

    canvas.drawLine(Offset(finalX - 15, finalY), Offset(finalX + 15, finalY), paint);
    canvas.drawLine(Offset(finalX, finalY - 15), Offset(finalX, finalY + 15), paint);

    // Tambahkan teks di atas kotak
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      backgroundColor: Colors.black54, 
    );

    const textSpan = TextSpan(
      text: " Searching for Road Damage... ", 
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
    return false;
  }
}