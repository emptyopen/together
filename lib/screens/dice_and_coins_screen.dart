import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:math';
import 'package:flutter/services.dart';

import 'package:together/components/buttons.dart';

class DiceAndCoinsScreen extends StatefulWidget {
  DiceAndCoinsScreen({this.userId});

  final String userId;

  @override
  _DiceAndCoinsScreenState createState() => _DiceAndCoinsScreenState();
}

class _DiceAndCoinsScreenState extends State<DiceAndCoinsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  List dice = [1, 1];
  bool rollingDice = false;
  bool coin = true;
  bool flippingCoin = false;

  rollDice() {
    rollingDice = true;
    HapticFeedback.vibrate();
    Future.delayed(
      Duration(milliseconds: 400),
      () {
        HapticFeedback.vibrate();
        rollingDice = false;
        var _random = new Random();
        for (int i = 0; i < dice.length; i++) {
          dice[i] = _random.nextInt(6);
        }
        setState(() {});
      },
    );
    setState(() {});
  }

  removeDice() {
    dice.removeLast();
    setState(() {});
  }

  addDice() {
    dice.add(1);
    setState(() {});
  }

  getDice() {
    List<Widget> diceWidgets = [];
    var width = MediaQuery.of(context).size.width;
    dice.forEach((v) {
      var diceIcon = MdiIcons.dice1;
      switch (v) {
        case 1:
          diceIcon = MdiIcons.dice2;
          break;
        case 2:
          diceIcon = MdiIcons.dice3;
          break;
        case 3:
          diceIcon = MdiIcons.dice4;
          break;
        case 4:
          diceIcon = MdiIcons.dice5;
          break;
        case 5:
          diceIcon = MdiIcons.dice6;
          break;
      }
      diceWidgets.add(
        Icon(
          rollingDice ? MdiIcons.squareMedium : diceIcon,
          size: min(
            90,
            (width * 0.70) / dice.length,
          ),
          color: rollingDice ? Colors.grey : Theme.of(context).highlightColor,
        ),
      );
    });
    return Container(
      width: width * 0.8,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).highlightColor),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              dice.length > 1
                  ? GestureDetector(
                      onTap: () {
                        removeDice();
                      },
                      child: Icon(
                        MdiIcons.minusBox,
                        size: 30,
                        color: Colors.red,
                      ),
                    )
                  : Container(),
              SizedBox(width: 3),
              dice.length < 10
                  ? GestureDetector(
                      onTap: () {
                        addDice();
                      },
                      child: Icon(
                        MdiIcons.plusBox,
                        size: 30,
                        color: Colors.green,
                      ),
                    )
                  : Container(),
            ],
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: diceWidgets,
          ),
          SizedBox(height: 5),
          RaisedGradientButton(
            child: Icon(MdiIcons.syncIcon),
            height: 40,
            width: 80,
            onPressed: rollingDice
                ? () {}
                : () {
                    rollDice();
                  },
          )
        ],
      ),
    );
  }

  flipCoin() async {
    HapticFeedback.vibrate();
    flippingCoin = true;
    Future.delayed(
      Duration(milliseconds: 400),
      () {
        flippingCoin = false;
        HapticFeedback.vibrate();
        var _random = new Random();
        coin = _random.nextBool();
        setState(() {});
      },
    );
    setState(() {});
  }

  getCoins() {
    var width = MediaQuery.of(context).size.width;
    return Container(
      width: width * 0.8,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).highlightColor),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.all(10),
      child: Center(
        child: Column(
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).highlightColor,
                ),
                borderRadius: BorderRadius.circular(100),
                color: Colors.grey,
              ),
              child: Center(
                child: Container(
                  height: 95,
                  width: 95,
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(100),
                    color: flippingCoin
                        ? Colors.grey.withAlpha(200)
                        : coin
                            ? Colors.pink.withAlpha(150)
                            : Colors.black.withAlpha(150),
                  ),
                  child: Icon(
                    flippingCoin
                        ? MdiIcons.squareMedium
                        : coin ? MdiIcons.heart : MdiIcons.heartBroken,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 5),
            RaisedGradientButton(
              child: Icon(MdiIcons.syncIcon),
              height: 40,
              width: 80,
              onPressed: flippingCoin
                  ? () {}
                  : () {
                      flipCoin();
                    },
            )
          ],
        ),
      ),
    );
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
          'Dice & Coin',
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            getDice(),
            SizedBox(height: 20),
            getCoins(),
            // TODO: at some point maybe
            // SizedBox(height: 20),
            // getRandomNumberGenerator(),
          ],
        ),
      ),
    );
  }
}
