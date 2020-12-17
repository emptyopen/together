import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'services/authentication.dart';
import 'screens/auth/root_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

// DONE:

// next up:
// bananaphone: increment player score
// remove scrolling issue
// voting screen: 2nd round still showing 1st round clues

// transact:
// bananaphone
// three crowns
// charade a trois for judging vs. playing - also look at how the timer might be getting set by everyone?

// help screen weird

// transact ALL!!!
// 3 crowns - show outline of winning card

// charade a trois: many duplicates across rounds
// starting with 2v3 teams in charade was bad for #3 (eric)

// keyboard issue in plot twist - all textfields should have a "go" button to close the keyboard

// charade: go button grey, stuck - add a permanent check for a bad state (band-aid?)
// charade: show crossed out words when judging
// charade: skip button seemed to freeze?

// Samesies:
// two modes, automatically chosen: high score mode vs survival mode
// TODO: survival mode: ends when lose (only available for one team)
// high score mode: play to the end, best score wins

// samesies: there should be an option for multiple teams if they want the same words or not (as each other)

// BIG: add additional skins after certain number of wins
// - new crowns for certain wins in three crowns

// TODO:
// samesies: there should be an option for multiple teams if they want the same words or not (as each other)
// bananaphone: maybe change voting to "entire progression", single vote
// big: consolidation of new game to simplified parameters / per screen (init, scaffold, etc.)
// charades: shimmer for high round scores
// charades: add everything to a log?
// team selector: a few annoying bugs remaining with rapid touches
// add LEGAL donations link for ios/android
// three crowns: better font for stealable tiles (holy letters)
// plot twist: add ability to click a chat to see the character description
// plot twist: add final scoreboard screen with "winners" who guessed correctly
// plot twist: capability for narrator to cast poll, and for players to vote
// plot twist: add "narrator silence" so narrators can only say something every X chats
// plot twist: add ability to delete chats?
// plot twist: add ability to choose narrator in lobby?
// the hunt: add timer to voting!!
// other tools: random number generator?
// abstract: (might not need) add voting system for choosing abstract cards (all members of team must select it)
// abstract: tiebreaker with total time used as second marker
// if leader leaves a game, need to assign remaining player the leader position - ORRRRR, "claim leadership" button would be more fun and easier
// add password reset option
// add snackbar when auto exiting to lobby or main menu
// ability to leave a game (might not need) (also delete session if last one out) - dialog on back button (leave game or just go to main menu)
// attribute icon: Icons made by "https://www.flaticon.com/authors/freepik

// fake users:
// cassie@g.com  F3cbzZifAqWWM2eyab6x6WvdkyL2
// henry@g.com  LoTLbkqfQWcFMzjrYGEne1JhN7j2
// markus@g.com  XMFwripPojYlcvagoiDEmyoxZyK2
// maggie@g.com  h4BrcG93XgYsBcGpH7q2WySK8rd2
// vanessa@g.com  z5SqbMUvLVb7CfSxQz4OEk9VyDE3
// greg@gmail.com  djawU3QzVCXkLq32mlmd6W81CqK2
// a@g.com alex V7YrOSWEDdTTrTRt6UlSFDZdgZN2
// m@g.com markus
// c@g.com cassie
// v@g.com vanessa
// h@g.com henry
// g@g.com greg
// p@g.com pyka
// q@g.com quentin

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
        dialogBackgroundColor: Colors.grey[200],
        fontFamily: 'Balsamiq',
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primaryColor: Colors.blue[700],
        accentColor: Colors.blue[300],
        highlightColor: Colors.white,
        dialogBackgroundColor: Colors.grey[900],
        fontFamily: 'Balsamiq',
        brightness: Brightness.dark,
      ),
      home: RootScreen(auth: new Auth()),
    );
  }
}
