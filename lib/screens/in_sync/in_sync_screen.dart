import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:together/components/buttons.dart';
import 'package:together/services/services.dart';
import 'package:together/services/firestore.dart';
import 'package:together/help_screens/help_screens.dart';
import 'package:together/components/end_game.dart';
import 'package:together/components/scroll_view.dart';

import 'in_sync_services.dart';

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
  Timer _timer;
  TextEditingController messageController;
  DateTime _now;
  var T;
  final _controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  int activeController;

  @override
  void initState() {
    super.initState();
    messageController = TextEditingController();
    T = Transactor(sessionId: widget.sessionId);
    setUpGame();
    _timer = Timer.periodic(Duration(milliseconds: 200), (Timer t) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    _controllers.forEach((v) {
      v.dispose();
    });
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

  String intToString(int i, {int pad: 0}) {
    var str = i.toString();
    var paddingToAdd = pad - str.length;
    return (paddingToAdd > 0)
        ? "${new List.filled(paddingToAdd, '0').join('')}$i"
        : str;
  }

  getMinutesSeconds(int seconds) {
    var m = seconds ~/ 60;
    var s = seconds - m * 60;
    return [m, s];
  }

  getStatus(data) {
    var title = 'Easy 1';
    var ms = [0, 0];
    if (data['expirationTime'] != null && _now != null) {
      ms = getMinutesSeconds(
          -_now.difference(data['expirationTime'].toDate()).inSeconds);
    }
    var subtitle = data['expirationTime'] == null
        ? 'Awaiting players'
        : '${intToString(ms[0], pad: 2)}:${intToString(ms[1], pad: 2)}';
    return Container(
      width: 200,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).highlightColor),
        borderRadius: BorderRadius.circular(15),
        color: Theme.of(context).dialogBackgroundColor,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
            ),
          ),
          Text(subtitle,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              )),
        ],
      ),
    );
  }

  getTimerBar(data) {
    var width = MediaQuery.of(context).size.width;
    var remainingPercentage =
        -_now.difference(data['expirationTime'].toDate()).inSeconds /
            data['rules']['roundTimeLimit'];
    // print(remainingPercentage);
    return Stack(children: [
      Container(
        height: 5,
        width: width,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).highlightColor),
        ),
      ),
      remainingPercentage > 0
          ? Positioned(
              left: 0,
              child: Container(
                height: 5,
                width: remainingPercentage * width,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                  color: Colors.blue,
                ),
              ),
            )
          : Container(),
    ]);
  }

  playerReady(data) async {
    data['ready'][widget.userId] = true;

    // if all players are ready, start the timer
    data['expirationTime'] =
        DateTime.now().add(Duration(seconds: data['rules']['roundTimeLimit']));
    T.transact(data);
  }

  getPrepare(data) {
    // check if player is ready, show who is ready
    List<Widget> playerStatuses = [];
    data['playerIds'].forEach((v) {
      playerStatuses.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(data['playerNames'][v]),
            SizedBox(width: 5),
            data['ready'][v]
                ? Icon(MdiIcons.checkBoxOutline, color: Colors.green)
                : Icon(MdiIcons.checkboxBlank, color: Colors.grey),
          ],
        ),
      );
    });
    return Center(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).highlightColor),
          borderRadius: BorderRadius.circular(15),
          color: Theme.of(context).dialogBackgroundColor,
        ),
        padding: EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).highlightColor),
                borderRadius: BorderRadius.circular(15),
              ),
              padding: EdgeInsets.all(5),
              child: Column(
                children: playerStatuses,
              ),
            ),
            SizedBox(height: 15),
            RaisedGradientButton(
              height: 60,
              width: 190,
              child: Text('Ready!', style: TextStyle(fontSize: 35)),
              gradient: LinearGradient(
                colors: !data['ready'][widget.userId]
                    ? [
                        Colors.blue,
                        Colors.blueAccent,
                      ]
                    : [
                        Colors.grey,
                        Colors.grey,
                      ],
              ),
              onPressed: !data['ready'][widget.userId]
                  ? () {
                      playerReady(data);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  getSubmit(data) {
    List<Widget> textInputForms = [];
    // String word = '';
    // data['teams'].forEach((v) {
    //   if (v['players'].contains(widget.userId)) {
    //     word = v['words'][data['level']];
    //   }
    // });
    for (int i = 0; i < 10; i++) {
      textInputForms.add(
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).highlightColor),
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextField(
            onTap: () {
              activeController = i;
            },
            style: TextStyle(fontSize: 18),
            controller: _controllers[i],
            textAlign: TextAlign.center,
            maxLines: null,
            decoration: InputDecoration(
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              hintText: '$i...',
              isDense: true,
            ),
          ),
        ),
      );
      textInputForms.add(SizedBox(height: 5));
    }
    var height = MediaQuery.of(context).size.height;
    return Container(
      height: 0.5 * height,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).highlightColor),
        borderRadius: BorderRadius.circular(15),
        color: Theme.of(context).dialogBackgroundColor,
      ),
      padding: EdgeInsets.all(15),
      child: TogetherScrollView(
        child: Column(
          children: textInputForms,
        ),
      ),
    );
  }

  getGameboard(data) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              getStatus(data),
              SizedBox(height: 20),
              getTimerBar(data),
              SizedBox(height: 10),
              !allPlayersAreReady(data) ? getPrepare(data) : getSubmit(data),
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
          ),
        ),
        activeController != null
            ? Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: Theme.of(context).dialogBackgroundColor.withAlpha(230),
                ),
                padding: EdgeInsets.all(15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 30),
                    AutoSizeText(
                      _controllers[activeController].text,
                      maxLines: 1,
                      style: TextStyle(fontSize: 28),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    RaisedGradientButton(
                        child: Text('Done', style: TextStyle(fontSize: 24)),
                        height: 50,
                        width: 150,
                        onPressed: () {
                          activeController = null;
                          FocusScope.of(context).unfocus();
                        },
                        gradient: LinearGradient(colors: [
                          Colors.blue.withAlpha(100),
                          Colors.blue[100].withAlpha(100)
                        ])),
                  ],
                ),
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
