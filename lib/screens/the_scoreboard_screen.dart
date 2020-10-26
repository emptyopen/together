import 'package:flutter/material.dart';
import 'package:together/components/misc.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class TheScoreboardScreen extends StatefulWidget {
  TheScoreboardScreen({this.userId});

  final String userId;

  @override
  _TheScoreboardScreenState createState() => _TheScoreboardScreenState();
}

class _TheScoreboardScreenState extends State<TheScoreboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  var teamNames = ['Team 1', 'Team 2'];
  var scoreValues = [
    [0],
    [0],
  ];

  getScoreboard() {
    List<Widget> scores = [];
    for (int i = 0; i < teamNames.length; i++) {
      List<Widget> teamScores = [
        Text(
          teamNames[i],
          style: TextStyle(
            fontSize: 22,
          ),
        ),
        SizedBox(height: 10),
        PageBreak(width: 50),
        Text(
          scoreValues[i].reduce((a, b) => a + b).toString(),
          style: TextStyle(fontSize: 22),
        ),
        SizedBox(height: 5),
        PageBreak(width: 50),
      ];
      scoreValues[i].reversed.forEach((v) {
        teamScores.add(Text(
          v.toString(),
          style: TextStyle(
            fontSize: 18,
          ),
        ));
        teamScores.add(SizedBox(height: 5));
      });
      teamScores.add(GestureDetector(
          onTap: () {
            print('hi');
          },
          child: Icon(MdiIcons.plusBox)));
      scores.add(Column(children: teamScores));
      scores.add(SizedBox(width: 30));
    }
    return Column(
      children: [
        SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: scores,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.cyan[700],
          title: Text(
            'The Scoreboard',
          ),
        ),
        body: getScoreboard());
  }
}
