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
// big: voice command for the scoreboard (+/- team, +/- score)
// general: show arrow for scrollable!!
// rivers: show stacks history
// BIG: update lobby to allow exlicit team selection:

// next up:
// bananaphone: increment player score
// sanity check after big updates:
// BANANAPHONE BIG PROBLEM: one vote moves entire state to next round - should multiply, know the answer
// drawing remains on the board when the final description is submitted...
// also draw 2 seems to fail????

// new:
// inSync: orange
// two modes, automatically chosen: high score mode (one group of 2 or 3 people) vs competitive mode (min 4 people, 2v2). groups of 2 or 3
// everyone gets presented with the same word, and write down 10 words
// input 10 (adjustable) words. score is calculated as the number of "similar" words
// 2 people teams: each shared word is worth 2 points (max = 20 points)
// 3 people teams: each tripled word is worth 3 points, each shared word is worth 1 point (max = 3 * 10 = 30)
// gets increasingly difficult:
// 1: easy, 2 points
// 2: easy, 4 points
// 3: easy, 6 points
// 4: medium: 4 points
// 5: medium: 6 points
// 6: medium: 8 points
// 7: hard: 6 points
// 8: hard: 8 points
// 9: hard: 10 points
// 10: expert: 8 points
// 11: expert: 10 points
// 12: expert: 12 points (6 out of 10 the same)

// list 3's, then 2's, then 1's... can fill in the blanks with loners
// ant ant ant
// blue blue blue
// crow crow x
// x dance dance
// smash x x

// in sync: there should be an option for multiple teams if they want the same words or not (as each other)
// in sync: add timer for round
// in sync: add rule for round timer

// TODO:
// big: consolidation of new game to simplified parameters / per screen (init, scaffold, etc.)
// charade a trois: shimmer for high round scores
// arrow for togetherScrollView bugged permanent on the hunt screen end game with incorrect guess
// consolidation: move all "strings" and colors to constants, i.e. "charade a trois", Colors.cyan[700], etc.
// team selector: a few annoying bugs remaining with rapid touches
// consolidate: single order of games for quick start and menu
// ensure everything is using transacts in the whole project
// add LEGAL donations link for ios/android
// charades: add everything to a log?
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
