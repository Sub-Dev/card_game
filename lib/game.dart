import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/events.dart';
import 'package:flame/sprite.dart';
import 'package:audioplayers/audioplayers.dart';

class CardGame extends FlameGame with TapDetector {
  late TextComponent statusText;
  late AudioPlayer audioPlayer;
  late AudioCache audioCache;
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

  // Propriedades de ataque e defesa
  List<int> cardAttack = [3, 4, 2, 5];
  List<int> cardDefense = [2, 3, 4, 1];

  // Vida separada para jogador e computador
  List<int> playerCardHealth = [10, 10, 10, 10];
  List<int> computerCardHealth = [10, 10, 10, 10];

  // Vida máxima das cartas
  final int maxHealth = 10;

  late SpriteAnimationComponent victoryAnimation;
  late SpriteAnimationComponent defeatAnimation;
  bool gameOver = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Inicializa o AudioPlayer e carrega os sons
    audioPlayer = AudioPlayer();
    audioCache = AudioCache();
    audioCache.loadAll(['victory_sound.mp3', 'defeat_sound.mp3']);
    // Carregar as imagens das cartas
    final centerX = size.x / 2;
    final cardWidth = 80;
    final cardSpacing = 20;

    for (int i = 0; i < cards.length; i++) {
      String path = cards[i];
      Sprite cardSprite = await loadSprite(path);

      double cardXPosition = centerX -
          ((cards.length - 1) * (cardWidth + cardSpacing) / 2) +
          i * (cardWidth + cardSpacing);

      SpriteComponent card = SpriteComponent(
        sprite: cardSprite,
        position: Vector2(cardXPosition, 200),
        size: Vector2(cardWidth.toDouble(), 120),
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

    // Carregar animações de vitória e derrota
    final victorySpriteSheet = await images.load('victory_animation.png');
    final defeatSpriteSheet = await images.load('defeat_animation.png');

    victoryAnimation = SpriteAnimationComponent(
      animation: SpriteAnimation.fromFrameData(
        victorySpriteSheet,
        SpriteAnimationData.sequenced(
          amount: 1, // Ajuste conforme o número de frames da sua animação
          stepTime: 1.0,
          textureSize:
              Vector2(512, 512), // Ajuste conforme o tamanho dos frames
        ),
      ),
      size: Vector2(512, 512), // Aumentando o tamanho da animação
      // Ajustando a posição para ficar mais à direita e mais para baixo
      position: Vector2(
          (size.x - 512) / 2 + 150, (size.y - 512) / 2 + 150), // Centralizando
      priority: 99999, // Aumentando a prioridade para ficar na frente
    );

    defeatAnimation = SpriteAnimationComponent(
      animation: SpriteAnimation.fromFrameData(
        defeatSpriteSheet,
        SpriteAnimationData.sequenced(
          amount: 1, // Ajuste conforme o número de frames da sua animação
          stepTime: 1.0,
          textureSize:
              Vector2(512, 512), // Ajuste conforme o tamanho dos frames
        ),
      ),
      size: Vector2(512, 512), // Aumentando o tamanho da animação
      // Ajustando a posição para ficar mais à direita e mais para baixo
      position: Vector2(
          (size.x - 512) / 2 + 150, (size.y - 512) / 2 + 150), // Centralizando
      priority: 99999, // Aumentando a prioridade para ficar na frente
    );

    victoryAnimation.removeOnFinish = true;
    defeatAnimation.removeOnFinish = true;
  }

  @override
  void onTapDown(TapDownInfo info) {
    if (!gameOver) {
      for (int i = 0; i < cardSprites.length; i++) {
        if (cardSprites[i].containsPoint(info.eventPosition.global)) {
          playCard(i);
          break;
        }
      }
    }
  }

  void playCard(int index) {
    if (playerCardHealth[index] <= 0) {
      updateStatus("Carta não pode ser usada. Escolha outra.");
      return;
    }

    playerCardIndex = index;
    do {
      computerCardIndex = Random().nextInt(cards.length);
    } while (computerCardHealth[computerCardIndex] <= 0);

    compareCombat();
    updateStatus();
  }

  void compareCombat() {
    int playerAttack = cardAttack[playerCardIndex];
    int computerDefense = cardDefense[computerCardIndex];
    int computerAttack = cardAttack[computerCardIndex];
    int playerDefense = cardDefense[playerCardIndex];

    // Jogador ataca o computador
    if (playerAttack >= computerDefense) {
      computerCardHealth[computerCardIndex] -=
          (playerAttack - computerDefense + 1);
    }

    // Computador ataca o jogador
    if (computerAttack >= playerDefense) {
      playerCardHealth[playerCardIndex] -= (computerAttack - playerDefense + 1);
    }

    // Garantir que a vida não fique negativa
    playerCardHealth[playerCardIndex] = playerCardHealth[playerCardIndex] < 0
        ? 0
        : playerCardHealth[playerCardIndex];
    computerCardHealth[computerCardIndex] =
        computerCardHealth[computerCardIndex] < 0
            ? 0
            : computerCardHealth[computerCardIndex];

    if (playerCardHealth[playerCardIndex] <= 0) {
      remove(cardSprites[playerCardIndex]);
    }
  }

  void updateStatus([String? customMessage]) {
    String result;
    if (customMessage != null) {
      result = customMessage;
    } else {
      result =
          "Jogador: ${cardNames[playerCardIndex]} (A:${cardAttack[playerCardIndex]}/D:${cardDefense[playerCardIndex]}/V:${playerCardHealth[playerCardIndex]}), "
          "Computador: ${cardNames[computerCardIndex]} (A:${cardAttack[computerCardIndex]}/D:${cardDefense[computerCardIndex]}/V:${computerCardHealth[computerCardIndex]})";
    }

    statusText.text =
        "$result\nVidas do Jogador: ${playerCardHealth.join(", ")}\nVidas do Computador: ${computerCardHealth.join(", ")}";
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Centralizar o texto de status
    final screenSize = size;
    final centerX = screenSize.x / 2;
    final centerY = screenSize.y / 2;
    statusText.position = Vector2(centerX - (statusText.width / 2), 10);

    // Verifica se o jogo acabou, se sim, não renderiza as cartas
    if (gameOver) {
      return; // Não renderiza cartas após o jogo terminar
    }

    // Renderiza a carta do jogador
    if (playerCardIndex != -1) {
      _renderCard(canvas, playerCardIndex, Offset(centerX - 180, centerY),
          playerCardHealth[playerCardIndex]);
    }

    // Renderiza a carta do computador
    if (computerCardIndex != -1) {
      _renderCard(canvas, computerCardIndex, Offset(centerX + 50, centerY),
          computerCardHealth[computerCardIndex]);
    }
  }

  void _renderCard(Canvas canvas, int index, Offset position, int health) {
    final image = images.fromCache(cards[index]);
    final cardWidth = 150.0;
    final cardHeight = 300.0;

    final destinationRect =
        Rect.fromLTWH(position.dx, position.dy, cardWidth, cardHeight);

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      destinationRect,
      Paint(),
    );

    // Desenhar a barra de vida
    final healthBarWidth = cardWidth - 20;
    final healthBarHeight = 10.0;
    final healthBarX = position.dx + 10;
    final healthBarY = position.dy + cardHeight + 10;

    // Fundo da barra de vida
    canvas.drawRect(
      Rect.fromLTWH(healthBarX, healthBarY, healthBarWidth, healthBarHeight),
      Paint()..color = Colors.grey,
    );

    // Barra de vida atual
    final currentHealthWidth = (health / maxHealth) * healthBarWidth;
    canvas.drawRect(
      Rect.fromLTWH(
          healthBarX, healthBarY, currentHealthWidth, healthBarHeight),
      Paint()..color = Colors.red,
    );
  }

