import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';

class BasketballCourt extends StatefulWidget {
  final bool isFullCourt;
  final bool isAddingSnapPositions;
  final int? selectedPlayerId;
  final Function(int?)? onPlayerSelected;

  const BasketballCourt({
    super.key,
    this.isFullCourt = true,
    this.isAddingSnapPositions = false,
    this.selectedPlayerId,
    this.onPlayerSelected,
  });

  @override
  _BasketballCourtState createState() => _BasketballCourtState();
}

class _BasketballCourtState extends State<BasketballCourt> {
  final FocusNode _focusNode = FocusNode();
  Timer? _moveTimer;
  Set<LogicalKeyboardKey> _pressedKeys = {};
  Map<int, bool> _hoverStates = {};  // Track hover state for each snap position

  // Movement speed is now relative to court dimensions
  double get _moveStepX => 0.003;  // 0.3% of court width per step
  double get _moveStepY => 0.003 * 1.9;  // Adjusted for court aspect ratio (1.9)

  @override
  void didUpdateWidget(BasketballCourt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAddingSnapPositions != widget.isAddingSnapPositions) {
      setState(() {
        _hoverStates.clear(); // Clear hover states when toggling edit mode
      });
    }
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
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
    double newX = player.x;
    double newY = player.y;

    switch (direction) {
      case 'left':
        newX -= _moveStepX;
        break;
      case 'right':
        newX += _moveStepX;
        break;
      case 'up':
        newY -= _moveStepY;
        break;
      case 'down':
        newY += _moveStepY;
        break;
    }

    // Clamp values to court boundaries
    newX = newX.clamp(0.0, 1.0);
    newY = newY.clamp(0.0, 1.0);

