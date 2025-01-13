import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../models/game_state.dart';

class BasketballCourt extends StatefulWidget {
  @override
  _BasketballCourtState createState() => _BasketballCourtState();
}

class _BasketballCourtState extends State<BasketballCourt> {
  String? selectedPlayerId;
  final FocusNode _focusNode = FocusNode();
  static const double _moveStep = 0.02;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _movePlayer(GameState gameState, String direction) {
    if (selectedPlayerId != null) {
      final player = gameState.players.firstWhere(
        (p) => p.id == selectedPlayerId,
        orElse: () => null as Player,
      );

      if (player != null) {
        double newX = player.x;
        double newY = player.y;

        switch (direction) {
          case 'left':
            newX = (player.x - _moveStep).clamp(0.0, 1.0);
            break;
          case 'right':
            newX = (player.x + _moveStep).clamp(0.0, 1.0);
            break;
          case 'up':
            newY = (player.y - _moveStep).clamp(0.0, 1.0);
            break;
          case 'down':
            newY = (player.y + _moveStep).clamp(0.0, 1.0);
            break;
        }

        if (newX != player.x || newY != player.y) {
          print('Moving player to ($newX, $newY)'); // Debug print
          gameState.updatePlayerPosition(player.id, newX, newY);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKey: (node, event) {
            if (event is RawKeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                _movePlayer(gameState, 'left');
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                _movePlayer(gameState, 'right');
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                _movePlayer(gameState, 'up');
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                _movePlayer(gameState, 'down');
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTapDown: (details) {
                _focusNode.requestFocus();
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(details.globalPosition);
                final x = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
                final y = (localPosition.dy / box.size.height).clamp(0.0, 1.0);

                double minDistance = double.infinity;
                String? nearestPlayerId;

                for (final player in gameState.players) {
                  final distance = _calculateDistance(
                    player.x,
                    player.y,
                    x,
                    y,
                  );
                  if (distance < minDistance) {
                    minDistance = distance;
                    nearestPlayerId = player.id;
                  }
                }

                setState(() {
                  selectedPlayerId = nearestPlayerId;
                });
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: CourtPainter(),
                        ),
                        ...gameState.players.map((player) {
                          final isSelected = player.id == selectedPlayerId;
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
                        if (selectedPlayerId != null)
                          Positioned(
                            left: 10,
                            top: 10,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Use arrow keys to move the selected player',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  double _calculateDistance(double x1, double y1, double x2, double y2) {
    return ((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
  }
}

class PlayerWidget extends StatelessWidget {
  final Player player;
  final bool isSelected;

  const PlayerWidget({
    Key? key,
    required this.player,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.white,
              width: isSelected ? 3 : 2,
            ),
            boxShadow: [
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
              player.role,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            player.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isSelected ? Colors.blue : Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

class CourtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Use the full screen height
    final courtWidth = size.width;
    final courtHeight = size.height;

    // Create a clip rect for the court
    canvas.clipRect(Rect.fromLTWH(0, 0, courtWidth, courtHeight));

    // Draw main court outline
    canvas.drawRect(Rect.fromLTWH(0, 0, courtWidth, courtHeight), paint);

    // Draw center line
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

    // Draw left half
    _drawHalfCourt(
      canvas, 
      paint,
      Rect.fromLTWH(0, 0, courtWidth / 2, courtHeight),
      true
    );

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
