import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:collection';
import 'dart:math';
import 'dart:convert';

import '../components/buttons.dart';
import '../components/layouts.dart';
import '../components/misc.dart';
import '../models/models.dart';
import 'package:together/constants/values.dart';
import 'package:together/services/services.dart';
import 'package:together/screens/thehunt_screen.dart';
import 'package:together/screens/abstract_screen.dart';


class LobbyScreen extends StatefulWidget {
  LobbyScreen({Key key, this.roomCode}) : super(key: key);

  final String roomCode;

  @override
  _LobbyScreenState createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  bool isLeader = false;
  bool isStarting = false;
  Timer _timer;
  DateTime startTime;
  DateTime _now;
  String sessionId;
  String userId;
  String leaderId;
  String gameName;
  bool calledGameRoom = false;

  @override
  void initState() {
    super.initState();
    initialize();
    // TODO: another timer to check if you've been kicked (or game has been destroyed)
    _timer = Timer.periodic(Duration(milliseconds: 100), (Timer t) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
      // move to new screen when time is passed
      if (startTime != null &&
          !calledGameRoom &&
          sessionId != null &&
          userId != null) {
        if (startTime.difference(_now).inSeconds < 0) {
          setState(() {
            calledGameRoom = true;
          });
          Navigator.of(context).pop();
          switch (gameName) {
            case 'The Hunt': 

          slideTransition(
            context,
            TheHuntScreen(
              sessionId: sessionId,
              userId: userId,
              roomCode: widget.roomCode,
              isLeader: isLeader,
            ),
          );
          break;
          case 'Abstract':

          slideTransition(
            context,
            AbstractScreen(
              sessionId: sessionId,
              userId: userId,
              roomCode: widget.roomCode,
              isLeader: isLeader,
            ),
          );
          break;
          }
        }
      }
    });
    print('initialized lobby for room # ${widget.roomCode}');
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  initialize() async {
    await Firestore.instance
        .collection('sessions')
        .where('roomCode', isEqualTo: widget.roomCode)
        .getDocuments()
        .then((event) async {
      if (event.documents.isNotEmpty) {
        Map<String, dynamic> documentData = event.documents.single.data;
        sessionId = event.documents.single.documentID;
        userId = (await FirebaseAuth.instance.currentUser()).uid;
        leaderId = event.documents.single.data['leader'];
        // check if current user is leader
        setState(() {
          isLeader = documentData['leader'] == userId;
          gameName = documentData['game'];
        });
      }
    }).catchError((e) => print('error fetching data: $e'));
  }

  kickPlayer(String playerId) async {
    // remove playerId from session
    var data = (await Firestore.instance
            .collection('sessions')
            .document(sessionId)
            .get())
        .data;
    var currPlayers = data['playerIds'];
    currPlayers.removeWhere((item) => item == playerId);
    await Firestore.instance
        .collection('sessions')
        .document(sessionId)
        .updateData({'playerIds': currPlayers});
  }

  startGame() async {
    // update session document with state and start date
    // TODO: just get session id during init and use it afterwards
    await Firestore.instance
        .collection('sessions')
        .where('roomCode', isEqualTo: widget.roomCode)
        .getDocuments()
        .then((event) async {
      if (event.documents.isNotEmpty) {
        String sessionId = event.documents.single.documentID;
        var data = (await Firestore.instance.collection('sessions').document(sessionId).get()).data;
        var boardSize = data['rules']['boardSize'];
        List<RowList> words = [];

        // hash set 
        var hashSet = HashSet();
        for (var i = 0; i < boardSize; i++) {
          words.add(RowList());
          for (var j = 0; j < boardSize; j++) {
            Random _random = new Random();
            String wordToAdd = abstractPossibleWords[_random.nextInt(abstractPossibleWords.length)];
            while (hashSet.contains(wordToAdd)) {
              wordToAdd = abstractPossibleWords[_random.nextInt(abstractPossibleWords.length)];
            }
            words[i].add(wordToAdd);
          }
        }
        var serializedWords = [];
        for (var i = 0; i < boardSize; i++) {
          serializedWords.add(words[i].toJson());
        }
        var rules = data['rules'];
        rules['words'] = serializedWords;
        await Firestore.instance
            .collection('sessions')
            .document(sessionId)
            .updateData({
          'rules': rules,
          'state': 'started',
          'startTime': DateTime.now().add(Duration(seconds: 5)),
        });
      }
    });//.catchError((e) => print('error fetching data: $e'));
  }

