import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:audioplayers/audio_cache.dart';

import '../screens/lobby_screen.dart';

checkIfExit(data, context, sessionId, roomCode) async {
  // run async func to check if game is over, or back to lobby or deleted (main menu)
  if (data == null) {
    // navigate to main menu
    Navigator.of(context).pop();
  } else if (data['state'] == 'lobby') {
    // I DON'T KNOW WHY WE NEED THIS BUT OTHERWISE WE GET DEBUG LOCKED ISSUES
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId) // TODO: check if it can be a generic await
        .set(data);
    // navigate to lobby
    Navigator.of(context).pop();
    slideTransition(
      context,
      LobbyScreen(
        roomCode: roomCode,
      ),
    );
  }
}

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

closeKeyboardIfOpen(context) {
  if (MediaQuery.of(context).viewInsets.bottom != 0) {
    FocusScope.of(context).unfocus();
  }
}

checkUserInGame({String userId, String sessionId = ''}) async {
  // check if player has currentGame (that is not this game). if so, remove player from currentGame
  var userData =
      (await FirebaseFirestore.instance.collection('users').doc(userId).get())
          .data();
  if (userData.containsKey('currentGame')) {
    print('user is still in game ${userData['currentGame']}, will remove');
    var session = await FirebaseFirestore.instance
        .collection('sessions')
        .doc(userData['currentGame'])
        .get();
    var sessionData = session.data;

    // if old game still exists and is not this game
    if (sessionData != null && (sessionId == '' || sessionId != session.id)) {
      // remove user from playerIds in old game
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(userData['currentGame'])
          .update({
        'playerIds': FieldValue.arrayRemove([userId])
      });
      // check if room is empty, if so, delete session
      var data = (await FirebaseFirestore.instance
              .collection('sessions')
              .doc(userData['currentGame'])
              .get())
          .data();
      if (data['playerIds'].length == 0) {
        print('no players remaining for room ${data['roomCode']}, will delete');
        await FirebaseFirestore.instance
            .collection('sessions')
            .doc(userData['currentGame'])
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
        'accusationsPerTurn': 1, // accusations allowed per turn
        'accusationCooldown':
            1, // number of other people who accuse before you can again
      };
      break;
    case 'Abstract':
      return {
        'numTeams': 2,
        'turnTimer': 30,
        'generalWordsOn': true,
        'locationsWordsOn': true,
        'peopleWordsOn': true,
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
        'minWordLength': 4,
        'maxWordLength': 7,
      };
    case 'Rivers':
      return {
        'cardRange': 100,
        'handSize': 7,
      };
      break;
    case 'Plot Twist':
      return {
        'location': 'The Elevator',
        'numNarrators': 1,
      };
      break;
    case 'Charáde à Trois':
      return {
        'numTeams': 2,
        'playerWords': true,
        'collectionWordLimit': 40,
        'collectionTimeLimit': 300,
        'roundTimeLimit': 60,
      };
      break;
  }
}

createGame(BuildContext context, String game, String password, bool pop,
    Function unpress) async {
  final _rnd = Random();
  final letters = 'ABCDEFGHJKMNPQRSTUVWXYZ';
  String randLetter() => letters[_rnd.nextInt(letters.length)];
  String randRoomCode() => randLetter() + randLetter() + randLetter();
  var _roomCode = randRoomCode();
  // final player = new AudioCache(prefix: 'sounds/');

  // check that room code doesn't exist
  bool roomCodeExists = true;
  while (roomCodeExists) {
    await FirebaseFirestore.instance
        .collection('sessions')
        .where('roomCode', isEqualTo: _roomCode)
        .get()
        .then((event) async {
      if (event.docs.isEmpty) {
        roomCodeExists = false;
      } else {
        _roomCode = randRoomCode();
      }
    }).catchError((e) => print('error fetching data: $e'));
  }

  final userId = (FirebaseAuth.instance.currentUser).uid;
  // remove user from old game
  // checkUserInGame(userId: userId);

  // define initial rules per game
  Map<String, dynamic> defaultRules = getDefaultRules(game);

  var sessionContents = {
    'game': game,
    'rules': defaultRules,
    'password': password,
    'roomCode': _roomCode,
    'playerIds': [userId],
    'spectatorIds': [],
    'state': 'lobby',
    'leader': userId,
    'dateCreated': DateTime.now(),
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
      break;
    case 'Rivers':
      sessionContents['turn'] = userId;
      break;
    default:
      break;
  }
  var result = await FirebaseFirestore.instance
      .collection('sessions')
      .add(sessionContents);

  // update user's current game
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .update({'currentGame': result.id});

  // navigate to lobby
  if (pop) {
    Navigator.of(context).pop();
  }

  // unpress
  unpress();

  // player.play('new-lobby.mp3');
  slideTransition(
    context,
    LobbyScreen(
      roomCode: _roomCode.toUpperCase(),
    ),
  );
}

incrementPlayerScore(String gameName, String playerId) async {
  String gameNameScore = gameName + 'Score';
  var data =
      (await FirebaseFirestore.instance.collection('users').doc(playerId).get())
          .data();
  if (data.containsKey(gameNameScore)) {
    data[gameNameScore] += 1;
  } else {
    data[gameNameScore] = 1;
  }
  await FirebaseFirestore.instance
      .collection('users')
      .doc(playerId)
      .update({gameNameScore: data[gameNameScore]});
}
