import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:shimmer/shimmer.dart';

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

class MainMenuButton extends StatelessWidget {
  final Function callback;
  final String title;
  final Color textColor;
  final icon;
  final gradient;

  MainMenuButton({
    this.callback,
    this.title,
    this.textColor,
    this.icon,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return RaisedGradientButton(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: textColor,
            size: 30,
          ),
          SizedBox(width: 10),
          Shimmer.fromColors(
            period: Duration(seconds: 3),
            baseColor: textColor.withAlpha(200),
            highlightColor: textColor.withAlpha(250),
            child: Container(
              width: 110,
              child: AutoSizeText(
                title,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 20,
                  color: textColor,
                ),
              ),
            ),
          ),
        ],
      ),
      height: 60,
      width: 200,
      gradient: LinearGradient(
        colors: gradient,
      ),
      onPressed: () {
        callback();
      },
    );
  }
}
