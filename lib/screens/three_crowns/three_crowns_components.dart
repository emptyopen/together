import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:together/components/buttons.dart';
import 'package:together/screens/three_crowns/three_crowns_services.dart';

class ThreeCrownsCard extends StatelessWidget {
  final String value;
  final String size;
  final double rotation;
  final Function callback;
  final bool faceDown;
  final bool empty;

  ThreeCrownsCard({
    this.value,
    this.size = 'medium',
    this.rotation,
    this.callback,
    this.faceDown = false,
    this.empty = false,
  });

  getIcon(size) {
    var suit = value[1];
    if (value.length == 3) {
      suit = value[2];
    }
    switch (suit) {
      case 'S':
        return Icon(
          MdiIcons.cardsSpade,
          // MdiIcons.fish,
          color: Colors.blue.withAlpha(230),
          size: size,
        );
        break;
      case 'H':
        return Icon(
          MdiIcons.cardsHeart,
          // MdiIcons.ladybug,
          color: Colors.red.withAlpha(230),
          size: size,
        );
        break;
      case 'C':
        return Icon(
          MdiIcons.cardsClub,
          // MdiIcons.alien,
          color: Colors.green.withAlpha(230),
          size: size,
        );
        break;
      case 'D':
        return Icon(
          MdiIcons.cardsDiamond,
          // MdiIcons.duck,
          color: Colors.amber.withAlpha(230),
          size: size,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    // medium defaults
    var width = screenWidth / 7;
    var height = width * 1.25;
    double fontSize = 40;
    double iconSize = 60;
    if (size == 'small') {
      height = 55;
      width = 40;
      fontSize = 36;
      iconSize = 50;
    }
    if (empty) {
      return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Theme.of(context).highlightColor),
            borderRadius: BorderRadius.circular(10),
          ));
    }
    if (faceDown) {
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          border: Border.all(color: Theme.of(context).highlightColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Container(
            height: height - 15,
            width: width - 15,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                MdiIcons.crown,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: callback,
      child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Theme.of(context).highlightColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                left: 1,
                top: 1,
                child: getIcon(
                  iconSize,
                ),
              ),
              Positioned(
                child: Text(
                  value[0],
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSize,
                  ),
                ),
                top: 3,
                left: 5,
              ),
              value[0] == '4' && size == 'medium'
                  ? Positioned(
                      child: Icon(
                        MdiIcons.autorenew,
                        size: 20,
                        color: Colors.black.withAlpha(100),
                      ),
                      bottom: 1,
                      right: 1,
                    )
                  : Container(),
              value[0] == '1' && size == 'medium'
                  ? Positioned(
                      child: Icon(
                        Icons.star,
                        size: 20,
                        color: Colors.black.withAlpha(100),
                      ),
                      bottom: 1,
                      right: 1,
                    )
                  : Container(),
              ['5', '6', '7'].contains(value[0]) && size == 'medium'
                  ? Positioned(
                      child: Icon(
                        MdiIcons.baguette,
                        size: 20,
                        color: Colors.black.withAlpha(100),
                      ),
                      bottom: 1,
                      right: 1,
                    )
                  : Container(),
            ],
          )),
    );
  }
}

class PillageDialog extends StatefulWidget {
  final data;
  final List<int> possiblePlayerIndices;
  final sessionId;
  final userId;

  PillageDialog({
    this.data,
    this.possiblePlayerIndices,
    this.sessionId,
    this.userId,
  });

  @override
  _PillageDialogState createState() => _PillageDialogState();
}

class _PillageDialogState extends State<PillageDialog> {
  int selectedPlayerIndex;
  int selectedTileIndex;
  List<int> possibleTileIndices;

  @override
  void initState() {
    super.initState();
    selectedPlayerIndex = widget.possiblePlayerIndices[0];
    selectedTileIndex = -1;
    if (widget.data['player${selectedPlayerIndex}Tiles'].length > 0) {
      selectedTileIndex = 0;
    }
    possibleTileIndices = List<int>.generate(
        widget.data['player${selectedPlayerIndex}Tiles'].length,
        (int index) => index);
  }

