import 'package:flutter/material.dart';

import 'services/authentication.dart';
import 'screens/root_screen.dart';

void main() => runApp(MyApp());

// done:

// next up:
// BIG: add spectator mode

// TODO:
// rivers: fix DEBUG LOCKED
// rivers: show num cards in each players hand
// rivers: show stacks history
// add basic functionality to three crowns -
// - play cards in duel
// - continue duel winner logic
// - add ability to match
// - display tiles
// - display crowns
// - add ability to gain a tile
// - add ability to steal a tile
// - display opponent tiles and crowns
// abstract games has funky behavior? - green wins then orange hits grey - should be over but timer glitches
// RUN THROUGH AN ENTIRE BANANAPHONE, many updates. - pretty close to done
// undo button not working in bananaphone 2nd+ drawings
// make all buttons disappear when they are clicked (especially when they cause an effect - there are double effects happening)
// add rules for three crowns
// fine grained control of teams in lobby for abstract
// add scores button to view scores in bananaphone
// orange team needs to win when green wins for them
// tiebreaker for abstract, with total time used as second marker
// add timer to the hunt
// abstract: ability to manually change teams (people can just join the team they want to be on?)
// abstract should show leader view at end of game (not just solid blocks)
// if leader leaves a game, need to assign remaining player the leader position - ORRRRR, "claim leadership" button would be more fun and easier
// add snackbar when auto exiting to lobby or main menu
// add password reset option
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
        primaryColor: Colors.blue[700],
        accentColor: Colors.blue[300],
        highlightColor: Colors.black,
        fontFamily: 'Balsamiq',
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primaryColor: Colors.blue[700],
        accentColor: Colors.blue[300],
        highlightColor: Colors.white,
        fontFamily: 'Balsamiq',
        brightness: Brightness.dark,
      ),
      home: RootScreen(auth: new Auth()),
    );
  }
}
