import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:together/services/firestore.dart';

import 'plot_twist_services.dart';

class Chatbox extends StatelessWidget {
  final String text;
  final String person;
  final String timestamp;
  final String alignment;
  final Color backgroundColor;
  final Color fontColor;
  final bool suppressName;
  final bool isNarrator;

  Chatbox({
    this.text,
    this.person,
    this.timestamp,
    this.alignment,
    this.backgroundColor,
    this.fontColor,
    this.suppressName = false,
    this.isNarrator = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Column(
        children: [
          isNarrator ? SizedBox(height: 10) : Container(),
          isNarrator
              ? Text(
                  'Narrator',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                )
              : Container(),
          isNarrator ? SizedBox(height: 5) : Container(),
          suppressName || isNarrator
              ? Container()
              : Row(
                  children: [
                    ['center', 'right'].contains(alignment)
                        ? Spacer()
                        : Container(),
                    Text(
                      person,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).highlightColor.withAlpha(200),
                      ),
                    ),
                    ['center', 'left'].contains(alignment)
                        ? Spacer()
                        : Container(),
                  ],
                ),
          suppressName || isNarrator ? Container() : SizedBox(height: 2),
          Row(
            children: [
              ['center', 'right'].contains(alignment) ? Spacer() : Container(),
              Container(
                padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                constraints: BoxConstraints(maxWidth: 200),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(5),
                  color: backgroundColor,
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: fontColor,
                    fontSize: 12,
                  ),
                ),
              ),
              ['center', 'left'].contains(alignment) ? Spacer() : Container(),
            ],
          ),
        ],
      ),
    );
  }
}

class CharactersDialog extends StatefulWidget {
  CharactersDialog({this.data, this.sessionId, this.userId});

  final data;
  final String sessionId;
  final String userId;

  @override
  _CharactersDialogState createState() => _CharactersDialogState();
}

class _CharactersDialogState extends State<CharactersDialog> {
  int selectedCharacterIndex;
  int selectedPlayerIndex;
  var T;

  @override
  initState() {
    super.initState();
    T = Transactor(sessionId: widget.sessionId);
  }

  matchColors(otherPlayers) {
    if (selectedCharacterIndex != null && selectedPlayerIndex != null) {
      print('updating color');
      widget.data['matchingGuesses'][widget.userId]
              [otherPlayers[selectedPlayerIndex]] =
          widget.data['playerColors'][otherPlayers[selectedCharacterIndex]];
      // iterate over other colors and set same colors to grey
      widget.data['playerIds'].forEach((v) {
        // not selected player, and colors match
        if (v != otherPlayers[selectedPlayerIndex] &&
            widget.data['matchingGuesses'][widget.userId][v] ==
                widget.data['playerColors']
                    [otherPlayers[selectedCharacterIndex]]) {
          print('found: $v');
          widget.data['matchingGuesses'][widget.userId][v] = null;
        }
      });
      selectedCharacterIndex = null;
      selectedPlayerIndex = null;
    }
  }

