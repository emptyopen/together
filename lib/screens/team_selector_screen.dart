import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class TeamSelectorScreen extends StatefulWidget {
  TeamSelectorScreen({this.userId});

  final String userId;

  @override
  _TeamSelectorScreenState createState() => _TeamSelectorScreenState();
}

class _TeamSelectorScreenState extends State<TeamSelectorScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool isPickTeams = true;
  int numTeams = 2;

  getSettings() {
    // pick 1 vs pick teams
    // if pick teams, how many teams (1 < x < 8)
    // (max 10 touch points)
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.vibrate();
            setState(() {
              isPickTeams = !isPickTeams;
            });
          },
          child: Container(
            width: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(5),
            ),
            padding: EdgeInsets.all(5),
            child: Column(
              children: [
                Text(
                  isPickTeams ? 'Pick teams' : 'Pick one',
                  style: TextStyle(
                      fontSize: 14, color: Colors.cyan[700].withAlpha(200)),
                ),
                SizedBox(height: 5),
                Container(
                  width: 50,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.withAlpha(100),
                  ),
                  child: Row(
                    mainAxisAlignment: isPickTeams
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      Container(
                        height: 20,
                        width: 25,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.cyan[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 20),
        Container(
          width: 160,
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(5),
          ),
          padding: EdgeInsets.all(5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: numTeams > 2 && isPickTeams
                    ? () {
                        setState(() {
                          numTeams -= 1;
                        });
                        HapticFeedback.vibrate();
                      }
                    : null,
                child: Icon(
                  MdiIcons.chevronLeftBoxOutline,
                  size: 35,
                  color: numTeams > 2 && isPickTeams
                      ? Colors.cyan[700]
                      : Colors.grey,
                ),
              ),
              SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$numTeams ',
                    style: TextStyle(
                      color: isPickTeams ? Colors.cyan[700] : Colors.grey,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    'teams',
                    style: TextStyle(
                      color: Colors.cyan[700].withAlpha(160),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 10),
              GestureDetector(
                onTap: numTeams < 8 && isPickTeams
                    ? () {
                        setState(() {
                          numTeams += 1;
                        });
                        HapticFeedback.vibrate();
                      }
                    : null,
                child: Icon(
                  MdiIcons.chevronRightBoxOutline,
                  size: 35,
                  color: numTeams < 8 && isPickTeams
                      ? Colors.cyan[700]
                      : Colors.grey,
                ),
              ),
            ],
          ),
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
          'Team Selector',
        ),
      ),
      body: Column(
        children: [
          getSettings(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.red,
                ),
              ),
              child: Center(child: Text('coming soon!')),
            ),
          ),
        ],
      ),
    );
  }
}
