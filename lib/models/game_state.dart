import 'dart:math';
import 'package:flutter/material.dart';

enum Team { home, away }

class Player {
  final int id;
  double x;
  double y;
  final int number;
  final Team team;
  String name;

  Player({
    required this.id,
    required this.x,
    required this.y,
    required this.number,
    required this.team,
    String? name,
  }) : name = name ?? 'Player $number';

  Color get color => team == Team.home ? const Color(0xFFE53935) : const Color(0xFF1E88E5);
}

class SnapPosition {
  final double x;
  final double y;
  final bool isVisible;
  final double snapRadius;

  SnapPosition({
    required this.x,
    required this.y,
    this.isVisible = true,
    this.snapRadius = 0.05,
  });
}

class GameState extends ChangeNotifier {
  List<Player> _players = [];
  List<SnapPosition> _snapPositions = [];
  bool _showSnapPositions = true;
  
  List<Player> get players => _players;
  List<SnapPosition> get snapPositions => _snapPositions;
  bool get showSnapPositions => _showSnapPositions;

  List<Player> getTeamPlayers(Team team) => _players.where((p) => p.team == team).toList();

  GameState() {
    _initializePlayers();
  }

  void _initializePlayers() {
    // Initialize home team (red) on the bottom
    final homePlayers = List.generate(
      5,
      (index) => Player(
        id: index + 1,
        x: 0.2 + (index * 0.15),  // Spread players horizontally
        y: 0.8,                    // Place them near the bottom
        number: index + 1,
        team: Team.home,
        name: 'Home ${index + 1}',
      ),
    );

    // Initialize away team (blue) on the top
    final awayPlayers = List.generate(
      5,
      (index) => Player(
        id: index + 6,  // Start IDs after home team
        x: 0.2 + (index * 0.15),  // Spread players horizontally
        y: 0.2,                    // Place them near the top
        number: index + 1,
        team: Team.away,
        name: 'Away ${index + 1}',
      ),
    );

    _players = [...homePlayers, ...awayPlayers];
    notifyListeners();
  }

  void updatePlayerPosition(int playerId, double x, double y) {
    final playerIndex = _players.indexWhere((p) => p.id == playerId);
    if (playerIndex != -1) {
      // Check if the player is near any snap position
      final nearestSnap = _findNearestSnapPosition(x, y);
      if (nearestSnap != null) {
        x = nearestSnap.x;
        y = nearestSnap.y;
      }

      _players[playerIndex].x = x;
      _players[playerIndex].y = y;
      notifyListeners();
    }
  }

  void updatePlayerName(int playerId, String name) {
    final playerIndex = _players.indexWhere((p) => p.id == playerId);
    if (playerIndex != -1) {
      _players[playerIndex].name = name;
      notifyListeners();
    }
  }

  void toggleSnapPositionsVisibility() {
    _showSnapPositions = !_showSnapPositions;
    notifyListeners();
  }

  void addSnapPosition(double x, double y) {
    _snapPositions.add(SnapPosition(x: x, y: y));
    notifyListeners();
  }

  void removeSnapPosition(int index) {
    if (index >= 0 && index < _snapPositions.length) {
      _snapPositions.removeAt(index);
      notifyListeners();
    }
  }

  void clearSnapPositions() {
    _snapPositions.clear();
    notifyListeners();
  }

  SnapPosition? _findNearestSnapPosition(double x, double y) {
    if (_snapPositions.isEmpty) return null;

    SnapPosition? nearest;
    double minDistance = double.infinity;

    for (var pos in _snapPositions) {
      final distance = _calculateDistance(x, y, pos.x, pos.y);
      if (distance < minDistance && distance < pos.snapRadius) {
        minDistance = distance;
        nearest = pos;
      }
    }

    return nearest;
  }

  double _calculateDistance(double x1, double y1, double x2, double y2) {
    return sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
  }
}