  StreamBuilder<QuerySnapshot> _getCountdown(BuildContext context) {
    return StreamBuilder(
        stream: Firestore.instance
            .collection('sessions')
            .where('roomCode', isEqualTo: widget.roomCode)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Text(
              'No Data...',
            );
          } else {
            DocumentSnapshot items = snapshot.data.documents[0];
            // check if we are in the started state. if we aren't, display nothing.
            if (items['state'] == 'lobby') {
              return Container();
            }
            // if we are started, countdown if we are before the time, otherwise pop and move to game room
            isStarting = true;
            startTime = items['startTime'].toDate();
            return Column(
              children: <Widget>[
                Text(
                  startTime == null || _now == null
                      ? ''
                      : 'Game is starting in ${startTime.difference(_now).inSeconds}',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 24,
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
              ],
            );
          }
        });
  }

  StreamBuilder<QuerySnapshot> getRules(BuildContext context) {
    return StreamBuilder(
        stream: Firestore.instance
            .collection('sessions')
            .where('roomCode', isEqualTo: widget.roomCode)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Text(
              'No Data...',
            );
          } else {
            DocumentSnapshot items = snapshot.data.documents[0];
            var rules = items['rules'];
            switch (gameName) {
              case 'The Hunt':
                return Container(
                  width: 250,
                  child: Column(
                    children: <Widget>[
                      Text('Number of spies: ${rules['numSpies']}'),
                      Text('Locations: ${rules['locations']}'),
                    ],
                  ),
                );
                break;
              case 'Abstract':
                return Container(
                  width: 250,
                  child: Column(
                    children: <Widget>[
                      Text('Board Size: ${rules['boardSize']}'),
                      Text('Number of Teams: ${rules['numTeams']}'),
                    ],
                  ),
                );
                break;
              default:
                return Text('Unknown game');
            }
          }
        });
  }

  StreamBuilder<QuerySnapshot> _getPlayers() {
    return StreamBuilder(
        stream: Firestore.instance
            .collection('sessions')
            .where('roomCode', isEqualTo: widget.roomCode)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Text(
              'No Data...',
            );
          } else {
            List<DocumentSnapshot> items = snapshot.data.documents;
            // if start date exists and we are past it, move to game screen (with session id)
            var playerIds = items[0]['playerIds'];
            return Container(
              height: 35.0 * playerIds.length,
              child: ListView.builder(
                  itemCount: playerIds.length,
                  itemBuilder: (context, index) {
                    return FutureBuilder(
                        future: Firestore.instance
                            .collection('users')
                            .document(playerIds[index])
                            .get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Container();
                          }
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    snapshot.data['name'],
                                    style: TextStyle(
                                        fontSize: 20,
                                        color: userId == playerIds[index]
                                            ? Theme.of(context).primaryColor
                                            : Colors.black),
                                  ),
                                  Text(
                                    playerIds[index] == leaderId
                                        ? ' (glorious leader) '
                                        : '',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  isLeader && playerIds[index] == leaderId
                                      ? SizedBox(height: 35)
                                      : Container(),
                                  isLeader && playerIds[index] != leaderId
                                      ? SizedBox(
                                          height: 35,
                                          child: IconButton(
                                            icon: Icon(
                                              MdiIcons.accountRemove,
                                              size: 20,
                                              color: Colors.redAccent,
                                            ),
                                            onPressed: () =>
                                                kickPlayer(playerIds[index]),
                                          ),
                                        )
                                      : Container(),
                                ],
                              ),
                            ],
                          );
                        });
                  }),
            );
          }
        });
  }

  shufflePlayers() async {
    var data = (await Firestore.instance
            .collection('sessions')
            .document(sessionId)
            .get())
        .data;
    var playerOrder = data['playerIds'];
    playerOrder.shuffle();
    await Firestore.instance
        .collection('sessions')
        .document(sessionId)
        .updateData({'playerIds': playerOrder, 'turnPlayerId': playerOrder[0]});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${gameName}: Lobby',
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 40),
              isLeader
                  ? Text('- you are the glorious leader -')
                  : Text('- bug the leader if you want the game to start -'),
              SizedBox(height: 30),
              _getCountdown(context),
              Text(
                'Room Code:',
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
              PageBreak(
                width: 100,
              ),
              Text(
                widget.roomCode,
                style: TextStyle(
                  fontSize: 34,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Text(
                'Players:',
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
              PageBreak(width: 50),
              _getPlayers(),
              isLeader && !isStarting
                  ? RaisedGradientButton(
                      child: Text(
                        'Shuffle Players',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      onPressed: shufflePlayers,
                      height: 40,
                      width: 150,
                      gradient: LinearGradient(
                        colors: <Color>[
                          Theme.of(context).primaryColor,
                          Theme.of(context).accentColor,
                        ],
                      ),
                    )
                  : Container(),
              SizedBox(height: 30),
              Text('Rules', style: TextStyle(fontSize: 24)),
              PageBreak(
                width: 80,
              ),
              getRules(context),
              isLeader && !isStarting
                  ? Column(
                      children: <Widget>[
                        SizedBox(height: 10),
                        RaisedGradientButton(
                          child: Text(
                            'Edit Rules',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          onPressed: () {
                            showDialog<Null>(
                              context: context,
                              builder: (BuildContext context) {
                                return EditRulesDialog(
                                  game: gameName,
                                  sessionId: sessionId,
                                );
                              },
                            );
                          },
                          height: 40,
                          width: 130,
                          gradient: LinearGradient(
                            colors: <Color>[
                              Theme.of(context).primaryColor,
                              Theme.of(context).accentColor,
                            ],
                          ),
                        ),
                        SizedBox(height: 40),
                        RaisedGradientButton(
                          child: Text(
                            'Start Game',
                            style: TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          onPressed: startGame,
                          height: 50,
                          width: 150,
                          gradient: LinearGradient(
                            colors: <Color>[
                              Color.fromARGB(255, 255, 185, 0),
                              Color.fromARGB(255, 255, 213, 0),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 30,
                        )
                      ],
                    )
                  : Container(),
              SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

class EditRulesDialog extends StatefulWidget {
  EditRulesDialog({this.sessionId, this.game});

  final String sessionId;
  final String game;

  @override
  _EditRulesDialogState createState() => _EditRulesDialogState();
}

class _EditRulesDialogState extends State<EditRulesDialog> {
  TextEditingController _passwordController = new TextEditingController();
  Map<String, dynamic> rules = {};
  bool isLoading = true;
  List<dynamic> possibleLocations;
  List<dynamic> subList1;
  List<dynamic> subList2;
  List<List<bool>> strikethroughs;
  int numLocationsEnabled = 0;

  @override
  void initState() {
    super.initState();
    getCurrentRules();
  }

  getCurrentRules() async {
    if (widget.game == 'The Hunt') {
      // get possible locations
      var locationData = (await Firestore.instance
              .collection('locations')
              .document('possible')
              .get())
          .data;
      setState(() {
        possibleLocations = locationData['locations'];
        subList2 = possibleLocations.sublist(0, possibleLocations.length ~/ 2);
        subList1 = possibleLocations.sublist(possibleLocations.length ~/ 2);
      });
    }
    var sessionData = (await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .get())
        .data;
    switch (widget.game) {
      case 'The Hunt':
        rules['numSpies'] = sessionData['rules']['numSpies'];
        rules['locations'] = sessionData['rules']['locations'];
        break;
      case 'Abstract':
        rules['boardSize'] = sessionData['rules']['boardSize'];
        rules['numTeams'] = sessionData['rules']['numTeams'];
        break;
    }
    setState(() {
      isLoading = false;
    });
    if (widget.game == 'The Hunt') {
      getChosenLocations();
    }
  }

  updateRules() async {
    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .updateData({'rules': rules});
    Navigator.of(context).pop();
  }

  locationCallback() {
    // update the rules, they will be saved when update is pressed
    // check strikethroughs, add all non striked to new rules value
    rules['locations'] = [];
    numLocationsEnabled = 0;
    subList1.asMap().forEach((index, value) {
      if (!strikethroughs[0][index]) {
        rules['locations'].add(value);
        numLocationsEnabled += 1;
      }
    });
    subList2.asMap().forEach((index, value) {
      if (!strikethroughs[1][index]) {
        rules['locations'].add(value);
        numLocationsEnabled += 1;
      }
    });
    setState(() {
      numLocationsEnabled = numLocationsEnabled;
    });
  }

  Widget getChosenLocations() {
    // this only runs on init
    setState(() {
      subList2 = possibleLocations.sublist(0, possibleLocations.length ~/ 2);
      subList1 = possibleLocations.sublist(possibleLocations.length ~/ 2);
    });
    strikethroughs = [
      List.filled(subList1.length, true),
      List.filled(subList2.length, true),
    ];
    // for each current location, mark as false for strikethrough (find indexes of possible location)
    numLocationsEnabled = 0;
    for (var location in rules['locations']) {
      if (subList1.contains(location)) {
        strikethroughs[0][subList1.indexOf(location)] = false;
        numLocationsEnabled += 1;
      } else {
        strikethroughs[1][subList2.indexOf(location)] = false;
        numLocationsEnabled += 1;
      }
    }
    setState(() {
      numLocationsEnabled = numLocationsEnabled;
    });
    return LocationBoard(
      subList1: subList1,
      subList2: subList2,
      strikethroughs: strikethroughs,
      contentsOnly: true,
      callback: locationCallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    if (isLoading) {
      return AlertDialog();
    }
    switch (widget.game) {
      case 'The Hunt':
        return AlertDialog(
          title: Text('Edit game rules:'),
          contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
          content: Container(
            // decoration: BoxDecoration(border: Border.all()),
            height:
                subList2 != null ? 120 + 40 * subList1.length.toDouble() : 100,
            width: width * 0.95,
            child: ListView(
              children: <Widget>[
                SizedBox(height: 20),
                Text('Number of spies:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['numSpies'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['numSpies'] = newValue;
                      });
                    },
                    items: <int>[1, 2, 3, 4, 5]
                        .map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString(),
                            style: TextStyle(fontFamily: 'Balsamiq')),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                    'Locations: $numLocationsEnabled/${possibleLocations.length}'),
                SizedBox(height: 5),
                getChosenLocations(),
              ],
            ),
          ),
          actions: <Widget>[
            Container(
              child: FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
            ),
            FlatButton(
              onPressed: () {
                updateRules();
              },
              child: Text('Update'),
            )
          ],
        );
        break;
      case 'Abstract':
        return AlertDialog(
          title: Text('Edit game rules:'),
          contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
          content: Container(
            // decoration: BoxDecoration(border: Border.all()),
            height: 200,
            width: width * 0.95,
            child: ListView(
              children: <Widget>[
                SizedBox(height: 20),
                Text('Board Size:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['boardSize'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['boardSize'] = newValue;
                      });
                    },
                    items: <int>[5, 6].map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString(),
                            style: TextStyle(fontFamily: 'Balsamiq')),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 10),
                Text('Num teams:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['numTeams'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['numTeams'] = newValue;
                      });
                    },
                    items: <int>[2, 3].map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString(),
                            style: TextStyle(fontFamily: 'Balsamiq')),
                      );
                    }).toList(),
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
                child: Text('Cancel'),
              ),
            ),
            FlatButton(
              onPressed: () {
                updateRules();
              },
              child: Text('Update'),
            )
          ],
        );
        break;
      default:
        return AlertDialog(
          title: Text('Edit Rules (unknown game)'),
          content: ListView(
            children: <Widget>[
              Text('Getting here is a bug lol, let Matt know')
            ],
          ),
        );
    }
  }
}
