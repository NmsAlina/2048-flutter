import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:twenty_forty_eight/helpers/next_move.dart';
import 'package:twenty_forty_eight/helpers/round.dart';
import 'package:twenty_forty_eight/models/board.dart';
import 'package:twenty_forty_eight/models/tile.dart';




class BoardManager extends StateNotifier<Board> {
  // We will use this list to retrieve the right index when user swipes up/down
  // which will allow us to reuse most of the logic.
  final verticalOrder = [12, 8, 4, 0, 13, 9, 5, 1, 14, 10, 6, 2, 15, 11, 7, 3];

  final StateNotifierProviderRef ref;
  BoardManager(this.ref) : super(Board.newGame(0, [])) {
    load();
  }

  void load() async {
    var box = await Hive.openBox<Board>('boardBox');
    state = box.get(0) ?? _newGame();
  }

  // Create New Game state.
  Board _newGame() {
    List<Tile> startingTiles = [];
    List<int> indexes = [];

    // Generate 3 to 4 tiles and place them randomly on the board
    for (int i = 0; i < Random().nextInt(2) + 3; i++) {
      // Generate a random index for the tile
      var index = _random(indexes);
      // Generate a random value for the tile (2 or 4)
      var tileValue = Random().nextInt(2) == 0 ? 2 : 4;
      // Add new tiles
      startingTiles.add(Tile(const Uuid().v4(), tileValue, index));
      // Add index to the used indexes list
      indexes.add(index);
    }

    // Calculate the new total score
    int newBestScore = state.best;
    if (state.score > state.best) {
      newBestScore = state.score;
    }

    return Board.newGame(newBestScore, startingTiles);
  }

  // Generate a random index that is not already used
  int _random(List<int> indexes) {
    var rng = Random();
    int index;
    do {
      index = rng.nextInt(16);
    } while (indexes.contains(index));
    return index;
  }


  void newGame() {
    state = _newGame();
  }

  // Check whether the indexes are in the same row or column in the board.
  bool _inRange(index, nextIndex) {
    return index < 4 && nextIndex < 4 ||
      index >= 4 && index < 8 && nextIndex >= 4 && nextIndex < 8 ||
      index >= 8 && index < 12 && nextIndex >= 8 && nextIndex < 12 ||
      index >= 12 && nextIndex >= 12;
  }

  Tile _calculate(Tile tile, List<Tile> tiles, direction) {
    bool asc =
        direction == SwipeDirection.left || direction == SwipeDirection.up;
    bool vert =
        direction == SwipeDirection.up || direction == SwipeDirection.down;
    // Get the first index from the left in the row
    // Example: for left swipe that can be: 0, 4, 8, 12
    // for right swipe that can be: 3, 7, 11, 15
    // depending which row in the column in the board we need
    // let's say the title.index = 6 (which is the 3rd tile from the left and 2nd from right side, 
    // in the second row)
    // ceil means it will ALWAYS round up to the next largest integer
    // NOTE: don't confuse ceil it with floor or round as even if the value is 2.1 output would be 3.
    // ((6 + 1) / 4) = 1.75
    // Ceil(1.75) = 2
    // If it's ascending: 2 * 4 – 4 = 4, which is the first index from the left side in the second row
    // If it's descending: 2 * 4 – 1 = 7, which is the last index from the left side and 
    // first index from the right side in the second row
    // If user swipes vertically use the verticalOrder list to retrieve the up/down index 
    // else use the existing index
    int index = vert ? verticalOrder[tile.index] : tile.index;
    int nextIndex = ((index + 1) / 4).ceil() * 4 - (asc ? 4 : 1);

    // If the list of the new tiles to be rendered is not empty get the last tile
    // and if that tile is in the same row as the curren tile set the next index for the current tile 
    // to be after the last tile
    if (tiles.isNotEmpty) {
      var last = tiles.last;
      var lastIndex = last.nextIndex ?? last.index;
      lastIndex = vert ? verticalOrder[lastIndex] : lastIndex;
      if (_inRange(index, lastIndex)) {
        nextIndex = lastIndex + (asc ? 1 : -1);
      }
    }

    // Return immutable copy of the current tile with the new next index
    return tile.copyWith(
        nextIndex: vert ? verticalOrder.indexOf(nextIndex) : nextIndex);
  }

  bool move(SwipeDirection direction) {
    bool asc =
        direction == SwipeDirection.left || direction == SwipeDirection.up;
    bool vert =
        direction == SwipeDirection.up || direction == SwipeDirection.down;
    state.tiles.sort(((a, b) =>
        (asc ? 1 : -1) *
        (vert
            ? verticalOrder[a.index].compareTo(verticalOrder[b.index])
            : a.index.compareTo(b.index))));

    List<Tile> tiles = [];

    for (int i = 0, l = state.tiles.length; i < l; i++) {
      var tile = state.tiles[i];

      tile = _calculate(tile, tiles, direction);
      tiles.add(tile);

      if (i + 1 < l) {
        var next = state.tiles[i + 1];
        if (tile.value == next.value) {
          var index = vert ? verticalOrder[tile.index] : tile.index,
              nextIndex = vert ? verticalOrder[next.index] : next.index;
          if (_inRange(index, nextIndex)) {
            tiles.add(next.copyWith(nextIndex: tile.nextIndex));
            i += 1;
            continue;
          }
        }
      }
    }

    // Assign immutable copy of the new board state and trigger rebuild.
    state = state.copyWith(tiles: tiles);
    return true;
  }

