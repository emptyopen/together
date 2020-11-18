import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import 'package:together/services/services.dart';
import 'package:together/services/firestore.dart';
import 'package:together/help_screens/help_screens.dart';
import 'package:together/components/end_game.dart';

class InSyncScreen extends StatefulWidget {
  InSyncScreen({this.sessionId, this.userId, this.roomCode});

  final String sessionId;
  final String userId;
  final String roomCode;

  @override
  _InSyncScreenState createState() => _InSyncScreenState();
}

class _InSyncScreenState extends State<InSyncScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool isSpectator = false;
  TextEditingController messageController;
  // vibrate states
  var T;

  @override
  void initState() {
    super.initState();
    messageController = TextEditingController();
    T = Transactor(sessionId: widget.sessionId);
    setUpGame();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  checkIfVibrate(data) {
    bool isNewVibrateData = false;

    if (isNewVibrateData) {
      HapticFeedback.vibrate();
    }
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

  getGameboard(data) {
    return Column(
      children: [
        Text('in sync'),
        SizedBox(height: 20),
        widget.userId == data['leader']
            ? EndGameButton(
                sessionId: widget.sessionId,
                fontSize: 14,
                height: 30,
                width: 100,
              )
            : Container(),
      ],
    );
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
                'In Sync',
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
                'In Sync',
              ),
            ),
            body: Container(),
          );
        }
        checkIfExit(data, context, widget.sessionId, widget.roomCode);
        checkIfVibrate(data);
        return Scaffold(
            key: _scaffoldKey,
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              title: Text(
                'In Sync',
              ),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.info),
                  onPressed: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (BuildContext context, _, __) {
                          return InSyncScreenHelp();
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
            body: getGameboard(data));
      },
    );
  }
}
