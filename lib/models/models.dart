
class RowList {

  RowList();

  List<String> rowWords = [];

  add(String word) {
    rowWords.add(word);
  }

  RowList.fromJson(Map<String, dynamic> json)
      : rowWords = json['rowWords'];

  Map<String, dynamic> toJson() =>
    {
      'rowWords': rowWords
    };
}