import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';

class PlayerListPanel extends StatefulWidget {
  final int? selectedPlayerId;
  final Function(int?) onPlayerSelected;

  const PlayerListPanel({
    super.key,
    this.selectedPlayerId,
    required this.onPlayerSelected,
  });

  @override
  State<PlayerListPanel> createState() => _PlayerListPanelState();
}

class _PlayerListPanelState extends State<PlayerListPanel> {
  Team _selectedTeam = Team.offense;

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final isCreatingPath = gameState.isCreatingPath;
    final allPlayers = [
      ...gameState.getTeamPlayers(Team.offense),
      ...gameState.getTeamPlayers(Team.defense)
    ];

    return Container(
      width: 200,
      color: Colors.grey[200],
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[300],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Players',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddPlayerDialog(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: allPlayers.length,
              itemBuilder: (context, index) {
                final player = allPlayers[index];
                final isSelected = player.id == widget.selectedPlayerId;
                
                // Show team header for first player or when team changes
                if (index == 0 || (index > 0 && player.team != allPlayers[index - 1].team)) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (index > 0) const SizedBox(height: 16),  // Only add spacing between teams
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: player.team == Team.offense 
                            ? Colors.red.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                          border: Border(
                            left: BorderSide(
                              color: player.team == Team.offense ? Colors.red : Colors.blue,
                              width: 4,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              player.team == Team.offense ? Icons.sports_basketball : Icons.shield,
                              color: player.team == Team.offense ? Colors.red : Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              player.team == Team.offense ? 'Offense' : 'Defense',
                              style: TextStyle(
                                color: player.team == Team.offense ? Colors.red : Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: player.color.withOpacity(isSelected ? 1.0 : 0.2),
                          child: Icon(
                            player.team == Team.offense ? Icons.sports_basketball : Icons.shield,
                            color: player.color,
                          ),
                        ),
                        title: Text(
                          player.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : null,
                          ),
                        ),
                        subtitle: Text(
                          '#${player.number} - ${player.team == Team.offense ? 'Offense' : 'Defense'}',
                          style: TextStyle(
                            color: player.color,
                          ),
                        ),
                        selected: isSelected,
                        selectedTileColor: Colors.blue[50],
                        onTap: () => widget.onPlayerSelected(isSelected ? null : player.id),
                      ),
                    ],
                  );
                }
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: player.color.withOpacity(isSelected ? 1.0 : 0.2),
                    child: Icon(
                      player.team == Team.offense ? Icons.sports_basketball : Icons.shield,
                      color: player.color,
                    ),
                  ),
                  title: Text(
                    player.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                  subtitle: Text(
                    '#${player.number} - ${player.team == Team.offense ? 'Offense' : 'Defense'}',
                    style: TextStyle(
                      color: player.color,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: Colors.blue[50],
                  onTap: () => widget.onPlayerSelected(isSelected ? null : player.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPlayerDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Player'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Player Name'),
            ),
            const SizedBox(height: 16),
            DropdownButton<Team>(
              value: _selectedTeam,
              items: Team.values.map((team) {
                return DropdownMenuItem(
                  value: team,
                  child: Text(team == Team.offense ? 'Offense' : 'Defense'),
                );
              }).toList(),
              onChanged: (Team? value) {
                if (value != null) {
                  setState(() {
                    _selectedTeam = value;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final gameState = Provider.of<GameState>(context, listen: false);
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                // Add player logic here
                // gameState.addPlayer(name, _selectedTeam);
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