  stealTiles() async {
    var tile =
        widget.data['player${selectedPlayerIndex}Tiles'][selectedTileIndex];
    // add tile to winner index
    var playerIndex = widget.data['playerIds'].indexOf(widget.userId);
    widget.data['player${playerIndex}Tiles'].add(tile);
    // remove tile from selectedPlayerIndex
    widget.data['player${selectedPlayerIndex}Tiles'].remove(tile);
    String winner = playerNameFromIndex(playerIndex, widget.data);
    String selected = playerNameFromIndex(selectedPlayerIndex, widget.data);
    widget.data['log']
        .add('$winner stole a ${tile.toUpperCase()} from $selected!');

    widget.data['duel']['pillagePrize'] -= 1;

    // if player has collected all rewards, move to next duel
    if (widget.data['duel']['pillagePrize'] == 0) {
      cleanupDuel(widget.data);
    }

    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .set(widget.data);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Choose your spoils!'),
      contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DropdownButton<int>(
            isExpanded: true,
            value: selectedPlayerIndex,
            iconSize: 24,
            elevation: 16,
            style: TextStyle(color: Theme.of(context).highlightColor),
            underline: Container(
              height: 2,
              color: Theme.of(context).highlightColor,
            ),
            onChanged: (int newValue) {
              setState(() {
                selectedPlayerIndex = newValue;
                possibleTileIndices = List<int>.generate(
                    widget.data['player${selectedPlayerIndex}Tiles'].length,
                    (int index) => index);
                if (widget.data['player${selectedPlayerIndex}Tiles'].length >
                    0) {
                  selectedTileIndex = 0;
                }
              });
            },
            items: widget.possiblePlayerIndices.map((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text(
                    widget.data['playerNames'][widget.data['playerIds'][value]],
                    style: TextStyle(
                      fontFamily: 'Balsamiq',
                      fontSize: 18,
                    )),
              );
            }).toList(),
          ),
          widget.data['player${selectedPlayerIndex}Tiles'].length > 0 &&
                  selectedTileIndex != -1
              ? DropdownButton<int>(
                  isExpanded: true,
                  value: selectedTileIndex,
                  iconSize: 24,
                  elevation: 16,
                  style: TextStyle(color: Theme.of(context).highlightColor),
                  underline: Container(
                    height: 2,
                    color: Theme.of(context).highlightColor,
                  ),
                  onChanged: (int newValue) async {
                    setState(() {
                      selectedTileIndex = newValue;
                    });
                  },
                  items: possibleTileIndices
                      .map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(
                        widget.data['player${selectedPlayerIndex}Tiles'][value]
                            .toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Balsamiq',
                          fontSize: 18,
                        ),
                      ),
                    );
                  }).toList(),
                )
              : Text(
                  'Player has no tiles!',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
          SizedBox(height: 15),
        ],
      ),
      actions: <Widget>[
        widget.data['player${selectedPlayerIndex}Tiles'].length == 0 ||
                selectedTileIndex == -1
            ? Container()
            : RaisedGradientButton(
                onPressed: () {
                  stealTiles();
                  Navigator.of(context).pop();
                },
                height: 30,
                width: 100,
                child: Text(
                  'Steal Tile!',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
                gradient: LinearGradient(
                  colors: <Color>[
                    Color.fromARGB(255, 255, 185, 0),
                    Color.fromARGB(255, 255, 213, 0),
                  ],
                ),
              ),
        RaisedGradientButton(
          onPressed: () async {
            // get two tiles
            var playerIndex = widget.data['playerIds'].indexOf(widget.userId);
            String winner = playerNameFromIndex(playerIndex, widget.data);
            String letter1 = generateRandomLetter();
            String letter2 = generateRandomLetter();
            widget.data['player${playerIndex}Tiles'].add(letter1);
            widget.data['player${playerIndex}Tiles'].add(letter2);
            widget.data['log'].add(
                '$winner collected two tiles: "${letter1.toUpperCase()}" and "${letter2.toUpperCase()}"');
            widget.data['duel']['pillagePrize'] -= 1;
            // if player has collected all rewards, move to next duel
            if (widget.data['duel']['pillagePrize'] == 0) {
              cleanupDuel(widget.data);
            }

            await FirebaseFirestore.instance
                .collection('sessions')
                .doc(widget.sessionId)
                .set(widget.data);

            Navigator.of(context).pop();
          },
          child: Text('2 Tiles!'),
          height: 30,
          width: 80,
          gradient: LinearGradient(
            colors: <Color>[
              Colors.green[600],
              Colors.green[400],
            ],
          ),
        ),
      ],
    );
  }
}

class Tile extends StatelessWidget {
  final String value;
  final bool holy;
  final Function callback;
  final bool selected;
  final bool empty;

  Tile({this.value, this.holy, this.callback, this.selected, this.empty});

  @override
  Widget build(BuildContext context) {
    if (empty) {
      return Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey,
            width: 1,
          ),
          color: Colors.grey,
          borderRadius: BorderRadius.circular(5),
        ),
      );
    }
    return GestureDetector(
      onTap: () {
        if (callback != null) {
          callback();
        }
      },
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Colors.green : Colors.grey,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(5),
          gradient: LinearGradient(
            colors: holy
                ? [
                    Colors.purple[500],
                    Colors.pink[300],
                  ]
                : [
                    Colors.grey[800],
                    Colors.grey[600],
                  ],
          ),
        ),
        child: Container(
          // decoration: BoxDecoration(border: Border.all()),
          child: Stack(
            children: [
              Positioned(
                top: selected ? 2 : 3,
                left: selected ? 4 : 5,
                child: Text(
                  value.toUpperCase(),
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                bottom: selected ? 1 : 2,
                right: selected ? 2 : 3,
                child: Text(
                  letterValues[value].toString(),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withAlpha(220),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
