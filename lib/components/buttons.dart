import 'package:flutter/material.dart';

import '../components/dialogs.dart';

class RaisedGradientButton extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final double height;
  final double width;
  final Function onPressed;
  final bool borderHighlight;

  const RaisedGradientButton(
      {Key key,
      @required this.child,
      this.gradient,
      this.height = 100,
      this.width = double.infinity,
      this.onPressed,
      this.borderHighlight = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      child: RaisedButton(
        onPressed: onPressed,
        shape: RoundedRectangleBorder(
            side: borderHighlight
                ? BorderSide(width: 3, color: Colors.white)
                : BorderSide.none,
            borderRadius: BorderRadius.circular(80.0)),
        padding: const EdgeInsets.all(0.0),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.all(Radius.circular(80.0)),
          ),
          child: Container(
              constraints: BoxConstraints(),
              alignment: Alignment.center,
              child: child),
        ),
      ),
    );
  }
}

class EndGameButton extends StatelessWidget {
  final String sessionId;
  final String gameName;
  final double fontSize;
  final double height;
  final double width;

  EndGameButton(
      {this.sessionId,
      this.gameName,
      this.fontSize = 14,
      this.height = 30,
      this.width = 100});
  @override
  Widget build(BuildContext context) {
    return RaisedGradientButton(
      child: Text(
        'End game',
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.black,
        ),
      ),
      onPressed: () {
        showDialog<Null>(
          context: context,
          builder: (BuildContext context) {
            return EndGameDialog(
              game: gameName,
              sessionId: sessionId,
              winnerAlreadyDecided: true,
            );
          },
        );
      },
      height: height,
      width: width,
      gradient: LinearGradient(
        colors: <Color>[
          Color.fromARGB(255, 255, 185, 0),
          Color.fromARGB(255, 255, 213, 0),
        ],
      ),
    );
  }
}
