import 'package:json_annotation/json_annotation.dart';

import 'package:twenty_forty_eight/models/tile.dart';

part 'board.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class Board {
  final int score;
  final int best;
  final List<Tile> tiles;
  final bool over;
  final bool won;

  Board(this.score, this.best, this.tiles,
      {this.over = false, this.won = false});

  Board.newGame(this.best, this.tiles)
      : score = 0,
        over = false,
        won = false;

  Board copyWith(
          {int? score,
          int? best,
          List<Tile>? tiles,
          bool? over,
          bool? won,
}) =>
      Board(score ?? this.score, best ?? this.best, tiles ?? this.tiles,
          over: over ?? this.over,
          won: won ?? this.won);

  //Create a Board from json data
  factory Board.fromJson(Map<String, dynamic> json) => _$BoardFromJson(json);

  //Generate json data from the Board
  Map<String, dynamic> toJson() => _$BoardToJson(this);
}