  // Generates tiles at random place on the board
  Tile random(List<int> indexes) {
    var i = 0;
    var rng = Random();
    do {
      i = rng.nextInt(16);
    } while (indexes.contains(i));

    return Tile(const Uuid().v4(), 2, i);
  }

  //Merge tiles
  void merge() {
    List<Tile> tiles = [];
    var tilesMoved = false;
    List<int> indexes = [];
    var score = state.score;

    for (int i = 0, l = state.tiles.length; i < l; i++) {
      var tile = state.tiles[i];

      var value = tile.value, merged = false;

      if (i + 1 < l) {
        //sum the number of the two tiles with same index and mark the tile as merged and skip the next iteration.
        var next = state.tiles[i + 1];
        if (tile.nextIndex == next.nextIndex ||
            tile.index == next.nextIndex && tile.nextIndex == null) {
          value = tile.value + next.value;
          merged = true;
          score += tile.value;
          i += 1;
        }
      }

      if (merged || tile.nextIndex != null && tile.index != tile.nextIndex) {
        tilesMoved = true;
      }

      tiles.add(tile.copyWith(
          index: tile.nextIndex ?? tile.index,
          nextIndex: null,
          value: value,
          merged: merged));
      indexes.add(tiles.last.index);
    }

    // If tiles got moved then generate a new tile at random position of the available positions 
    // on the board.
    if (tilesMoved) {
      tiles.add(random(indexes));
    }
    state = state.copyWith(score: score, tiles: tiles);
  }

  //Finish round, win or loose the game.
  void _endRound() {
    var gameOver = true, gameWon = false;
    List<Tile> tiles = [];

    // If there is no more empty place on the board
    if (state.tiles.length < 16) {
      state.tiles.sort(((a, b) => a.index.compareTo(b.index)));

      for (int i = 0, l = state.tiles.length; i < l; i++) {
        var tile = state.tiles[i];

        if (tile.value == 2048) {
          gameWon = true;
        }

        var x = (i - (((i + 1) / 4).ceil() * 4 - 4));

        if (x > 0 && i - 1 >= 0) {
          //If tile can be merged with left tile then game is not lost.
          var left = state.tiles[i - 1];
          if (tile.value == left.value) {
            gameOver = false;
          }
        }

        if (x < 3 && i + 1 < l) {
          //If tile can be merged with right tile then game is not lost.
          var right = state.tiles[i + 1];
          if (tile.value == right.value) {
            gameOver = false;
          }
        }

        if (i - 4 >= 0) {
          //If tile can be merged with above tile then game is not lost.
          var top = state.tiles[i - 4];
          if (tile.value == top.value) {
            gameOver = false;
          }
        }

        if (i + 4 < l) {
          //If tile can be merged with the bellow tile then game is not lost.
          var bottom = state.tiles[i + 4];
          if (tile.value == bottom.value) {
            gameOver = false;
          }
        }

        tiles.add(tile.copyWith(merged: false));
      }
    } else {
      // If there are empty places on the board, the game is not over
      gameOver = false;
      for (var tile in state.tiles) {
        tiles.add(tile.copyWith(merged: false));
        if (tile.value == 2048) {
          gameWon = true;
        }
      }
    }

    state = state.copyWith(tiles: tiles, won: gameWon, over: gameOver);
  }


  //Mark the merged as false after the merge animation is complete.
  bool endRound() {
    _endRound();
    ref.read(roundManager.notifier).end();

    // If player moved too fast before the current animation/transition finished, 
    // start the move for the next direction
    var nextDirection = ref.read(nextDirectionManager);
    if (nextDirection != null) {
      move(nextDirection);
      ref.read(nextDirectionManager.notifier).clear();
      return true;
    }
    return false;
  }


//Move the tiles using the arrow keys on the keyboard.
  bool onKey(KeyEvent event) {
    SwipeDirection? direction;
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        direction = SwipeDirection.right;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        direction = SwipeDirection.left;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        direction = SwipeDirection.up;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        direction = SwipeDirection.down;
      }
    }

    if (direction != null) {
      move(direction);
      return true;
    }
    return false;
  }

  void save() async {
    //Here we don't need to call toJson function of the board model
    //in order to convert the data to json
    //instead the adapter we added earlier will do that automatically.
    var box = await Hive.openBox<Board>('boardBox');
    try {
      box.putAt(0, state);
    } catch (e) {
      box.add(state);
    }
  }
}

final boardManager = StateNotifierProvider<BoardManager, Board>((ref) {
  return BoardManager(ref);
});