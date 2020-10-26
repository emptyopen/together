import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class DiceAndCoinsScreen extends StatefulWidget {
  DiceAndCoinsScreen({this.userId});

  final String userId;

  @override
  _DiceAndCoinsScreenState createState() => _DiceAndCoinsScreenState();
}

class _DiceAndCoinsScreenState extends State<DiceAndCoinsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  List dice = [1, 1];

  getDice() {
    List<Widget> diceWidgets = [];
    dice.forEach((v) {
      var diceIcon = MdiIcons.dice1;
      switch (v) {
        case 2:
          diceIcon = MdiIcons.dice2;
          break;
        case 3:
          diceIcon = MdiIcons.dice3;
          break;
        case 4:
          diceIcon = MdiIcons.dice4;
          break;
        case 5:
          diceIcon = MdiIcons.dice5;
          break;
        case 6:
          diceIcon = MdiIcons.dice6;
          break;
      }
      diceWidgets.add(
        Icon(
          diceIcon,
          size: 60,
        ),
      );
    });
    return Container(
      width: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).highlightColor),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: EdgeInsets.all(10),
      child: Column(
        children: [
          Text(
            'Number of dice: ${dice.length}',
            style: TextStyle(
              fontSize: 20,
            ),
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: diceWidgets,
          ),
        ],
      ),
    );
  }

  getCoins() {
    return Text('Coins here');
  }

  getRandomNumberGenerator() {
    return Text('RNG here');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan[700],
        title: Text(
          'Dice & Coins',
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            getDice(),
            getCoins(),
            getRandomNumberGenerator(),
          ],
        ),
      ),
    );
  }
}
