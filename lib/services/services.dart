import 'package:flutter/material.dart';
import 'dart:math';

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