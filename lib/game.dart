import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/events.dart';
import 'package:flame/sprite.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'status_background_component.dart';

class CardGame extends FlameGame with TapDetector {
  late TextComponent statusText;
  late AudioPlayer audioPlayer;
  late AudioCache audioCache;

  final bool isMuted;
  final String backgroundImage;

  int playerLifeLost = 0;
  int computerLifeLost = 0;

  CardGame({required this.isMuted, required this.backgroundImage});
  late SpriteAnimationComponent attackAnimation;

  List<SpriteComponent> cardSprites = [];

  List<String> cards = [
    'card_0.png',
    'card_1.png',
    'card_2.png',
    'card_3.png',
  ];

  List<String> cardNames = [
    'Hydra',
    'Minotaur',
    'Qilin',
    'Dragon',
  ];

  int playerCardIndex = -1;
  int computerCardIndex = -1;

  List<int> cardAttack = [3, 4, 2, 5];
  List<int> cardDefense = [2, 3, 4, 1];

  List<int> playerCardHealth = [10, 10, 10, 10];
  List<int> computerCardHealth = [10, 10, 10, 10];

  final int maxHealth = 10;

  late SpriteAnimationComponent victoryAnimation;
  late SpriteAnimationComponent defeatAnimation;
  bool gameOver = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final backgroundSprite = await loadSprite(backgroundImage);

    final background = SpriteComponent(
      sprite: backgroundSprite,
      size: size,
      position: Vector2.zero(),
    );
    add(background);

    audioPlayer = AudioPlayer();
    audioCache = AudioCache();
    audioCache.loadAll([
      'sounds/victory_sound.mp3',
      'sounds/defeat_sound.mp3',
      'sounds/attack_sound.mp3'
    ]);

    final centerX = size.x / 2.1;
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

    final attackSpriteSheet = await images.load('attack_image.png');
    attackAnimation = SpriteAnimationComponent(
      animation: SpriteAnimation.fromFrameData(
        attackSpriteSheet,
        SpriteAnimationData.variable(
          stepTimes: [0.08, 0.08, 0.08, 0.08, 0.08],
          textureSize: Vector2(1500, 1400),
          amount: 5,
        ),
      ),
      size: Vector2(220, 200),
      position: Vector2(0, 0),
      priority: 999,
    );

    attackAnimation.removeOnFinish = true;

