import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:together/services/services.dart';

class RevealDialog extends StatefulWidget {
  RevealDialog({this.data, this.sessionId});

  final data;
  final String sessionId;

  @override
  _RevealDialogState createState() => _RevealDialogState();
}

class _RevealDialogState extends State<RevealDialog> {
  String _guessedLocation = '';

  reveal() async {
    // if spy guessed correct location, spies win. otherwise, citizens win
    var data = widget.data.data;
    if (_guessedLocation == data['location']) {
      for (int i = 0; i < data['playerIds'].length; i++) {
        if (data['playerRoles'][data['playerIds'][i]] == 'spy') {
          incrementPlayerScore('theHunt', data['playerIds'][i]);
        }
      }
    } else {
      for (int i = 0; i < data['playerIds'].length; i++) {
        if (data['playerRoles'][data['playerIds'][i]] != 'spy') {
          incrementPlayerScore('theHunt', data['playerIds'][i]);
        }
      }
    }
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .update({'spyRevealed': _guessedLocation});
  }

  @override
  Widget build(BuildContext context) {
    List<String> possibleLocations = [''];
    widget.data['rules']['locations'].forEach((v) {
      possibleLocations.add(v);
    });
    return AlertDialog(
      title: Text('Reveal yourself and guess the location!'),
      content: Container(
        height: 60.0,
        decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).highlightColor)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _guessedLocation,
            iconSize: 24,
            elevation: 16,
            style: TextStyle(color: Theme.of(context).primaryColor),
            underline: Container(
              height: 2,
              color: Theme.of(context).primaryColor,
            ),
            onChanged: (String newValue) {
              setState(() {
                _guessedLocation = newValue;
              });
            },
            items:
                possibleLocations.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  '   ' + value,
                  style: TextStyle(
                      fontSize: 18, color: Theme.of(context).highlightColor),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: <Widget>[
        FlatButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel')),
        // This button results in adding the contact to the database
        FlatButton(
            onPressed: () {
              if (_guessedLocation == '') {
                // TODO: add error for blank submission
                print('error');
              } else {
                reveal();
                Navigator.of(context).pop();
              }
            },
            child: Text('Reveal'))
      ],
    );
  }
}

class AccuseDialog extends StatefulWidget {
  AccuseDialog({this.data, this.userId, this.sessionId});

  final data;
  final userId;
  final sessionId;

  @override
  _AccuseDialogState createState() => _AccuseDialogState();
}

class _AccuseDialogState extends State<AccuseDialog> {
  String _accusedPlayer = '';

  submitAccusation(String accusedId, data) async {
    data = data.data;
    var accusation = {'accuser': widget.userId, 'accused': accusedId};
    data['playerIds'].forEach((val) {
      if (val != widget.userId && val != accusedId) {
        accusation[val] = '';
      }
    });
    data['accusation'] = accusation;

    String playerName = data['playerNames'][widget.userId];
    String accusedName = data['playerNames'][accusedId];
    data['log'].add('$playerName accuses $accusedName!');

    // decrement all other player's accusation cooldown
    data['playerIds'].asMap().forEach((i, v) {
      if (v != widget.userId && data['player${i}AccusationCooldown'] > 0) {
        data['player${i}AccusationCooldown'] -= 1;
      }
    });
    // set player's accusation cooldown
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    data['player${playerIndex}AccusationCooldown'] =
        data['rules']['accusationCooldown'];
    // decrement general accusation cooldown
    if (data['remainingAccusationsThisTurn'] < 0) {
      data['remainingAccusationsThisTurn'] -= 1;
    }

    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .set(data);
  }

  @override
  Widget build(BuildContext context) {
    List<String> accusablePlayers = [''];
    widget.data['playerIds'].forEach((v) {
      if (v != widget.userId) {
        accusablePlayers.add(v);
      }
    });
    return AlertDialog(
      title: Text('Accuse someone of being the spy!'),
      content: Container(
        height: 60.0,
        decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).highlightColor)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _accusedPlayer,
            iconSize: 24,
            elevation: 16,
            style: TextStyle(color: Theme.of(context).primaryColor),
            underline: Container(
              height: 2,
              color: Theme.of(context).primaryColor,
            ),
            onChanged: (String newValue) {
              setState(() {
                _accusedPlayer = newValue;
              });
            },
            items: accusablePlayers.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: value == ''
                    ? Text('')
                    : Text(
                        '   ' + widget.data['playerNames'][value],
                        style: TextStyle(
                            fontSize: 20,
                            color: Theme.of(context).highlightColor),
                      ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: <Widget>[
        FlatButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Cancel")),
        FlatButton(
            onPressed: () {
              if (_accusedPlayer == '') {
                // TODO: add error for blank submission
                print('error');
              } else {
                submitAccusation(_accusedPlayer, widget.data);
                Navigator.of(context).pop();
              }
            },
            child: Text('Accuse'))
      ],
    );
  }
}
