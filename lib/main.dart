import 'package:flutter/material.dart';

import 'services/authentication.dart';
import 'screens/root_screen.dart';

void main() => runApp(MyApp());

// done:
// BIG: Add ability to change rules in lobby
// Finish ability to kick
// make lobby scrollable
// Add turn system!!
//   - Generate order of players and store it
//   - Set turn player Id to first item in list
//   - display cycle of player order
//   - notice next to it with player's status
// don't update game as leader when rejoining
// add rules to info box in the hunt
// add ability for leader to end the game, return to lobby (add stats to winner, etc) or kill game

// next up: 

// TODO: 
// add credits screen for winners and losers (template)
// when room is destroyed by host (or is removed for any other reason), make sure everyone resolves back to main menu (with snackbar)
// when joining a game (and setting current game), check if current game exists. if so, remove player from game 
// clean up games that are finished (might need backend service)
// ensure creating new game that code is unique
// ability to leave a game (also delete session if last one out) - dialog on back button (leave game or just go to main menu)
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
    );
  }
}

