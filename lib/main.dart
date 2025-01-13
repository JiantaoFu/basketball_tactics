import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/court_screen.dart';
import 'models/game_state.dart';

void main() {
  runApp(const BasketballTacticsApp());
}

class BasketballTacticsApp extends StatelessWidget {
  const BasketballTacticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GameState(),
      child: MaterialApp(
        title: 'Basketball Tactics',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const CourtScreen(),
      ),
    );
  }
}
