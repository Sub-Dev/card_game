import 'package:flame/components.dart'; // Para o uso do PositionComponent e Vector2
import 'package:flutter/material.dart'; // Para o uso do Canvas, Paint, Colors, etc.

class StatusBackgroundComponent extends PositionComponent {
  final double padding = 10.0; // Espaçamento interno
  final double borderRadius = 15.0; // Raio das bordas arredondadas
  static const double screenMargin =
      5.0; // Espaçamento das bordas da tela (constante)

  StatusBackgroundComponent(Vector2 screenSize, Vector2 textPosition)
      : super(
          // Coloca o fundo com a mesma posição do texto
          position: Vector2(
              screenMargin,
              textPosition.y -
                  10), // Alinha na parte superior do texto com margem
          size: Vector2(
            screenSize.x -
                (screenMargin *
                    5), // Define a largura com espaçamento nas bordas
            100, // Aumenta a altura do fundo
          ),
        );

  @override
  void render(Canvas canvas) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          position.x, // A posição já inclui o padding no cálculo
          position.y,
          size.x,
          size.y),
      Radius.circular(borderRadius),
    );

    // Desenha um fundo semi-transparente com bordas arredondadas
    final paint = Paint()
      ..color = const Color.fromARGB(255, 70, 61, 61)
          .withOpacity(0.7) // Cor vermelha com 70% de transparência
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rect, paint);
  }
}
