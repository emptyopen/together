import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:together/components/buttons.dart';

class EndGameButton extends StatelessWidget {
  final String sessionId;
  final String gameName;
  final double fontSize;
  final double height;
  final double width;

  EndGameButton(
      {this.sessionId,
      this.gameName,
      this.fontSize = 14,
      this.height = 30,
      this.width = 100});
  @override
  Widget build(BuildContext context) {
    return RaisedGradientButton(
      child: Text(
        'End game',
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.black,
        ),
      ),
      onPressed: () {
        showDialog<Null>(
          context: context,
          builder: (BuildContext context) {
            return EndGameDialog(
              game: gameName,
              sessionId: sessionId,
            );
          },
        );
      },
      height: height,
      width: width,
      gradient: LinearGradient(
        colors: <Color>[
          Color.fromARGB(255, 255, 185, 0),
          Color.fromARGB(255, 255, 213, 0),
        ],
      ),
    );
  }
}

class EndGameDialog extends StatefulWidget {
  EndGameDialog({this.game, this.sessionId});

  final String game;
  final String sessionId;

  @override
  _EndGameDialogState createState() => _EndGameDialogState();
}

class _EndGameDialogState extends State<EndGameDialog> {
  @override
  void initState() {
    super.initState();
  }

  endGame(bool isToLobby) async {
    // go to lobby or main menu
    if (isToLobby) {
      // update session state to lobby - this automatically will trigger to lobby
      await Firestore.instance
          .collection('sessions')
          .document(widget.sessionId)
          .updateData({'state': 'lobby'});
      Navigator.of(context).pop();
    } else {
      await Firestore.instance
          .collection('sessions')
          .document(widget.sessionId)
          .delete();
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //       Navigator.of(context)
      //           .pushReplacementNamed(MyScreen.routeName);
      //     });
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   Navigator.of(context).pop();
      //   Navigator.of(context).pop();
      // });
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return AlertDialog(
      title: Text('End the game!'),
      contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
      content: Container(
        height: 100,
        width: width * 0.95,
        child: ListView(
          children: <Widget>[
            SizedBox(height: 20),
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
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                      ),
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
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                      ),
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
