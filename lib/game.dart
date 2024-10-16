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
// Suponha que você tenha uma referência à largura da tela
    final screenSize = size; // tamanho da tela do jogo

// Posição do texto
    final textPosition = statusText.position;

// Cria o fundo com a largura da tela e a posição do texto
    final statusBackground =
        StatusBackgroundComponent(screenSize, textPosition);
    add(statusBackground); // Adiciona o fundo ao jogo

// Adiciona o texto acima do fundo
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
      int damage = (playerAttack - computerDefense + 1);
      computerCardHealth[computerCardIndex] -= damage;
      computerLifeLost += damage; // Atualiza vida perdida

      // Calcular a posição da animação baseada na posição renderizada da carta do computador
      final centerX = size.x / 2;
      final centerY = size.y / 2;
      Vector2 computerCardPosition =
          Vector2(centerX + 50, centerY); // Posição da carta do computador

      // Adicionar a animação de ataque na posição renderizada da carta do computador
      attackAnimation.position = computerCardPosition;
      attackAnimation.priority =
          1000; // Prioridade alta para ficar por cima das cartas

      add(attackAnimation);
      _showLifeLostAnimation(damage.toString(), computerCardPosition);
      // Verifica se não está mudo antes de tocar o som
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

    // Computador ataca o jogador
    if (computerAttack >= playerDefense) {
      int damage = (computerAttack - playerDefense + 1);
      playerCardHealth[playerCardIndex] -= damage;
      playerLifeLost += damage; // Atualiza vida perdida

      // Calcular a posição da animação baseada na posição renderizada da carta do jogador
      final centerX = size.x / 2;
      final centerY = size.y / 2;
      Vector2 playerCardPosition =
          Vector2(centerX - 180, centerY); // Posição da carta do jogador

      // Adicionar a animação de ataque na posição renderizada da carta do jogador
      attackAnimation.position = playerCardPosition;
      attackAnimation.priority =
          1000; // Prioridade alta para ficar por cima das cartas

      add(attackAnimation);
      _showLifeLostAnimation(damage.toString(), playerCardPosition);
      // Verifica se não está mudo antes de tocar o som
      if (!isMuted) {
        audioPlayer
            .play(AssetSource('sounds/attack_sound.mp3'))
            .catchError((error) {
          print('Erro ao tocar o som: $error');
        });
      }
      Future.delayed(Duration(seconds: 1), () {
        remove(attackAnimation); // Permite nova animação
      });
    }

    // Garantir que a vida não fique negativa
    playerCardHealth[playerCardIndex] = playerCardHealth[playerCardIndex] < 0
        ? 0
        : playerCardHealth[playerCardIndex];
    computerCardHealth[computerCardIndex] =
        computerCardHealth[computerCardIndex] < 0
            ? 0
            : computerCardHealth[computerCardIndex];

    // Remover carta se a vida for zero
    if (playerCardHealth[playerCardIndex] <= 0) {
      if (children.contains(cardSprites[playerCardIndex])) {
        remove(cardSprites[playerCardIndex]);
      }
    }
  }

  void _showLifeLostAnimation(String damage, Vector2 position) {
    // Criar um círculo como fundo
    final circle = CircleComponent(
      radius: 40, // Ajuste o tamanho do círculo conforme necessário
      position: position.clone(), // Posição inicial
      paint: Paint()
        ..color = Colors.black.withOpacity(0.8), // Cor de fundo com opacidade
      priority: 1000, // Prioridade do círculo
    );

    // Criar o texto que será exibido sobre o círculo
    final lifeLostText = TextComponent(
      text: '-$damage',
      position: position.clone(), // Posição inicial
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.red,
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
      ),
    );

    lifeLostText.priority =
        1001; // Prioridade do texto deve ser maior que a do círculo

    // Adicionar o círculo e o texto à cena
    add(circle);
    add(lifeLostText);

    // Animação para mover ambos (círculo e texto) para cima
    Future.delayed(Duration.zero, () {
      // Define a animação de movimento para cima
      circle.position.y -= -150;
      lifeLostText.position.y -= -170;
      circle.position.x -= -40;
      lifeLostText.position.x -= -65;

      // Fade out do texto
      Future.delayed(Duration(seconds: 1), () {
        lifeLostText.textRenderer = TextPaint(
          style: TextStyle(
            color: Colors.transparent, // Nova cor do texto
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
          remove(lifeLostText); // Remove o texto após a animação
        });
      });

      // Fade out do círculo
      Future.delayed(Duration(seconds: 1), () {
        circle.paint.color =
            Colors.transparent; // Faz o círculo ficar invisível
        Future.delayed(Duration(milliseconds: 300), () {
          remove(circle); // Remove o círculo após a animação
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
      _renderCard(playerCardIndex, Offset(centerX - 180, centerY));
      _drawHealthBar(canvas, Offset(centerX - 180, centerY),
          playerCardHealth[playerCardIndex]);
    }

    // Renderiza a carta do computador
    if (computerCardIndex != -1) {
      _renderCard(computerCardIndex, Offset(centerX + 50, centerY));
      _drawHealthBar(canvas, Offset(centerX + 50, centerY),
          computerCardHealth[computerCardIndex]);
    }
  }

  void _renderCard(int index, Offset position) async {
    // Carregar a imagem da carta como um sprite
    String path = cards[index];
    Sprite cardSprite = await loadSprite(path);

    // Configura o SpriteComponent para a carta
    final cardWidth = 150.0;
    final cardHeight = 300.0;

    SpriteComponent cardComponent = SpriteComponent(
        sprite: cardSprite,
        position:
            Vector2(position.dx, position.dy), // Define a posição da carta
        size: Vector2(cardWidth, cardHeight),
        priority: 1 // Define o tamanho da carta
        );

    // Adiciona a carta como um SpriteComponent no jogo
    add(cardComponent);
  }

  void _drawHealthBar(Canvas canvas, Offset position, int health) {
    final cardWidth = 150.0;
    final healthBarWidth = cardWidth - 5;
    final healthBarHeight = 10.0;

    // Escolhe a cor da barra com base na vida restante
    Color healthColor = health > 6
        ? Colors.green
        : health > 3
            ? Colors.orange
            : Colors.red;

    final healthBarY = position.dy + 310;
    // Fundo da barra de vida
    canvas.drawRect(
      Rect.fromLTWH(position.dx, healthBarY, healthBarWidth, healthBarHeight),
      Paint()..color = Colors.grey,
    );

    // Barra de vida atual
    final currentHealthWidth = (health / maxHealth) * healthBarWidth;
    canvas.drawRect(
      Rect.fromLTWH(
          position.dx, healthBarY, currentHealthWidth, healthBarHeight),
      Paint()..color = healthColor,
    );
  }

  void removeAllExtraCards() {
    for (var card in cardSprites) {
      if (children.contains(card)) {
        remove(card);
      }
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
    playerLifeLost = 0; // Resetar vida perdida
    computerLifeLost = 0; // Resetar vida perdida
    // Atualiza o status do jogo
    updateStatus("Jogo reiniciado. Toque em uma carta para jogar.");
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
