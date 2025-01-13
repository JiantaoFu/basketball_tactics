import 'package:flutter/foundation.dart';

class Player {
  final String id;
  final String name;
  double x;
  double y;
  String role;

  Player({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.role,
  });

  @override
  String toString() {
    return 'Player{id: $id, name: $name, role: $role, x: $x, y: $y}';
  }

  Player copyWith({
    String? id,
    String? name,
    double? x,
    double? y,
    String? role,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      x: x ?? this.x,
      y: y ?? this.y,
      role: role ?? this.role,
    );
  }
}

class GameState extends ChangeNotifier {
  final List<Player> _players = [];
  
  List<Player> get players => List.unmodifiable(_players);
  
  void addPlayer(Player player) {
    print('Adding player: $player'); // Debug print
    _players.add(player);
    print('Current players: $_players'); // Debug print
    notifyListeners();
  }

  void updatePlayerPosition(String playerId, double x, double y) {
    print('Updating player $playerId position to ($x, $y)'); // Debug print
    final playerIndex = _players.indexWhere((p) => p.id == playerId);
    if (playerIndex != -1) {
      final updatedPlayer = _players[playerIndex].copyWith(x: x, y: y);
      _players[playerIndex] = updatedPlayer;
      print('Player position updated: ${_players[playerIndex]}'); // Debug print
      notifyListeners();
    } else {
      print('Player $playerId not found!'); // Debug print
    }
  }

  void updatePlayerRole(String playerId, String newRole) {
    final playerIndex = _players.indexWhere((p) => p.id == playerId);
    if (playerIndex != -1) {
      final updatedPlayer = _players[playerIndex].copyWith(role: newRole);
      _players[playerIndex] = updatedPlayer;
      notifyListeners();
    }
  }
}
