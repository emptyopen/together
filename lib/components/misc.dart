import 'package:flutter/material.dart';

class PageBreak extends StatelessWidget {
  PageBreak({this.width = 50});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(height: 3,),
        Container(
          height: 2,
          width: width,
          decoration: BoxDecoration(border: Border.all()),
        ),
        SizedBox(height: 10,),
      ],
    );
  }
}
