import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:async';
import 'package:string_similarity/string_similarity.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flushbar/flushbar.dart';

import 'package:together/components/misc.dart';
import 'package:together/components/buttons.dart';
import 'package:together/components/scroll_view.dart';
import 'package:together/services/services.dart';
import 'package:together/services/firestore.dart';
import 'package:together/help_screens/help_screens.dart';
import 'package:together/components/end_game.dart';
import 'package:together/constants/values.dart';

import 'in_the_club_services.dart';

class InTheClubScreen extends StatefulWidget {
  InTheClubScreen({this.sessionId, this.userId, this.roomCode});

  final String sessionId;
  final String userId;
  final String roomCode;

  @override
  _InTheClubScreenState createState() => _InTheClubScreenState();
}

class _InTheClubScreenState extends State<InTheClubScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool isSpectator = false;
  var T;

  @override
  void initState() {
    super.initState();
    T = Transactor(sessionId: widget.sessionId);
    setUpGame();
  }

  setUpGame() async {
    // get session info for locations
    var data = (await FirebaseFirestore.instance
            .collection('sessions')
            .doc(widget.sessionId)
            .get())
        .data();
    setState(() {
      isSpectator = data['spectatorIds'].contains(widget.userId);
    });
  }

  getRoomCode(data) {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: Theme.of(context).highlightColor,
          ),
          color: Theme.of(context).dialogBackgroundColor,
        ),
        padding: EdgeInsets.all(5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Room code:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              widget.roomCode,
              style: TextStyle(
                fontSize: 22,
              ),
            ),
          ],
        ));
  }

  playerReady(data) async {
    data['ready${widget.userId}'] = true;

    data = await T.transactInTheClubReady(widget.userId);

    // if all players are ready, start the timer
    bool allReady = true;
    data['playerIds'].forEach((v) {
      if (!data['ready$v']) {
        allReady = false;
      }
    });
    if (allReady) {
      // clear previous results
      data['teams'].asMap().forEach((i, v) {
        data['teams'][i]['results'] = [];
      });
      data['expirationTime'] = DateTime.now()
          .add(Duration(seconds: data['rules']['roundTimeLimit']));
    }
    T.transact(data);
  }

  getScoreboard(data) {
    return TogetherScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 30),
            Text('scoreboard'),
            widget.userId == data['leader']
                ? EndGameButton(
                    sessionId: widget.sessionId,
                    fontSize: 14,
                    height: 30,
                    width: 100,
                  )
                : Container(),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  getGameboard(data) {
    return Text('gameboard');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'In The Club',
              ),
            ),
            body: Container(),
          );
        }
        // all data for all components
        DocumentSnapshot snapshotData = snapshot.data;
        var data = snapshotData.data();
        if (data == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'In The Club',
              ),
            ),
            body: Container(),
          );
        }
        checkIfExit(data, context, widget.sessionId, widget.roomCode);
        return Scaffold(
            key: _scaffoldKey,
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              title: Text(
                'In The Club',
              ),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.info),
                  onPressed: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (BuildContext context, _, __) {
                          return InTheClubScreenHelp();
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
            body: data['state'] == 'scoreboard'
                ? getScoreboard(data)
                : getGameboard(data));
      },
    );
  }
}
