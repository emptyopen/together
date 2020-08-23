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
import '../services/three_crowns_services.dart';
import 'package:together/constants/values.dart';
import 'package:together/services/services.dart';
import 'package:together/screens/thehunt_screen.dart';
import 'package:together/screens/abstract_screen.dart';
import 'package:together/screens/bananaphone_screen.dart';
import 'package:together/screens/three_crowns_screen.dart';
import 'package:together/screens/rivers_screen.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

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
            case 'Rivers':
              slideTransition(
                context,
                RiversScreen(
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

  kickSpectator(String spectatorId) async {
    // remove playerId from session
    var data = (await Firestore.instance
            .collection('sessions')
            .document(sessionId)
            .get())
        .data;
    var currSpecators = data['spectatorIds'];
    currSpecators.removeWhere((item) => item == spectatorId);
    await Firestore.instance
        .collection('sessions')
        .document(sessionId)
        .updateData({'spectatorIds': currSpecators});
  }

  setupTheHunt(data) async {
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
    var location = possibleLocations[_random.nextInt(possibleLocations.length)];
    data['location'] = location;

    // randomize player order
    var playerIds = data['playerIds'];
    playerIds.shuffle();

    // add player names
    data['playerNames'] = {};
    for (int i = 0; i < playerIds.length; i++) {
      data['playerNames'][playerIds[i]] = (await Firestore.instance
              .collection('users')
              .document(playerIds[i])
              .get())
          .data['name'];
    }

    // set player roles - mapping of playerId to role
    data['playerRoles'] = {};
    // spies
    int numSpies = data['rules']['numSpies'];
    var i = 0;
    while (i < numSpies) {
      data['playerRoles'][playerIds[i]] = 'spy';
      i += 1;
    }
    // citizens
    List<dynamic> possibleRoles = (await Firestore.instance
            .collection('locations')
            .document(location)
            .get())
        .data['roles'];
    while (i < playerIds.length) {
      data['playerRoles'][playerIds[i]] =
          possibleRoles[_random.nextInt(possibleRoles.length)];
      i += 1;
    }

    // set accused to noone
    data['accusation'] = {};

    // set spyRevealed to noone
    data['spyRevealed'] = '';

    return data;
  }

  setupAbstract(data) async {
    var rules = data['rules'];
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

    // verify at least one word set is selected
    if (!rules['generalWordsOn'] &&
        !rules['locationsWordsOn'] &&
        !rules['peopleWordsOn']) {
      startError = 'At least one word set must be selected';
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
    var possibleWords = [];
    // add selected word sets
    if (rules['generalWordsOn']) {
      possibleWords.addAll(abstractGeneralWords);
    }
    if (rules['peopleWordsOn']) {
      possibleWords.addAll(abstractPeopleWords);
    }
    if (rules['locationsWordsOn']) {
      possibleWords.addAll(abstractLocationWords);
    }
    var wordsHashSet = HashSet();
    for (var i = 0; i < boardSize; i++) {
      words.add(RowList());
      for (var j = 0; j < boardSize; j++) {
        Random _random = new Random();
        String wordToAdd = possibleWords[_random.nextInt(possibleWords.length)];
        while (wordsHashSet.contains(wordToAdd)) {
          wordToAdd = possibleWords[_random.nextInt(possibleWords.length)];
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
    var players = data['playerIds'];
    players.shuffle();
    if (rules['numTeams'] == 2) {
      // divide playerIds into 2 teams
      rules['greenTeam'] = players.sublist(0, players.length ~/ 2);
      rules['greenLeader'] = players[0];
      rules['orangeTeam'] =
          players.sublist(players.length ~/ 2, players.length);
      rules['orangeLeader'] = players[players.length ~/ 2];
    } else {
      // divide playerIds into 3 teams
      rules['greenTeam'] = players.sublist(0, players.length ~/ 3);
      rules['greenLeader'] = players[0];
      rules['orangeTeam'] =
          players.sublist(players.length ~/ 3, players.length ~/ 3 * 2);
      rules['orangeLeader'] = players[players.length ~/ 3];
      rules['purpleTeam'] =
          players.sublist(players.length ~/ 3 * 2, players.length);
      rules['purpleLeader'] = players[players.length ~/ 3 * 2];
    }

    // initialize cumulative times
    if (rules['numTeams'] == 2) {
      data['greenTime'] = 0;
      data['orangeTime'] = 0;
      data['greenStart'] = DateTime.now();
      data['orangeStart'] = DateTime.now();
      data['timer'] = DateTime.now().add(
        Duration(seconds: 9 * rules['turnTimer'] + 120),
      );
    } else {
      data['greenTime'] = 0;
      data['orangeTime'] = 0;
      data['purpleTime'] = 0;
      data['greenStart'] = DateTime.now();
      data['orangeStart'] = DateTime.now();
      data['purpleStart'] = DateTime.now();
      data['timer'] = DateTime.now().add(
        Duration(seconds: 8 * rules['turnTimer'] + 120),
      );
    }

    data['rules'] = rules;
    return data;
  }

  setupBananaphone(data) async {
    // verify that there are sufficient number of players
    if ((data['rules']['numDrawDescribe'] == 2 &&
            data['playerIds'].length < 4) ||
        (data['rules']['numDrawDescribe'] == 3 &&
            data['playerIds'].length < 6)) {
      setState(() {
        if (data['rules']['numDrawDescribe'] == 2) {
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

    // initialize score and voteStatus per player
    data['scores'] = [];
    data['votes'] = [];
    data['playerIds'].asMap().forEach((i, v) async {
      data['scores'].add(0);
      data['votes'].add(false);
    });

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

    data['rules']['prompts'] = prompts;

    return data;
  }

  setupThreeCrowns(data) async {
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

    // initialize players' data
    var playerIds = data['playerIds'];
    playerIds.asMap().forEach((i, v) async {
      data['player${v}Hand'] = [];
      while (data['player${v}Hand'].length < 5) {
        String randomCard = generateRandomThreeCrownsCard();
        data['player${v}Hand'].add(randomCard);
      }
      data['player${i}Tiles'] = [];
      data['player${i}Crowns'] = 0;
    });

    // add player names
    data['playerNames'] = {};
    for (int i = 0; i < playerIds.length; i++) {
      data['playerNames'][playerIds[i]] = (await Firestore.instance
              .collection('users')
              .document(playerIds[i])
              .get())
          .data['name'];
    }

    data['duel'] = {'duelerIndex': 0, 'duelerCard': '', 'dueleeCard': ''};

    return data;
  }

  setupRivers(data) async {
    // verify that there are sufficient number of players
    if (data['playerIds'].length < 2) {
      setState(() {
        startError = 'Need at least 2 players';
      });
      return;
    }

    // clear error if we are good to start
    setState(() {
      startError = '';
    });

    // initialize players' data
    var playerIds = data['playerIds'];
    var shuffledDeck =
        new List<int>.generate(data['rules']['cardRange'] - 2, (i) => i + 2);
    shuffledDeck.shuffle();
    var shuffledDeckIndex = 0;

    playerIds.asMap().forEach((i, v) async {
      data['player${i}Hand'] = [];
      while (data['player${i}Hand'].length < data['rules']['handSize']) {
        data['player${i}Hand'].add(shuffledDeck[shuffledDeckIndex]);
        shuffledDeckIndex += 1;
      }
      await Firestore.instance
          .collection('sessions')
          .document(sessionId)
          .updateData({'player${i}Hand': data['player${i}Hand']});
    });

    // add player names
    data['playerNames'] = {};
    for (int i = 0; i < playerIds.length; i++) {
      data['playerNames'][playerIds[i]] = (await Firestore.instance
              .collection('users')
              .document(playerIds[i])
              .get())
          .data['name'];
    }

    data['log'] = ['', '', ''];
    data['cardsToPlay'] = 2;
    data['drawPile'] =
        shuffledDeck.sublist(shuffledDeckIndex, shuffledDeck.length);
    data['ascendPile1'] = [1];
    data['ascendPile2'] = [1];
    data['descendPile1'] = [data['rules']['cardRange']];
    data['descendPile2'] = [data['rules']['cardRange']];

    return data;
  }

  startGame(data) async {
    // initialize final values/rules for games
    switch (gameName) {
      case 'The Hunt':
        print('Setting up The Hunt game...');
        data = await setupTheHunt(data);
        break;

      case 'Abstract':
        print('Setting up Abstract game...');
        data = await setupAbstract(data);
        break;

      case 'Bananaphone':
        print('Setting up Bananaphone game...');
        data = await setupBananaphone(data);
        break;

      case 'Three Crowns':
        print('Setting up Bananaphone game...');
        data = await setupThreeCrowns(data);
        break;

      case 'Rivers':
        print('Setting up Rivers game...');
        data = await setupRivers(data);
        break;
    }

    if (startError == '') {
      // update data
      data['state'] = 'started';
      data['startTime'] = DateTime.now().add(Duration(seconds: 5));
      await Firestore.instance
          .collection('sessions')
          .document(sessionId)
          .setData(data);
    }
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
          'Game is starting in ${startTime.difference(_now).inSeconds}',
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
            SizedBox(height: 5),
            RulesContainer(
              rules: <Widget>[
                Text(
                  'General words on:',
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  rules['generalWordsOn'].toString(),
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 2),
            RulesContainer(
              rules: <Widget>[
                Text(
                  'People words on:',
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  rules['peopleWordsOn'].toString(),
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 2),
            RulesContainer(
              rules: <Widget>[
                Text(
                  'Locations words on:',
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  rules['locationsWordsOn'].toString(),
                  style: TextStyle(fontSize: 12),
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
      case 'Rivers':
        return Column(
          children: <Widget>[
            RulesContainer(rules: <Widget>[
              Text(
                'Card Range:',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                rules['cardRange'].toString(),
                style: TextStyle(fontSize: 18),
              ),
            ]),
            SizedBox(height: 5),
            RulesContainer(
              rules: <Widget>[
                Text(
                  'Hand Size:',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  rules['handSize'].toString(),
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ],
        );
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
                              ? Row(
                                  children: <Widget>[
                                    SizedBox(width: 20),
                                    GestureDetector(
                                      child: Icon(
                                        MdiIcons.accountRemove,
                                        size: 20,
                                        color: Colors.redAccent,
                                      ),
                                      onTap: () => kickPlayer(playerIds[index]),
                                    ),
                                  ],
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

  Widget _getSpectators(data) {
    var spectatorIds = data['spectatorIds'];
    return Container(
      height: 16.0 * spectatorIds.length,
      child: ListView.builder(
          itemCount: spectatorIds.length,
          itemBuilder: (context, index) {
            return FutureBuilder(
                future: Firestore.instance
                    .collection('users')
                    .document(spectatorIds[index])
                    .get(),
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
                          fontSize: 14,
                          color: userId == spectatorIds[index]
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                        ),
                      ),
                      Text(
                        spectatorIds[index] == data['leader']
                            ? ' (glorious leader) '
                            : '',
                        style: TextStyle(fontSize: 14),
                      ),
                      userId == data['leader'] &&
                              spectatorIds[index] == data['leader']
                          ? SizedBox(height: 16)
                          : Container(),
                      userId == data['leader'] &&
                              spectatorIds[index] != data['leader']
                          ? Row(
                              children: <Widget>[
                                SizedBox(width: 10),
                                GestureDetector(
                                  child: Icon(
                                    MdiIcons.accountRemove,
                                    size: 16,
                                    color: Colors.redAccent,
                                  ),
                                  onTap: () =>
                                      kickSpectator(spectatorIds[index]),
                                ),
                              ],
                            )
                          : Container(),
                    ],
                  );
                });
          }),
    );
  }

  toggleSpectator(data) async {
    bool userIsPlayer = data['playerIds'].contains(userId);
    if (userIsPlayer) {
      // remove from playerIds and add to spectatorIds
      data['playerIds'].remove(userId);
      data['spectatorIds'].add(userId);
    } else {
      // remove from spectatorIds and add to playerIds
      data['playerIds'].add(userId);
      data['spectatorIds'].remove(userId);
    }
    await Firestore.instance
        .collection('sessions')
        .document(sessionId)
        .setData(data);
  }

  _getSwitchSpectatorButton(data) {
    bool userIsPlayer = data['playerIds'].contains(userId);
    return RaisedGradientButton(
        child: Text(userIsPlayer ? 'Switch to spectator' : 'Switch to player',
            style: TextStyle(
              fontSize: 12,
            )),
        height: 30,
        width: 130,
        gradient: LinearGradient(
          colors: userIsPlayer
              ? [Colors.grey[600], Colors.grey[500]]
              : [
                  Colors.blue[600],
                  Colors.blue[500],
                ],
        ),
        onPressed: () {
          toggleSpectator(data);
        });
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
    // TODO: check if this is working
    if ((startTime != null && _now != null) &&
        startTime.difference(_now).inSeconds < 0) {
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
            key: _scaffoldKey,
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
                    Text(
                      'Spectators:',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    PageBreak(width: 50, color: Colors.grey),
                    _getSpectators(data),
                    SizedBox(height: 10),
                    userId != data['leader']
                        ? _getSwitchSpectatorButton(data)
                        : Container(),
                    SizedBox(height: 20),
                    Text('Rules:', style: TextStyle(fontSize: 20)),
                    PageBreak(
                      width: 50,
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
        rules['generalWordsOn'] = sessionData['rules']['generalWordsOn'];
        rules['peopleWordsOn'] = sessionData['rules']['peopleWordsOn'];
        rules['locationsWordsOn'] = sessionData['rules']['peopleWordsOn'];
        break;
      case 'Bananaphone':
        rules['numRounds'] = sessionData['rules']['numRounds'];
        rules['numDrawDescribe'] = sessionData['rules']['numDrawDescribe'];
        break;
      case 'Three Crowns':
        rules['maxWordLength'] = sessionData['rules']['maxWordLength'];
        break;
      case 'Rivers':
        rules['cardRange'] = sessionData['rules']['cardRange'];
        rules['handSize'] = sessionData['rules']['handSize'];
        break;
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
            height: 310,
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
                SizedBox(height: 20),
                Text('Words:'),
                Container(
                  width: 80,
                  child: Column(
                    children: <Widget>[
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            rules['generalWordsOn'] = !rules['generalWordsOn'];
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: rules['generalWordsOn']
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                          ),
                          padding: EdgeInsets.all(5),
                          child: Text(
                            'General',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            rules['peopleWordsOn'] = !rules['peopleWordsOn'];
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: rules['peopleWordsOn']
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                          ),
                          padding: EdgeInsets.all(5),
                          child: Text(
                            'People',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            rules['locationsWordsOn'] =
                                !rules['locationsWordsOn'];
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: rules['locationsWordsOn']
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                          ),
                          padding: EdgeInsets.all(5),
                          child: Text(
                            'Locations',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
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
      case 'Rivers':
        return AlertDialog(
          title: Text('Edit game rules:'),
          contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
          content: Container(
            // decoration: BoxDecoration(border: Border.all()),
            height: 170,
            width: width * 0.95,
            child: ListView(
              children: <Widget>[
                SizedBox(height: 20),
                Text('Maximum word length:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['cardRange'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['cardRange'] = newValue;
                      });
                    },
                    items: <int>[80, 100, 120, 140]
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
                Text('Maximum hand size:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['handSize'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['handSize'] = newValue;
                      });
                    },
                    items:
                        <int>[5, 6, 7].map<DropdownMenuItem<int>>((int value) {
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
