import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        onPressed: () {
          HapticFeedback.vibrate();
          onPressed();
        },
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
