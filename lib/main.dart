import 'package:flutter/material.dart';

import 'services/authentication.dart';
import 'screens/root_screen.dart';

void main() => runApp(MyApp());

// done:

// next up:
// three round charades - SHOW & TELL
// lots of settings:
// - word collection - min/max number of words, time limit on collection
// - user inputted words or generated random words
// - round time limits (describe, gesture, one word)
// random teams initially with captain on each team (responsible for confirming guesses of other team)
// phase = 'wordCollection': enter words/phrases
// phase = 'describe': teams take turns to burn through as many words as possible
// phase = 'gesture': teams take turns using gestures
// phase = 'oneWord': teams take turns using one word
// when guessing, presenter has option to 'skip' or 'got it!', team leaders see a list of guessed words and can veto
// add everything to a log
// timer and log are available to everyone
// phase = 'scoreboard': how many clues everyone got, which team wins
// update lobby to allow team switching?

// PLOT TWIST: (formerly Chit Chat and Hear Me Out):
// - add ability to click a chat to see the character description
// - narrator can see everyone's vote to end
// - add final scoreboard screen with "winners" who guessed correctly

// TODO:
// show arrow for scrollable!!
// check if working: undo button not working in bananaphone 2nd+ drawings
// plot twist: capability for narrator to cast poll, and for players to vote
// plot twist: add "narrator silence" so narrators can only say something every X chats
// plot twist: add ability to delete chats?
// plot twist: add ability to choose narrator in lobby?
// add sounds and vibration
// the hunt: add timer to voting!!
// change button texture when loading during async call
// abstract: logic to ensure at least one group of words is selected
// rivers: show stacks history
// abstract games has funky behavior? - green wins then orange hits grey - should be over but timer glitches
// make all buttons disappear when they are clicked (especially when they cause an effect - there are double effects happening)
// fine grained control of teams in lobby for abstract
// add scores button to view scores in bananaphone
// orange team needs to win when green wins for them
// tiebreaker for abstract, with total time used as second marker
// add timer to the hunt?
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
