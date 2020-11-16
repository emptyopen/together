import 'package:flutter/material.dart';
import 'package:transformer_page_view/transformer_page_view.dart';

import 'package:together/components/buttons.dart';
import 'package:together/components/misc.dart';
import 'package:together/components/scroll_view.dart';

class TheHuntScreenHelp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HelpScreen(
      title: 'The Hunt: Rules',
      information: [
        '    The objectives of the game are simple:\n\n(1) If you ARE NOT a spy, you are a citizen trying to find the spy(ies). \n\n(2) If you ARE a spy, '
            'you are trying to figure out where the location is.\n\n(3) Spies lose and win, together. Same for citizens.',
        '    Players take turns asking questions to a player of their choice. The question can be anything, '
            'and the answer can be anything.\n\n    Just keep in mind that vagueness can be suspicious!',
        '    At any point, a player can accuse another player of being the spy.\n\n    '
            'A verdict requires a unanimous vote, less the remaining number of spies.',
        '    The game ends in two general ways:\n\n(1) A spy can reveal they are the spy at any time (except during an accusation), and attempt to guess the location. '
            'If they guess correctly, the spies win. If they guess incorrectly, the spies lose.'
            '\n\n(continued on next page)',
        '\n\n(2) If a citizen is unanimously accused, the spies win. Otherwise the spy is exiled, and if there are no spies left, the citizens win.'
            '\n\nThe spies can always guess the location once the game is over, for "honor"!'
      ],
      buttonColor: Theme.of(context).primaryColor,
    );
  }
}

class AbstractScreenHelp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HelpScreen(
      title: 'Abstract: Rules',
      information: [
        '    The objective of this game is to flip all cards for your team. '
            'Leaders of teams take turns giving a clue to their team which should tie different words on the board together. '
            'A clue can be anything that has a Wikipedia page. ',
        '    The timer is shared for the leader giving the clue and the leader\'s team guessing.',
        '    If a team wins, teams that didn\'t initially start before the winning team get chance for rebuttal. In '
            'case of ties, the team that used the least time throughout the game wins.',
      ],
      buttonColor: Theme.of(context).primaryColor,
    );
  }
}

class BananaphoneScreenHelp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HelpScreen(
      title: 'Bananaphone: Rules',
      information: [
        '    All you have to do is follow the prompts!\n    Players are each initially assigned a prompt, and are tasked with drawing it. '
            'The drawings are "passed" around the "table" and players then describe the drawing. These drawing / describe alternations are repeated a couple times. ',
        '    Once the round is complete, players vote on their favorite drawings and description, one per round (that isn\'t theirs). Once all the rounds '
            'are complete, the player with the highest score wins! In case of ties, there are multipled winners.'
      ],
      buttonColor: Theme.of(context).primaryColor,
    );
  }
}

class RiversScreenHelp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HelpScreen(
      title: 'Rivers: Rules',
      information: [
        '    Welcome to Rivers! In this game, we\'re going to work together! Players take turns playing cards, and the '
            'objective of the game is to play every single card!\n\n    With standard rules, the deck contains cards from 2 to '
            '99, one of each. While there are cards remaining in the draw pile, player must play at least two cards. Once the '
            'draw pile runs out of cards, players must play at least one card. ',
        '    There are four piles to play on: two ascending piles and two descending piles. The rules for playing a card are '
            'simple: you can only play cards higher than the current card for ascending piles, and cards lower than the current card '
            'for descending piles.\n\n    The only exception is a card exactly 10 lower on ascending piles, and 10 higher on descending '
            'piles. For examples, for an ascending pile that is currently at 42, a player could play 43, 44, 45, etc., and the best card '
            'to play would be a 32. But not 41, 40, 39, etc. ',
        '    The final major rule is that players cannot specify what numbered cards they have in any way. Players can say things like '
            '"Don\'t play on this pile", or "I have something really good for the left ascending pile", or "Definitely, definitely don\'t '
            'play on 35". But nothing that could definitively describe a specific number.\n\n'
            '    The game ends when all cards are played (amazing job!), or if a player cannot play the required number of cards. The score '
            'is counted by the remaining unplayed cards in players\' hands and in the draw pile. '
      ],
      buttonColor: Theme.of(context).primaryColor,
    );
  }
}

