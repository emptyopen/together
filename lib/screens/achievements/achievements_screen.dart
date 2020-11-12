import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:together/components/misc.dart';

import 'achievements_components.dart';

class AchievementsScreen extends StatefulWidget {
  final userId;

  AchievementsScreen({Key key, this.userId}) : super(key: key);

  @override
  _AchievementsScreenState createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  bool isLoading = true;
  int theHuntScore = 0;
  int riversScore = 0;
  int abstractScore = 0;
  int bananaphoneScore = 0; // TODO: increment
  int threeCrownsScore = 0;
  int charadeATroisScore = 0;

  @override
  initState() {
    super.initState();
    getScores();
  }

  getScores() async {
    var data = (await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get())
        .data();
    if (data['theHuntScore'] == null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'theHuntScore': 0});
    }
    if (data['theHuntScore'] == null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'riversScore': 0});
    }
    if (data['abstractScore'] == null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'abstractScore': 0});
    }
    if (data['bananaphoneScore'] == null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'bananaphoneScore': 0});
    }
    if (data['threeCrownsScore'] == null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'threeCrownsScore': 0});
    }
    if (data['riversScore'] == null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'riversScore': 0});
    }
    if (data['charadeATroisScore'] == null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'charadeATroisScore': 0});
    }
    data = (await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get())
        .data();
    setState(() {
      theHuntScore = data['theHuntScore'];
      riversScore = data['riversScore'];
      abstractScore = data['abstractScore'];
      bananaphoneScore = data['bananaphoneScore'];
      threeCrownsScore = data['threeCrownsScore'];
      charadeATroisScore = data['charadeATroisScore'];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Achievements',
          style: TextStyle(fontFamily: 'Balsamiq'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 275,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).highlightColor),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.all(15),
              child: isLoading
                  ? Center(child: Text('Loading...'))
                  : Column(
                      children: <Widget>[
                        Text(
                          'Achievements',
                          style: TextStyle(
                            fontSize: 22,
                          ),
                        ),
                        PageBreak(width: 150),
                        SizedBox(height: 30),
                        Achievement(
                          achievementName: 'The Hunt',
                          subHeading: '(games won)',
                          value: theHuntScore,
                          icon: Icon(
                            MdiIcons.incognito,
                            size: 30,
                          ),
                        ),
                        SizedBox(height: 10),
                        Achievement(
                          achievementName: 'Rivers',
                          subHeading: '(games won)',
                          value: riversScore,
                          icon: Icon(
                            MdiIcons.waves,
                            color: Colors.lightBlue,
                            size: 30,
                          ),
                        ),
                        SizedBox(height: 10),
                        Achievement(
                          achievementName: 'Abstract',
                          subHeading: '(games won)',
                          value: abstractScore,
                          icon: Icon(
                            MdiIcons.resistorNodes,
                            color: Colors.green,
                            size: 30,
                          ),
                        ),
                        SizedBox(height: 10),
                        Achievement(
                          achievementName: 'Bananaphone',
                          subHeading: '(games won)',
                          value: bananaphoneScore,
                          icon: Icon(
                            MdiIcons.phoneSettingsOutline,
                            color: Colors.blue,
                            size: 30,
                          ),
                        ),
                        SizedBox(height: 10),
                        Achievement(
                          achievementName: 'Three Crowns',
                          subHeading: '(games won)',
                          value: threeCrownsScore,
                          icon: Icon(
                            MdiIcons.crown,
                            color: Colors.amber,
                            size: 30,
                          ),
                        ),
                        SizedBox(height: 10),
                        Achievement(
                          achievementName: 'Charáde à Trois',
                          subHeading: '(games won)',
                          value: charadeATroisScore,
                          icon: Icon(
                            MdiIcons.dramaMasks,
                            color: Colors.indigoAccent,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
