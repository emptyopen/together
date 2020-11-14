import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'services/authentication.dart';
import 'screens/auth/root_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

// done:
// big: voice command for the scoreboard (+/- team, +/- score)
// general: show arrow for scrollable!!
// sanity check after big updates:
// the hunt - good
// rivers - good
// abstract
// bananaphone
// charade
// plot twist
// three crowns - good

// next up:
// dice & coins vibrations
// increment player scores for some games

// TODO:
// abstract: it's all broken and i'm drunk and asya keeps talking about some miami story about a ...........;.

// abstract: orange team needs to win when green wins for them
// abstract games has funky behavior? - green wins then orange hits grey - should be over but timer glitches
// abstract: ability to manually change teams (people can just join the team they want to be on?)
// abstract should show leader view at end of game (not just solid blocks)
// abstract: (might not need) add voting system for choosing abstract cards (all members of team must select it)
// abstract: logic to ensure at least one group of words is selected
// abstract, tiebreaker with total time used as second marker
// arrow for togetherScrollView bugged permanent on the hunt screen end game with incorrect guess
// consolidation: move all "strings" and colors to constants, i.e. "charade a trois", Colors.cyan[700], etc.
// team selector: a few annoying bugs remaining with rapid touches
// ensure everything is using transacts in the whole project
// show & tell: shimmer for high round scores
// add LEGAL donations link for ios/android
// charades: add everything to a log?
// BIG: update lobby to allow team switching?
// three crowns: better font for stealable tiles (holy letters)
// check if working: undo button not working in bananaphone 2nd+ drawings
// plot twist: add ability to click a chat to see the character description
// plot twist: add final scoreboard screen with "winners" who guessed correctly
// plot twist: capability for narrator to cast poll, and for players to vote
// plot twist: add "narrator silence" so narrators can only say something every X chats
// plot twist: add ability to delete chats?
// plot twist: add ability to choose narrator in lobby?
// the hunt: add timer to voting!!
// rivers: show stacks history
// other tools: random number generator?
// make all buttons disappear when they are clicked (especially when they cause an effect - there are double effects happening)
// fine grained control of teams in lobby for abstract
// bananaphone: add scores button to view scores
// add timer to the hunt?
// if leader leaves a game, need to assign remaining player the leader position - ORRRRR, "claim leadership" button would be more fun and easier
// add snackbar when auto exiting to lobby or main menu
// add password reset option
// ability to leave a game (might not need) (also delete session if last one out) - dialog on back button (leave game or just go to main menu)
// attribute icon: Icons made by "https://www.flaticon.com/authors/freepik

// fake users:
// cassie@g.com  F3cbzZifAqWWM2eyab6x6WvdkyL2
// henry@g.com  LoTLbkqfQWcFMzjrYGEne1JhN7j2
// markus@g.com  XMFwripPojYlcvagoiDEmyoxZyK2
// maggie@g.com  h4BrcG93XgYsBcGpH7q2WySK8rd2
// vanessa@g.com  z5SqbMUvLVb7CfSxQz4OEk9VyDE3
// greg@gmail.com  djawU3QzVCXkLq32mlmd6W81CqK2
// abr
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