    statusText = TextComponent(
      text: 'Toque em uma carta para jogar',
      position: Vector2(10, 10),
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(2.0, 2.0),
              blurRadius: 3.0,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
    final screenSize = size;

    final textPosition = statusText.position;

    final statusBackground =
        StatusBackgroundComponent(screenSize, textPosition);
    add(statusBackground);

    add(statusText);

    final victorySpriteSheet = await images.load('victory_animation.png');
    final defeatSpriteSheet = await images.load('defeat_animation.png');

    victoryAnimation = SpriteAnimationComponent(
      animation: SpriteAnimation.fromFrameData(
        victorySpriteSheet,
        SpriteAnimationData.sequenced(
          amount: 1,
          stepTime: 1.0,
          textureSize: Vector2(512, 512),
        ),
      ),
      size: Vector2(512, 512),
      position: Vector2((size.x - 512) / 2 + 150, (size.y - 512) / 2 + 150),
      priority: 99999,
    );

    defeatAnimation = SpriteAnimationComponent(
      animation: SpriteAnimation.fromFrameData(
        defeatSpriteSheet,
        SpriteAnimationData.sequenced(
          amount: 1,
          stepTime: 1.0,
          textureSize: Vector2(512, 512),
        ),
      ),
      size: Vector2(512, 512),
      position: Vector2((size.x - 512) / 2 + 150, (size.y - 512) / 2 + 150),
      priority: 99999,
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

  bool isCriticalHit() {
    Random random = Random();
    return random.nextDouble() < 0.2;
  }

  int calculateDamage(int attack, int defense, bool criticalHit) {
    if (criticalHit) {
      return attack * 2;
    } else {
      return attack >= defense ? attack - defense : 0;
    }
  }

  void compareCombat() {
    int playerAttack = cardAttack[playerCardIndex];
    int computerDefense = cardDefense[computerCardIndex];
    int computerAttack = cardAttack[computerCardIndex];
    int playerDefense = cardDefense[playerCardIndex];

    bool playerCriticalHit = isCriticalHit();
    int playerDamage =
        calculateDamage(playerAttack, computerDefense, playerCriticalHit);

    if (playerDamage > 0) {
      computerCardHealth[computerCardIndex] -= playerDamage;
      computerLifeLost += playerDamage;

      final centerX = size.x / 2;
      final centerY = size.y / 2;
      Vector2 computerCardPosition = Vector2(centerX + 50, centerY);

      attackAnimation.position = computerCardPosition;
      attackAnimation.priority = 1000;

      add(attackAnimation);
      _showLifeLostAnimation(playerDamage.toString(), computerCardPosition,
          isCritical: playerCriticalHit);

      if (!isMuted) {
        audioPlayer
            .play(AssetSource('sounds/attack_sound.mp3'))
            .catchError((error) {
          print('Erro ao tocar o som: $error');
        });
      }

      Future.delayed(Duration(seconds: 1), () {
        if (children.contains(attackAnimation)) {
          remove(attackAnimation);
        }
      });
    }

    bool computerCriticalHit = isCriticalHit();
    int computerDamage =
        calculateDamage(computerAttack, playerDefense, computerCriticalHit);

    if (computerDamage > 0) {
      playerCardHealth[playerCardIndex] -= computerDamage;
      playerLifeLost += computerDamage;

      final centerX = size.x / 2;
      final centerY = size.y / 2;
      Vector2 playerCardPosition = Vector2(centerX - 180, centerY);

      attackAnimation.position = playerCardPosition;
      attackAnimation.priority = 1000;

      add(attackAnimation);
      _showLifeLostAnimation(computerDamage.toString(), playerCardPosition,
          isCritical: computerCriticalHit);

      if (!isMuted) {
        audioPlayer
            .play(AssetSource('sounds/attack_sound.mp3'))
            .catchError((error) {
          print('Erro ao tocar o som: $error');
        });
      }

      Future.delayed(Duration(seconds: 1), () {
        if (children.contains(attackAnimation)) {
          remove(attackAnimation);
        }
      });
    }

    playerCardHealth[playerCardIndex] = playerCardHealth[playerCardIndex] < 0
        ? 0
        : playerCardHealth[playerCardIndex];
    computerCardHealth[computerCardIndex] =
        computerCardHealth[computerCardIndex] < 0
            ? 0
            : computerCardHealth[computerCardIndex];

    if (playerCardHealth[playerCardIndex] <= 0) {
      if (children.contains(cardSprites[playerCardIndex])) {
        remove(cardSprites[playerCardIndex]);
      }
    }
  }

  void _showLifeLostAnimation(String damage, Vector2 position,
      {bool isCritical = false}) {
    final circle = CircleComponent(
      radius: 40,
      position: position.clone(),
      paint: Paint()
        ..color = isCritical
            ? Colors.orange.withOpacity(0.9)
            : Colors.black.withOpacity(0.8),
      priority: 1000,
    );

    final lifeLostText = TextComponent(
      text: isCritical ? 'CRITICAL! -$damage' : '-$damage',
      position: position.clone(),
      textRenderer: TextPaint(
        style: TextStyle(
          color: isCritical ? Colors.yellow : Colors.red,
          fontSize: isCritical ? 25 : 30,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(1.0, 1.0),
              blurRadius: isCritical ? 5.0 : 3.0,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );

    lifeLostText.priority = 1001;

    add(circle);
    add(lifeLostText);

    Future.delayed(Duration.zero, () {
      circle.position.y -= -150;
      lifeLostText.position.y -= -170;
      circle.position.x -= -40;
      lifeLostText.position.x -= -65;

      Future.delayed(Duration(seconds: 1), () {
        lifeLostText.textRenderer = TextPaint(
          style: TextStyle(
            color: Colors.transparent,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(1.0, 1.0),
                blurRadius: 3.0,
                color: Colors.black,
              ),
            ],
          ),
        );

        Future.delayed(Duration(milliseconds: 300), () {
          remove(lifeLostText);
        });
      });

      Future.delayed(Duration(seconds: 1), () {
        circle.paint.color = Colors.transparent;
        Future.delayed(Duration(milliseconds: 300), () {
          remove(circle);
        });
      });
    });
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
        "$result\nVidas do Jogador: ${playerCardHealth.join(", ")} (Vida Perdida: $playerLifeLost)\nVidas do Computador: ${computerCardHealth.join(", ")} (Vida Perdida: $computerLifeLost)";
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final screenSize = size;
    final centerX = screenSize.x / 2;
    final centerY = screenSize.y / 2;
    statusText.position = Vector2(centerX - (statusText.width / 2), 10);

    if (gameOver) {
      return;
    }

    if (playerCardIndex != -1) {
      _renderCard(playerCardIndex, Offset(centerX - 180, centerY));
      _drawHealthBar(canvas, Offset(centerX - 180, centerY),
          playerCardHealth[playerCardIndex]);
    }

    if (computerCardIndex != -1) {
      _renderCard(computerCardIndex, Offset(centerX + 50, centerY));
      _drawHealthBar(canvas, Offset(centerX + 50, centerY),
          computerCardHealth[computerCardIndex]);
    }
  }

  SpriteComponent? currentCardComponent;

  void _renderCard(int index, Offset position) async {
    if (currentCardComponent != null) {
      remove(currentCardComponent!);
    }

    String path = cards[index];
    Sprite cardSprite = await loadSprite(path);

    final cardWidth = 150.0;
    final cardHeight = 300.0;

    currentCardComponent = SpriteComponent(
      sprite: cardSprite,
      position: Vector2(position.dx, position.dy),
      size: Vector2(cardWidth, cardHeight),
      priority: 1,
    );

    add(currentCardComponent!);
  }

  void _drawHealthBar(Canvas canvas, Offset position, int health) {
    final cardWidth = 150.0;
    final healthBarWidth = cardWidth - 5;
    final healthBarHeight = 10.0;

    Color healthColor = health > 6
        ? Colors.green
        : health > 3
            ? Colors.orange
            : Colors.red;

    final healthBarY = position.dy + 310;
    canvas.drawRect(
      Rect.fromLTWH(position.dx, healthBarY, healthBarWidth, healthBarHeight),
      Paint()..color = Colors.grey,
    );

    final currentHealthWidth = (health / maxHealth) * healthBarWidth;
    canvas.drawRect(
      Rect.fromLTWH(
          position.dx, healthBarY, currentHealthWidth, healthBarHeight),
      Paint()..color = healthColor,
    );
  }

  void removeAllExtraCards() {
    for (var card in cardSprites) {
      if (card.isMounted) {
        remove(card);
      }
    }
  }

  void checkGameOver() async {
    if (playerCardHealth.every((health) => health <= 0)) {
      gameOver = true;
      removeAllExtraCards();
      add(defeatAnimation);
      await audioPlayer.play(AssetSource('sounds/defeat_sound.mp3'));
      updateStatus("Você perdeu! Todas as suas cartas foram derrotadas.");
    } else if (computerCardHealth.every((health) => health <= 0)) {
      gameOver = true;
      removeAllExtraCards();
      add(victoryAnimation);
      await audioPlayer.play(AssetSource('sounds/victory_sound.mp3'));
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
      if (children.contains(victoryAnimation)) {
        remove(victoryAnimation);
      }
      if (children.contains(defeatAnimation)) {
        remove(defeatAnimation);
      }
      resetGame();
    }
  }

  void resetGame() {
    audioPlayer.stop();
    gameOver = false;
    playerCardHealth = List.filled(4, maxHealth);
    computerCardHealth = List.filled(4, maxHealth);
    playerCardIndex = -1;
    computerCardIndex = -1;

    if (children.contains(victoryAnimation)) {
      remove(victoryAnimation);
    }
    if (children.contains(defeatAnimation)) {
      remove(defeatAnimation);
    }

    for (var card in cardSprites) {
      if (!children.contains(card)) {
        add(card);
      }
    }

    playerLifeLost = 0;
    computerLifeLost = 0;

    updateStatus("Jogo reiniciado. Toque em uma carta para começar.");
  }
}

class CardGameWidget extends StatelessWidget {
  final bool isMuted;
  final String backgroundImage;

  CardGameWidget({required this.isMuted, required this.backgroundImage});

  @override
  Widget build(BuildContext context) {
    final game = CardGame(isMuted: isMuted, backgroundImage: backgroundImage);
    return GameWidget(game: game);
  }
}
