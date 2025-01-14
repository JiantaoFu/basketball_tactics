import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/game_state.dart';
import 'widgets/basketball_court.dart';
import 'widgets/player_list_panel.dart';
import 'widgets/play_control_pannel.dart';

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
  bool _isCreatingPaths = false;
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
                // Mode Selection
                ToggleButtons(
                  isSelected: [_isAddingSnapPositions, _isCreatingPaths],
                  onPressed: (index) {
                    setState(() {
                      if (index == 0) {
                        _isAddingSnapPositions = !_isAddingSnapPositions;
                        if (_isAddingSnapPositions) {
                          _isCreatingPaths = false;
                          context.read<GameState>().cancelPathCreation();
                        }
                      } else {
                        final wasCreatingPaths = _isCreatingPaths;
                        _isCreatingPaths = !_isCreatingPaths;
                        if (_isCreatingPaths) {
                          _isAddingSnapPositions = false;
                          // Start path creation if we have a player selected
                          if (_selectedPlayerId != null) {
                            context.read<GameState>().startPathCreation();
                          }
                        } else if (wasCreatingPaths) {
                          context.read<GameState>().cancelPathCreation();
                        }
                      }
                    });
                  },
                  children: [
                    Tooltip(
                      message: 'Add Positions Mode\nClick court to add positions',
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_location,
                              color: _isAddingSnapPositions ? Colors.orange : null,
                            ),
                            const Text('Add Positions', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'Create Paths Mode\nConnect positions to create movement paths',
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timeline,
                              color: _isCreatingPaths ? Colors.orange : null,
                            ),
                            const Text('Create Paths', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // View Controls
                IconButton(
                  icon: Icon(
                    gameState.showSnapPositions ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    context.read<GameState>().toggleSnapPositionsVisibility();
                  },
                  tooltip: 'Toggle Position Visibility',
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
                  child: Column(
                    children: [
                      const PlayControlPanel(),
                      Expanded(
                        child: Stack(
                          children: [
                            BasketballCourt(
                              isFullCourt: _isFullCourt,
                              isAddingSnapPositions: _isAddingSnapPositions,
                              isCreatingPaths: _isCreatingPaths,
                              selectedPlayerId: _selectedPlayerId,
                              onPlayerSelected: (playerId) {
                                setState(() {
                                  _selectedPlayerId = playerId;
                                });
                                gameState.setSelectedPlayer(playerId);
                              },
                              onPlayerMoved: (player, newX, newY) {
                                // Update player position in GameState
                                gameState.updatePlayerPosition(player.id, newX, newY);
                              },
                            ),
                            if (_isCreatingPaths)
                              Positioned(
                                top: 16,
                                left: 16,
                                right: 16,
                                child: Card(
                                  color: _selectedPlayerId == null ? Colors.orange[100] : Colors.blue[100],
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedPlayerId == null
                                              ? '⚠️ Select a player first from the player list'
                                              : gameState.pathStartPositionIndex == null
                                                  ? '1. Click a position to start the path'
                                                  : '2. Click another position to complete the path',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (_selectedPlayerId == null)
                                          const Text(
                                            'You must select a player before creating their movement path',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                PlayerListPanel(
                  selectedPlayerId: _selectedPlayerId,
                  onPlayerSelected: (id) {
                    setState(() {
                      _selectedPlayerId = id;
                    });
                    gameState.setSelectedPlayer(id);
                    // Start path creation if we're in path creation mode and selected a player
                    if (_isCreatingPaths && id != null) {
                      gameState.startPathCreation();
                    }
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
