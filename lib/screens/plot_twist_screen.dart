import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import 'package:together/services/services.dart';
import 'package:together/help_screens/help_screens.dart';
import 'lobby_screen.dart';
import 'package:together/components/end_game.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../services/plot_twist_services.dart';

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
    if (data['narrators'].contains(player)) {
      return Colors.grey[900];
    }
    var colorString = data['playerColors'][player];
    switch (colorString) {
      case 'green':
        return Colors.green.withAlpha(180);
        break;
      case 'blue':
        return Colors.blue.withAlpha(180);
        break;
      case 'purple':
        return Colors.purple.withAlpha(180);
        break;
      case 'orange':
        return Colors.orange.withAlpha(180);
        break;
      case 'lime':
        return Colors.lime.withAlpha(180);
        break;
      case 'pink':
        return Colors.pink.withAlpha(180);
        break;
      case 'red':
        return Colors.red.withAlpha(180);
        break;
      case 'brown':
        return Colors.brown.withAlpha(180);
        break;
      case 'cyan':
        return Colors.cyan.withAlpha(180);
        break;
      case 'teal':
        return Colors.teal.withAlpha(180);
        break;
    }
    return Colors.green[700];
  }

  getChatBoxes(data) {
    List<Widget> chatboxes = [];
    String lastPlayer = 'narrator';
    data['texts'].reversed.forEach((v) {
      String alignment = 'left';
      bool isRepeated = lastPlayer == v['playerId'];
      bool isNarrator = false;
      if (data['narrators'].contains(v['playerId'])) {
        alignment = 'center';
        isNarrator = true;
      } else if (widget.userId == v['playerId']) {
        alignment = 'right';
      }
      chatboxes.add(
        Chatbox(
          text: v['text'],
          timestamp: v['timestamp'].toString(),
          person: data['playerNames'][v['playerId']],
          alignment: alignment,
          backgroundColor: getPlayerColor(v['playerId'], data),
          fontColor: Colors.white,
          suppressName: isRepeated,
          isNarrator: isNarrator,
        ),
      );
      lastPlayer = v['playerId'];
    });
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey,
        ),
      ),
      padding: EdgeInsets.all(10),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: chatboxes,
        ),
      ),
    );
  }

  sendMessage(data) async {
    // TODO: add some kind of retry logic for clashes

    if (_controller.text == '') {
      return;
    }

    var message = {
      'playerId': widget.userId,
      'text': _controller.text,
      'timestamp': DateTime.now(),
    };

    data['texts'].add(message);

    _controller.text = '';

    FocusScope.of(context).unfocus();

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);

    HapticFeedback.vibrate();
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
          getInputBox(data),
          SizedBox(height: 10),
          Container(
            width: screenWidth * 0.8,
            height: screenHeight * 0.55,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).highlightColor,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: getChatBoxes(data),
          ),
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
            resizeToAvoidBottomInset: false,
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
  final bool isNarrator;

  Chatbox({
    this.text,
    this.person,
    this.timestamp,
    this.alignment,
    this.backgroundColor,
    this.fontColor,
    this.suppressName = false,
    this.isNarrator = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Column(
        children: [
          isNarrator ? SizedBox(height: 10) : Container(),
          isNarrator
              ? Text(
                  'Narrator',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                )
              : Container(),
          isNarrator ? SizedBox(height: 5) : Container(),
          suppressName || isNarrator
              ? Container()
              : Row(
                  children: [
                    ['center', 'right'].contains(alignment)
                        ? Spacer()
                        : Container(),
                    Text(
                      '$person',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withAlpha(200),
                      ),
                    ),
                    ['center', 'left'].contains(alignment)
                        ? Spacer()
                        : Container(),
                  ],
                ),
          suppressName || isNarrator ? Container() : SizedBox(height: 2),
          Row(
            children: [
              ['center', 'right'].contains(alignment) ? Spacer() : Container(),
              Container(
                padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                constraints: BoxConstraints(maxWidth: 200),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(5),
                  color: backgroundColor,
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: fontColor,
                    fontSize: 12,
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