  void removeAllExtraCards() {
    // Remove todas as cartas que não fazem parte das 4 cartas principais (player e computador)
    for (var card in cardSprites) {
      if (!children.contains(card)) {
        continue; // Se a carta já foi removida, pula
      }
      remove(card); // Remove a carta do jogo
    }
  }

  void checkGameOver() async {
    if (playerCardHealth.every((health) => health <= 0)) {
      gameOver = true;
      removeAllExtraCards(); // Remove as cartas extras
      add(defeatAnimation); // Mostra animação de derrota
      await audioPlayer.play(
          AssetSource('sounds/defeat_sound.mp3')); // Tocar o som de derrota
      updateStatus("Você perdeu! Todas as suas cartas foram derrotadas.");
    } else if (computerCardHealth.every((health) => health <= 0)) {
      gameOver = true;
      removeAllExtraCards(); // Remove as cartas extras
      add(victoryAnimation); // Mostra animação de vitória
      await audioPlayer.play(
          AssetSource('sounds/victory_sound.mp3')); // Tocar o som de vitória
      updateStatus(
          "Você venceu! Todas as cartas do computador foram derrotadas.");
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!gameOver) {
      checkGameOver();
    }
  }

  @override
  void handleTapDown(TapDownDetails details) {
    if (!gameOver) {
      for (int i = 0; i < cardSprites.length; i++) {
        if (cardSprites[i].containsPoint(
            Vector2(details.globalPosition.dx, details.globalPosition.dy))) {
          playCard(i);
          break;
        }
      }
    } else {
      // Remover animações de vitória e derrota ao clicar, se estiverem no jogo
      if (children.contains(victoryAnimation)) {
        remove(victoryAnimation);
      }
      if (children.contains(defeatAnimation)) {
        remove(defeatAnimation);
      }
      resetGame(); // Reinicia o jogo após remover as animações
    }
  }

  void resetGame() {
    // Para o som atual, se estiver tocando
    audioPlayer.stop();
    // Reinicia o estado do jogo
    gameOver = false;
    playerCardHealth = List.filled(4, maxHealth);
    computerCardHealth = List.filled(4, maxHealth);
    playerCardIndex = -1;
    computerCardIndex = -1;

    // Limpa as animações de vitória ou derrota, se estiverem presentes
    if (children.contains(victoryAnimation)) {
      remove(victoryAnimation);
    }
    if (children.contains(defeatAnimation)) {
      remove(defeatAnimation);
    }

    // Adiciona novamente as cartas ao jogo
    for (var card in cardSprites) {
      if (!children.contains(card)) {
        add(card); // Adiciona novamente as cartas removidas
      }
    }

    // Atualiza o status do jogo
    updateStatus("Jogo reiniciado. Toque em uma carta para jogar.");
  }
}

class CardGameWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final game = CardGame();
    return GameWidget(game: game);
  }
}
