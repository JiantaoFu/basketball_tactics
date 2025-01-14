import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/game_state.dart';
import 'widgets/basketball_court.dart';
import 'widgets/player_list_panel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameState(),
      child: MaterialApp(
        title: 'Basketball Tactics',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isFullCourt = true;
  bool _isAddingSnapPositions = false;
  int? _selectedPlayerId;

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_location),
                  onPressed: () {
                    setState(() {
                      _isAddingSnapPositions = !_isAddingSnapPositions;
                    });
                  },
                  color: _isAddingSnapPositions ? Colors.orange : null,
                  tooltip: 'Add Snap Positions',
                ),
                IconButton(
                  icon: Icon(
                    gameState.showSnapPositions ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    context.read<GameState>().toggleSnapPositionsVisibility();
                  },
                  tooltip: 'Toggle Snap Positions',
                ),
                IconButton(
                  icon: const Icon(Icons.sports_basketball),
                  onPressed: () {
                    setState(() {
                      _isFullCourt = !_isFullCourt;
                    });
                  },
                  tooltip: 'Toggle Full/Half Court',
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: BasketballCourt(
                    isFullCourt: _isFullCourt,
                    isAddingSnapPositions: _isAddingSnapPositions,
                    selectedPlayerId: _selectedPlayerId,
                    onPlayerSelected: (playerId) {
                      setState(() {
                        _selectedPlayerId = playerId;
                      });
                    },
                  ),
                ),
                PlayerListPanel(
                  selectedPlayerId: _selectedPlayerId,
                  onPlayerSelected: (playerId) {
                    setState(() {
                      _selectedPlayerId = playerId;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
