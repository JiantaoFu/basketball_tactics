import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';

class PlayControlPanel extends StatelessWidget {
  const PlayControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final currentPlay = gameState.currentPlay;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.sports_basketball),
              const SizedBox(width: 8),
              Text(
                'Pick and Roll Play',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!gameState.isPlayMode) ...[
            ElevatedButton.icon(
              onPressed: () {
                if (gameState.plays.isEmpty) {
                  gameState.createPickAndRollPlay();
                }
                if (gameState.plays.isNotEmpty) {
                  gameState.startPlay(gameState.plays.first);
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Play'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ] else ...[
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => gameState.resetPlay(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => gameState.endPlay(),
                  icon: const Icon(Icons.stop),
                  label: const Text('End'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            if (currentPlay != null && currentPlay.currentStep != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step ${currentPlay.currentStepIndex + 1} of ${currentPlay.steps.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getStepDescription(currentPlay.currentStep!),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _getStepDescription(PlayStep step) {
    final playerDesc = 'Player #${step.playerId}';
    switch (step.type) {
      case PlayStepType.move:
        return '$playerDesc: Move to position';
      case PlayStepType.screen:
        return '$playerDesc: Set screen';
      case PlayStepType.dribble:
        return '$playerDesc: Dribble to position';
      case PlayStepType.shoot:
        return '$playerDesc: Shoot';
    }
  }
}
