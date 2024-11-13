import 'package:json_annotation/json_annotation.dart';

part 'tile.g.dart';

@JsonSerializable(anyMap: true)
class Tile {
  final String id;
  final int value;
  final int index;
  final int? nextIndex;
  final bool merged;

  Tile(this.id, this.value, this.index, {this.nextIndex, this.merged = false});

  //Calculate the current top position based on the current index
  double getTop(double size) {
    var i = ((index + 1) / 4).ceil();
    return ((i - 1) * size) + (12.0 * i);
  }

  //Calculate the current left position based on the current index
  double getLeft(double size) {
    var i = (index - (((index + 1) / 4).ceil() * 4 - 4));
    return (i * size) + (12.0 * (i + 1));
  }

  //Calculate the next top position based on the next index
  double? getNextTop(double size) {
    if (nextIndex == null) return null;
    var i = ((nextIndex! + 1) / 4).ceil();
    return ((i - 1) * size) + (12.0 * i);
  }

  //Calculate the next top position based on the next index
  double? getNextLeft(double size) {
    if (nextIndex == null) return null;
    var i = (nextIndex! - (((nextIndex! + 1) / 4).ceil() * 4 - 4));
    return (i * size) + (12.0 * (i + 1));
  }

  //Create an immutable copy of the tile
  Tile copyWith(
          {String? id, int? value, int? index, int? nextIndex, bool? merged}) =>
      Tile(id ?? this.id, value ?? this.value, index ?? this.index,
          nextIndex: nextIndex ?? this.nextIndex,
          merged: merged ?? this.merged);

  //Create a Tile from json data
  factory Tile.fromJson(Map<String, dynamic> json) => _$TileFromJson(json);

  //Generate json data from the Tile
  Map<String, dynamic> toJson() => _$TileToJson(this);
}