import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:together/components/buttons.dart';
import 'package:flutter/services.dart';

import 'package:together/components/misc.dart';
import 'package:together/components/layouts.dart';
import 'package:together/services/services.dart';
import 'template/help_screen.dart';
import 'lobby_screen.dart';

class TheHuntScreen extends StatefulWidget {
  TheHuntScreen({this.sessionId, this.userId, this.roomCode});

  final String sessionId;
  final String userId;
  final String roomCode;

  @override
  _TheHuntScreenState createState() => _TheHuntScreenState();
}

class _TheHuntScreenState extends State<TheHuntScreen> {
  List<dynamic> subList1;
  List<dynamic> subList2;
  List<List<bool>> strikethroughs;
  bool roleIsVisible = false;
  String currPlayer = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    setUpGame();
  }

  checkIfExit(data) async {
    if (data == null) {
      print('game was deleted');
      // navigate to main menu
      Navigator.of(context).pop();
    } else if (data['state'] == 'lobby') {
      // reset first player
      String firstPlayer = data['playerIds'][0];
      await Firestore.instance
          .collection('sessions')
          .document(widget.sessionId)
          .updateData({'turn': firstPlayer});
      // navigate to lobby
      Navigator.of(context).pop();
      slideTransition(
        context,
        LobbyScreen(
          roomCode: widget.roomCode,
        ),
      );
    }
  }

  checkIfVibrate(data) {
    if (currPlayer != data['turn']) {
      currPlayer = data['turn'];
      if (currPlayer == widget.userId) {
        HapticFeedback.vibrate();
      }
    }
  }

  setUpGame() async {
    // get session info for locations
    var data = (await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .get())
        .data;
    var possibleLocations = data['rules']['locations'];
    subList2 = possibleLocations.sublist(0, possibleLocations.length ~/ 2);
    subList1 = possibleLocations.sublist(possibleLocations.length ~/ 2);
    strikethroughs = [
      List.filled(subList1.length, false),
      List.filled(subList2.length, false),
    ];
  }

  updateTurn() async {
    Map<String, dynamic> sessionData = (await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .get())
        .data;
    var currActivePlayer = sessionData['turn'];
    var allPlayers = sessionData['playerIds'];
    var activePlayerIndex = allPlayers.indexOf(currActivePlayer);
    var nextActivePlayer;
    if (activePlayerIndex == allPlayers.length - 1) {
      nextActivePlayer = allPlayers[0];
    } else {
      nextActivePlayer = allPlayers[activePlayerIndex + 1];
    }
    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .updateData({'turn': nextActivePlayer});
  }

  fakeCallback() {}

  Widget getTurn(BuildContext context, data) {
    var players = data['playerIds'];
    var activePlayer = data['turn'];
    List<Widget> names = [];
    players.forEach((val) {
      names.add(
        FutureBuilder(
            future: Firestore.instance.collection('users').document(val).get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container();
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    snapshot.data['name'],
                    style: TextStyle(
                      color: val == activePlayer
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).highlightColor,
                    ),
                  ),
                  Text(widget.userId == val ? ' (you)' : '',
                      style: TextStyle(fontSize: 12, color: Colors.grey))
                ],
              );
            }),
      );
    });
    return FutureBuilder(
      future:
          Firestore.instance.collection('users').document(activePlayer).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data.data == null) {
          return Container();
        }
        return Container(
          width: 250,
          decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).highlightColor),
              borderRadius: BorderRadius.circular(20)),
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              widget.userId == activePlayer
                  ? Text(
                      'It is your turn!',
                      style: TextStyle(
                          fontSize: 20, color: Theme.of(context).primaryColor),
                      textAlign: TextAlign.center,
                    )
                  : Text(
                      'It is ${snapshot.data['name']}\'s turn!',
                      style: TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
              PageBreak(width: 80),
              Column(children: names),
              SizedBox(height: 10),
              widget.userId == activePlayer
                  ? RaisedGradientButton(
                      child: Text(
                        'End my turn',
                        style: TextStyle(fontSize: 18),
                      ),
                      onPressed: () {
                        if (data['accusation']['accuser'] == null) {
                          updateTurn();
                        } else {
                          _scaffoldKey.currentState.showSnackBar(SnackBar(
                            content:
                                Text('Can\'t end turn during an accusation!'),
                            duration: Duration(seconds: 3),
                          ));
                          print('snackbar for ongoing accusation');
                        }
                      },
                      height: 40,
                      width: 180,
                      gradient: data['accusation']['accuser'] == null
                          ? LinearGradient(
                              colors: <Color>[
                                Theme.of(context).primaryColor,
                                Theme.of(context).accentColor,
                              ],
                            )
                          : LinearGradient(
                              colors: <Color>[
                                Colors.grey[600],
                                Colors.grey[500],
                              ],
                            ),
                    )
                  : Container(),
            ],
          ),
        );
      },
    );
  }

  getRoleButton(data) {
    return FlatButton(
      splashColor: Color.fromARGB(0, 1, 1, 1),
      highlightColor: Color.fromARGB(0, 1, 1, 1),
      onPressed: () {
        setState(() {
          roleIsVisible = !roleIsVisible;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).highlightColor),
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).primaryColor,
        ),
        padding: EdgeInsets.all(10),
        width: 250,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              roleIsVisible ? '(Tap to hide role)' : 'Tap to show role',
              style: TextStyle(
                  fontSize: roleIsVisible ? 16 : 20,
                  color: roleIsVisible ? Colors.grey[400] : Colors.white),
            ),
            roleIsVisible
                ? SizedBox(
                    height: 10,
                  )
                : Container(),
            roleIsVisible
                ? data['playerRoles'][widget.userId] == 'spy'
                    ? Column(
                        children: <Widget>[
                          Text(
                            'You are the spy!',
                            style: TextStyle(fontSize: 22, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '(Try and figure out the location!)',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[300]),
                            textAlign: TextAlign.center,
                          )
                        ],
                      )
                    : Column(
                        children: <Widget>[
                          Text(
                            'Location:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[400],
                            ),
                          ),
                          Text(
                            '${data['location']}',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Your role:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[400],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '${data['playerRoles'][widget.userId]}',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                : Container(),
          ],
        ),
      ),
    );
  }

  addVoteToAccusation(data, vote) async {
    var accusation = (await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .get())
        .data['accusation'];
    accusation[widget.userId] = vote;
    // check if all votes are in (need to add logic for more than one spy)
    bool allPlayersVoted = true;
    bool allPlayersVotedGuilty = true;
    data['playerIds'].forEach((val) {
      if (val != accusation['accuser'] && val != accusation['accused']) {
        if (accusation[val] == '') {
          allPlayersVoted = false;
        } else if (accusation[val] == 'no') {
          allPlayersVotedGuilty = false;
        }
      }
    });
    if (allPlayersVoted) {
      if (allPlayersVotedGuilty) {
        // game is over
        accusation['charged'] = accusation['accused'];
        // if charged was spy, all citizens win, otherwise all spies win
        if (data['playerRoles'][accusation['accused']] == 'spy') {
          for (int i = 0; i < data['playerIds'].length; i++) {
            if (data['playerRoles'][i] != 'spy') {
              incrementPlayerScore('theHunt', data['playerIds'][i]);
            }
          }
        } else {
          for (int i = 0; i < data['playerIds'].length; i++) {
            if (data['playerRoles'][i] == 'spy') {
              incrementPlayerScore('theHunt', data['playerIds'][i]);
            }
          }
        }
      } else {
        // delete the accusation and temporarily notify
        accusation = {
          'lastAccused': accusation['accused'],
          'accusationComplete': DateTime.now(),
        };
      }
    }
    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .updateData({'accusation': accusation});
  }

  getAccuseOrReveal(data) {
    return FlatButton(
      splashColor: Color.fromARGB(0, 1, 1, 1),
      highlightColor: Color.fromARGB(0, 1, 1, 1),
      onPressed: () {
        if (data['playerRoles'][widget.userId] == 'spy') {
          showDialog<Null>(
            context: context,
            builder: (BuildContext context) {
              return RevealDialog(data: data, sessionId: widget.sessionId);
            },
          );
        } else {
          showDialog<Null>(
            context: context,
            builder: (BuildContext context) {
              return AccuseDialog(
                  data: data,
                  userId: widget.userId,
                  sessionId: widget.sessionId);
            },
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).highlightColor),
          borderRadius: BorderRadius.circular(20),
          color: Color.fromARGB(255, 255, 213, 0),
        ),
        padding: EdgeInsets.all(10),
        width: 160,
        child: Text(
          'I know!',
          style: TextStyle(
            fontSize: 20,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  getAccusation(data) {
    if (data['accusation']['accuser'] == null && data['spyRevealed'] == '') {
      return getAccuseOrReveal(data);
    }
    var mapping = data['playerNames'];
    String accuser = mapping[data['accusation']['accuser']];
    String accused = mapping[data['accusation']['accused']];
    var spy = '';
    List<Widget> votersStatus = [];
    data['playerIds'].forEach((val) {
      if (val != data['accusation']['accuser'] &&
          val != data['accusation']['accused']) {
        // TODO: logic for multiple spies (many sections need to be updated!)
        if (data['playerRoles'][val] == 'spy') {
          spy = mapping[val];
        }
        votersStatus.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '${mapping[val]}:  ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              data['accusation'][val] == ''
                  ? Text(
                      'waiting',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    )
                  : data['accusation'][val] == 'yes'
                      ? Text(
                          'YES',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                          ),
                        )
                      : Text(
                          'NO',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                          ),
                        ),
            ],
          ),
        );
      }
    });
    // check if user needs to vote
    bool userNeedsToVote = false;
    if (widget.userId != data['accusation']['accuser'] &&
        widget.userId != data['accusation']['accused']) {
      // user is not accuser or accused
      if (data['accusation'][widget.userId] == '') {
        userNeedsToVote = true;
      }
    }
    return Column(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).highlightColor),
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey[700],
          ),
          padding: EdgeInsets.all(10),
          width: 250,
          child: data['spyRevealed'] != ''
              ? Column(
                  children: <Widget>[
                    Text(
                      'Game is over!',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      '$spy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'reveals themselves as the spy!\n\nThey guess location is: ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${data.data['spyRevealed']}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 15),
                    data['spyRevealed'] == data['location']
                        ? Column(
                            children: <Widget>[
                              Text(
                                'That\'s correct!',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Spies win!',
                                style: TextStyle(
                                    fontSize: 24,
                                    color: Color.fromARGB(255, 255, 213, 0)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        : Column(
                            children: <Widget>[
                              Text('Unfortunately, incorrect!'),
                              Text(
                                'The correct location is: ${data['location']}',
                                style: TextStyle(
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                'Citizens win!',
                                style: TextStyle(
                                    fontSize: 24,
                                    color: Color.fromARGB(255, 255, 213, 0)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                  ],
                )
              : !data.data['accusation'].containsKey('charged')
                  ? Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              '$accuser ',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color.fromARGB(255, 255, 213, 0),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'accuses ',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              '$accused!',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color.fromARGB(255, 255, 213, 0),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        PageBreak(width: 50),
                        Column(children: votersStatus)
                        // if player should vote but hasn't, add button to vote yes or no
                      ],
                    )
                  : Column(
                      children: <Widget>[
                        Text(
                          'Game is over!',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '$accuser accused $accused,\n and everyone agreed.',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 5),
                        data['playerRoles'][data['accusation']['accused']] ==
                                'spy'
                            ? Text(
                                '$accused was the spy!\nCitizens win!',
                                style: TextStyle(
                                    fontSize: 20,
                                    color: Color.fromARGB(255, 255, 213, 0)),
                                textAlign: TextAlign.center,
                              )
                            : Text(
                                '$accused was NOT the spy!\nSpies win!',
                                style: TextStyle(
                                    fontSize: 20,
                                    color: Color.fromARGB(255, 255, 213, 0)),
                                textAlign: TextAlign.center,
                              ),
                      ],
                    ),
        ),
        userNeedsToVote
            ? Column(
                children: <Widget>[
                  SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: Theme.of(context).highlightColor),
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey[700],
                    ),
                    padding: EdgeInsets.all(10),
                    width: 250,
                    child: Column(
                      children: <Widget>[
                        Text(
                          'Do you think ${mapping[data['accusation']['accused']]} is guilty?',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            RaisedGradientButton(
                              width: 70,
                              height: 30,
                              onPressed: () {
                                addVoteToAccusation(data, 'yes');
                              },
                              child: Text('Yes'),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green[400],
                                  Colors.green[300],
                                ],
                              ),
                            ),
                            SizedBox(width: 20),
                            RaisedGradientButton(
                              width: 70,
                              height: 30,
                              onPressed: () {
                                addVoteToAccusation(data, 'no');
                              },
                              child: Text('No'),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red[400],
                                  Colors.red[300],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Container(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
                appBar: AppBar(
                  title: Text(
                    'The Hunt!',
                  ),
                ),
                body: Container());
          }
          // all data for all components
          DocumentSnapshot data = snapshot.data;
          if (data.data == null) {
            return Scaffold(
                appBar: AppBar(
                  title: Text(
                    'The Hunt!',
                  ),
                ),
                body: Container());
          }
          checkIfExit(data);
          // check if current player's turn
          checkIfVibrate(data);
          return Scaffold(
              key: _scaffoldKey,
              appBar: AppBar(
                title: Text(
                  'The Hunt!',
                ),
                actions: <Widget>[
                  IconButton(
                    icon: Icon(Icons.info),
                    onPressed: () {
                      // HapticFeedback.heavyImpact();
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          opaque: false,
                          pageBuilder: (BuildContext context, _, __) {
                            return TheHuntScreenHelp();
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
              body: SingleChildScrollView(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: 50),
                      !data['accusation'].containsKey('charged')
                          ? getTurn(context, data)
                          : Container(),
                      SizedBox(height: 20),
                      getRoleButton(data),
                      SizedBox(height: 20),
                      getAccusation(data),
                      SizedBox(height: 20),
                      !data['accusation'].containsKey('charged')
                          ? LocationBoard(
                              subList1: subList1,
                              subList2: subList2,
                              strikethroughs: strikethroughs,
                              callback: fakeCallback,
                            )
                          : Container(),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        'Room Code:',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      PageBreak(width: 80),
                      Text(
                        widget.roomCode,
                        style: TextStyle(
                          fontSize: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 30),
                      widget.userId == data['leader']
                          ? EndGameButton(
                              gameName: 'The Hunt',
                              sessionId: widget.sessionId,
                              fontSize: 18,
                              height: 40,
                              width: 140,
                            )
                          : Container(),
                      SizedBox(height: 80),
                    ],
                  ),
                ),
              ));
        });
  }
}

class TheHuntScreenHelp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HelpScreen(
      title: 'The Hunt: Rules',
      information: [
        '    The objectives of the game are simple:\n\n(1) If you ARE NOT a spy, you are a citizen trying to find the spy(ies). \n\n(2) If you ARE a spy, '
            'you are trying to figure out where the location is.\n\n(3) Spies lose and win, together. Same for citizens.',
        '    Players take turns asking questions to a player of their choice. The question can be anything, '
            'and the answer can be anything.\n\n    Just keep in mind that vagueness can be suspicious!',
        '    At any point, a player can accuse another player of being the spy.\n\n    '
            'A verdict requires a unanimous vote, less the remaining number of spies.',
        '    The game ends in two general ways:\n\n(1) A spy can reveal they are the spy at any time (except during an accusation), and attempt to guess the location. '
            'If they guess correctly, the spies win. If they guess incorrectly, the spies lose.'
            '\n\n(continued on next page)',
        '\n\n(2) If a citizen is unanimously accused, the spies win. Otherwise the spy is exiled, and if there are no spies left, the citizens win.'
            '\n\nThe spies can always guess the location once the game is over, for "honor"!'
      ],
      buttonColor: Theme.of(context).primaryColor,
    );
  }
}

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
    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .updateData({'spyRevealed': _guessedLocation});
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
    var accusation = {'accuser': widget.userId, 'accused': accusedId};
    data['playerIds'].forEach((val) {
      if (val != widget.userId && val != accusedId) {
        accusation[val] = '';
      }
    });
    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .updateData({'accusation': accusation});
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
