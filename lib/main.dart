// main.dart
import 'package:flutter/material.dart';
import 'menu.dart'; // Importa o menu modularizado

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jogo de Cartas',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GameMenu(), // Usa o menu modularizado como tela principal
    );
  }
}
