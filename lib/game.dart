import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/events.dart';

class CardGame extends FlameGame with TapDetector {
  late TextComponent statusText;
  List<SpriteComponent> cardSprites = [];

  // Lista de imagens das cartas
  List<String> cards = [
    'card_0.png',
    'card_1.png',
    'card_2.png',
    'card_3.png',
  ];

  // Nomes correspondentes das cartas
  List<String> cardNames = [
    'Hydra',
    'Minotaur',
    'Qilin',
    'Dragon',
  ];

  int playerCardIndex = -1;
  int computerCardIndex = -1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

// Carregar as imagens das cartas
    final centerX = size.x / 2; // Centro horizontal da tela
    final cardWidth = 80; // Largura da carta
    final cardSpacing = 20; // Espaçamento entre as cartas

    for (int i = 0; i < cards.length; i++) {
      String path = cards[i];
      Sprite cardSprite = await loadSprite(path);

      // Calcula a posição de cada carta para centralizá-las
      double cardXPosition = centerX -
          ((cards.length - 1) * (cardWidth + cardSpacing) / 2) +
          i * (cardWidth + cardSpacing);

      SpriteComponent card = SpriteComponent(
        sprite: cardSprite,
        position: Vector2(cardXPosition, 200), // Posição vertical fixa
        size: Vector2(cardWidth.toDouble(), 120), // Tamanho da carta
      );
      cardSprites.add(card);
      add(card);
    }

    // Adicionar texto de status
    statusText = TextComponent(
      text: 'Toque em uma carta para jogar',
      position: Vector2(10, 10),
      textRenderer: TextPaint(
        style: TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
    add(statusText);
  }

  @override
  void onTapDown(TapDownInfo info) {
    // Lógica para detectar qual carta foi tocada
    for (int i = 0; i < cardSprites.length; i++) {
      if (cardSprites[i].containsPoint(info.eventPosition.global)) {
        playCard(i);
        break;
      }
    }
  }

  void playCard(int index) {
    playerCardIndex = index;
    computerCardIndex = Random().nextInt(cards.length);
    determineWinner();
    updateStatus();
  }

  void determineWinner() {
    if (playerCardIndex == computerCardIndex) {
      print("Empate!");
    } else if ((playerCardIndex + 1) % cards.length == computerCardIndex ||
        (playerCardIndex + 2) % cards.length == computerCardIndex) {
      print("Computador ganhou!");
    } else {
      print("Você ganhou!");
    }
  }

  void updateStatus() {
    String result;
    if (playerCardIndex == computerCardIndex) {
      result = "Empate!";
    } else if ((playerCardIndex + 1) % cards.length == computerCardIndex ||
        (playerCardIndex + 2) % cards.length == computerCardIndex) {
      result = "Computador ganhou!";
    } else {
      result = "Você ganhou!";
    }

    statusText.text =
        "Jogador: ${cardNames[playerCardIndex]} (Carta ${playerCardIndex + 1}), Computador: ${cardNames[computerCardIndex]} (Carta ${computerCardIndex + 1})\n$result";
  }

  @override
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Calcular a posição central da tela
    final screenSize = size; // Obtém o tamanho da tela do jogo
    final centerX = screenSize.x / 2; // Centro horizontal
    final centerY = screenSize.y / 2; // Centro vertical

    // Renderizar o texto de status no centro da tela
    statusText.position = Vector2(centerX - (statusText.width / 2), 10);

    // Renderizar as cartas
    if (playerCardIndex != -1) {
      // Renderizar a carta do jogador centralizada
      _renderCard(
          canvas,
          playerCardIndex,
          Offset(
              centerX - 180, centerY)); // Ajusta a posição da carta do jogador
    }
    if (computerCardIndex != -1) {
      // Renderizar a carta do computador ao lado da carta do jogador
      _renderCard(
          canvas,
          computerCardIndex,
          Offset(centerX + 50,
              centerY)); // Ajusta a posição da carta do computador
    }
  }

  void _renderCard(Canvas canvas, int index, Offset position) {
    // Desenhar a imagem da carta no canvas
    final image = images.fromCache(cards[index]);

    // Define o tamanho da carta
    final cardWidth = 150; // Largura desejada
    final cardHeight = 300; // Altura desejada

    // Define um retângulo com a posição e o tamanho desejados
    final destinationRect = Rect.fromLTWH(
        position.dx, // Já é double, não precisa converter
        position.dy, // Já é double, não precisa converter
        cardWidth.toDouble(),
        cardHeight.toDouble());

    // Desenha a imagem na área especificada
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      destinationRect,
      Paint(),
    );
  }
}

class CardGameWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final game = CardGame();

    return GameWidget(game: game);
  }
}
