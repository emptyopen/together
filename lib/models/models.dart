import 'package:flutter/material.dart';

class Word {

  Word({this.name, this.flipped, this.flippedTurns, this.color});

  String name;
  bool flipped;
  int flippedTurns;
  String color;

  Word.fromJson(Map<String, dynamic> json)
      : name = json['name'],
      flipped = json['flipped'],
      flippedTurns = json['flippedTurns'],
      color = json['color'];

  Map<String, dynamic> toJson() =>
    {
      'name': name,
      'flipped': flipped,
      'flippedTurns': flippedTurns,
      'color': color,
    };
}

class RowList {

  RowList();

  List<dynamic> rowWords = [];

  add(String word) {
    rowWords.add(Word(name: word, flipped: false, flippedTurns: 0, color: 'grey').toJson());
  }

  RowList.fromJson(Map<String, dynamic> json)
      : rowWords = json['rowWords'];

  Map<String, dynamic> toJson() =>
    {
      'rowWords': rowWords
    };
}

class Coords {

  Coords({this.x, this.y});

  int x;
  int y;

  Coords.fromJson(Map<String, dynamic> json)
      : x = json['x'],
      y = json['y'];

  Map<String, dynamic> toJson() =>
    {
      'x': x,
      'y': y,
    };

  bool operator == (o) => o is Coords && o.x == x && o.y == y;

  int get hashCode => x.hashCode ^ y.hashCode;

}

class RoundPrompts {

  RoundPrompts();

  List<String> prompts = [];

  add(String word) {
    prompts.add(word);
  }

  RoundPrompts.fromJson(Map<String, dynamic> json)
      : prompts = json['prompts'];

  Map<String, dynamic> toJson() =>
    {
      'prompts': prompts
    };
}

class DrawingPoint {
  Paint paint;
  Offset point;
  
  DrawingPoint({this.point, this.paint});

  DrawingPoint.fromJson(Map<String, dynamic> json)
      : paint = json['paint'],
      point = json['points'];

  Map<String, dynamic> toJson() =>
    {
      'paint': paint,
      'points': point,
    };
}