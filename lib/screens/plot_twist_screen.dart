import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import 'package:together/services/services.dart';
import 'package:together/help_screens/help_screens.dart';
import 'lobby_screen.dart';
import 'package:together/components/end_game.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class PlotTwistScreen extends StatefulWidget {
  PlotTwistScreen({this.sessionId, this.userId, this.roomCode});

  final String sessionId;
  final String userId;
  final String roomCode;

  @override
  _PlotTwistScreenState createState() => _PlotTwistScreenState();
}

class _PlotTwistScreenState extends State<PlotTwistScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool isSpectator = false;
  TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    setUpGame();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  checkIfExit(data) async {
    // run async func to check if game is over, or back to lobby or deleted (main menu)
    if (data == null) {
      // navigate to main menu
      Navigator.of(context).pop();
    } else if (data['state'] == 'lobby') {
      // I DON'T KNOW WHY WE NEED THIS BUT OTHERWISE WE GET DEBUG LOCKED ISSUES
      await Firestore.instance
          .collection('sessions')
          .document(widget.sessionId)
          .setData(data);
      // navigate to lobby
      Navigator.of(context).pop();
      slideTransition(
        context,
        LobbyScreen(
          roomCode: widget.roomCode,
        ),
      );
    }
  }

  checkIfVibrate(data) {}

  setUpGame() async {
    // get session info for locations
    var data = (await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .get())
        .data;
    setState(() {
      isSpectator = data['spectatorIds'].contains(widget.userId);
    });
  }

  getPlayerColor(player, data) {
    return Colors.green;
  }

  getChatBoxes(data) {
    List<Widget> chatboxes = [];
    data['texts'].forEach((v) {
      String alignment = 'left';
      bool isNarrator = false;
      if (isNarrator) {
        // is narrator
        alignment = 'center';
      }
      if (true) {
        // is self
        alignment = 'right';
      }
      chatboxes.add(
        Chatbox(
          text: v['text'],
          timestamp: v['timestamp'].toString(),
          person: v['playerId'],
          alignment: alignment,
          backgroundColor: getPlayerColor(v['playerId'], data),
          fontColor: Colors.white,
          suppressName: isNarrator,
        ),
      );
    });
    chatboxes.add(Chatbox(
      text: 'This is me',
      person: 'Matt',
      timestamp: '10:14:30',
      alignment: 'right',
      backgroundColor: Colors.green,
      fontColor: Colors.white,
    ));
    chatboxes.add(Chatbox(
      text: 'Definitely a stranger',
      person: 'John',
      timestamp: '10:13:12',
      alignment: 'left',
      backgroundColor: Colors.blue,
      fontColor: Colors.white,
    ));
    chatboxes.add(Chatbox(
      text: 'This is a stranger',
      person: 'John',
      timestamp: '10:13:12',
      alignment: 'left',
      backgroundColor: Colors.blue,
      fontColor: Colors.white,
      suppressName: true,
    ));
    chatboxes.add(Chatbox(
      text: 'This is another stranger',
      person: 'Lex',
      timestamp: '10:11:41',
      alignment: 'left',
      backgroundColor: Colors.purple,
      fontColor: Colors.white,
    ));
    chatboxes.add(Chatbox(
      text: 'This is the narrator',
      person: 'narrator',
      timestamp: '10:11:58',
      alignment: 'center',
      backgroundColor: Colors.grey,
      fontColor: Colors.white,
      suppressName: true,
    ));
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: chatboxes,
      ),
    );
  }

  sendMessage(data) async {
    // TODO: add some kind of retry logic for clashes

    print('will send ${_controller.text}');
    var message = {
      'playerId': widget.userId,
      'text': _controller.text,
      'timestamp': 
    };
  }

  getInputBox(data) {
    var screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth * 0.8,
      height: 90,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).highlightColor,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            height: 70,
            width: screenWidth * 0.8 - 20 - 50 - 15,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.grey,
              ),
            ),
            padding: EdgeInsets.fromLTRB(10, 2, 10, 2),
            child: TextField(
              maxLines: null,
              decoration: InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintText: 'type here',
              ),
              controller: _controller,
            ),
          ),
          SizedBox(width: 10),
          GestureDetector(
            child: Container(
              width: 50,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(colors: [
                  Colors.blue[800],
                  Colors.lightBlue,
                ]),
                border: Border.all(
                  color: Theme.of(context).highlightColor,
                ),
              ),
              child: Center(
                child: Icon(
                  MdiIcons.send,
                  size: 30,
                ),
              ),
            ),
            onTap: () {
              sendMessage(data);
            },
          ),
        ],
      ),
    );
  }

  getGameboard(data) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            data['rules']['location'],
            style: TextStyle(
              fontSize: 30,
            ),
          ),
          SizedBox(height: 10),
          Container(
            width: screenWidth * 0.8,
            height: screenHeight * 0.55,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).highlightColor,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: getChatBoxes(data),
          ),
          SizedBox(height: 10),
          getInputBox(data),
          SizedBox(height: 20),
          widget.userId == data['leader']
              ? EndGameButton(
                  sessionId: widget.sessionId,
                  fontSize: 14,
                  height: 30,
                  width: 100,
                )
              : Text(
                  '(Glorious leader can take you back to the lobby)',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
        ],
      ),
    );
  }

  getScoreboard(data) {
    return Text('Scoreboard');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  'Plot Twist',
                ),
              ),
              body: Container(),
            );
          }
          // all data for all components
          DocumentSnapshot snapshotData = snapshot.data;
          var data = snapshotData.data;
          if (data == null) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  'Plot Twist',
                ),
              ),
              body: Container(),
            );
          }
          checkIfExit(data);
          checkIfVibrate(data);
          return Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: Text(
                'Plot Twist',
              ),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.info),
                  onPressed: () {
                    // HapticFeedback.heavyImpact();
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (BuildContext context, _, __) {
                          return PlotTwistScreenHelp();
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
            body: data['state'] == 'started'
                ? getGameboard(data)
                : getScoreboard(data),
          );
        });
  }
}

class Chatbox extends StatelessWidget {
  final String text;
  final String person;
  final String timestamp;
  final String alignment;
  final Color backgroundColor;
  final Color fontColor;
  final bool suppressName;

  Chatbox({
    this.text,
    this.person,
    this.timestamp,
    this.alignment,
    this.backgroundColor,
    this.fontColor,
    this.suppressName = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Column(
        children: [
          suppressName
              ? Container()
              : Row(
                  children: [
                    ['center', 'right'].contains(alignment)
                        ? Spacer()
                        : Container(),
                    Text(
                      '$person',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withAlpha(200),
                      ),
                    ),
                    ['center', 'left'].contains(alignment)
                        ? Spacer()
                        : Container(),
                  ],
                ),
          suppressName ? Container() : SizedBox(height: 2),
          Row(
            children: [
              ['center', 'right'].contains(alignment) ? Spacer() : Container(),
              Container(
                padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(5),
                  color: backgroundColor,
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: fontColor,
                    fontSize: 16,
                  ),
                ),
              ),
              ['center', 'left'].contains(alignment) ? Spacer() : Container(),
            ],
          ),
        ],
      ),
    );
  }
}
