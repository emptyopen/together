import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

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
  '1S',
  '2S',
  '3S',
  '4S',
  '5S',
  '6S',
  '7S',
  // '8S',
  // '9S',
  'CS',
  'BS',
  'AS',
  '1H',
  '2H',
  '3H',
  '4H',
  '5H',
  '6H',
  '7H',
  // '8H',
  // '9H',
  'CH',
  'BH',
  'AH',
  '1C',
  '2C',
  '3C',
  '4C',
  '5C',
  '6C',
  '7C',
  // '8C',
  // '9C',
  'CC',
  'BC',
  'AC',
  '1D',
  '2D',
  '3D',
  '4D',
  '5D',
  '6D',
  '7D',
  // '8D',
  // '9D',
  'CD',
  'BD',
  'AD',
];

generateRandomThreeCrownsCard() {
  final _random = new Random();
  return deck[_random.nextInt(deck.length)];
}

fillHand({data, scaffoldKey, userId, sessionId, force = false}) async {
  // check if in duel or forced
  if (!force && playerInDuel(data, userId)) {
    scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text('Can\'t draw cards right now!'),
      duration: Duration(seconds: 3),
    ));
    return;
  }
  var playerIndex = data['playerIds'].indexOf(userId);
  bool changed = false;
  var cnt = 0;
  while (data['player${playerIndex}Hand'].length < 5 && cnt < 8) {
    String randomCard = generateRandomThreeCrownsCard();
    data['player${playerIndex}Hand'].add(randomCard);
    changed = true;
    cnt += 1;
  }
  if (changed) {
    await Firestore.instance
        .collection('sessions')
        .document(sessionId)
        .setData(data);
  }
}

bool playerInDuel(data, userId) {
  var playerIndex = data['playerIds'].indexOf(userId);
  var duelerIndex = data['duel']['duelerIndex'];
  var dueleeIndex = duelerIndex + 1;
  if (dueleeIndex > data['playerIds'].length) {
    dueleeIndex = 0;
  }
  if (playerIndex != duelerIndex && playerIndex != dueleeIndex) {
    return false;
  }
  return true;
}
