import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../widgets/basketball_court.dart';
import '../widgets/player_controls.dart';

class CourtScreen extends StatelessWidget {
  const CourtScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basketball Tactics'),
        backgroundColor: Colors.orange,
        elevation: 4,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.add, size: 30),
              onPressed: () {
                print('Add button pressed'); // Debug print
                _showAddPlayerDialog(context);
              },
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AspectRatio(
                aspectRatio: 1.9, // Standard basketball court ratio
                child: BasketballCourt(),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: PlayerControls(),
          ),
        ],
      ),
    );
  }

  void _showAddPlayerDialog(BuildContext context) {
    print('Showing add player dialog'); // Debug print
    String name = '';
    String role = 'PG';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add New Player'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Player Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                print('Name changed to: $value'); // Debug print
                name = value;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: role,
              decoration: const InputDecoration(
                labelText: 'Position',
                border: OutlineInputBorder(),
              ),
              items: ['PG', 'SG', 'SF', 'PF', 'C']
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r),
                      ))
                  .toList(),
              onChanged: (value) {
                print('Role changed to: $value'); // Debug print
                role = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              print('Add player button pressed'); // Debug print
              print('Name: $name, Role: $role'); // Debug print
              if (name.isNotEmpty) {
                final player = Player(
                  id: DateTime.now().toString(),
                  name: name,
                  x: 0.5,
                  y: 0.5,
                  role: role,
                );
                Provider.of<GameState>(context, listen: false).addPlayer(player);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Add Player'),
          ),
        ],
      ),
    );
  }
}
