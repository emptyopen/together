import 'package:flutter/material.dart';

class TeamSelectorScreen extends StatefulWidget {
  TeamSelectorScreen({this.userId});

  final String userId;

  @override
  _TeamSelectorScreenState createState() => _TeamSelectorScreenState();
}

class _TeamSelectorScreenState extends State<TeamSelectorScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan[700],
        title: Text(
          'Team Selector',
        ),
      ),
      body: Container(),
    );
  }
}
