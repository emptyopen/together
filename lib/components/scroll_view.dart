import 'package:flutter/material.dart';

class TogetherScrollView extends StatefulWidget {
  final Widget child;

  TogetherScrollView({this.child});

  @override
  _TogetherScrollViewState createState() => _TogetherScrollViewState();
}

class _TogetherScrollViewState extends State<TogetherScrollView> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: widget.child,
        ),
        Text('a'),
      ],
    );
  }
}
