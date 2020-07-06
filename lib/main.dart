import 'package:flutter/material.dart';

import 'services/authentication.dart';
import 'screens/root_screen.dart';

void main() => runApp(MyApp());

// done:

// next up:
// RUN THROUGH AN ENTIRE BANANAPHONE, many updates. - pretty close to done 
// undo button not working in bananaphone 2nd+ drawings 
// add rules for bananaphone 
// add basic functionality to three crowns - show cards, play cards in duel, set up rotating duel 
// Add ability to vote for player in The Hunt
//  - automatically choose winner by vote or reveal 

// TODO:
// INFO: abstract, word overflow is 11 characters for iphone 10
// add rules for three crowns
// will need support in The Hunt for more than one spy in terms of moving turns around 
// BIG: add statistics for player accounts (number of games won, etc.)
// add scores button to view scores in bananaphone
// BIG: add spectator mode
// orange team needs to win when green wins for them
// tiebreaker for abstract, with total time used as second marker
// add timer to the hunt
// abstract: ability to manually change teams (people can just join the team they want to be on?)
// abstract should show leader view at end of game (not just solid blocks)
// probably don't need setupComplete flag, games can only be configured from the lobby
// if leader leaves a game, need to assign remaining player the leader position - ORRRRR, "claim leadership" button would be more fun and easier
// add snackbar when auto exiting to lobby or main menu
// add password reset option
// clean up games that are finished/old (might need backend service)
// add ability to join current game (in case of crash, accidental) in main menu (3rd option if available)
// React to getting kicked (timer check every 1 second to go back to lobby)
// periodically check if player info isn't true? check current game and see if player is in it
// ability to leave a game (might not need) (also delete session if last one out) - dialog on back button (leave game or just go to main menu)
// abstract: (might not need) add voting system for choosing abstract cards (all members of team must select it)
// attribute icon: Icons made by "https://www.flaticon.com/authors/freepik

// fake users:
// cassie@g.com  F3cbzZifAqWWM2eyab6x6WvdkyL2
// henry@g.com  LoTLbkqfQWcFMzjrYGEne1JhN7j2
// markus@g.com  XMFwripPojYlcvagoiDEmyoxZyK2
// maggie@g.com  h4BrcG93XgYsBcGpH7q2WySK8rd2
// vanessa@g.com  z5SqbMUvLVb7CfSxQz4OEk9VyDE3
// greg@gmail.com  djawU3QzVCXkLq32mlmd6W81CqK2

// temp banana: UMR
// Markus
// Cassie
// Henry
// Vanessa

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Together',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blue[600],
        accentColor: Colors.blue[200],
        highlightColor: Colors.black,
        fontFamily: 'Balsamiq',
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primaryColor: Colors.blue[600],
        accentColor: Colors.blue[300],
        // primaryColor: Colors.pink[600],
        // accentColor: Colors.pink[400],
        highlightColor: Colors.white,
        fontFamily: 'Balsamiq',
        brightness: Brightness.dark,
      ),
      home: RootScreen(auth: new Auth()),
    );
  }
}