  getCharacterTiles() {
    List otherPlayers = List.from(widget.data['playerIds']);
    otherPlayers.remove(widget.userId);
    return Container(
      height: 90.0 * (widget.data['playerIds'].length ~/ 3),
      width: 100,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).highlightColor,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: GridView.count(
        crossAxisCount: 3,
        children: List.generate(otherPlayers.length, (index) {
          return GestureDetector(
            onTap: () async {
              if (selectedCharacterIndex != index) {
                selectedCharacterIndex = index;
              } else {
                selectedCharacterIndex = null;
              }

              // check if character and player is selected, if so set player color (and clear the color elsewhere)
              matchColors(otherPlayers);

              setState(() {});

              T.transact(widget.data);
            },
            child: Center(
              child: Container(
                height: 75,
                width: 75,
                padding:
                    EdgeInsets.all(selectedCharacterIndex == index ? 6 : 8),
                decoration: BoxDecoration(
                  color: getPlayerColor(otherPlayers[index], widget.data),
                  border: Border.all(
                    width: selectedCharacterIndex == index ? 3 : 1,
                    color: selectedCharacterIndex == index
                        ? Colors.blue
                        : Theme.of(context).highlightColor,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  child: AutoSizeText(
                    widget.data['characters'][otherPlayers[index]]['name'],
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    minFontSize: 5,
                    maxFontSize: 13,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  getPlayerTiles() {
    List otherPlayers = List.from(widget.data['playerIds']);
    otherPlayers.remove(widget.userId);
    return Container(
      height: 90.0 * (widget.data['playerIds'].length ~/ 3),
      width: 100,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).highlightColor,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: GridView.count(
        crossAxisCount: 3,
        children: List.generate(otherPlayers.length, (index) {
          Color color = Colors.grey;
          if (widget.data['matchingGuesses'][widget.userId]
                  [otherPlayers[index]] !=
              null) {
            color = stringToColor(widget.data['matchingGuesses'][widget.userId]
                [otherPlayers[index]]);
          }
          return GestureDetector(
            onTap: () async {
              if (selectedPlayerIndex != index) {
                selectedPlayerIndex = index;
              } else {
                selectedPlayerIndex = null;
              }

              // check if character and player is selected, if so set player color (and clear the color elsewhere)
              matchColors(otherPlayers);

              setState(() {});

              T.transact(widget.data);
            },
            child: Center(
              child: Container(
                height: 75,
                width: 75,
                padding: EdgeInsets.all(selectedPlayerIndex == index ? 6 : 8),
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(
                    width: selectedPlayerIndex == index ? 3 : 1,
                    color: selectedPlayerIndex == index
                        ? Colors.blue
                        : Theme.of(context).highlightColor,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  child: Text(
                    widget.data['playerNames'][otherPlayers[index]],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return AlertDialog(
      title: Text('Match players to characters!'),
      contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
      content: Container(
        height: 160 + 180.0 * (widget.data['playerIds'].length ~/ 3),
        width: width * 0.95,
        child: ListView(
          children: <Widget>[
            SizedBox(height: 20),
            Text(
              'Characters:',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            SizedBox(height: 5),
            getCharacterTiles(),
            SizedBox(height: 20),
            Text(
              'Players:',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            SizedBox(height: 5),
            getPlayerTiles(),
            SizedBox(height: 20),
            Text(
              '(Click a character and then a player to match colors)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        Container(
          child: FlatButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'OK',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class CharacterDescriptionsDialog extends StatefulWidget {
  CharacterDescriptionsDialog({this.data, this.userId});

  final data;
  final userId;

  @override
  _CharacterDescriptionsDialogState createState() =>
      _CharacterDescriptionsDialogState();
}

class _CharacterDescriptionsDialogState
    extends State<CharacterDescriptionsDialog> {
  getCharacterFromPlayer(player) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).highlightColor),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
      child: widget.data['narrators'].contains(player)
          ? Column(
              children: [
                Text(
                  'Narrator',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
                Row(),
              ],
            )
          : Column(
              children: [
                Text(
                  'Name:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  widget.data['characters'][player]['name'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 5,
                      width: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: getPlayerColor(player, widget.data),
                      ),
                    ),
                    SizedBox(width: 30),
                    Column(
                      children: [
                        Text(
                          'Age:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          "${widget.data['characters'][player]['age']}",
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 30),
                    Container(
                      height: 5,
                      width: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: getPlayerColor(player, widget.data),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Description:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  widget.data['characters'][player]['description'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
    );
  }

  getOtherCharacters() {
    List<Widget> others = [];

    var otherPlayers = List.from(widget.data['playerIds']);
    otherPlayers.remove(widget.userId);

    otherPlayers.forEach((v) {
      others.add(getCharacterFromPlayer(v));
      others.add(
        SizedBox(height: 5),
      );
    });

    return Column(children: others);
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return AlertDialog(
      title: Text('Character Descriptions:'),
      contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
      content: Container(
        height: 130 + 180.0 * (widget.data['playerIds'].length ~/ 3),
        width: width * 0.95,
        child: ListView(
          children: <Widget>[
            SizedBox(height: 40),
            Text(
              'Your Character:',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            SizedBox(height: 5),
            getCharacterFromPlayer(widget.userId),
            SizedBox(height: 20),
            Text('Others: '),
            SizedBox(height: 5),
            getOtherCharacters(),
          ],
        ),
      ),
      actions: <Widget>[
        Container(
          child: FlatButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'OK',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class GameStateDialog extends StatefulWidget {
  GameStateDialog({this.data});

  final data;

  @override
  _GameStateDialogState createState() => _GameStateDialogState();
}

class _GameStateDialogState extends State<GameStateDialog> {
  getPlayerVotes() {
    List<Widget> votes = [];

    var players = [];
    widget.data['playerIds'].forEach((v) {
      if (!widget.data['narrators'].contains(v)) {
        players.add(v);
      }
    });
    players.forEach((v) {
      votes.add(
        Text(
          '${widget.data['playerNames'][v]} votes ${widget.data['readyToEnd'][v] ? 'YES' : 'NO'}',
          style: TextStyle(
            color: widget.data['readyToEnd'][v] ? Colors.green : Colors.red,
          ),
        ),
      );
    });
    return Column(children: votes);
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return AlertDialog(
      title: Text('Players voting to end:'),
      contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
      content: Container(
        height: 130 + 180.0 * (widget.data['playerIds'].length ~/ 3),
        width: width * 0.95,
        child: ListView(
          children: <Widget>[
            SizedBox(height: 40),
            getPlayerVotes(),
          ],
        ),
      ),
      actions: <Widget>[
        Container(
          child: FlatButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'OK',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
