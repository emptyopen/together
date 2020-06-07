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

class RulesContainer extends StatelessWidget {

  final List<Widget> rules;
  RulesContainer({this.rules});

  @override
  Widget build(BuildContext context) {
    return Container(
              padding: EdgeInsets.fromLTRB(15, 5, 15, 5),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: rules
              ),
            );
  }
}