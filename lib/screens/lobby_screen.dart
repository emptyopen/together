import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/services.dart';

import '../components/buttons.dart';
import '../components/layouts.dart';
import '../components/misc.dart';
import '../models/models.dart';
import 'package:together/constants/values.dart';
import 'package:together/services/services.dart';
import 'package:together/screens/thehunt_screen.dart';
import 'package:together/screens/abstract_screen.dart';
import 'package:together/screens/bananaphone_screen.dart';
import 'package:together/screens/three_crowns_screen.dart';

class LobbyScreen extends StatefulWidget {
  LobbyScreen({Key key, this.roomCode}) : super(key: key);

  final String roomCode;

  @override
  _LobbyScreenState createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  bool isStarting = false;
  Timer _timer;
  DateTime startTime;
  DateTime _now;
  String sessionId;
  String userId;
  String leaderId;
  String gameName;
  bool calledGameRoom = false;
  bool isLoading = true;
  String startError = '';
  bool willVibrate1 = true;
  bool willVibrate2 = true;
  bool willVibrate3 = true;

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
        if (startTime.difference(_now).inSeconds == 1) {
          if (willVibrate1) {
            HapticFeedback.vibrate();
            willVibrate1 = false;
          }
        }
        if (startTime.difference(_now).inSeconds == 2) {
          if (willVibrate2) {
            HapticFeedback.vibrate();
            willVibrate2 = false;
          }
        }
        if (startTime.difference(_now).inSeconds == 3) {
          if (willVibrate3) {
            HapticFeedback.vibrate();
            willVibrate3 = false;
          }
        }
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
                ),
              );
              break;
            case 'Bananaphone':
              slideTransition(
                context,
                BananaphoneScreen(
                  sessionId: sessionId,
                  userId: userId,
                  roomCode: widget.roomCode,
                ),
              );
              break;
            case 'Three Crowns':
              slideTransition(
                context,
                ThreeCrownsScreen(
                  sessionId: sessionId,
                  userId: userId,
                  roomCode: widget.roomCode,
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
          gameName = documentData['game'];
          isLoading = false;
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

  startGame(data) async {
    var rules = data['rules'];

    if (data.containsKey('setupComplete') && data['setupComplete']) {
      print('skipping setup, already complete');
    } else {
      // initialize final values/rules for games
      switch (gameName) {
        case 'The Hunt':
          print('Setting up The Hunt game...');

          // verify that there are sufficient number of players
          if (data['playerIds'].length < 3) {
            setState(() {
              startError = 'Need at least 3 players';
            });
            return;
          }

          // clear error if we are good to start
          setState(() {
            startError = '';
          });

          // initialize random tool
          final _random = new Random();

          // set location
          var possibleLocations = data['rules']['locations'];
          var location =
              possibleLocations[_random.nextInt(possibleLocations.length)];
          print('location is $location');

          // randomize player order
          var playerIds = data['playerIds'];
          playerIds.shuffle();

          // set spies
          int numSpies = data['rules']['numSpies'];
          var i = 0;
          while (i < numSpies) {
            print('spy is ${playerIds[i]}');
            await Firestore.instance
                .collection('users')
                .document(playerIds[i])
                .updateData({'huntRole': 'spy', 'huntLocation': location});
            i += 1;
          }

          // set other roles
          List<dynamic> possibleRoles = (await Firestore.instance
                  .collection('locations')
                  .document(location)
                  .get())
              .data['roles'];
          while (i < playerIds.length) {
            print('player ${playerIds[i]} is not spy');
            await Firestore.instance
                .collection('users')
                .document(playerIds[i])
                .updateData({
              'huntRole': possibleRoles[_random.nextInt(possibleRoles.length)],
              'huntLocation': location,
            });
            i += 1;
          }
          break;

        case 'Abstract':
          print('Setting up Abstract game...');

          // verify that there are sufficient number of players
          if ((rules['numTeams'] == 2 && data['playerIds'].length < 4) ||
              (rules['numTeams'] == 3 && data['playerIds'].length < 6)) {
            setState(() {
              if (rules['numTeams'] == 2) {
                startError = 'Need at least 4 players for two teams';
              } else {
                startError = 'Need at least 6 players for three teams';
              }
            });
            return;
          }

          // clear error if we are good to start
          setState(() {
            startError = '';
          });

          // initialize board, words
          var boardSize = 5;
          if (rules['numTeams'] == 3) {
            boardSize = 6;
          }
          List<RowList> words = [];
          var wordsHashSet = HashSet();
          for (var i = 0; i < boardSize; i++) {
            words.add(RowList());
            for (var j = 0; j < boardSize; j++) {
              Random _random = new Random();
              String wordToAdd = abstractPossibleWords[
                  _random.nextInt(abstractPossibleWords.length)];
              while (wordsHashSet.contains(wordToAdd)) {
                wordToAdd = abstractPossibleWords[
                    _random.nextInt(abstractPossibleWords.length)];
              }
              wordsHashSet.add(wordToAdd);
              words[i].add(wordToAdd);
            }
          }

          // functions for getting random coordinates for board size
          Random _random = new Random();
          Coords randomCoords(int boardSize) {
            return Coords(
                x: _random.nextInt(boardSize), y: _random.nextInt(boardSize));
          }
          // function for filling a list with unused random coordinates
          List<Coords> getWordCoords(
              HashSet wordCoordsHashSet, int boardSize, int numWords) {
            List<Coords> coordsList = [];
            while (coordsList.length < numWords) {
              Coords coordsToAdd = randomCoords(boardSize);
              while (wordCoordsHashSet.contains(coordsToAdd)) {
                coordsToAdd = randomCoords(boardSize);
              }
              wordCoordsHashSet.add(coordsToAdd);
              coordsList.add(Coords(x: coordsToAdd.x, y: coordsToAdd.y));
            }
            return coordsList;
          }
          // update colors for words for teams / death word
          // 2 teams & 5x5=25: (9, 8) = 17, 7 neutral, 1 death
          // 3 teams & 6x6=36: (10, 9, 8) = 27, 8 neutral, 1 death
          var wordCoordsHashSet = HashSet();
          if (rules['numTeams'] == 2) {
            // var possibleCardsNeeded = [9, 8];
            // possibleCardsNeeded.shuffle();
            for (var coords in getWordCoords(wordCoordsHashSet, 5, 9)) {
              words[coords.x].rowWords[coords.y]['color'] = 'green';
            }
            for (var coords in getWordCoords(wordCoordsHashSet, 5, 9)) {
              words[coords.x].rowWords[coords.y]['color'] = 'orange';
            }
            for (var coords in getWordCoords(wordCoordsHashSet, 5, 1)) {
              words[coords.x].rowWords[coords.y]['color'] = 'black';
            }
          } else {
            // var possibleCardsNeeded = [9, 8, 7];
            // possibleCardsNeeded.shuffle();
            // set order for now (otherwise need to keep track of which team needs to do the most)
            for (var coords in getWordCoords(wordCoordsHashSet, 6, 8)) {
              //possibleCardsNeeded[0])) {
              words[coords.x].rowWords[coords.y]['color'] = 'green';
            }
            for (var coords in getWordCoords(wordCoordsHashSet, 6, 8)) {
              words[coords.x].rowWords[coords.y]['color'] = 'orange';
            }
            for (var coords in getWordCoords(wordCoordsHashSet, 6, 8)) {
              words[coords.x].rowWords[coords.y]['color'] = 'purple';
            }
            for (var coords in getWordCoords(wordCoordsHashSet, 5, 1)) {
              words[coords.x].rowWords[coords.y]['color'] = 'black';
            }
          }
          // set words
          var serializedWords = [];
          for (var i = 0; i < boardSize; i++) {
            serializedWords.add(words[i].toJson());
          }
          rules['words'] = serializedWords;

          // set greenAlreadyWon for ensuring rebuttal for orange/purple
          rules['greenAlreadyWon'] = false;

          // initialize who is on which teams, and spymasters
          // update user documents with their team color and isTeamLeader
          // TODO: might want fine grained control of teams in lobby
          var players = data['playerIds'];
          players.shuffle();
          if (rules['numTeams'] == 2) {
            // divide playerIds into 2 teams
            rules['greenTeam'] = players.sublist(0, players.length ~/ 2);
            for (var playerId in rules['greenTeam']) {
              await Firestore.instance
                  .collection('users')
                  .document(playerId)
                  .updateData({
                'abstractTeam': 'green',
                'abstractTeamLeader': '',
              });
            }
            rules['greenLeader'] = players[0];
            await Firestore.instance
                .collection('users')
                .document(rules['greenLeader'])
                .updateData({'abstractTeamLeader': 'green'});
            rules['orangeTeam'] =
                players.sublist(players.length ~/ 2, players.length);
            for (var playerId in rules['orangeTeam']) {
              await Firestore.instance
                  .collection('users')
                  .document(playerId)
                  .updateData({
                'abstractTeam': 'orange',
                'abstractTeamLeader': '',
              });
            }
            rules['orangeLeader'] = players[players.length ~/ 2];
            await Firestore.instance
                .collection('users')
                .document(rules['orangeLeader'])
                .updateData({'abstractTeamLeader': 'orange'});
          } else {
            // divide playerIds into 3 teams
            rules['greenTeam'] = players.sublist(0, players.length ~/ 3);
            for (var playerId in rules['greenTeam']) {
              await Firestore.instance
                  .collection('users')
                  .document(playerId)
                  .updateData({
                'abstractTeam': 'green',
                'abstractTeamLeader': '',
              });
            }
            rules['greenLeader'] = players[0];
            await Firestore.instance
                .collection('users')
                .document(rules['greenLeader'])
                .updateData({'abstractTeamLeader': 'green'});
            rules['orangeTeam'] =
                players.sublist(players.length ~/ 3, players.length ~/ 3 * 2);
            for (var playerId in rules['orangeTeam']) {
              await Firestore.instance
                  .collection('users')
                  .document(playerId)
                  .updateData({
                'abstractTeam': 'orange',
                'abstractTeamLeader': '',
              });
            }
            rules['orangeLeader'] = players[players.length ~/ 3];
            await Firestore.instance
                .collection('users')
                .document(rules['orangeLeader'])
                .updateData({'abstractTeamLeader': 'orange'});
            rules['purpleTeam'] =
                players.sublist(players.length ~/ 3 * 2, players.length);
            for (var playerId in rules['purpleTeam']) {
              await Firestore.instance
                  .collection('users')
                  .document(playerId)
                  .updateData({
                'abstractTeam': 'purple',
                'abstractTeamLeader': '',
              });
            }
            rules['purpleLeader'] = players[players.length ~/ 3 * 2];
            await Firestore.instance
                .collection('users')
                .document(rules['purpleLeader'])
                .updateData({'abstractTeamLeader': 'purple'});
          }

          // start the timer, and initialize cumulative times
          if (rules['numTeams'] == 2) {
            await Firestore.instance
                .collection('sessions')
                .document(sessionId)
                .updateData({
              'greenTime': 0,
              'orangeTime': 0,
              'greenStart': DateTime.now(),
              'orangeStart': DateTime.now(),
              'timer': DateTime.now().add(
                Duration(
                    seconds: (rules['numTeams'] == 2 ? 9 : 8) *
                        rules['turnTimer'] + 120),
              )
            });
          } else {
            await Firestore.instance
                .collection('sessions')
                .document(sessionId)
                .updateData({
              'greenTime': 0,
              'orangeTime': 0,
              'purpleTime': 0,
              'greenStart': DateTime.now(),
              'orangeStart': DateTime.now(),
              'purpleStart': DateTime.now(),
              'timer': DateTime.now().add(
                Duration(
                    seconds: (rules['numTeams'] == 2 ? 9 : 8) *
                        rules['turnTimer']),
              )
            });
          }

          break;

        case 'Bananaphone':
          print('Setting up Bananaphone game...');

          // verify that there are sufficient number of players
          if ((rules['numDrawDescribe'] == 2 && data['playerIds'].length < 4) ||
              (rules['numDrawDescribe'] == 3 && data['playerIds'].length < 6)) {
            setState(() {
              if (rules['numDrawDescribe'] == 2) {
                startError = 'Need at least 4 players for 2 rounds of draw/describe';
              } else {
                startError = 'Need at least 6 players for 3 rounds of draw/describe';
              }
            });
            return;
          }

          // clear error if we are good to start
          setState(() {
            startError = '';
          });

          // initialize random tool
          final _random = new Random();

          // initialize score per player
          var scores = [];
          data['playerIds'].asMap().forEach((i, v) async {
            scores.add(0);
            await Firestore.instance
                .collection('sessions')
                .document(sessionId)
                .updateData({'player${i}Voted': false});
          });
          await Firestore.instance
              .collection('sessions')
              .document(sessionId)
              .updateData({'scores': scores});

          // set prompts (one per player per round)
          var prompts = [];
          HashSet usedPrompts = HashSet();
          for (var round = 0; round < data['rules']['numRounds']; round++) {
            var roundPrompt = RoundPrompts();
            for (String _ in data['playerIds']) {
              // find two unused prompt
              String promptToAdd = bananaphonePossiblePrompts[
                  _random.nextInt(bananaphonePossiblePrompts.length)];
              while (usedPrompts.contains(promptToAdd)) {
                promptToAdd = bananaphonePossiblePrompts[
                    _random.nextInt(bananaphonePossiblePrompts.length)];
              }
              usedPrompts.add(promptToAdd);
              var promptsToAdd = promptToAdd;
              roundPrompt.add(promptsToAdd);
            }
            prompts.add(roundPrompt.toJson());
          }
          rules['prompts'] = prompts;
          await Firestore.instance
              .collection('sessions')
              .document(sessionId)
              .updateData({'rules': rules});
          break;

        case 'Three Crowns':
          print('Setting up Bananaphone game...');

          // verify that there are sufficient number of players
          if (data['playerIds'].length < 3) {
            setState(() {
              startError = 'Need at least 3 players';
            });
            return;
          }

          // clear error if we are good to start
          setState(() {
            startError = '';
          });

          // initialize players' hands
          data['playerIds'].asMap().forEach((i, v) async {
            // generate random hand
            await Firestore.instance
                .collection('sessions')
                .document(sessionId)
                .updateData({'player${i}Hand': []});
            await Firestore.instance
                .collection('sessions')
                .document(sessionId)
                .updateData({'player${i}Tiles': []});
            await Firestore.instance
                .collection('sessions')
                .document(sessionId)
                .updateData({'player${i}Crowns': 0});
          });

          print('updating $sessionId with $rules');
          await Firestore.instance
              .collection('sessions')
              .document(sessionId)
              .updateData({'rules': rules});

          break;
      }
    }

    await Firestore.instance
        .collection('sessions')
        .document(sessionId)
        .updateData({
      'rules': rules,
      'state': 'started',
      'startTime': DateTime.now().add(Duration(seconds: 5)),
      'setupComplete': true,
    });
  }

  Widget _getCountdown(BuildContext context, data) {
    // check if we are in the started state. if we aren't, display nothing.
    if (data['state'] == 'lobby') {
      return Container();
    }
    // if we are started, countdown if we are before the time, otherwise pop and move to game room
    isStarting = true;
    startTime = data['startTime'].toDate();
    return Column(
      children: <Widget>[
        Text(
          (startTime == null || _now == null) &&
                  startTime.difference(_now).inSeconds < 0
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

  Widget getRules(BuildContext context, data) {
    var rules = data['rules'];
    switch (gameName) {
      case 'The Hunt':
        return Container(
          width: 250,
          child: Column(
            children: <Widget>[
              Text('Number of spies: ${rules['numSpies']}'),
              SizedBox(height: 5),
              Text('Possible locations: ${rules['locations']}'),
            ],
          ),
        );
        break;
      case 'Abstract':
        return Column(
          children: <Widget>[
            RulesContainer(
              rules: <Widget>[
                Text(
                  'Number of Teams:',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  rules['numTeams'].toString(),
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
            SizedBox(height: 5),
            RulesContainer(
              rules: <Widget>[
                Text(
                  'Turn timer:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  '(seconds per remaining word)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  rules['turnTimer'].toString(),
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ],
        );
        break;
      case 'Bananaphone':
        return Column(
          children: <Widget>[
            RulesContainer(rules: <Widget>[
              Text('Number of rounds: ${rules['numRounds']}'),
            ]),
            SizedBox(height: 5),
            RulesContainer(rules: <Widget>[
              Text('Number of draw/describe: ${rules['numDrawDescribe']}'),
            ]),
          ],
        );
        break;
      case 'Three Crowns':
        return RulesContainer(rules: <Widget>[
          Text('Maximum word length: ${rules['maxWordLength']}'),
        ]);
        break;
      default:
        return Text('Unknown game');
    }
  }

  Widget _getPlayers(data) {
    // if start date exists and we are past it, move to game screen (with session id)
    var playerIds = data['playerIds'];
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
                                  : Theme.of(context).highlightColor,
                            ),
                          ),
                          Text(
                            playerIds[index] == data['leader']
                                ? ' (glorious leader) '
                                : '',
                            style: TextStyle(fontSize: 14),
                          ),
                          userId == data['leader'] &&
                                  playerIds[index] == data['leader']
                              ? SizedBox(height: 30)
                              : Container(),
                          userId == data['leader'] &&
                                  playerIds[index] != data['leader']
                              ? SizedBox(
                                  height: 30,
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

  shufflePlayers(data) async {
    var playerOrder = data['playerIds'];
    playerOrder.shuffle();
    await Firestore.instance
        .collection('sessions')
        .document(sessionId)
        .updateData({'playerIds': playerOrder, 'turn': playerOrder[0]});
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            '$gameName: Lobby',
          ),
        ),
        body: Container(),
      );
    }
    return StreamBuilder(
        stream: Firestore.instance
            .collection('sessions')
            .document(sessionId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
                appBar: AppBar(
                  title: Text(
                    '$gameName: Lobby',
                  ),
                ),
                body: Container());
          }
          // all data for all components
          var data = snapshot.data.data;
          return Scaffold(
            appBar: AppBar(
              title: Text(
                '$gameName: Lobby',
              ),
            ),
            body: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: 40),
                    _getCountdown(context, data),
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
                    _getPlayers(data),
                    userId == data['leader'] &&
                            !isStarting &&
                            ['The Hunt', 'Bananaphone'].contains(gameName)
                        ? Column(
                            children: <Widget>[
                              RaisedGradientButton(
                                child: Text(
                                  'Shuffle Players',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                                onPressed: () => shufflePlayers(data),
                                height: 40,
                                width: 170,
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    Theme.of(context).primaryColor,
                                    Theme.of(context).accentColor,
                                  ],
                                ),
                              ),
                              SizedBox(height: 30),
                            ],
                          )
                        : Container(),
                    Text('Rules', style: TextStyle(fontSize: 24)),
                    PageBreak(
                      width: 80,
                    ),
                    getRules(context, data),
                    userId == data['leader'] && !isStarting
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
                                  setState(() {
                                    startError = '';
                                  });
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
                                    color: Colors.black,
                                  ),
                                ),
                                onPressed: () => startGame(data),
                                height: 50,
                                width: 160,
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    Color.fromARGB(255, 255, 185, 0),
                                    Color.fromARGB(255, 255, 213, 0),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10),
                              startError == ''
                                  ? Container()
                                  : Text(
                                      startError,
                                      style: TextStyle(
                                        color: Colors.red,
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
        });
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
        rules['numTeams'] = sessionData['rules']['numTeams'];
        rules['turnTimer'] = sessionData['rules']['turnTimer'];
        break;
      case 'Bananaphone':
        rules['numRounds'] = sessionData['rules']['numRounds'];
        rules['numDrawDescribe'] = sessionData['rules']['numDrawDescribe'];
        break;
      case 'Three Crowns':
        rules['maxWordLength'] = sessionData['rules']['maxWordLength'];
    }
    if (widget.game == 'The Hunt') {
      getChosenLocations();
    }
    setState(() {
      isLoading = false;
    });
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
                SizedBox(height: 20),
                Text('Turn timer:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['turnTimer'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['turnTimer'] = newValue;
                      });
                    },
                    items: <int>[20, 30, 40, 50]
                        .map<DropdownMenuItem<int>>((int value) {
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
      case 'Bananaphone':
        return AlertDialog(
          title: Text('Edit game rules:'),
          contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
          content: Container(
            height: 180,
            width: width * 0.95,
            child: ListView(
              children: <Widget>[
                SizedBox(height: 20),
                Text('Number of rounds:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['numRounds'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['numRounds'] = newValue;
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
                SizedBox(height: 20),
                Text('Number of draw/describes:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['numDrawDescribe'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['numDrawDescribe'] = newValue;
                      });
                    },
                    items: <int>[2, 3]
                        .map<DropdownMenuItem<int>>((int value) {
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
      case 'Three Crowns':
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
                Text('Maximum word length:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['maxWordLength'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['maxWordLength'] = newValue;
                      });
                    },
                    items: <int>[5, 6, 7, 8, 9, 10]
                        .map<DropdownMenuItem<int>>((int value) {
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