class ThreeCrownsScreenHelp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HelpScreen(
      title: 'Three Crowns: Rules',
      information: [
        '    Three Crowns is an unnecessarily complicated game, but here are the rules.\n\n    The objective of the game is to collect three crowns, '
            'which can be achieved in two ways. By far the most common way to collect a crown is to collect sufficient tiles to complete the target word for the round. '
            'The other (legendary) way is to achieve a "Peasant\'s Uprising", which will be discussed later. ',
        '    The game is played with a duel that rotates around the table. Two players start dueling by playing a single card from their hand '
            '(face down), then both reveal, and the winner of the duel receives some prize based on the duel outcome.\n\n    Letter tiles are collected '
            'in this manner until one of the players can create the target word, which is randomly generated for each round.',
        'Now, some terms.\n\n - Joust: Each duel starts on the 1st joust. When there is a value tie in the duel, the duel immediately moves to the '
            'next joust. If the 4th joust is reached, both duelers immediately receive 3 tiles and the duel is compelete. The reward for any duel is multiplied by the '
            'number of jousts for that duel.\n\n - Holy tile: '
            'A letter tile whose letter is contained within the target word. Cannot be burned.\n\n - Grail: A blank letter tile that can be a wildcard for any letter. '
            'Highly coveted. ',
        ' - Siege: When a One and a face card (J, Q, K) duel. Winner pillages.\n\n - Pillage: Winner can steal a non-holy tile, or receive two random tiles.',
        '    Some duel rules! In general, the higher value card wins, and the winner of the duel will receive one random tile.\n    If a face card is involved, '
            'the prize becomes two tiles (8 vs. K, 2 vs. Q, K vs. J, etc.).\n    If a 4 is involved or if the cards are of the same suit, the result is flipped '
            '(lower value wins). If both occur, higher value wins as usual.\n    Ones are lower than every other value, but defeat face cards with a Siege. In '
            'a Siege, the One beats the face card unless they are the same suit. The winner of a siege pillages. ',
        '    Here\'s where things get marginally more interesting.\n\n    If a duel winner wins with a higher value card, the loser has a chance to "match", '
            'which means they can play any number of cards whose value sum equals the difference between the lower card and the higher card. Face card values are '
            'J = 10, Q = 11, K = 12.\n    So in an example case where a 4 is defeated by a K, the losing duelist could play a 9, or a 7 plus two 1\'s, etc. \n\n    '
            'If a match is successful, the matcher gets to "pillage" the original winner. No matching can occur for sieges.',
        '\n    Finally, if a duelist is "matched", they have a chance to respond to the match and avoid being pillaged. This can be accomplished by playing one or more '
            'duplicates of the card they already played. To extend the previous example, the original winner of the duel could respond to a match by playing one or more K\'s.'
            '\n    If the response is one card, it is called a "Peasant\'s Blockage", and the matcher loses the ability to steal tiles and simply receives two random tiles. ',
        '    Two of a kind results in a "Peasant\'s Reversal", and the pillager becomes the pillagee (the original winner now pillages). Three or more of a kind results in a '
            '"Peasant\'s Uprising", for which the player receives a crown and the round immediately ends. This is astoundingly rare. '
            '\n\n    A pillage reward, like a tile reward, is multiplied '
            'by the number of jousts for that duel. Each reward can be chosen differently (i.e. two jousts, then player A wins a siege. Player A can steal one tile, then '
            'receive two random tiles).',
        '    FAQ:\n\n    Why?\n\n    Three Crowns is the unholy result of three bored kids during Thanksgiving on Long Island many years ago.\n  It is entirely made possible '
            'by wonderful friends who forgive haphazard rule creation, arbitrary and experimental decisions, and random themetic elements.'
      ],
      buttonColor: Theme.of(context).primaryColor,
    );
  }
}

class PlotTwistScreenHelp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HelpScreen(
      title: 'Plot Twist: Rules',
      information: [
        '    Welcome to Plot Twist! If you\'re looking for a game with basically no rules and total freedom for creative expression, this is it.'
            '\n\n    The objective of the game is not so much to win as it is to have fun and come up with a story. Essentially, all of the players '
            'will take part in a group chat conversation. You will choose or make up a character, and act as that character in the chat room.',
        '    Narrators will be randomly chosen - they control what actually happens in the story. The narrators can ask the players for consensus '
            'on determining a choice by polling the group, or can simply provide informational context.\n    If there is more than one narrator, '
            'they take turns deciding what new direction the story will take.',
        '    Players can guess who is playing which characters in the "Game" menu, and if at the end of the game their choices are completely '
            'accurate, they can be one of the "winners".\n'
            '    The game is over when there is a general consensus that it is over (each player can indicate their consent with the end of the game '
            'in the "Game" menu.',
      ],
      buttonColor: Theme.of(context).primaryColor,
    );
  }
}

class InSyncScreenHelp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HelpScreen(
      title: 'Plot Twist: Rules',
      information: [
        '    In Sync help: TBD! lol',
      ],
      buttonColor: Theme.of(context).primaryColor,
    );
  }
}

