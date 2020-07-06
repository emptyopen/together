import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../screens/lobby_screen.dart';

slideTransition(BuildContext context, Widget route) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) =>
          route,
      transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) =>
          SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    ),
  );
}


// Three crowns

var letterFrequencies = {
  'a': 8,
  'b': 2,
  'c': 3,
  'd': 4,
  'e': 12,
  'f': 2,
  'g': 2.5,
  'h': 2.5,
  'i': 6.5,
  'j': 1,
  'k': 1,
  'l': 3.5,
  'm': 3,
  'n': 6.5,
  'o': 7.5,
  'p': 2,
  'q': 1,
  'r': 6.5,
  's': 5,
  't': 7.5,
  'u': 3.5,
  'v': 2.5,
  'w': 2,
  'x': 1,
  'y': 2,
  'z': 1,
  ' ': 2,
};

generateRandomLetter() {

  // initialize random tool
  var letters = 'abcdefghijklmnopqrstuvwxyz';
  final _random = new Random();
  var randInt100 = _random.nextDouble() * 100;
  double frequencyIndex = 0.0;
  int letterIndex = 0;
  while (frequencyIndex < 100) {
    frequencyIndex += letterFrequencies[letters[letterIndex]];
    if (randInt100 < frequencyIndex) {
      return letters[letterIndex];
    }
    letterIndex += 1;
  }
  return 'e';
}

var deck = [
  'AS',
  '2S',
  '3S',
  '4S',
  '5S',
  '6S',
  '7S',
  '8S',
  '9S',
  '10S',
  'JS',
  'QS',
  'KS',
  'AH',
  '2H',
  '3H',
  '4H',
  '5H',
  '6H',
  '7H',
  '8H',
  '9H',
  '10H',
  'JH',
  'QH',
  'KH',
  'AC',
  '2C',
  '3C',
  '4C',
  '5C',
  '6C',
  '7C',
  '8C',
  '9C',
  '10C',
  'JC',
  'QC',
  'KC',
  'AD',
  '2D',
  '3D',
  '4D',
  '5D',
  '6D',
  '7D',
  '8D',
  '9D',
  '10D',
  'JD',
  'QD',
  'KD',
];

generateRandomCard() {
  final _random = new Random();
  return deck[_random.nextInt(deck.length)];
}


checkUserInGame({String userId, String sessionId = ''}) async {
  // check if player has currentGame (that is not this game). if so, remove player from currentGame
  var userData =
      (await Firestore.instance.collection('users').document(userId).get())
          .data;
  if (userData.containsKey('currentGame')) {
    print('user is still in game ${userData['currentGame']}, will remove');
    var session = await Firestore.instance
        .collection('sessions')
        .document(userData['currentGame'])
        .get();
    var sessionData = session.data;

    // if old game still exists and is not this game
    if (sessionData != null &&
        (sessionId == '' || sessionId != session.documentID)) {
      // remove user from playerIds in old game
      await Firestore.instance
          .collection('sessions')
          .document(userData['currentGame'])
          .updateData({
        'playerIds': FieldValue.arrayRemove([userId])
      });
      // check if room is empty, if so, delete session
      var playerIds = (await Firestore.instance
              .collection('sessions')
              .document(userData['currentGame'])
              .get())
          .data['playerIds'];
      if (playerIds.length == 0) {
        await Firestore.instance
            .collection('sessions')
            .document(userData['currentGame'])
            .delete();
      }
    }
  } else {
    print('user is not in another game, no problem');
  }
}

getDefaultRules(String gameName) {
  switch (gameName) {
    case 'The Hunt':
      return {
        'locations': ['Casino', 'Pirate Ship', 'Coal Mine', 'University'],
        'numSpies': 1,
      };
      break;
    case 'Abstract':
      return {
        'numTeams': 2,
        'turnTimer': 30,
      };
      break;
    case 'Bananaphone':
      return {
        'numRounds': 2,
        'numDrawDescribe': 2,
      };
      break;
    case 'Three Crowns':
      return {
        'maxWordLength': 6,
      };
  }
}

createGame(BuildContext context, String game, String password, bool pop) async {
  final _rnd = Random();
  final letters = 'ABCDEFGHJKMNPQRSTUVWXYZ';
  String randLetter() => letters[_rnd.nextInt(letters.length)];
  String randRoomCode() => randLetter() + randLetter() + randLetter();
  var _roomCode = randRoomCode();

  // check that room code doesn't exist
  bool roomCodeExists = true;
  while (roomCodeExists) {
    await Firestore.instance
        .collection('sessions')
        .where('roomCode', isEqualTo: _roomCode)
        .getDocuments()
        .then((event) async {
      if (event.documents.isEmpty) {
        roomCodeExists = false;
      } else {
        _roomCode = randRoomCode();
      }
    }).catchError((e) => print('error fetching data: $e'));
  }

  // remove user from old game
  final userId = (await FirebaseAuth.instance.currentUser()).uid;
  checkUserInGame(userId: userId);

  // define initial rules per game
  Map<String, dynamic> defaultRules = getDefaultRules(game);

  var sessionContents = {
    'game': game,
    'rules': defaultRules,
    'password': password,
    'roomCode': _roomCode,
    'playerIds': [userId],
    'state': 'lobby',
    'leader': userId,
    'dateCreated': DateTime.now(),
    'setupComplete': false,
  };
  switch (game) {
    case 'The Hunt':
      sessionContents['turn'] = userId;
      break;
    case 'Abstract':
      sessionContents['turn'] = 'green';
      break;
    case 'Bananaphone':
      sessionContents['phase'] = 'draw1';
      sessionContents['round'] = 0;
      break;
    case 'Three Crowns':
      sessionContents['turn'] = userId;
  }
  var result =
      await Firestore.instance.collection('sessions').add(sessionContents);

  // update user's current game
  await Firestore.instance
      .collection('users')
      .document(userId)
      .updateData({'currentGame': result.documentID});

  // vibrate
  HapticFeedback.vibrate();

  // navigate to lobby
  if (pop) {
  Navigator.of(context).pop();
  }
  slideTransition(
    context,
    LobbyScreen(
      roomCode: _roomCode.toUpperCase(),
    ),
  );
}