    gameState.updatePlayerPosition(widget.selectedPlayerId!, newX, newY);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (widget.isAddingSnapPositions) return KeyEventResult.ignored;
        
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          _pressedKeys.add(event.logicalKey);
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _startMovingPlayer(gameState, 'left');
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _startMovingPlayer(gameState, 'right');
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _startMovingPlayer(gameState, 'up');
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _startMovingPlayer(gameState, 'down');
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
      },
      child: Stack(
        children: [
          GestureDetector(
            onTapDown: (details) {
              if (widget.isAddingSnapPositions) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(details.globalPosition);
                final x = localPosition.dx / box.size.width;
                final y = localPosition.dy / box.size.height;

                // Check if we're clicking on a delete button
                bool clickedOnDelete = false;
                for (var entry in gameState.snapPositions.asMap().entries) {
                  final snapX = entry.value.x * box.size.width;
                  final snapY = entry.value.y * box.size.height;
                  // Calculate distance from click to delete button center
                  final deleteX = snapX;  // Center of delete button
                  final deleteY = snapY;  // Center of delete button
                  final dx = localPosition.dx - deleteX;
                  final dy = localPosition.dy - deleteY;
                  final distance = sqrt(dx * dx + dy * dy);
                  
                  if (distance <= 24) {  // Increased radius to cover the entire button
                    setState(() {
                      _hoverStates.clear(); // Clear all hover states when removing a snap position
                    });
                    gameState.removeSnapPosition(entry.key);
                    clickedOnDelete = true;
                    break;
                  }
                }

                // Only add new snap position if we didn't click on a delete button
                if (!clickedOnDelete) {
                  setState(() {
                    // Get the next index that will be used for the new snap position
                    final newIndex = gameState.snapPositions.length;
                    _hoverStates[newIndex] = false;
                  });
                  gameState.addSnapPosition(x, y);
                }
              } else {
                // Select nearest player when clicking
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(details.globalPosition);
                final x = localPosition.dx / box.size.width;
                final y = localPosition.dy / box.size.height;

                double minDistance = double.infinity;
                int? nearestPlayerId;

                for (final player in gameState.players) {
                  final distance = _calculateDistance(player.x, player.y, x, y);
                  if (distance < minDistance) {
                    minDistance = distance;
                    nearestPlayerId = player.id;
                  }
                }

                widget.onPlayerSelected?.call(nearestPlayerId);
              }
              _focusNode.requestFocus();
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
                      child: CustomPaint(
                        painter: CourtPainter(isFullCourt: widget.isFullCourt),
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                      ),
                    ),
                    if (widget.isAddingSnapPositions)
                      Container(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        color: Colors.black.withOpacity(0.1),
                      ),
                    if (gameState.showSnapPositions)
                      ...gameState.snapPositions.asMap().entries.map((entry) {
                        return Positioned(
                          left: entry.value.x * constraints.maxWidth - 12,
                          top: entry.value.y * constraints.maxHeight - 12,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.5),
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                              ),
                              if (widget.isAddingSnapPositions)
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  onEnter: (_) => setState(() => _hoverStates[entry.key] = true),
                                  onExit: (_) => setState(() => _hoverStates[entry.key] = false),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: _hoverStates[entry.key] == true ? Colors.red : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _hoverStates[entry.key] == true ? Colors.transparent : Colors.grey.withOpacity(0.5),
                                        width: 2,
                                      ),
                                      boxShadow: _hoverStates[entry.key] == true ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          spreadRadius: 1,
                                          blurRadius: 2,
                                        ),
                                      ] : [],
                                    ),
                                    child: _hoverStates[entry.key] == true ? const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ) : null,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ...gameState.players.map((player) {
                      if (widget.isAddingSnapPositions) return const SizedBox.shrink();
                      final isSelected = player.id == widget.selectedPlayerId;
                      return Positioned(
                        left: player.x * constraints.maxWidth - 20,
                        top: player.y * constraints.maxHeight - 20,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.move,
                          child: Draggable(
                            feedback: Material(
                              color: Colors.transparent,
                              child: PlayerWidget(
                                player: player,
                                isSelected: isSelected,
                              ),
                            ),
                            childWhenDragging: Container(),
                            child: PlayerWidget(
                              player: player,
                              isSelected: isSelected,
                            ),
                            onDragEnd: (details) {
                              final RenderBox box = context.findRenderObject() as RenderBox;
                              final localPosition = box.globalToLocal(details.offset);
                              final x = ((localPosition.dx + 20) / constraints.maxWidth).clamp(0.0, 1.0);
                              final y = ((localPosition.dy + 20) / constraints.maxHeight).clamp(0.0, 1.0);
                              gameState.updatePlayerPosition(player.id, x, y);
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
          if (widget.isAddingSnapPositions)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Edit Mode: Click to add positions',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _calculateDistance(double x1, double y1, double x2, double y2) {
    return sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
  }
}

class PlayerWidget extends StatelessWidget {
  final Player player;
  final bool isSelected;

  const PlayerWidget({
    super.key,
    required this.player,
    this.isSelected = false,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: player.color,
              border: Border.all(
                color: isSelected ? Colors.yellow : Colors.white,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.3),
                    spreadRadius: 4,
                    blurRadius: 4,
                  ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '#${player.number}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              player.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CourtPainter extends CustomPainter {
  final bool isFullCourt;

  CourtPainter({
    this.isFullCourt = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Add margins to the court dimensions
    final margin = 20.0;  // Add 20 pixels of margin
    final courtWidth = (isFullCourt ? size.width : size.width * 0.6) - (margin * 2);  // Subtract margins
    final courtHeight = size.height - (margin * 2);  // Subtract margins

    // Translate the canvas to create the margin space
    canvas.translate(margin, margin);

    // Center the court horizontally if it's half court
    if (!isFullCourt) {
      canvas.translate((size.width - courtWidth - margin * 2) / 2, 0);
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
      final centerY = courtHeight / 2;
      final centerCircleRadius = courtWidth * 0.06;
      canvas.drawCircle(
        Offset(centerX, centerY),
        centerCircleRadius,
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

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
