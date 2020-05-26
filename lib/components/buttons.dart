import 'package:flutter/material.dart';

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
    return RaisedButton(
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
            constraints: BoxConstraints(
              minWidth: 88.0,
              minHeight: 36.0,
              maxHeight: height,
              maxWidth: width,
            ),
            alignment: Alignment.center,
            child: child),
      ),
    );
  }
}
