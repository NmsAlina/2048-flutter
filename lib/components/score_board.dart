import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twenty_forty_eight/constants/colors.dart';
import 'package:twenty_forty_eight/helpers/board_helper.dart';

class ScoreBoard extends ConsumerWidget {
  const ScoreBoard({Key? key, required this.isLightMode}) : super(key: key);
    final bool isLightMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(boardManager.select((board) => board.score));
    final best = ref.watch(boardManager.select((board) => board.best));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Score(label: 'Score', score: '$score', isLightMode: isLightMode),
        const SizedBox(
          width: 8.0,
        ),
        Score(
          label: 'Best',
          score: '$best',
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          isLightMode: isLightMode, 
        ),
      ],
    );
  }
}

class Score extends StatelessWidget {
  const Score({
    Key? key,
    required this.label,
    required this.score,
    this.padding,
    required this.isLightMode,
  }) : super(key: key);

  final String label;
  final String score;
  final EdgeInsets? padding;
  final bool isLightMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isLightMode ? scoreColor : scoreColorDark,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 18.0,
              color: isLightMode ? Colors.black : Colors.white,
            ),
          ),
          Text(
            score,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
            ),
          ),
        ],
      ),
    );
  }
}