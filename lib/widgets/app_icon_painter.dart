import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class AppIconPainter extends CustomPainter {
  final bool isAdaptive;

  AppIconPainter({this.isAdaptive = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Fundo com gradiente (se não for adaptivo)
    if (!isAdaptive) {
      final backgroundGradient = ui.Gradient.radial(
        Offset(centerX, centerY),
        size.width * 0.6,
        [
          const Color(0xFF26A69A), // Teal 400
          const Color(0xFF00897B), // Teal 600
        ],
        [0.0, 1.0],
      );
      paint.shader = backgroundGradient;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(size.width * 0.22),
        ),
        paint,
      );
      paint.shader = null;
    }

    // Escala para o ícone interno
    final scale = size.width / 512;
    final potWidth = 180.0 * scale;
    final potHeight = 100.0 * scale;
    final potY = size.height * 0.60;

    // Vaso (trapézio arredondado)
    final potPath = Path();
    final potTopWidth = potWidth;
    final potBottomWidth = potWidth * 0.65;
    
    potPath.moveTo(centerX - potTopWidth / 2, potY);
    potPath.lineTo(centerX + potTopWidth / 2, potY);
    potPath.lineTo(centerX + potBottomWidth / 2, potY + potHeight);
    potPath.quadraticBezierTo(
      centerX,
      potY + potHeight + 10 * scale,
      centerX - potBottomWidth / 2,
      potY + potHeight,
    );
    potPath.close();

    // Sombra do vaso
    paint.color = const Color(0xFF5D4037).withValues(alpha: 0.3);
    canvas.drawPath(
      potPath.shift(Offset(4 * scale, 4 * scale)),
      paint,
    );

    // Vaso principal
    final potGradient = ui.Gradient.linear(
      Offset(centerX - potTopWidth / 2, potY),
      Offset(centerX + potTopWidth / 2, potY),
      [
        const Color(0xFF8D6E63), // Brown 300
        const Color(0xFF6D4C41), // Brown 500
        const Color(0xFF5D4037), // Brown 700
      ],
      [0.0, 0.5, 1.0],
    );
    paint.shader = potGradient;
    canvas.drawPath(potPath, paint);
    paint.shader = null;

    // Borda do vaso (mais clara)
    final rimPath = Path();
    rimPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, potY + 8 * scale),
        width: potTopWidth - 12 * scale,
        height: 20 * scale,
      ),
      Radius.circular(10 * scale),
    ));
    paint.color = const Color(0xFFA1887F); // Brown 200
    canvas.drawPath(rimPath, paint);

    // Terra
    paint.color = const Color(0xFF4E342E); // Brown 900
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, potY + 12 * scale),
        width: potTopWidth - 20 * scale,
        height: 24 * scale,
      ),
      paint,
    );

    // Caule
    final stemWidth = 16.0 * scale;
    final stemHeight = size.height * 0.45;
    paint.color = const Color(0xFF2E7D32); // Green 800
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, potY - stemHeight / 2 + 10 * scale),
          width: stemWidth,
          height: stemHeight,
        ),
        Radius.circular(stemWidth / 2),
      ),
      paint,
    );

    // Função auxiliar para desenhar folha estilizada
    void drawStylizedLeaf(Offset position, double width, double height, double angle, Color color, {bool detailed = true}) {
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(angle);

      final leafPath = Path();
      // Base da folha
      leafPath.moveTo(0, 0);
      
      // Lado esquerdo superior (curva suave)
      leafPath.cubicTo(
        width * 0.15, -height * 0.25,
        width * 0.25, -height * 0.45,
        width * 0.35, -height * 0.52,
      );
      
      // Ponta da folha (afilada)
      leafPath.cubicTo(
        width * 0.42, -height * 0.55,
        width * 0.48, -height * 0.54,
        width * 0.52, -height * 0.50,
      );
      
      // Lado direito superior
      leafPath.cubicTo(
        width * 0.62, -height * 0.42,
        width * 0.68, -height * 0.22,
        width * 0.70, 0,
      );
      
      // Lado direito inferior (curva para dentro)
      leafPath.cubicTo(
        width * 0.65, height * 0.15,
        width * 0.55, height * 0.25,
        width * 0.42, height * 0.28,
      );
      
      // Base inferior (retorna à origem)
      leafPath.cubicTo(
        width * 0.25, height * 0.22,
        width * 0.12, height * 0.12,
        0, 0,
      );
      leafPath.close();

      // Gradiente radial na folha para mais profundidade
      final leafGradient = ui.Gradient.radial(
        Offset(width * 0.25, -height * 0.15),
        width * 0.6,
        [
          color.withValues(alpha: 0.95),
          color,
          Color.lerp(color, Colors.black, 0.15)!,
        ],
        [0.0, 0.6, 1.0],
      );
      paint.shader = leafGradient;
      canvas.drawPath(leafPath, paint);
      paint.shader = null;

      if (detailed) {
        // Nervura central mais realista
        paint.color = Color.lerp(color, Colors.black, 0.3)!.withValues(alpha: 0.4);
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 2.5 * scale;
        paint.strokeCap = StrokeCap.round;
        
        final veinPath = Path();
        veinPath.moveTo(0, 0);
        veinPath.quadraticBezierTo(
          width * 0.2, -height * 0.15,
          width * 0.35, -height * 0.35,
        );
        veinPath.quadraticBezierTo(
          width * 0.42, -height * 0.48,
          width * 0.48, -height * 0.52,
        );
        canvas.drawPath(veinPath, paint);
        
        // Nervuras secundárias
        paint.strokeWidth = 1.2 * scale;
        paint.color = paint.color.withValues(alpha: 0.25);
        
        // Nervuras esquerdas
        canvas.drawLine(
          Offset(width * 0.1, -height * 0.08),
          Offset(width * 0.18, -height * 0.25),
          paint,
        );
        canvas.drawLine(
          Offset(width * 0.18, -height * 0.18),
          Offset(width * 0.25, -height * 0.38),
          paint,
        );
        
        // Nervuras direitas
        canvas.drawLine(
          Offset(width * 0.25, -height * 0.05),
          Offset(width * 0.45, -height * 0.15),
          paint,
        );
        canvas.drawLine(
          Offset(width * 0.35, -height * 0.12),
          Offset(width * 0.55, -height * 0.28),
          paint,
        );
        
        paint.style = PaintingStyle.fill;
      }

      canvas.restore();
    }

    // Folhas com distribuição mais orgânica
    final leafBaseSize = 75.0 * scale;
    final leafColor1 = const Color(0xFF66BB6A); // Green 400 - mais claro
    final leafColor2 = const Color(0xFF4CAF50); // Green 500 - médio
    final leafColor3 = const Color(0xFF388E3C); // Green 700 - mais escuro
    final leafColor4 = const Color(0xFF43A047); // Green 600 - intermediário

    // Camada de trás (folhas mais escuras para profundidade)
    drawStylizedLeaf(
      Offset(centerX - 35 * scale, potY - stemHeight * 0.25),
      leafBaseSize * 1.0,
      leafBaseSize * 1.3,
      -0.85,
      leafColor3,
      detailed: false,
    );
    drawStylizedLeaf(
      Offset(centerX + 35 * scale, potY - stemHeight * 0.28),
      leafBaseSize * 0.95,
      leafBaseSize * 1.25,
      0.8,
      leafColor3,
      detailed: false,
    );

    // Camada do meio inferior
    drawStylizedLeaf(
      Offset(centerX - 28 * scale, potY - stemHeight * 0.35),
      leafBaseSize * 1.1,
      leafBaseSize * 1.4,
      -0.65,
      leafColor4,
    );
    drawStylizedLeaf(
      Offset(centerX + 28 * scale, potY - stemHeight * 0.38),
      leafBaseSize * 1.05,
      leafBaseSize * 1.35,
      0.7,
      leafColor2,
    );

    // Camada do meio
    drawStylizedLeaf(
      Offset(centerX - 22 * scale, potY - stemHeight * 0.52),
      leafBaseSize * 1.15,
      leafBaseSize * 1.5,
      -0.5,
      leafColor1,
    );
    drawStylizedLeaf(
      Offset(centerX + 22 * scale, potY - stemHeight * 0.55),
      leafBaseSize * 1.1,
      leafBaseSize * 1.45,
      0.55,
      leafColor4,
    );

    // Camada superior
    drawStylizedLeaf(
      Offset(centerX - 18 * scale, potY - stemHeight * 0.70),
      leafBaseSize * 1.05,
      leafBaseSize * 1.35,
      -0.4,
      leafColor2,
    );
    drawStylizedLeaf(
      Offset(centerX + 18 * scale, potY - stemHeight * 0.72),
      leafBaseSize * 1.0,
      leafBaseSize * 1.3,
      0.45,
      leafColor1,
    );

    // Folhas do topo (3 folhas para criar volume)
    drawStylizedLeaf(
      Offset(centerX - 12 * scale, potY - stemHeight * 0.85),
      leafBaseSize * 0.9,
      leafBaseSize * 1.15,
      -0.25,
      leafColor4,
    );
    drawStylizedLeaf(
      Offset(centerX + 12 * scale, potY - stemHeight * 0.87),
      leafBaseSize * 0.85,
      leafBaseSize * 1.1,
      0.3,
      leafColor2,
    );
    drawStylizedLeaf(
      Offset(centerX, potY - stemHeight * 0.95),
      leafBaseSize * 0.95,
      leafBaseSize * 1.2,
      0.05,
      leafColor1,
    );

    // Pequenos brotos no topo (mais sutis)
    final budGradient = ui.Gradient.radial(
      Offset(centerX, potY - stemHeight * 0.98),
      6 * scale,
      [
        const Color(0xFF81C784),
        const Color(0xFF66BB6A),
      ],
    );
    paint.shader = budGradient;
    canvas.drawCircle(
      Offset(centerX - 6 * scale, potY - stemHeight * 0.98),
      3.5 * scale,
      paint,
    );
    canvas.drawCircle(
      Offset(centerX + 6 * scale, potY - stemHeight * 0.98),
      3.5 * scale,
      paint,
    );
    paint.shader = null;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Widget para preview do ícone
class AppIconPreview extends StatelessWidget {
  final double size;

  const AppIconPreview({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: AppIconPainter(),
      ),
    );
  }
}

// Widget para ícone adaptativo (Android)
class AdaptiveAppIcon extends StatelessWidget {
  final double size;

  const AdaptiveAppIcon({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: AppIconPainter(isAdaptive: true),
      ),
    );
  }
}
