import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart'; // Import flutter/foundation.dart for listEquals
import 'package:provider/provider.dart';
import '../models/game_state.dart';

class BasketballCourt extends StatefulWidget {
  final bool isFullCourt;
  final bool isAddingSnapPositions;
  final bool isCreatingPaths;
  final int? selectedPlayerId;
  final Function(int?)? onPlayerSelected;
  final Function(Player, double, double)? onPlayerMoved;

  const BasketballCourt({
    super.key,
    this.isFullCourt = true,
    this.isAddingSnapPositions = false,
    this.isCreatingPaths = false,
    this.selectedPlayerId,
    this.onPlayerSelected,
    this.onPlayerMoved,
  });

  @override
  State<BasketballCourt> createState() => _BasketballCourtState();
}

class _BasketballCourtState extends State<BasketballCourt> {
  final FocusNode _focusNode = FocusNode();
  Timer? _moveTimer;
  Set<LogicalKeyboardKey> _pressedKeys = {};
  final Map<int, bool> _hoverStates = {};
  final Map<int, Offset> _dragOffsets = {};

  void _onTapUp(TapUpDetails details) {
    final gameState = context.read<GameState>();
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);

    if (widget.isAddingSnapPositions) {
      _handleAddSnapPosition(localPosition);
    } else if (widget.isCreatingPaths) {
      _handlePathCreation(localPosition);
    }
  }

  void _handleAddSnapPosition(Offset localPosition) {
    final gameState = context.read<GameState>();
    final RenderBox box = context.findRenderObject() as RenderBox;
  
    final x = localPosition.dx / box.size.width;
    final y = localPosition.dy / box.size.height;

    bool clickedOnDelete = false;
    
    // Check if we clicked on a delete button
    if (gameState.showSnapPositions) {
      for (var entry in gameState.snapPositions.asMap().entries) {
        final snapX = entry.value.x * box.size.width;
        final snapY = entry.value.y * box.size.height;
        final dx = localPosition.dx - snapX;
        final dy = localPosition.dy - snapY;
        final distance = sqrt(dx * dx + dy * dy);
        
        if (distance <= CourtPainter.kSnapPositionHalfSize) {
          setState(() {
            _hoverStates.clear();
          });
          gameState.removeSnapPosition(entry.key);
          clickedOnDelete = true;
          break;
        }
      }
    }

    // Only add new position if we didn't click on a delete button
    if (!clickedOnDelete) {
      setState(() {
        final newIndex = gameState.snapPositions.length;
        _hoverStates[newIndex] = false;
      });
      gameState.addSnapPosition(x, y);
    }
  }

  void _handlePathCreation(Offset localPosition) {
    final gameState = context.read<GameState>();
    
    // Only proceed if we're in path creation mode
    if (!widget.isCreatingPaths) {
      return;
    }
    
    // Only allow path creation if a player is selected
    if (widget.selectedPlayerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a player first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Find the closest snap position
    int? closestIndex;
    double minDistance = double.infinity;
    final RenderBox box = context.findRenderObject() as RenderBox;

    for (var entry in gameState.snapPositions.asMap().entries) {
      final snapX = entry.value.x * box.size.width;
      final snapY = entry.value.y * box.size.height;
      final dx = localPosition.dx - snapX;
      final dy = localPosition.dy - snapY;
      final distance = sqrt(dx * dx + dy * dy);
      
      if (distance <= CourtPainter.kSnapPositionHalfSize && distance < minDistance) {
        minDistance = distance;
        closestIndex = entry.key;
      }
    }

    if (closestIndex != null) {
      print('Selected position: $closestIndex'); // Debug print
      // Start path creation if needed
      if (!gameState.isCreatingPath) {
        gameState.startPathCreation();
      }
      gameState.selectPathPosition(closestIndex);
    }
  }

  Widget _buildCourt(GameState gameState, BoxConstraints constraints) {
    return CustomPaint(
      painter: CourtPainter(
        isFullCourt: widget.isFullCourt,
        snapPositions: gameState.snapPositions,
        movementPaths: gameState.movementPaths,
        showSnapPositions: gameState.showSnapPositions || widget.isAddingSnapPositions || widget.isCreatingPaths,
        isCreatingPath: widget.isCreatingPaths,
        pathStartIndex: gameState.pathStartPositionIndex,
        selectedPlayerId: widget.selectedPlayerId,
        playSteps: gameState.playSteps ?? [], // Provide empty list as fallback
      ),
      size: Size(constraints.maxWidth, constraints.maxHeight),
    );
  }

  List<Widget> _buildSnapPositions(GameState gameState, BoxConstraints constraints) {
    if (!gameState.showSnapPositions && !widget.isAddingSnapPositions && !widget.isCreatingPaths) {
      return [];
    }

    return gameState.snapPositions.asMap().entries.map((entry) {
      final index = entry.key;
      final pos = entry.value;
      return Positioned(
        left: pos.x * constraints.maxWidth - CourtPainter.kSnapPositionHalfSize,
        top: pos.y * constraints.maxHeight - CourtPainter.kSnapPositionHalfSize,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hoverStates[index] = true),
          onExit: (_) => setState(() => _hoverStates[index] = false),
          child: Container(
            width: CourtPainter.kSnapPositionSize,
            height: CourtPainter.kSnapPositionSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isCreatingPaths
                  ? (gameState.pathStartPositionIndex == index
                      ? Colors.orange
                      : Colors.blue.withOpacity(0.3))
                  : (_hoverStates[index] == true
                      ? Colors.red.withOpacity(0.3)
                      : Colors.transparent),
              border: Border.all(
                color: widget.isCreatingPaths
                    ? Colors.blue
                    : Colors.blue.withOpacity(0.6),
                width: 2,
              ),
            ),
            child: widget.isAddingSnapPositions && _hoverStates[index] == true
                ? const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.red,
                  )
                : null,
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildPlayers(GameState gameState, BoxConstraints constraints) {
    return gameState.players.map((player) {
      return Positioned(
        left: player.position.x * constraints.maxWidth - CourtPainter.kPlayerHalfSize,
        top: player.position.y * constraints.maxHeight - CourtPainter.kPlayerHalfSize,
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: GestureDetector(
            onTap: () {
              if (widget.onPlayerSelected != null) {
                widget.onPlayerSelected!(player.id == widget.selectedPlayerId ? null : player.id);
              }
            },
            onPanStart: (details) {
              final grabOffsetX = details.localPosition.dx - CourtPainter.kPlayerHalfSize;
              final grabOffsetY = details.localPosition.dy - CourtPainter.kPlayerHalfSize;
              setState(() {
                _dragOffsets[player.id] = Offset(grabOffsetX, grabOffsetY);
              });
              if (widget.onPlayerSelected != null) {
                widget.onPlayerSelected!(player.id);
              }
            },
            onPanUpdate: (details) {
              final box = context.findRenderObject() as RenderBox;
              final grabOffset = _dragOffsets[player.id] ?? Offset.zero;
              final position = box.globalToLocal(details.globalPosition);
              
              final adjustedX = position.dx - grabOffset.dx;
              final adjustedY = position.dy - grabOffset.dy;
              
              final x = (adjustedX / box.size.width).clamp(0.0, 1.0);
              final y = (adjustedY / box.size.height).clamp(0.0, 1.0);
              
              context.read<GameState>().updatePlayerPosition(player.id, x, y);
              if (widget.onPlayerMoved != null) {
                widget.onPlayerMoved!(player, x, y);
              }
            },
            onPanEnd: (details) {
              setState(() {
                _dragOffsets.remove(player.id);
              });
            },
            child: PlayerWidget(
              player: player,
              isSelected: gameState.selectedPlayerId == player.id,
              gameState: gameState, // Pass GameState to PlayerWidget
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTapUp: _onTapUp,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildCourt(gameState, constraints),
                      ..._buildSnapPositions(gameState, constraints),
                      ..._buildPlayers(gameState, constraints),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (widget.isAddingSnapPositions) return KeyEventResult.ignored;
    
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      _pressedKeys.add(event.logicalKey);
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _startMovingPlayer(context.read<GameState>(), 'left');
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _startMovingPlayer(context.read<GameState>(), 'right');
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _startMovingPlayer(context.read<GameState>(), 'up');
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _startMovingPlayer(context.read<GameState>(), 'down');
        return KeyEventResult.handled;
      }
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
      if (_pressedKeys.isEmpty) {
        _stopMovingPlayer();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _startMovingPlayer(GameState gameState, String direction) {
    _movePlayer(gameState, direction);
    _moveTimer?.cancel();
    _moveTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _movePlayer(gameState, direction);
    });
  }

  void _stopMovingPlayer() {
    _moveTimer?.cancel();
    _moveTimer = null;
  }

  void _movePlayer(GameState gameState, String direction) {
    if (widget.selectedPlayerId == null || widget.isAddingSnapPositions) return;

    final playerIndex = gameState.players.indexWhere((p) => p.id == widget.selectedPlayerId);
    if (playerIndex == -1) return;

    final player = gameState.players[playerIndex];
    double newX = player.position.x;
    double newY = player.position.y;

    switch (direction) {
      case 'left':
        newX -= 0.003;
        break;
      case 'right':
        newX += 0.003;
        break;
      case 'up':
        newY -= 0.003 * 1.9;
        break;
      case 'down':
        newY += 0.003 * 1.9;
        break;
    }

    // Clamp values to court boundaries
    newX = newX.clamp(0.0, 1.0);
    newY = newY.clamp(0.0, 1.0);

    gameState.updatePlayerPosition(widget.selectedPlayerId!, newX, newY);
    if (widget.onPlayerMoved != null) {
      widget.onPlayerMoved!(player, newX, newY);
    }
  }
}

class PlayerWidget extends StatelessWidget {
  final Player player;
  final bool isSelected;
  final GameState gameState;

  const PlayerWidget({
    super.key,
    required this.player,
    required this.isSelected,
    required this.gameState,
  });

  void _showNameEditDialog(BuildContext context) {
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
              final gameState = context.read<GameState>();
              gameState.updatePlayerName(player.id, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () => _showNameEditDialog(context),
      child: CustomPaint(
        painter: PlayerPainter(
          player: player,
          isSelected: isSelected,
          gameState: gameState,
        ),
        child: const SizedBox(
          width: CourtPainter.kPlayerSize,
          height: CourtPainter.kPlayerSize,
        ),
      ),
    );
  }
}

class PlayerPainter extends CustomPainter {
  final Player player;
  final bool isSelected;
  final GameState gameState;

  PlayerPainter({
    required this.player,
    required this.isSelected,
    required this.gameState,
  });

  void _drawPlayer(Canvas canvas, Size size) {
    final x = size.width / 2;   // Center in the widget
    final y = size.height / 2;  // Center in the widget

    // Check if player is in correct position for current play step
    final isInPosition = _isPlayerInPosition(player);
    
    // Draw player circle with feedback color
    final playerPaint = Paint()
      ..color = isSelected 
          ? Colors.blue.withOpacity(0.7)
          : isInPosition != null
              ? (isInPosition ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3))
              : player.team == Team.offense
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3);

    canvas.drawCircle(
      Offset(x, y),
      CourtPainter.kPlayerHalfSize,
      playerPaint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = isSelected ? Colors.yellow : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3 : 2;
    
    canvas.drawCircle(
      Offset(x, y),
      CourtPainter.kPlayerHalfSize,
      borderPaint,
    );

    // Draw player number
    final textPainter = TextPainter(
      text: TextSpan(
        text: player.number.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        x - textPainter.width / 2,
        y - textPainter.height / 2,
      ),
    );
  }

  bool? _isPlayerInPosition(Player player) {
    if (gameState.playSteps.isEmpty) return null;
    
    // Find the current step for this player
    final currentStep = gameState.playSteps.firstWhere(
      (step) => step.playerId == player.number,
      orElse: () => PlayStep(  // Return a dummy step that will result in null
        playerId: -1,
        type: PlayStepType.move,
        targetPositionIndex: -1,
      ),
    );
    
    // If we got the dummy step, return null
    if (currentStep.playerId == -1) return null;

    // Get target position
    if (currentStep.targetPositionIndex < 0 || 
        currentStep.targetPositionIndex >= gameState.snapPositions.length) {
      return null;
    }
    final targetPos = gameState.snapPositions[currentStep.targetPositionIndex];

    // Check if player is close enough to target
    const threshold = 0.05; // 5% of court size
    final dx = player.position.x - targetPos.x;
    final dy = player.position.y - targetPos.y;
    final distance = sqrt(dx * dx + dy * dy);
    
    return distance <= threshold;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawPlayer(canvas, size);
  }

  @override
  bool shouldRepaint(PlayerPainter oldDelegate) {
    return player != oldDelegate.player || 
           isSelected != oldDelegate.isSelected ||
           gameState != oldDelegate.gameState;
  }
}

class CourtPainter extends CustomPainter {
  static const double kSnapPositionSize = 40.0;
  static const double kSnapPositionRadius = 10.0;
  static const double kPlayerSize = 40.0;
  static const double kMargin = 20.0;
  static const double kSnapPositionHalfSize = kSnapPositionSize / 2;
  static const double kPlayerHalfSize = kPlayerSize / 2;

  final bool isFullCourt;
  final List<SnapPosition> snapPositions;
  final List<MovementPath> movementPaths;
  final bool showSnapPositions;
  final bool isCreatingPath;
  final int? pathStartIndex;
  final int? selectedPlayerId;
  final List<PlayStep> playSteps;

  CourtPainter({
    required this.isFullCourt,
    required this.snapPositions,
    required this.movementPaths,
    required this.showSnapPositions,
    required this.isCreatingPath,
    this.pathStartIndex,
    this.selectedPlayerId,
    required this.playSteps,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Add margins to the court dimensions
    final margin = kMargin;
    final courtWidth = (isFullCourt ? size.width : size.width * 0.6) - (kMargin * 2);
    final courtHeight = size.height - (kMargin * 2);

    // Translate canvas to account for margin
    canvas.translate(margin, margin);

    // Center the court horizontally if it's half court
    if (!isFullCourt) {
      canvas.translate((size.width - courtWidth - kMargin * 2) / 2, 0);
    }

    // Create a clip rect for the court
    canvas.clipRect(Rect.fromLTWH(0, 0, courtWidth, courtHeight));

    // Draw main court outline
    canvas.drawRect(Rect.fromLTWH(0, 0, courtWidth, courtHeight), paint);

    // Draw center line only for full court
    if (isFullCourt) {
      final centerX = courtWidth / 2;
      canvas.drawLine(
        Offset(centerX, 0),
        Offset(centerX, courtHeight),
        paint,
      );

      // Draw center circle
      final centerCircleRadius = courtWidth * 0.06;
      canvas.drawCircle(
        Offset(centerX, courtHeight / 2),
        centerCircleRadius,
        paint,
      );
    } else {
      // Draw half circle at the right edge
      final halfCircleRadius = courtWidth * 0.06;
      canvas.drawCircle(
        Offset(courtWidth, courtHeight / 2),
        halfCircleRadius,
        paint,
      );
    }

    // Draw left half
    _drawHalfCourt(
      canvas, 
      paint,
      Rect.fromLTWH(0, 0, courtWidth / (isFullCourt ? 2 : 1), courtHeight),
      true
    );

    // Draw right half only for full court
    if (isFullCourt) {
      // Save the canvas state
      canvas.save();
      
      // Translate to the right edge
      canvas.translate(courtWidth, 0);
      
      // Scale x by -1 to mirror, keep y as 1
      canvas.scale(-1, 1);
      
      // Draw the mirrored left half (which will appear on the right)
      _drawHalfCourt(
        canvas, 
        paint,
        Rect.fromLTWH(0, 0, courtWidth / 2, courtHeight),
        true
      );
      
      // Restore the canvas state
      canvas.restore();
    }

    // Draw movement paths
    if (movementPaths.isNotEmpty) {
      final pathPaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      for (final path in movementPaths) {
        if (path.startPositionIndex < snapPositions.length && 
            path.endPositionIndex < snapPositions.length) {
          final start = snapPositions[path.startPositionIndex];
          final end = snapPositions[path.endPositionIndex];

          // Convert from widget coordinates to translated canvas coordinates
          // Account for both translations:
          // 1. margin translation: (margin, margin)
          // 2. half court centering: ((size.width - courtWidth - margin * 2) / 2, 0)
          final courtWidth = (isFullCourt ? size.width : size.width * 0.6) - (kMargin * 2);
          final halfCourtOffset = !isFullCourt ? (size.width - courtWidth - kMargin * 2) / 2 : 0;

          final startPoint = Offset(
            start.x * size.width - kMargin - halfCourtOffset,
            start.y * size.height - kMargin
          );
          final endPoint = Offset(
            end.x * size.width - kMargin - halfCourtOffset,
            end.y * size.height - kMargin
          );
          
          print('Path ${path.startPositionIndex} -> ${path.endPositionIndex}:');
          print('  Line start: (${startPoint.dx}, ${startPoint.dy})');
          print('  Raw position: (${start.x}, ${start.y})');
          
          // Draw path line
          canvas.drawLine(startPoint, endPoint, pathPaint);
          
          // Draw arrow at end
          final angle = (endPoint - startPoint).direction;
          final arrowSize = 10.0;
          
          final arrowPath = Path()
            ..moveTo(endPoint.dx - arrowSize * cos(angle - pi / 6),
                    endPoint.dy - arrowSize * sin(angle - pi / 6))
            ..lineTo(endPoint.dx, endPoint.dy)
            ..lineTo(endPoint.dx - arrowSize * cos(angle + pi / 6),
                    endPoint.dy - arrowSize * sin(angle + pi / 6))
            ..close();
          
          canvas.drawPath(arrowPath, pathPaint..style = PaintingStyle.fill);
        }
      }
    }

    // Draw play targets
    for (final step in playSteps) {
      _drawPlayTargets(canvas, size, step);
    }
  }

  void _drawPlayTargets(Canvas canvas, Size size, PlayStep step) {
    // Safety check for valid index
    if (step.targetPositionIndex < 0 || step.targetPositionIndex >= snapPositions.length) {
      return;
    }

    final targetPaint = Paint()
      ..color = step.isCompleted 
          ? Colors.green.withOpacity(0.5)  // More visible when complete
          : Colors.green.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final targetStrokePaint = Paint()
      ..color = step.isCompleted ? Colors.green : Colors.green.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = step.isCompleted ? 3 : 2;  // Thicker when complete

    final screenPaint = Paint()
      ..color = step.isCompleted
          ? Colors.orange.withOpacity(0.5)
          : Colors.orange.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    // Get target position from snap positions with safety check
    final targetPos = snapPositions[step.targetPositionIndex];
    final targetX = targetPos.x * size.width;
    final targetY = targetPos.y * size.height;
    
    // Different visualization based on step type
    switch (step.type) {
      case PlayStepType.move:
      case PlayStepType.dribble:
        // Highlight the snap position circle
        canvas.drawCircle(
          Offset(targetX, targetY),
          kSnapPositionRadius * 1.5,
          targetPaint,
        );
        canvas.drawCircle(
          Offset(targetX, targetY),
          kSnapPositionRadius * 1.5,
          targetStrokePaint,
        );
        
        // Draw completion indicator
        if (step.isCompleted) {
          final checkPaint = Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
          
          // Draw checkmark
          final path = Path()
            ..moveTo(targetX - 8, targetY)
            ..lineTo(targetX - 3, targetY + 5)
            ..lineTo(targetX + 8, targetY - 6);
          
          canvas.drawPath(path, checkPaint);
        }
        
        // Draw dotted path line if path indices exist and are valid
        if (step.pathIndices.isNotEmpty) {
          final path = Path();
          var isFirstPoint = true;
          
          for (final index in step.pathIndices) {
            if (index < 0 || index >= snapPositions.length) continue;
            
            final pos = snapPositions[index];
            final x = pos.x * size.width;
            final y = pos.y * size.height;
            
            if (isFirstPoint) {
              path.moveTo(x, y);
              isFirstPoint = false;
            } else {
              path.lineTo(x, y);
            }
          }
          
          // Draw dotted line if path has points
          if (!path.getBounds().isEmpty) {
            final dashPaint = Paint()
              ..color = step.isCompleted ? Colors.green : Colors.green.withOpacity(0.7)
              ..style = PaintingStyle.stroke
              ..strokeWidth = step.isCompleted ? 3 : 2;
            
            _drawDashedLine(canvas, path, dashPaint);
          }
        }
        break;
        
      case PlayStepType.screen:
        // Draw screen position indicator
        final screenRect = Rect.fromCenter(
          center: Offset(targetX, targetY),
          width: kSnapPositionRadius * 2.5,
          height: kSnapPositionRadius * 2.5,
        );
        
        canvas.drawRect(screenRect, screenPaint);
        canvas.drawRect(
          screenRect,
          targetStrokePaint..color = step.isCompleted ? Colors.orange : Colors.orange.withOpacity(0.7),
        );
        
        // Draw screen icon
        final textPainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(Icons.screen_rotation.codePoint),
            style: TextStyle(
              fontSize: 16,
              color: step.isCompleted ? Colors.orange[900] : Colors.orange[700],
              fontFamily: Icons.screen_rotation.fontFamily,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            targetX - textPainter.width / 2,
            targetY - textPainter.height / 2,
          ),
        );

        // Draw completion indicator
        if (step.isCompleted) {
          canvas.drawCircle(
            Offset(targetX + kSnapPositionRadius, targetY - kSnapPositionRadius),
            8,
            Paint()..color = Colors.green,
          );
          
          final checkPaint = Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
          
          final checkPath = Path()
            ..moveTo(targetX + kSnapPositionRadius - 4, targetY - kSnapPositionRadius)
            ..lineTo(targetX + kSnapPositionRadius - 1, targetY - kSnapPositionRadius + 3)
            ..lineTo(targetX + kSnapPositionRadius + 4, targetY - kSnapPositionRadius - 3);
          
          canvas.drawPath(checkPath, checkPaint);
        }
        break;
        
      case PlayStepType.shoot:
        // Draw shooting target
        final shootRect = Rect.fromCenter(
          center: Offset(targetX, targetY),
          width: kSnapPositionRadius * 3,
          height: kSnapPositionRadius * 3,
        );
        
        canvas.drawOval(shootRect, targetPaint);
        canvas.drawOval(
          shootRect,
          targetStrokePaint,
        );
        
        // Draw basketball icon
        final textPainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(Icons.sports_basketball.codePoint),
            style: TextStyle(
              fontSize: 20,
              color: step.isCompleted ? Colors.green[900] : Colors.green[700],
              fontFamily: Icons.sports_basketball.fontFamily,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            targetX - textPainter.width / 2,
            targetY - textPainter.height / 2,
          ),
        );

        // Draw completion indicator
        if (step.isCompleted) {
          canvas.drawCircle(
            Offset(targetX + kSnapPositionRadius * 1.5, targetY - kSnapPositionRadius * 1.5),
            8,
            Paint()..color = Colors.green,
          );
          
          final checkPaint = Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
          
          final checkPath = Path()
            ..moveTo(targetX + kSnapPositionRadius * 1.5 - 4, targetY - kSnapPositionRadius * 1.5)
            ..lineTo(targetX + kSnapPositionRadius * 1.5 - 1, targetY - kSnapPositionRadius * 1.5 + 3)
            ..lineTo(targetX + kSnapPositionRadius * 1.5 + 4, targetY - kSnapPositionRadius * 1.5 - 3);
          
          canvas.drawPath(checkPath, checkPaint);
        }
        break;
    }
  }

  void _drawHalfCourt(Canvas canvas, Paint paint, Rect halfCourt, bool isLeft) {
    final centerY = halfCourt.height / 2;
    final baseX = halfCourt.left;
    
    // Calculate proportions based on the court size
    final keyWidth = halfCourt.height * 0.375;  // Key width proportional to court height
    final keyHeight = halfCourt.width * 0.19;   // Key height proportional to half court width
    final keyY = centerY - (keyWidth / 2);
    
    // Draw key lines
    final keyX = baseX;
    canvas.drawLine(
      Offset(keyX, keyY),
      Offset(keyX + keyHeight, keyY),
      paint,
    );
    canvas.drawLine(
      Offset(keyX, keyY + keyWidth),
      Offset(keyX + keyHeight, keyY + keyWidth),
      paint,
    );
    
    // Draw free throw line
    final freeThrowX = baseX + keyHeight;
    canvas.drawLine(
      Offset(freeThrowX, keyY),
      Offset(freeThrowX, keyY + keyWidth),
      paint,
    );
    
    // Draw free throw circle
    final freeThrowCenter = Offset(freeThrowX, centerY);
    final freeThrowRadius = keyWidth / 2;
    canvas.drawArc(
      Rect.fromCircle(center: freeThrowCenter, radius: freeThrowRadius),
      -pi/2,
      pi,
      false,
      paint,
    );
    
    // Save canvas state before drawing three-point line
    canvas.save();
    
    // Create a clip path for the three-point line
    final clipPath = Path()
      ..addRect(halfCourt);
    canvas.clipPath(clipPath);
    
    // Draw three-point line
    final threePointRadius = halfCourt.width * 0.45;
    final threePointCenter = Offset(baseX, centerY);
    
    // Draw the arc
    canvas.drawArc(
      Rect.fromCircle(center: threePointCenter, radius: threePointRadius),
      -pi/2,
      pi,
      false,
      paint,
    );
    
    // Restore canvas state
    canvas.restore();
    
    // Draw restricted area (no-charge semi-circle)
    final restrictedRadius = keyWidth * 0.2;
    canvas.drawArc(
      Rect.fromCircle(center: threePointCenter, radius: restrictedRadius),
      -pi/2,
      pi,
      false,
      paint,
    );
    
    // Draw lane markers (hash marks)
    final markerLength = keyWidth * 0.05;
    final numMarkers = 4;
    final markerSpacing = keyHeight / (numMarkers + 1);
    
    for (int i = 1; i <= numMarkers; i++) {
      final markerX = baseX + (i * markerSpacing);
      
      // Top marker
      canvas.drawLine(
        Offset(markerX, keyY),
        Offset(markerX, keyY + markerLength),
        paint,
      );
      
      // Bottom marker
      canvas.drawLine(
        Offset(markerX, keyY + keyWidth - markerLength),
        Offset(markerX, keyY + keyWidth),
        paint,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Path path, Paint paint) {
    final dashPath = Path();
    const dashWidth = 10.0;
    const dashSpace = 5.0;
    var distance = 0.0;
    
    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        final start = distance;
        final end = start + dashWidth;
        if (end <= metric.length) {
          dashPath.addPath(
            metric.extractPath(start, end),
            Offset.zero,
          );
        }
        distance = end + dashSpace;
      }
    }
    
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CourtPainter oldDelegate) {
    return isFullCourt != oldDelegate.isFullCourt ||
           !listEquals(snapPositions, oldDelegate.snapPositions) || // Use listEquals for proper list comparison
           !listEquals(movementPaths, oldDelegate.movementPaths) || // Use listEquals for proper list comparison
           showSnapPositions != oldDelegate.showSnapPositions ||
           isCreatingPath != oldDelegate.isCreatingPath ||
           pathStartIndex != oldDelegate.pathStartIndex ||
           selectedPlayerId != oldDelegate.selectedPlayerId ||
           !listEquals(playSteps, oldDelegate.playSteps); // Use listEquals for proper list comparison
  }
}