class CharadeATroisScreenHelp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HelpScreen(
      title: 'Plot Twist: Rules',
      information: [
        '    Welcome to charade à trois! The rules are simple. There are three rounds in which players take turns '
            'describing, gesturing, and saying but one word to get their teammates to guess the words and phrases. \n'
            '    Words and phrases can be generated automatically, or players can write their own.',
      ],
      buttonColor: Theme.of(context).primaryColor,
    );
  }
}

class HelpScreen extends StatefulWidget {
  final String title;
  final List<String> information;
  final Color buttonColor;
  final Function callback;

  HelpScreen({
    this.title = '',
    this.information,
    this.buttonColor,
    this.callback,
  });

  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int slideIndex = 0;
  final IndexController indexController = IndexController();
  List<Widget> informationList = [];
  bool firstHelp = true;

  @override
  void initState() {
    super.initState();

    if (widget.information.length > 1) {
      informationList.add(Column(
        children: <Widget>[
          Text(
            widget.information[0],
            style: TextStyle(
              fontSize: 18,
              color: Colors.black,
            ),
            textAlign: TextAlign.left,
          ),
          SizedBox(
            height: 20,
          ),
          Text(
            '(Swipe for more information)',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ));
      widget.information.sublist(1).forEach((f) {
        informationList.add(Text(
          f,
          style: TextStyle(
            fontSize: 18,
            color: Colors.black,
          ),
          textAlign: TextAlign.left,
        ));
      });
    } else {
      informationList.add(Text(
        widget.information[0],
        style: TextStyle(fontSize: 18, color: Colors.black),
        textAlign: TextAlign.left,
      ));
    }
  }

  getSlideCircles(
      int numCircles, int currentCircleIndex, Color highlightColor) {
    List<Widget> circles = [];
    for (int i = 0; i < numCircles; i++) {
      bool isCurrent = i == currentCircleIndex;
      circles.add(
        Container(
          height: isCurrent ? 14 : 10,
          width: isCurrent ? 14 : 10,
          decoration: BoxDecoration(
            color: isCurrent ? highlightColor : Colors.grey,
            borderRadius:
                isCurrent ? BorderRadius.circular(7) : BorderRadius.circular(7),
            // border: i == currentCircleIndex ? Border.all(color) : null,
          ),
        ),
      );
      circles.add(
        SizedBox(
          width: 5,
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: circles,
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    TransformerPageView transformerPageView = TransformerPageView(
      pageSnapping: true,
      onPageChanged: (index) {
        setState(() {
          slideIndex = index;
        });
      },
      loop: false,
      controller: indexController,
      transformer:
          PageTransformerBuilder(builder: (Widget child, TransformInfo info) {
        return Container(
          margin: EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(50)),
          alignment: Alignment.center,
          child: Stack(
            children: <Widget>[
              Center(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                  child: TogetherScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        slideIndex == 0
                            ? Column(
                                children: <Widget>[
                                  Text(
                                    widget.title,
                                    style: TextStyle(
                                      fontSize: 28,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                ],
                              )
                            : Container(),
                        slideIndex == 0 ? PageBreak(width: 80) : Container(),
                        ParallaxContainer(
                          child: informationList[info.index],
                          position: info.position,
                          translationFactor: 100,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              widget.information.length > 1
                  ? Padding(
                      padding: EdgeInsets.all(25),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: getSlideCircles(widget.information.length,
                            slideIndex, widget.buttonColor),
                      ),
                    )
                  : Container(),
            ],
          ),
        );
      }),
      itemCount: widget.information.length,
    );

    return Material(
        color: Color.fromRGBO(0, 0, 0, 0.7),
        child: Stack(
          children: <Widget>[
            Container(
              color: Colors.transparent,
              constraints: BoxConstraints.expand(),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: screenWidth * 0.9,
                    height: screenHeight * 0.65,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(5))),
                    child: transformerPageView,
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  HelpOKButton(
                    buttonColor: widget.buttonColor,
                    buttonSplashColor: widget.buttonColor,
                    callback: widget.callback,
                  )
                ],
              ),
            ),
          ],
        ));
  }
}

class HelpOKButton extends StatelessWidget {
  final Color buttonColor;
  final Color buttonSplashColor;
  final String firstHelpKey;
  final Function callback;

  HelpOKButton(
      {this.buttonColor,
      this.buttonSplashColor,
      this.firstHelpKey,
      this.callback});

  @override
  Widget build(BuildContext context) {
    return RaisedGradientButton(
      child: Text('Fine', style: TextStyle(color: Colors.white, fontSize: 22)),
      onPressed: () {
        if (callback != null) {
          callback();
        }
        Navigator.pop(context);
      },
      height: 60,
      width: 120,
      gradient: LinearGradient(
        colors: <Color>[
          Theme.of(context).primaryColor,
          Theme.of(context).accentColor,
        ],
      ),
      borderHighlight: true,
    );
  }
}
