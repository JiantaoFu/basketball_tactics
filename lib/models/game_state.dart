import 'dart:math';
import 'package:flutter/material.dart';

enum Team { offense, defense }

enum PathType {
  dribble,
  cut,
  screen
}

enum PlayStepType {
  move,      // Player moves to position
  screen,    // Player sets screen
  dribble,   // Player dribbles to position
  shoot      // Player shoots
}

class Position {
  double x;
  double y;

  Position({required this.x, required this.y});

  Position copyWith({double? x, double? y}) {
    return Position(
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}

class Player {
  final int id;
  String name;
  Team team;
  Position position;
  Color color;
  int number;

  Player({
    required this.id,
    required this.name,
    required this.team,
    required this.position,
    required this.color,
    int? number,
  }) : number = number ?? id;

  Player copyWith({
    int? id,
    String? name,
    Team? team,
    Position? position,
    Color? color,
    int? number,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      team: team ?? this.team,
      position: position ?? this.position,
      color: color ?? this.color,
      number: number ?? this.number,
    );
  }
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

extension SnapPositionExt on SnapPosition {
  Position toPosition() => Position(x: x, y: y);
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

class PlayStep {
  final int playerId;
  final PlayStepType type;
  final int targetPositionIndex;  // Index of snap position instead of raw coordinates
  final List<int> pathIndices;    // List of snap position indices for the path
  bool isCompleted = false;

  PlayStep({
    required this.playerId,
    required this.type,
    required this.targetPositionIndex,
    this.pathIndices = const [],
  });
}

class Play {
  final String name;
  final String description;
  final List<PlayStep> steps;
  final Map<int, Position> initialPositions;  // Store initial positions for each player
  int currentStepIndex;

  Play({
    required this.name,
    required this.description,
    required this.steps,
    required this.initialPositions,
    this.currentStepIndex = 0,
  });

  bool get isComplete => steps.every((step) => step.isCompleted);
  bool get isStarted => currentStepIndex >= 0;
  bool get isCompleted => currentStepIndex >= steps.length;
  PlayStep? get currentStep => 
    isStarted && !isCompleted ? steps[currentStepIndex] : null;
  
  @override
  String toString() {
    return 'Play($name, $description, ${steps.length} steps, ${initialPositions.length} positions, $currentStepIndex current, ${isComplete ? 'complete' : 'incomplete'})';
  }
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
  List<Play> _plays = [];
  Play? _currentPlay;
  bool _isPlayMode = false;

  List<Player> get players => _players;
  List<SnapPosition> get snapPositions => _snapPositions;
  List<MovementPath> get movementPaths => _movementPaths;
  bool get showSnapPositions => _showSnapPositions;
  bool get isCreatingPath => _isCreatingPath;
  int? get selectedPlayerId => _selectedPlayerId;
  int? get pathStartPositionIndex => _pathStartPositionIndex;
  PathType get currentPathType => _currentPathType;
  List<Play> get plays => _plays;
  Play? get currentPlay => _currentPlay;
  bool get isPlayMode => _isPlayMode;

  List<PlayStep> get playSteps => 
    currentPlay?.steps.where((step) => !step.isCompleted).toList() ?? [];

  List<Player> getTeamPlayers(Team team) => _players.where((p) => p.team == team).toList();

  GameState() {
    _initializePlayers();
  }

  void _initializePlayers() {
    // Initialize offense team (red) on the bottom
    final offensePlayers = List.generate(
      5,
      (index) => Player(
        id: index + 1,
        name: 'Offense ${index + 1}',
        team: Team.offense,
        position: Position(x: 0.2 + (index * 0.15), y: 0.8),
        color: const Color(0xFFE53935),
      ),
    );

    // Initialize defense team (blue) on the top
    final defensePlayers = List.generate(
      5,
      (index) => Player(
        id: index + 6,  // Start IDs after offense team
        name: 'Defense ${index + 1}',
        team: Team.defense,
        position: Position(x: 0.2 + (index * 0.15), y: 0.2),
        color: const Color(0xFF1E88E5),
      ),
    );

    _players = [...offensePlayers, ...defensePlayers];
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

      _players[playerIndex].position = Position(x: x, y: y);
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
    if (_snapPositions.isEmpty) {
      print('No snap positions available');
      return null;
    }

    var minDistance = double.infinity;
    SnapPosition? nearest;

    for (final pos in _snapPositions) {
      final dx = pos.x - x;
      final dy = pos.y - y;
      final distance = sqrt(dx * dx + dy * dy);

      if (distance < minDistance) {
        minDistance = distance;
        nearest = pos;
      }
    }

    print('Finding nearest snap position to ($x, $y):');
    print('  Nearest: (${nearest?.x}, ${nearest?.y})');
    print('  Distance: $minDistance');

    const snapThreshold = 0.1; // 10% of court size
    return minDistance <= snapThreshold ? nearest : null;
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

  void addPlay(Play play) {
    _plays.add(play);
    notifyListeners();
  }

  void removePlay(int index) {
    if (index >= 0 && index < _plays.length) {
      _plays.removeAt(index);
      notifyListeners();
    }
  }

  void clearPlays() {
    _plays.clear();
    notifyListeners();
  }

  void createPickAndRollPlay() {
    // First ensure we have the necessary snap positions
    final topKeyIndex = _snapPositions.indexWhere((pos) => pos.x == 0.5 && pos.y == 0.7);
    final screenPosIndex = _snapPositions.indexWhere((pos) => pos.x == 0.4 && pos.y == 0.6);
    final shootPosIndex = _snapPositions.indexWhere((pos) => pos.x == 0.3 && pos.y == 0.5);
  
    // Add positions if they don't exist
    if (topKeyIndex == -1) {
      addSnapPosition(0.5, 0.7);
    }
    if (screenPosIndex == -1) {
      addSnapPosition(0.4, 0.6);
    }
    if (shootPosIndex == -1) {
      addSnapPosition(0.3, 0.5);
    }
  
    // Get the indices (they must exist now)
    final topKey = _snapPositions.indexWhere((pos) => pos.x == 0.5 && pos.y == 0.7);
    final screenPos = _snapPositions.indexWhere((pos) => pos.x == 0.4 && pos.y == 0.6);
    final shootPos = _snapPositions.indexWhere((pos) => pos.x == 0.3 && pos.y == 0.5);
  
    final play = Play(
      name: 'Basic Pick and Roll',
      description: 'A basic pick and roll play with the point guard and power forward',
      steps: [
        // Step 1: PG moves to top of key
        PlayStep(
          playerId: 1,
          type: PlayStepType.move,
          targetPositionIndex: topKey,
        ),
        
        // Step 2: PF sets screen
        PlayStep(
          playerId: 4,
          type: PlayStepType.screen,
          targetPositionIndex: screenPos,
        ),
        
        // Step 3: PG dribbles around screen to shooting zone
        PlayStep(
          playerId: 1,
          type: PlayStepType.dribble,
          targetPositionIndex: shootPos,
          pathIndices: [screenPos, shootPos],
        ),
      ],
      initialPositions: {
        1: _snapPositions[topKey].toPosition(),  // PG starts at top
        4: _snapPositions[screenPos].toPosition(),  // PF starts at screen position
      },
    );
    addPlay(play);
  }

  void startPlay(Play play) {
    print('\n=== Starting Play ===');
    print('Current Play: ${play.steps.length} steps');
    print('Players: ${_players.length}');
    _currentPlay = play;
    _isPlayMode = true;
    _currentPlay!.currentStepIndex = 0;
    
    // Reset player positions
    play.initialPositions.forEach((playerId, position) {
      final player = _players.firstWhere((p) => p.id == playerId);
      player.position = Position(x: position.x, y: position.y);
    });
    
    notifyListeners();
  }
  
  void resetPlay() {
    if (_currentPlay != null) {
      // Reset step completion status
      for (var step in _currentPlay!.steps) {
        step.isCompleted = false;
      }
      _currentPlay!.currentStepIndex = -1;
      
      // Reset positions
      _currentPlay!.initialPositions.forEach((playerId, position) {
        final player = _players.firstWhere((p) => p.id == playerId);
        player.position = Position(x: position.x, y: position.y);
      });
    }
    notifyListeners();
  }

  void endPlay() {
    _currentPlay = null;
    _isPlayMode = false;
    notifyListeners();
  }

  void addPlayStep(PlayStep step) {
    print('\n=== Adding Play Step ===');
    print('Step: $step');
    print('Player exists: ${_players.any((p) => p.id == step.playerId)}');
    print('Target position valid: ${step.targetPositionIndex >= 0 && step.targetPositionIndex < _snapPositions.length}');
    
    if (_currentPlay == null) {
      _currentPlay = Play(
        name: 'New Play',
        description: 'Play created during editing',
        steps: [],
        initialPositions: {},
      );
      print('Created new play');
    }
    _currentPlay!.steps.add(step);
    print('Play now has ${_currentPlay!.steps.length} steps');
    notifyListeners();
  }

  void movePlayer(int playerIndex, double x, double y, {bool snapToGrid = true}) {
    print('\n=== Moving Player ===');
    print('Player Index: $playerIndex');
    print('Target Position: ($x, $y)');
    print('Snap to Grid: $snapToGrid');
    
    if (playerIndex < 0 || playerIndex >= _players.length) {
      print('Invalid player index!');
      return;
    }

    Position? originalPos = _players[playerIndex].position;
    
    if (snapToGrid) {
      final nearestSnap = _findNearestSnapPosition(x, y);
      if (nearestSnap != null) {
        print('Snapped from ($x, $y) to (${nearestSnap.x}, ${nearestSnap.y})');
        x = nearestSnap.x;
        y = nearestSnap.y;
      } else {
        print('No snap position found');
      }
    }

    _players[playerIndex].position = Position(x: x, y: y);
    print('Moved player ${_players[playerIndex].number} from (${originalPos.x}, ${originalPos.y}) to ($x, $y)');
    
    if (_isPlayMode) {
      print('\nIn play mode, checking completion...');
      print('Current play: ${_currentPlay?.steps.length ?? 0} steps');
      checkStepCompletion();
    } else {
      print('Not in play mode, skipping completion check');
    }
    
    notifyListeners();
  }

  bool isPlayerInPosition(Player player, PlayStep step) {
    print('\n=== Checking Player Position ===');
    print('Player: ${player.name} (#${player.number})');
    print('Step: $step');
    
    if (step.targetPositionIndex < 0 || step.targetPositionIndex >= _snapPositions.length) {
      print('❌ Invalid target position index: ${step.targetPositionIndex}');
      return false;
    }

    final targetPos = _snapPositions[step.targetPositionIndex];
    const threshold = 0.05; // 5% of court size
    
    final dx = player.position.x - targetPos.x;
    final dy = player.position.y - targetPos.y;
    final distance = sqrt(dx * dx + dy * dy);
    
    print('Position Check:');
    print('  Player pos: (${player.position.x.toStringAsFixed(3)}, ${player.position.y.toStringAsFixed(3)})');
    print('  Target pos: (${targetPos.x.toStringAsFixed(3)}, ${targetPos.y.toStringAsFixed(3)})');
    print('  Distance: ${distance.toStringAsFixed(3)} (threshold: $threshold)');
    print('  Result: ${distance <= threshold ? '✅ In position' : '❌ Not in position'}');
    
    return distance <= threshold;
  }

  void checkStepCompletion() {
    if (_currentPlay == null || !_isPlayMode) return;

    var allStepsComplete = true;
    var anyStepCompleted = false;

    for (final step in _currentPlay!.steps) {
      if (step.isCompleted) continue;

      Player? player;
      try {
        player = _players.firstWhere((p) => p.id == step.playerId);
      } catch (_) {
        continue;  // Skip if player not found
      }

      bool isComplete;
      switch (step.type) {
        case PlayStepType.move:
        case PlayStepType.dribble:
        case PlayStepType.screen:
        case PlayStepType.shoot:
          isComplete = isPlayerInPosition(player, step);
          break;
      }

      if (isComplete && !step.isCompleted) {
        step.isCompleted = true;
        anyStepCompleted = true;
      }

      if (!isComplete) {
        allStepsComplete = false;
      }
    }

    // If any step was completed or all steps are complete, notify listeners
    if (anyStepCompleted) {
      if (allStepsComplete) {
        _isPlayMode = false;  // End play when all steps complete
      }
      notifyListeners();
    }
  }
}
