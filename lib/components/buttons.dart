import 'package:flutter/material.dart';

class RaisedGradientButton extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final double height;
  final double width;
  final Function onPressed;

  const RaisedGradientButton({
    Key key,
    @required this.child,
    this.gradient,
    this.height = 100,
    this.width = double.infinity,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      onPressed: onPressed,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(80.0)),
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