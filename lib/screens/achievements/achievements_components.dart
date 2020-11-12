import 'package:flutter/material.dart';

class Achievement extends StatelessWidget {
  final Icon icon;
  final String achievementName;
  final String subHeading;
  final value;

  Achievement({
    this.icon,
    this.achievementName,
    this.subHeading = '',
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).highlightColor),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          icon,
          SizedBox(width: 10),
          Column(
            children: <Widget>[
              Text(
                achievementName,
                style: TextStyle(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subHeading,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          SizedBox(width: 10),
          Text(
            ' =  $value',
            style: TextStyle(
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}
