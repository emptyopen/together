import 'package:flutter/material.dart';

import 'services/authentication.dart';
import 'screens/root_screen.dart';

void main() => runApp(MyApp());

// done:
// add optional to password

// next up:
// BIG: add bananaphone 
// ability to leave a game (also delete session if last one out) - dialog on back button (leave game or just go to main menu)
// add timer to the hunt
// abstract:
//  - add turn timer
//  - add help screen: any number of teams can win with rebuttal
//  - or tiebreaker, with total time used as second marker
//  - max time limit per session of 30 seconds per remaining word
// fix abstract end game logic (simplify and clean up)
// add indicators to words that have been flipped this turn - use an additional property when storing it - might need to loop over all letters to set old ones false

// TODO:
// abstract: ability to manually change teams (people can just join the team they want to be on?)
// abstract should show leader view at end of game (not just solid blocks)
// probably don't need setupComplete flag, games can only be configured from the lobby
// abstract: add voting system for choosing abstract cards (all members of team must select it)
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

// fake users:
// cassie@g.com  F3cbzZifAqWWM2eyab6x6WvdkyL2
// henry@g.com  LoTLbkqfQWcFMzjrYGEne1JhN7j2
// markus@g.com  XMFwripPojYlcvagoiDEmyoxZyK2
// maggie@g.com  h4BrcG93XgYsBcGpH7q2WySK8rd2
// vanessa@g.com  z5SqbMUvLVb7CfSxQz4OEk9VyDE3

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
