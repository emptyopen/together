import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/services.dart';
// import 'package:audioplayers/audio_cache.dart';
import 'package:string_similarity/string_similarity.dart';

import '../../components/buttons.dart';
import '../../components/misc.dart';
import 'package:together/components/info_box.dart';
import 'package:together/components/scroll_view.dart';
import '../../models/models.dart';
import '../three_crowns/three_crowns_services.dart';
import '../plot_twist/plot_twist_services.dart';
import 'package:together/screens/charade_a_trois/charade_a_trois_services.dart';
import 'package:together/help_screens/help_screens.dart';
import 'package:together/constants/values.dart';
import 'package:together/services/services.dart';
import 'package:together/screens/the_hunt/the_hunt_screen.dart';
import 'package:together/screens/abstract/abstract_screen.dart';
import 'package:together/screens/bananaphone/bananaphone_screen.dart';
import 'package:together/screens/three_crowns/three_crowns_screen.dart';
import 'package:together/screens/rivers/rivers_screen.dart';
import 'package:together/screens/plot_twist/plot_twist_screen.dart';
import 'package:together/screens/charade_a_trois/charade_a_trois_screen.dart';

import 'lobby_components.dart';

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
  // final player = new AudioCache(prefix: 'sounds/');
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    initialize();
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
            case 'Plot Twist':
              slideTransition(
                context,
                PlotTwistScreen(
                  sessionId: sessionId,
                  userId: userId,
                  roomCode: widget.roomCode,
                ),
              );
              break;
            case 'Charáde à Trois':
              slideTransition(
                context,
                CharadeATroisScreen(
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
    await FirebaseFirestore.instance
        .collection('sessions')
        .where('roomCode', isEqualTo: widget.roomCode)
        .get()
        .then((event) async {
      if (event.docs.isNotEmpty) {
        Map<String, dynamic> documentData = event.docs.single.data();
        sessionId = event.docs.single.id;
        userId = FirebaseAuth.instance.currentUser.uid;
        leaderId = event.docs.single.data()['leader'];
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
    var data = (await FirebaseFirestore.instance
            .collection('sessions')
            .doc(sessionId)
            .get())
        .data();
    var currPlayers = data['playerIds'];
    currPlayers.removeWhere((item) => item == playerId);
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .update({'playerIds': currPlayers});
  }

  kickSpectator(String spectatorId) async {
    // remove playerId from session
    var data = (await FirebaseFirestore.instance
            .collection('sessions')
            .doc(sessionId)
            .get())
        .data();
    var currSpecators = data['spectatorIds'];
    currSpecators.removeWhere((item) => item == spectatorId);
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .update({'spectatorIds': currSpecators});
  }

  setupTheHunt(data) async {
    // verify that there are sufficient number of players
    if (data['playerIds'].length < 3) {
      setState(() {
        startError = 'Need at least 3 players';
      });
      return;
    }

    // verify that accusation cooldown is low enough
    if (data['rules']['accusationCooldown'] >
        data['playerIds'].length - 1 - data['rules']['numSpies']) {
      setState(() {
        startError =
            'Accusation cooldown must be less than ${data['playerIds'].length - data['numSpies']}';
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
      data['playerNames'][playerIds[i]] = (await FirebaseFirestore.instance
              .collection('users')
              .doc(playerIds[i])
              .get())
          .data()['name'];
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
    List<dynamic> possibleRoles = (await FirebaseFirestore.instance
            .collection('locations')
            .doc(location)
            .get())
        .data()['roles'];
    while (i < playerIds.length) {
      data['playerRoles'][playerIds[i]] =
          possibleRoles[_random.nextInt(possibleRoles.length)];
      i += 1;
    }

    // set each players individal accusation cooldown to available
    data['playerIds'].asMap().forEach((i, v) {
      data['player${i}AccusationCooldown'] = 0;
    });

    // set accused to noone, and accusation unavailable
    data['accusation'] = {};
    data['remainingAccusationsThisTurn'] = data['rules']['accusationsPerTurn'];
    data['numQuestions'] = 0;

    // set spyRevealed to noone
    data['spyRevealed'] = '';

    data['log'] = ['', '', ''];

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
    data['words'] = serializedWords;

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
    data['greenTime'] = 0;
    data['orangeTime'] = 0;
    data['roundStart'] = DateTime.now();
    if (rules['numTeams'] == 3) {
      data['purpleTime'] = 0;
    }

    data['roundExpiration'] = DateTime.now().add(
      Duration(seconds: 9 * rules['turnTimer'] + 120),
    );

    // add player names
    data['playerNames'] = {};
    for (int i = 0; i < players.length; i++) {
      data['playerNames'][players[i]] = (await FirebaseFirestore.instance
              .collection('users')
              .doc(players[i])
              .get())
          .data()['name'];
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
    if (data['playerIds'].length < 2) {
      setState(() {
        startError = 'Need at least 2 players';
      });
      return;
    }

    // check valid rules
    if (data['rules']['minWordLength'] > data['rules']['maxWordLength']) {
      setState(() {
        startError = 'Impossible word length!';
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
      data['player${i}Hand'] = [];
      while (data['player${i}Hand'].length < threeCardsHandSize) {
        String randomCard = generateRandomThreeCrownsCard();
        data['player${i}Hand'].add(randomCard);
      }
      data['player${i}Tiles'] = [];
      data['player${i}Crowns'] = 0;
      data['player${i}SelectedTiles'] = [];
    });

    // add player names
    data['playerNames'] = {};
    for (int i = 0; i < playerIds.length; i++) {
      data['playerNames'][playerIds[i]] = (await FirebaseFirestore.instance
              .collection('users')
              .doc(playerIds[i])
              .get())
          .data()['name'];
    }

    data['log'] = ['', '', ''];

    data['targetWord'] = generateRandomWord(
        data['rules']['minWordLength'], data['rules']['maxWordLength']);

    data['duel'] = {
      'duelerIndex': 0,
      'dueleeIndex': 1,
      'duelerCard': '',
      'dueleeCard': '',
      'joust': 1,
      'state': 'duel',
      'matchingCards': [],
      'peasantCards': [],
      'oldJoustCards': {},
      'tilePrizes': [],
      'pillagePrize': 0,
      'matcherIndex': 0,
      'responderIndex': 0,
      'winnerIndex': 0,
    };

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
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .update({'player${i}Hand': data['player${i}Hand']});
    });

    // add player names
    data['playerNames'] = {};
    for (int i = 0; i < playerIds.length; i++) {
      data['playerNames'][playerIds[i]] = (await FirebaseFirestore.instance
              .collection('users')
              .doc(playerIds[i])
              .get())
          .data()['name'];
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

  setupPlotTwist(data) async {
    var playerIds = data['playerIds'];
    // verify that there are sufficient number of players
    if (data['playerIds'].length < data['rules']['numNarrators'] + 2) {
      setState(() {
        startError =
            'Need at least ${data['rules']['numNarrators'] + 2} players for ${data['rules']['numNarrators']} narrators.';
      });
      return;
    }

    data['characters'] = {};

    // determine narrators randomly
    playerIds.shuffle();
    data['narrators'] = [];
    for (int i = 0; i < data['rules']['numNarrators']; i++) {
      data['narrators'].add(playerIds[i]);
      data['characters'][playerIds[i]] = {
        'name': 'Narrator',
        'age': 99,
        'description': 'A narrator',
      };
    }

    if (data['playerIds'].length - data['narrators'].length > 10) {
      setState(() {
        startError = 'Max players is ${10 + data['narrators'].length}.';
      });
      return;
    }

    // clear error if we are good to start
    setState(() {
      startError = '';
    });

    // add player names
    data['playerNames'] = {};
    for (int i = 0; i < playerIds.length; i++) {
      data['playerNames'][playerIds[i]] = (await FirebaseFirestore.instance
              .collection('users')
              .doc(playerIds[i])
              .get())
          .data()['name'];
    }

    // add player colors randomly
    var possibleColors = [
      'green',
      'blue',
      'pink',
      'orange',
      'purple',
      'lime',
      'red',
      'brown',
      'cyan',
      'teal',
    ];
    possibleColors.shuffle();
    var playerColors = {};
    data['playerIds'].asMap().forEach((i, v) {
      if (data['narrators'].contains(v)) {
        // narrators are black
        playerColors[v] = 'black';
      } else {
        playerColors[v] = possibleColors[i];
      }
    });
    data['playerColors'] = playerColors;

    // initialize conversation
    data['texts'] = [
      {
        'playerId': data['narrators'][0],
        'text': storyBeginnings[data['rules']['location']],
        'timestamp': DateTime.now(),
      }
    ];

    // randomly choose two characters for each player to choose from
    var exampleCharacterNames = exampleCharacters.keys.toList();
    exampleCharacterNames.shuffle();
    var characterCount = 0;
    data['sampleCharacters'] = {};
    data['playerIds'].forEach((v) {
      data['sampleCharacters'][v] = [
        exampleCharacterNames[characterCount],
        exampleCharacterNames[characterCount + 1],
      ];
      characterCount += 2;
    });

    // add read to end game options for each player
    data['readyToEnd'] = {};
    data['playerIds'].forEach((v) {
      if (!data['narrators'].contains(v)) {
        data['readyToEnd'][v] = false;
      }
    });

    // initialize matching guesses for each player
    data['matchingGuesses'] = {};
    for (int i = 0; i < data['playerIds'].length; i++) {
      data['matchingGuesses'][data['playerIds'][i]] = {};
      // for every other player, create an empty guess
      List otherPlayers = List.from(data['playerIds']);
      otherPlayers.remove(data['playerIds'][i]);
      otherPlayers.forEach((w) {
        data['matchingGuesses'][data['playerIds'][i]][w] = null;
      });
    }
    data['internalState'] = 'characterSelection';

    return data;
  }

  setupCharadeATrois(data) async {
    // verify that there are sufficient number of players
    if (data['playerIds'].length < 2 * data['rules']['numTeams']) {
      setState(() {
        startError = 'Need at least ${2 * data['rules']['numTeams']} players';
      });
      return;
    }

    // clear error if we are good to start
    setState(() {
      startError = '';
    });

    var playerIds = List.from(data['playerIds']);

    // add player names
    data['playerNames'] = {};
    for (int i = 0; i < playerIds.length; i++) {
      data['playerNames'][playerIds[i]] = (await FirebaseFirestore.instance
              .collection('users')
              .doc(playerIds[i])
              .get())
          .data()['name'];
    }

    // separate into two teams - captains of each team will be first player in each array
    var teams = {};
    for (int i = 0; i < data['rules']['numTeams']; i++) {
      teams['team$i'] = [];
    }
    playerIds.shuffle();
    while (playerIds.length > 0) {
      for (int i = 0; i < data['rules']['numTeams']; i++) {
        if (playerIds.length <= 0) {
          break;
        }
        teams['team$i'].add(playerIds.last);
        playerIds.removeLast();
      }
    }
    data['teams'] = teams;

    // initialize words (generate if not user input)
    data['words'] = [];
    data['expirationTime'] = DateTime.now()
        .add(Duration(seconds: data['rules']['collectionTimeLimit'] + 6));
    data['internalState'] = 'wordSelection';
    if (!data['rules']['playerWords']) {
      // random words
      var words = [
        charadeATroisWords,
        charadeATroisExpressions,
        charadeATroisPeople
      ].expand((x) => x).toList();
      words.shuffle();
      int i = 0;
      while (data['words'].length < data['rules']['collectionWordLimit']) {
        bool wordAlreadyExists = false;
        data['words'].forEach((v) {
          if (StringSimilarity.compareTwoStrings(v, words[i]) > 0.7) {
            wordAlreadyExists = true;
          }
        });
        if (!wordAlreadyExists) {
          data['words'].add(words[i]);
        }
        i += 1;
      }
      data['internalState'] = 'describe';
      data['expirationTime'] = null;
    }

    // set piles equal to word list
    data['describePile'] = List.from(data['words']);
    data['describePile'].shuffle();
    data['gesturePile'] = List.from(data['words']);
    data['gesturePile'].shuffle();
    data['oneWordPile'] = List.from(data['words']);
    data['oneWordPile'].shuffle();

    data['scores'] = [];
    for (int i = 0; i < data['rules']['numTeams']; i++) {
      data['scores'].add(0);
    }

    // initialize turns
    data['turn'] = {
      'teamTurn': 0,
    };
    for (int i = 0; i < data['rules']['numTeams']; i++) {
      data['turn']['team${i}Turn'] = 0;
    }

    data['log'] = ['', '', ''];
    data['judgeList'] = [];
    data['roundScore'] = 0;
    data['temporaryExpirationTime'] = null;

    return data;
  }

  startGame(data) async {
    // initialize final values/rules for games
    switch (gameName) {
      case 'The Hunt':
        data = await setupTheHunt(data);
        break;

      case 'Abstract':
        data = await setupAbstract(data);
        break;

      case 'Bananaphone':
        data = await setupBananaphone(data);
        break;

      case 'Three Crowns':
        data = await setupThreeCrowns(data);
        break;

      case 'Rivers':
        data = await setupRivers(data);
        break;

      case 'Plot Twist':
        data = await setupPlotTwist(data);
        break;

      case 'Charáde à Trois':
        data = await setupCharadeATrois(data);
        break;
    }

    if (startError == '') {
      // update data
      data['state'] = 'started';
      data['startTime'] = DateTime.now().add(Duration(seconds: 5));

      // player.play('reveal.wav');

      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .set(data);
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
    if (startTime.difference(_now).inSeconds <= 0) {
      return Container();
    }
    return Column(
      children: <Widget>[
        Text(
          'Game is starting in',
          style: TextStyle(
            color: Theme.of(context).highlightColor,
            fontSize: 24,
          ),
        ),
        SizedBox(height: 5),
        Text(startTime.difference(_now).inSeconds.toString(),
            style: TextStyle(
              fontSize: 40,
              color: Theme.of(context).primaryColor,
            )),
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
              RulesContainer(
                rules: <Widget>[
                  Text(
                    'Number of spies:',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    rules['numSpies'].toString(),
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
              SizedBox(height: 5),
              RulesContainer(
                rules: <Widget>[
                  Text(
                    'Possible locations:',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    rules['locations'].toString(),
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              SizedBox(height: 5),
              RulesContainer(
                rules: <Widget>[
                  Text(
                    'Accusations allowed per turn:',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    rules['accusationsPerTurn'].toString(),
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
              SizedBox(height: 5),
              RulesContainer(
                rules: <Widget>[
                  Text(
                    'Accusation cooldown:',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    rules['accusationCooldown'].toString(),
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
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
        return Column(
          children: [
            RulesContainer(rules: <Widget>[
              Text('Minimum word length: ${rules['minWordLength']}'),
            ]),
            SizedBox(height: 5),
            RulesContainer(rules: <Widget>[
              Text('Maximum word length: ${rules['maxWordLength']}'),
            ]),
          ],
        );
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
      case 'Plot Twist':
        return Column(
          children: <Widget>[
            RulesContainer(rules: <Widget>[
              Text(
                'Location:',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                rules['location'],
                style: TextStyle(fontSize: 18),
              ),
            ]),
            SizedBox(height: 5),
            RulesContainer(
              rules: <Widget>[
                Text(
                  'Number of narrators:',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  rules['numNarrators'].toString(),
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ],
        );
        break;
      case 'Charáde à Trois':
        return Column(
          children: <Widget>[
            RulesContainer(rules: <Widget>[
              Text(
                'Number of Teams:',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                rules['numTeams'].toString(),
                style: TextStyle(fontSize: 18),
              ),
            ]),
            SizedBox(height: 5),
            RulesContainer(rules: <Widget>[
              Text(
                'Round Time Limit:',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                rules['roundTimeLimit'].toString(),
                style: TextStyle(fontSize: 18),
              ),
            ]),
            SizedBox(height: 5),
            RulesContainer(
              rules: <Widget>[
                Text(
                  'Number of Words:',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  rules['collectionWordLimit'].toString(),
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
            SizedBox(height: 5),
            RulesContainer(rules: <Widget>[
              Text(
                'Player/Random Words:',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                rules['playerWords'] ? 'Player' : 'Random',
                style: TextStyle(fontSize: 18),
              ),
            ]),
            SizedBox(height: 5),
            RulesContainer(
              rules: <Widget>[
                Text(
                  'Word Collection Time Limit:',
                  style: TextStyle(
                    fontSize: 14,
                    color: rules['playerWords']
                        ? Theme.of(context).highlightColor
                        : Colors.grey,
                  ),
                ),
                Text(
                  rules['collectionTimeLimit'].toString(),
                  style: TextStyle(
                    fontSize: 18,
                    color: rules['playerWords']
                        ? Theme.of(context).highlightColor
                        : Colors.grey,
                  ),
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
    var playerIds = data['playerIds'];
    return Column(
      children: [
        ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: playerIds.length,
            itemBuilder: (context, index) {
              return FutureBuilder(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(playerIds[index])
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
                                        onTap: () =>
                                            kickPlayer(playerIds[index]),
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
        SizedBox(height: 10),
      ],
    );
  }

  shufflePlayers(data) async {
    var playerOrder = data['playerIds'];
    playerOrder.shuffle();
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .update({'playerIds': playerOrder, 'turn': playerOrder[0]});
  }

  addTheGang(data) async {
    data['playerIds'].add('F3cbzZifAqWWM2eyab6x6WvdkyL2');
    data['playerIds'].add('LoTLbkqfQWcFMzjrYGEne1JhN7j2');
    data['playerIds'].add('h4BrcG93XgYsBcGpH7q2WySK8rd2');
    data['playerIds'].add('z5SqbMUvLVb7CfSxQz4OEk9VyDE3');
    data['playerIds'].add('djawU3QzVCXkLq32mlmd6W81CqK2');
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .set(data);
  }

  Widget _getSpectators(data) {
    var spectatorIds = data['spectatorIds'];
    return Container(
      height: 16.0 * spectatorIds.length,
      child: ListView.builder(
          itemCount: spectatorIds.length,
          itemBuilder: (context, index) {
            return FutureBuilder(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(spectatorIds[index])
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
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .set(data);
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
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .doc(sessionId)
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
          var data = snapshot.data.data();
          return Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: Text(
                '$gameName: Lobby',
              ),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.info),
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (BuildContext context, _, __) {
                          switch (gameName) {
                            case 'The Hunt':
                              return TheHuntScreenHelp();
                              break;
                            case 'Abstract':
                              return AbstractScreenHelp();
                              break;
                            case 'Bananaphone':
                              return BananaphoneScreenHelp();
                              break;
                            case 'Rivers':
                              return RiversScreenHelp();
                              break;
                            case 'Three Crowns':
                              return ThreeCrownsScreenHelp();
                              break;
                            case 'Plot Twist':
                              return PlotTwistScreenHelp();
                              break;
                          }
                          return Text('tell Matt you got here: 1');
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
            body: Stack(
              children: [
                TogetherScrollView(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(height: 50),
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
                        userId == data['leader'] && !isStarting
                            ? Column(
                                children: <Widget>[
                                  RaisedGradientButton(
                                    child: Text(
                                      'Shuffle Players',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    onPressed: () => shufflePlayers(data),
                                    height: 25,
                                    width: 120,
                                    gradient: LinearGradient(
                                      colors: <Color>[
                                        Theme.of(context).primaryColor,
                                        Theme.of(context).accentColor,
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                ],
                              )
                            : Container(),
                        // if markus, add the gang
                        userId == 'XMFwripPojYlcvagoiDEmyoxZyK2' && !isStarting
                            ? Column(
                                children: <Widget>[
                                  RaisedGradientButton(
                                    child: Text(
                                      'Add the gang',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    onPressed: () => addTheGang(data),
                                    height: 25,
                                    width: 120,
                                    gradient: LinearGradient(
                                      colors: <Color>[
                                        Colors.green[200],
                                        Colors.green[100],
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 20),
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
                        userId != data['leader'] ||
                                data['spectatorIds'].contains(data['leader'])
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
                Positioned(
                  top: 4,
                  right: 4,
                  child: InfoBox(
                    text: 'Find game rules here!',
                    infoKey: 'gameRules',
                    userId: userId,
                  ),
                ),
              ],
            ),
          );
        });
  }
}
