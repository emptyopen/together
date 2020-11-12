import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:math';

class RiversCard extends StatelessWidget {
  final String value;
  final Function callback;
  final bool clickable;
  final bool extraClickable;
  final bool empty;
  final bool flipped;
  final bool clicked;
  final bool isCenter;
  final int numCards;

  RiversCard({
    this.value,
    this.callback,
    this.clickable,
    this.numCards = 7,
    this.extraClickable = false,
    this.empty = false,
    this.flipped = false,
    this.clicked = false,
    this.isCenter = false,
  });

  getIcon(double iconSize) {
    var icon = MdiIcons.ladybug;
    var color = Colors.red;
    int intValue = int.parse(value);
    if (intValue >= 10 && intValue < 20) {
      icon = MdiIcons.ninja;
      color = Colors.green;
    }
    if (intValue >= 20 && intValue < 30) {
      icon = MdiIcons.jellyfishOutline;
      color = Colors.purple;
    }
    if (intValue >= 30 && intValue < 40) {
      icon = MdiIcons.ufoOutline;
      color = Colors.lime;
    }
    if (intValue >= 40 && intValue < 50) {
      icon = MdiIcons.rocketOutline;
      color = Colors.grey;
    }
    if (intValue >= 50 && intValue < 60) {
      icon = MdiIcons.atom;
      color = Colors.blue;
    }
    if (intValue >= 60 && intValue < 70) {
      icon = MdiIcons.beehiveOutline;
      color = Colors.amber;
    }
    if (intValue >= 70 && intValue < 80) {
      icon = MdiIcons.feather;
      color = Colors.indigo;
    }
    if (intValue >= 80 && intValue < 90) {
      icon = MdiIcons.footPrint;
      color = Colors.brown;
    }
    if (intValue >= 90 && intValue <= 100) {
      icon = MdiIcons.silverwareVariant;
      color = Colors.teal;
    }
    return Container(
      // decoration: BoxDecoration(border: Border.all()),
      child: Icon(
        icon,
        size: iconSize,
        color: color.withAlpha(140),
      ),
    );
  }

  getIconBackground(double iconSize) {
    return Transform.rotate(
      angle: 0, //0.2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              getIcon(iconSize),
              getIcon(iconSize),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              getIcon(iconSize),
              getIcon(iconSize),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              getIcon(iconSize),
              getIcon(iconSize),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double width = (screenWidth - 20 - 5 * numCards) / numCards;
    double height = width * 1.5;
    double fontSize = [40.0, width * 0.5].reduce(min);
    double iconSize = [(width - 10) / 2, (height - 10) / 3].reduce(min);
    Color textColor = Colors.black;
    if (isCenter) {
      height = 100;
      width = 80;
      fontSize = 40;
      iconSize = 28;
    }
    if (empty) {
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Theme.of(context).highlightColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            'X',
            style: TextStyle(
              color: Colors.red,
              fontSize: 40,
            ),
          ),
        ),
      );
    }
    if (flipped) {
      return GestureDetector(
        onTap: callback,
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Theme.of(context).highlightColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Container(
              height: height - 10,
              width: width - 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    Colors.pinkAccent,
                    Colors.blue,
                  ],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  MdiIcons.waves,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: callback,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: clicked
                ? Colors.blue
                : clickable
                    ? Colors.lightGreen
                    : extraClickable
                        ? Colors.indigoAccent
                        : Colors.black,
            width: clickable || clicked || extraClickable ? 5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: <Widget>[
              Center(
                child: getIconBackground(iconSize),
              ),
              Center(
                child: Text(
                  value,
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
