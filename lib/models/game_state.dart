import 'dart:math';
import 'package:flutter/material.dart';

enum Team { home, away }

enum PathType {
  dribble,
  cut,
  screen
}

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
    this.snapRadius = 0.1,  // Increase snap radius to 10% of court size
  });
}

class MovementPath {
  final int startPositionIndex;
  final int endPositionIndex;
  final int playerId;
  final PathType pathType;

  MovementPath({
    required this.startPositionIndex,
    required this.endPositionIndex,
    required this.playerId,
    required this.pathType,
  });
}

class GameState extends ChangeNotifier {
  List<Player> _players = [];
  List<SnapPosition> _snapPositions = [];
  List<MovementPath> _movementPaths = [];
  bool _showSnapPositions = true;
  bool _isCreatingPath = false;
  int? _selectedPlayerId;
  int? _pathStartPositionIndex;
  PathType _currentPathType = PathType.dribble;
  
  List<Player> get players => _players;
  List<SnapPosition> get snapPositions => _snapPositions;
  List<MovementPath> get movementPaths => _movementPaths;
  bool get showSnapPositions => _showSnapPositions;
  bool get isCreatingPath => _isCreatingPath;
  int? get selectedPlayerId => _selectedPlayerId;
  int? get pathStartPositionIndex => _pathStartPositionIndex;
  PathType get currentPathType => _currentPathType;

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
    // Adjust for court aspect ratio (court is typically wider than tall)
    final dx = x1 - x2;
    final dy = (y1 - y2) * 1.9;  // Multiply by court aspect ratio
    return sqrt(dx * dx + dy * dy);
  }

  void startPathCreation() {
    print('Starting path creation mode (selectedPlayer: $_selectedPlayerId)'); // Debug print
    _isCreatingPath = true;
    _pathStartPositionIndex = null;
    notifyListeners();
  }

  void selectPathPosition(int positionIndex) {
    print('Attempting to select position $positionIndex. isCreatingPath: $_isCreatingPath, startPos: $_pathStartPositionIndex, selectedPlayer: $_selectedPlayerId'); // Debug print
    
    if (!_isCreatingPath) {
      print('Not in path creation mode'); // Debug print
      return;
    }

    if (_selectedPlayerId == null) {
      print('No player selected'); // Debug print
      return;
    }

    if (_pathStartPositionIndex == null) {
      print('Setting start position: $positionIndex'); // Debug print
      _pathStartPositionIndex = positionIndex;
      notifyListeners();
      return;
    }
    
    if (_pathStartPositionIndex != positionIndex) {
      print('Creating path from ${_pathStartPositionIndex} to $positionIndex'); // Debug print
      _movementPaths.add(MovementPath(
        startPositionIndex: _pathStartPositionIndex!,
        endPositionIndex: positionIndex,
        playerId: _selectedPlayerId!,
        pathType: _currentPathType,
      ));
      _pathStartPositionIndex = null;
      notifyListeners();
    } else {
      print('Same position selected, ignoring'); // Debug print
    }
  }

  void setSelectedPlayer(int? playerId) {
    print('Setting selected player to: $playerId (isCreatingPath: $_isCreatingPath)'); // Debug print
    _selectedPlayerId = playerId;
    // Reset path start position when switching players
    if (_isCreatingPath) {
      _pathStartPositionIndex = null;
    }
    notifyListeners();
  }

  void cancelPathCreation() {
    print('Exiting path creation mode (selectedPlayer: $_selectedPlayerId)'); // Debug print
    _isCreatingPath = false;
    _pathStartPositionIndex = null;
    notifyListeners();
  }

  void togglePathCreation() {
    _isCreatingPath = !_isCreatingPath;
    if (!_isCreatingPath) {
      _pathStartPositionIndex = null;
    }
    notifyListeners();
  }

  void setPathType(PathType type) {
    _currentPathType = type;
    notifyListeners();
  }

  void removeMovementPath(int index) {
    if (index >= 0 && index < _movementPaths.length) {
      _movementPaths.removeAt(index);
      notifyListeners();
    }
  }

  void clearMovementPaths() {
    _movementPaths.clear();
    notifyListeners();
  }
}
