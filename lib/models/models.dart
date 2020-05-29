class Word {

  Word({this.name, this.flipped, this.color});

  String name;
  bool flipped;
  String color;

  Word.fromJson(Map<String, dynamic> json)
      : name = json['name'],
      flipped = json['flipped'],
      color = json['color'];

  Map<String, dynamic> toJson() =>
    {
      'name': name,
      'flipped': flipped,
      'color': color,
    };
}

class RowList {

  RowList();

  List<dynamic> rowWords = [];

  add(String word) {
    rowWords.add(Word(name: word, flipped: false, color: 'grey').toJson());
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

}