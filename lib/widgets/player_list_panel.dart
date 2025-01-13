import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';

class PlayerListPanel extends StatelessWidget {
  final int? selectedPlayerId;
  final Function(int) onPlayerSelected;

  const PlayerListPanel({
    super.key,
    required this.selectedPlayerId,
    required this.onPlayerSelected,
  });

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTeamSection(context, 'Home Team', Team.home, gameState),
          const Divider(height: 1),
          _buildTeamSection(context, 'Away Team', Team.away, gameState),
        ],
      ),
    );
  }

  Widget _buildTeamSection(BuildContext context, String title, Team team, GameState gameState) {
    final players = gameState.getTeamPlayers(team);
    final teamColor = team == Team.home ? const Color(0xFFE53935) : const Color(0xFF1E88E5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: teamColor.withOpacity(0.1),
          child: Text(
            title,
            style: TextStyle(
              color: teamColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        ...players.map((player) => _buildPlayerTile(context, player, gameState)),
      ],
    );
  }

  Widget _buildPlayerTile(BuildContext context, Player player, GameState gameState) {
    final isSelected = player.id == selectedPlayerId;

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: player.color,
          border: Border.all(
            color: isSelected ? Colors.yellow : Colors.white,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.yellow.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 2,
              ),
          ],
        ),
        child: Center(
          child: Text(
            '#${player.number}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: Text(player.name),
      selected: isSelected,
      selectedTileColor: Colors.yellow.withOpacity(0.1),
      onTap: () => onPlayerSelected(player.id),
      trailing: IconButton(
        icon: const Icon(Icons.edit, size: 20),
        onPressed: () => _showNameEditDialog(context, player, gameState),
      ),
    );
  }

  void _showNameEditDialog(BuildContext context, Player player, GameState gameState) {
    final controller = TextEditingController(text: player.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Player ${player.number}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Player Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              gameState.updatePlayerName(player.id, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
