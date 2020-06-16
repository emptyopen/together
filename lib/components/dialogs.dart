import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:together/components/buttons.dart';

class EndGameDialog extends StatefulWidget {
  EndGameDialog(
      {this.game,
      this.sessionId,
      this.numTeams = 2,
      this.winnerAlreadyDecided = false});

  final String game;
  final String sessionId;
  final int numTeams;
  final bool winnerAlreadyDecided;

  @override
  _EndGameDialogState createState() => _EndGameDialogState();
}

class _EndGameDialogState extends State<EndGameDialog> {
  String theHuntWinner = 'Spies';
  String abstractWinner = 'Green';

  @override
  void initState() {
    super.initState();
    print('init with ${widget.game}');
  }

  endGame(bool isToLobby) async {
    // TODO: assign winner (add statistics)

    // clear old data
    print('flushing data...');
    if (widget.game == 'Abstract') {
      var data = (await Firestore.instance.collection('sessions').document(widget.sessionId).get()).data;
      data.remove('endOnNextGreen');
      await Firestore.instance.collection('sessions').document(widget.sessionId).setData(data);
    }
    if (widget.game == 'Bananaphone') {
      var data = (await Firestore.instance.collection('sessions').document(widget.sessionId).get()).data;
      data['playerIds'].asMap().forEach((i, val) {
        data.remove('draw1Prompt$i');
        data.remove('describe1Prompt$i');
        data.remove('draw2Prompt$i');
        data.remove('describe2Prompt$i');
        data['phase'] = 'draw1';
      });
      await Firestore.instance.collection('sessions').document(widget.sessionId).setData(data);
    }

    // go to lobby or main menu 
    if (isToLobby) {
      // update session state to lobby - this automatically will trigger to lobby
      await Firestore.instance
          .collection('sessions')
          .document(widget.sessionId)
          .updateData({'state': 'lobby', 'setupComplete': false});
      Navigator.of(context).pop();
    } else {
      await Firestore.instance
          .collection('sessions')
          .document(widget.sessionId)
          .delete();
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }
  }

  getWinnerDropdown() {
    switch (widget.game) {
      case 'The Hunt':
        return ['Spies', 'Citizens']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value,
                style: TextStyle(
                  fontFamily: 'Balsamiq',
                  fontSize: 18,
                )),
          );
        }).toList();
        break;
    }
  }

  getDropdownValue() {
    switch (widget.game) {
      case 'The Hunt':
        return theHuntWinner;
        break;
      case 'Abstract':
        return abstractWinner;
        break;
    }
  }

  setDropdownValue(String newValue) {
    switch (widget.game) {
      case 'The Hunt':
        setState(() {
          theHuntWinner = newValue;
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return AlertDialog(
      title: Text('End the game!'),
      contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
      content: Container(
        height: widget.winnerAlreadyDecided ? 100 : 200,
        width: width * 0.95,
        child: ListView(
          children: <Widget>[
            SizedBox(height: 20),
            widget.winnerAlreadyDecided
                ? Container()
                : Column(
                    children: <Widget>[
                      Text('Who won?'),
                      Container(
                        width: 80,
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: getDropdownValue(),
                          iconSize: 24,
                          elevation: 16,
                          style:
                              TextStyle(color: Theme.of(context).primaryColor),
                          underline: Container(
                            height: 2,
                            color: Theme.of(context).primaryColor,
                          ),
                          onChanged: (String newValue) =>
                              setDropdownValue(newValue),
                          items: getWinnerDropdown(),
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
            Text('End game and go back to:'),
            SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Container(
                  height: 40,
                  width: 90,
                  child: RaisedGradientButton(
                    child: Text(
                      'Lobby',
                      style: TextStyle(fontSize: 18),
                    ),
                    gradient: LinearGradient(
                      colors: <Color>[
                        Color.fromARGB(255, 255, 185, 0),
                        Color.fromARGB(255, 255, 213, 0),
                      ],
                    ),
                    onPressed: () => endGame(true),
                  ),
                ),
                Container(
                  height: 40,
                  width: 130,
                  child: RaisedGradientButton(
                    child: Text(
                      'Main Menu',
                      style: TextStyle(fontSize: 18),
                    ),
                    gradient: LinearGradient(
                      colors: <Color>[
                        Color.fromARGB(255, 255, 185, 0),
                        Color.fromARGB(255, 255, 213, 0),
                      ],
                    ),
                    onPressed: () => endGame(false),
                  ),
                ),
              ],
            )
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
              'Cancel',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
