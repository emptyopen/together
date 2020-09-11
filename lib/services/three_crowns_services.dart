import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:random_words/random_words.dart';

int threeCardsHandSize = 6;

// Three crowns

var letterValues = {
  'a': 1,
  'b': 3,
  'c': 3,
  'd': 2,
  'e': 1,
  'f': 5,
  'g': 2,
  'h': 5,
  'i': 1,
  'j': 9,
  'k': 6,
  'l': 1,
  'm': 3,
  'n': 2,
  'o': 1,
  'p': 3,
  'q': 1,
  'r': 2,
  's': 1,
  't': 1,
  'u': 1,
  'v': 4,
  'w': 4,
  'x': 8,
  'y': 4,
  'z': 10,
  ' ': 0,
};

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
  var letters = 'abcdefghijklmnopqrstuvwxyz ';
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
  '8S',
  '9S',
  'JS',
  'QS',
  'KS',
  '1H',
  '2H',
  '3H',
  '4H',
  '5H',
  '6H',
  '7H',
  '8H',
  '9H',
  'JH',
  'QH',
  'KH',
  '1C',
  '2C',
  '3C',
  '4C',
  '5C',
  '6C',
  '7C',
  '8C',
  '9C',
  'JC',
  'QC',
  'KC',
  '1D',
  '2D',
  '3D',
  '4D',
  '5D',
  '6D',
  '7D',
  '8D',
  '9D',
  'JD',
  'QD',
  'KD',
];

stringToNumeric(String v) {
  if (v == 'J') {
    return 10;
  }
  if (v == 'Q') {
    return 11;
  }
  if (v == 'K') {
    return 12;
  }
  return int.parse(v);
}

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
  while (data['player${playerIndex}Hand'].length < threeCardsHandSize &&
      cnt < 10) {
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
  return playerIndex == data['duel']['duelerIndex'] ||
      playerIndex == data['duel']['dueleeIndex'];
}

playerNameFromIndex(int index, data) {
  var playerId = data['playerIds'][index];
  return data['playerNames'][playerId];
}

cleanupDuel(data) async {
  data['duel']['dueleeCard'] = '';
  data['duel']['duelerCard'] = '';
  data['duel']['matchingCards'] = [];
  data['duel']['peasantCards'] = [];
  data['duel']['joust'] = 1;
  data['duel']['tilePrize'] = 0;
  data['duel']['pillagePrize'] = 0;
  // next duel
  data['duel']['duelerIndex'] += 1;
  if (data['duel']['duelerIndex'] >= data['playerIds'].length) {
    data['duel']['duelerIndex'] = 0;
  }
  data['duel']['dueleeIndex'] += 1;
  if (data['duel']['dueleeIndex'] >= data['playerIds'].length) {
    data['duel']['dueleeIndex'] = 0;
  }
  // fill hands for dueler and duelee
  int duelerIndex = data['duel']['duelerIndex'];
  while (data['player${duelerIndex}Hand'].length < threeCardsHandSize) {
    String randomCard = generateRandomThreeCrownsCard();
    data['player${duelerIndex}Hand'].add(randomCard);
  }
  int dueleeIndex = data['duel']['dueleeIndex'];
  while (data['player${dueleeIndex}Hand'].length < threeCardsHandSize) {
    String randomCard = generateRandomThreeCrownsCard();
    data['player${dueleeIndex}Hand'].add(randomCard);
  }
  data['duel']['state'] = 'duel';
}

generateRandomWord(int minLength, int maxLength) {
  final _random = new Random();
  int tries = 0;
  var word = all[_random.nextInt(all.length)];
  while (word.length < minLength || word.length > maxLength) {
    word = all[_random.nextInt(all.length)];
    tries += 1;
    if (tries > 200) {
      break;
    }
  }
  return word;
}
