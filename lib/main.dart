import 'package:flutter/material.dart';

import 'services/authentication.dart';
import 'screens/root_screen.dart';

void main() => runApp(MyApp());

// done:

// next up:
// BIG: add bananaphone 
/*
need to initialize: turn order
number of rounds
drawing prompt per player per round
currentRound = (1, 2, 3) rounds?
currentPhase = 'draw1', 'describe1', 'draw2', 'describe2'

need at least 4 players? 
Each person draws, then describes, then draws, then describes

Will need a voting system to pick best drawing/description per phase 
*/
// ability to leave a game (also delete session if last one out) - dialog on back button (leave game or just go to main menu)

// TODO:
// abstract should show leader view at end of game (not just solid blocks)
// probably don't need setupComplete flag, games can only be configured from the lobby
// abstract:
//  - add turn timer
//  - voting system for choosing abstract cards (all members of team must select it)
//  - add help screen: any number of teams can win with rebuttal
//  - or tiebreaker, with total time used as second marker
//  - max time limit per session of 45 seconds per remaining word
// if leader leaves a game, need to assign remaining player the leader position
// require minimum num players for hunt (remove error message in abstract when cleared)
// add snackbar when auto exiting to lobby or main menu
// add credits screen for winners and losers (template) (mode of "ending" with new time limit of when to go to lobby / main menu)
// add password reset option
// clean up games that are finished/old (might need backend service)
// add ability to join current game (in case of crash, accidental) in main menu (3rd option if available)
// React to getting kicked (timer check every 1 second to go back to lobby)
// periodically check if player info isn't true? check current game and see if player is in it
// BIG: add statistics for player accounts (number of games won, etc.)
// attribute icon: Icons made by "https://www.flaticon.com/authors/freepik

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Together',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // primarySwatch: Colors.lightBlue,
        primaryColor: Colors.blue[600],
        accentColor: Colors.blue[200],
        fontFamily: 'Balsamiq',
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primaryColor: Colors.pinkAccent,
        fontFamily: 'Balsamiq',
        brightness: Brightness.dark,
      ),
      home: RootScreen(auth: new Auth()),
      // home: Scaffold(
      //   body: Container(
      //     alignment: Alignment.center,
      //     child: Text('hi yo'),
      //   ),
      // ),
    );
  }
}
