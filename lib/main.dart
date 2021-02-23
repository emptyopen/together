import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'services/authentication.dart';
import 'screens/auth/root_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  runApp(MyApp());
}

// DONE:
// three crowns: better font for stealable tiles (holy letters)
// samesies: there should be an option for multiple teams if they want the same words or not (as each other)

// next up:
// add LEGAL donations link for ios/android

// TODO:
// bananaphone: increment player score
// charades: shimmer for high round scores
// big: add additional skins after certain number of wins (new crowns for certain wins in three crowns)
// big: add emoji version to samesies
// big: consolidation of new game to simplified parameters / per screen (init, scaffold, etc.)
// bananaphone: maybe change voting to "entire progression", single vote
// team selector: a few annoying bugs remaining with rapid touches
// plot twist: add ability to click a chat to see the character description
// plot twist: add final scoreboard screen with "winners" who guessed correctly
// plot twist: add "narrator silence" so narrators can only say something every X chats
// plot twist: add ability to choose narrator in lobby?
// the hunt: add timer to voting!!
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
