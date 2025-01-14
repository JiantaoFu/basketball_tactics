import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';

class PlayerListPanel extends StatelessWidget {
  final int? selectedPlayerId;
  final Function(int?) onPlayerSelected;

  const PlayerListPanel({
    super.key,
    required this.selectedPlayerId,
    required this.onPlayerSelected,
  });

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final isCreatingPath = gameState.isCreatingPath;
    final allPlayers = [...gameState.getTeamPlayers(Team.home), ...gameState.getTeamPlayers(Team.away)];

    return Container(
      width: 300,  
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people),
                    const SizedBox(width: 8),
                    const Text(
                      'Players',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                if (isCreatingPath) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: selectedPlayerId == null ? Colors.orange[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: selectedPlayerId == null ? Colors.orange : Colors.green,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedPlayerId == null ? Icons.warning : Icons.check_circle,
                          size: 16,
                          color: selectedPlayerId == null ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            selectedPlayerId == null
                                ? 'Select a player to create path'
                                : 'Player selected',
                            style: TextStyle(
                              color: selectedPlayerId == null ? Colors.orange[900] : Colors.green[900],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: allPlayers.length,
              itemBuilder: (context, index) {
                final player = allPlayers[index];
                final isSelected = player.id == selectedPlayerId;
                
                // Show team header for first player or when team changes
                if (index == 0 || (index > 0 && player.team != allPlayers[index - 1].team)) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (index > 0) const SizedBox(height: 16),  // Only add spacing between teams
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: player.team == Team.home 
                            ? Colors.red.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                          border: Border(
                            left: BorderSide(
                              color: player.team == Team.home ? Colors.red : Colors.blue,
                              width: 4,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              player.team == Team.home ? Icons.home : Icons.flight,
                              color: player.team == Team.home ? Colors.red : Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              player.team == Team.home ? 'Home Team' : 'Away Team',
                              style: TextStyle(
                                color: player.team == Team.home ? Colors.red : Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildPlayerTile(player, isSelected),
                    ],
                  );
                }
                
                return _buildPlayerTile(player, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTile(Player player, bool isSelected) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: player.color.withOpacity(isSelected ? 1.0 : 0.7),
        child: Text(
          player.number.toString(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        player.name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      subtitle: Text(
        '#${player.number} - ${player.team == Team.home ? 'Home' : 'Away'}',
        style: TextStyle(
          color: player.team == Team.home ? Colors.red : Colors.blue,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue[50],
      onTap: () => onPlayerSelected(isSelected ? null : player.id),
    );
  }
}
