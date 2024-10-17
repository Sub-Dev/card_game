import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'game.dart'; // Importa o jogo que será iniciado

class GameMenu extends StatefulWidget {
  @override
  _GameMenuState createState() => _GameMenuState();
}

class _GameMenuState extends State<GameMenu> {
  bool isSoundMuted = false;
  String backgroundImage = 'background1.png'; // Padrão
  late AudioPlayer _audioPlayer;
  double _volume = 0.5; // Volume padrão
  bool isMusicPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onUserInteraction() {
    if (!isSoundMuted && !isMusicPlaying) {
      _playBackgroundMusic();
    }
  }

  // Tocar música de fundo
  void _playBackgroundMusic() async {
    if (!isSoundMuted) {
      // Verifica se a música não está tocando
      await _audioPlayer.setSource(AssetSource('sounds/menu_music.mp3'));
      _audioPlayer.setVolume(_volume); // Configura o volume
      _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer
          .resume(); // Adicionando 'await' para garantir que a música seja reproduzida
      isMusicPlaying = true; // Marca a música como tocando
    }
  }

  /// Alternar o som
  void _toggleSound(bool value) {
    setState(() {
      isSoundMuted = value; // Atualiza o estado do som
      if (isSoundMuted) {
        _audioPlayer.pause();
        _audioPlayer.setVolume(0); // Muda o volume para 0
      } else {
        _playBackgroundMusic(); // Reproduz a música de fundo novamente
      }
    });
  }

  void _changeBackground(String newImage) {
    setState(() {
      backgroundImage = newImage;
    });
  }

  void _showImageZoom(String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: InteractiveViewer(
            child: Image.asset(imagePath),
          ),
        );
      },
    );
  }

  // Atualiza o volume
  void _updateVolume(double value) {
    setState(() {
      _volume = value;
      _audioPlayer.setVolume(isSoundMuted
          ? 0
          : _volume); // Atualiza o volume baseado no estado de mudo
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _onUserInteraction, // Chama a função ao tocar na tela
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/$backgroundImage'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Logo na parte superior
                Image.asset(
                  'images/logo.png', // Caminho para o logo
                  fit: BoxFit.contain,
                  height: MediaQuery.of(context).size.height *
                      0.5, // Ajusta a altura do logo
                ),
                SizedBox(height: 20), // Espaço abaixo do logo
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CardGameWidget(
                          isMuted: isSoundMuted, // Ajustado para "isMuted"
                          backgroundImage: backgroundImage,
                        ),
                      ),
                    );
                  },
                  child: Text('Iniciar Jogo'),
                ),
                SizedBox(height: 16), // Espaçamento entre botões
                ElevatedButton(
                  onPressed: () {
                    _showOptions(context);
                  },
                  child: Text('Opções'),
                ),
                SizedBox(height: 16), // Espaçamento entre botões
                ElevatedButton(
                  onPressed: () {
                    // Fechar o app
                    Navigator.of(context).pop();
                  },
                  child: Text('Sair'),
                ),
                SizedBox(height: 16), // Espaçamento entre botões
                ElevatedButton(
                  onPressed: () => _toggleSound(
                      !isSoundMuted), // Passa o valor oposto para o método
                  child: Text(isSoundMuted ? 'Ativar Música' : 'Mutar Música'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Tela de Opções
  void _showOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Opções"),
          content: SingleChildScrollView(
            // Adiciona scroll se necessário
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: Text("Mutar som"),
                      value: isSoundMuted,
                      onChanged: (bool value) {
                        setState(() {
                          isSoundMuted = value; // Atualiza o estado do som
                          _toggleSound(
                              isSoundMuted); // Chama a função para alterar o som
                        });
                      },
                    ),
                    Text(
                        "Volume: ${(_volume * 100).round()}"), // Exibe o volume atual
                    Slider(
                      value: _volume,
                      onChanged: (double value) {
                        setState(() {
                          _volume = value;
                        });
                        _audioPlayer.setVolume(_volume); // Atualiza o volume
                      },
                      min: 0,
                      max: 1,
                      divisions: 10,
                      label: (_volume * 100).round().toString(),
                    ),
                    Text("Alterar imagem de fundo:"),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        GestureDetector(
                          onTap: () {
                            _changeBackground('background1.png');
                          },
                          onDoubleTap: () =>
                              _showImageZoom('assets/images/background1.png'),
                          child: Column(
                            children: [
                              Image.asset('assets/images/background1.png',
                                  width: 50, height: 50),
                              Checkbox(
                                value: backgroundImage == 'background1.png',
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _changeBackground('background1.png');
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _changeBackground('background2.png');
                          },
                          onDoubleTap: () =>
                              _showImageZoom('assets/images/background2.png'),
                          child: Column(
                            children: [
                              Image.asset('assets/images/background2.png',
                                  width: 50, height: 50),
                              Checkbox(
                                value: backgroundImage == 'background2.png',
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _changeBackground('background2.png');
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            ElevatedButton(
              child: Text("Fechar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
