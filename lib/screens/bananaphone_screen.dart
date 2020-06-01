import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:together/components/buttons.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui';

import 'package:together/models/models.dart';
import 'package:together/components/dialogs.dart';
import 'package:together/services/services.dart';
import 'template/help_screen.dart';
import 'lobby_screen.dart';

class BananaphoneScreen extends StatefulWidget {
  BananaphoneScreen({this.sessionId, this.userId, this.roomCode});

  final String sessionId;
  final String userId;
  final String roomCode;

  @override
  _BananaphoneScreenState createState() => _BananaphoneScreenState();
}

class _BananaphoneScreenState extends State<BananaphoneScreen> {
  bool isLoading = true;
  final pointsList = <DrawingPoints>[];

  checkIfExit(data) async {
    // run async func to check if game is over, or back to lobby or deleted (main menu)
    if (data == null) {
      print('game was deleted');

      // navigate to main menu
      Navigator.of(context).pop();
    } else if (data['state'] == 'lobby') {
      print('moving to lobby');
      // reset first team to green
      await Firestore.instance
          .collection('sessions')
          .document(widget.sessionId)
          .updateData({'turn': 'green'});

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

  updatePhase(data) async {
    var currPhase = data['phase'];
    var nextPhase = '';
    if (currPhase == 'draw1') {
      nextPhase = 'describe1';
    } else if (currPhase == 'describe1') {
      nextPhase = 'draw2';
    } else if (currPhase == 'draw2') {
      nextPhase = 'describe2';
    } else {
      nextPhase = 'vote';
    }
    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .updateData({'phase': nextPhase});
  }

  Widget getStatusOverview(data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 200,
          padding: EdgeInsets.fromLTRB(30, 5, 30, 5),
          decoration: BoxDecoration(
              border: Border.all(), borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Round ${data['round'] + 1}',
                    style: TextStyle(fontSize: 20),
                  ),
                  Text(
                    '  of ${data['rules']['numRounds']}',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Draw',
                      style: data['phase'] == 'draw1'
                          ? TextStyle(
                              fontSize: 18,
                              color: Theme.of(context).primaryColor)
                          : TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(' > ',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('Describe',
                      style: data['phase'] == 'describe1'
                          ? TextStyle(
                              fontSize: 18,
                              color: Theme.of(context).primaryColor)
                          : TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(' > ',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: <
                  Widget>[
                Text('Draw',
                    style: data['phase'] == 'draw2'
                        ? TextStyle(
                            fontSize: 18, color: Theme.of(context).primaryColor)
                        : TextStyle(fontSize: 12, color: Colors.grey)),
                Text(' > ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text('Describe',
                    style: data['phase'] == 'describe2'
                        ? TextStyle(
                            fontSize: 18, color: Theme.of(context).primaryColor)
                        : TextStyle(fontSize: 12, color: Colors.grey)),
                Text(' > ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text('Vote',
                    style: data['phase'] == 'vote'
                        ? TextStyle(
                            fontSize: 18, color: Theme.of(context).primaryColor)
                        : TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ],
          ),
        ),
        SizedBox(width: 10),
        getRoomCode(),
      ],
    );
  }

  Widget getStatus(data) {
    // gets phase status, and prompt or picture
    List<Widget> columnItems = [];

    columnItems.add(getStatusOverview(data));
    columnItems.add(SizedBox(height: 10));

    // get index of player in order, pull prompt (or image)
    int playerIndex = data['playerIds'].indexOf(widget.userId);
    var phase = data['phase'];
    if (phase == 'draw1' || phase == 'draw2') {
      columnItems.add(Container(
        constraints: BoxConstraints(maxWidth: 250),
        padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
        decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: <Widget>[
            Text('Draw this prompt:',
                style: TextStyle(fontSize: 14), textAlign: TextAlign.center),
            SizedBox(height: 5),
            Text(
                data['rules']['prompts'][data['round']]['prompts'][playerIndex],
                style: TextStyle(
                    fontSize: 18, color: Theme.of(context).primaryColor),
                textAlign: TextAlign.center),
          ],
        ),
      ));
    } else if (phase == 'describe1' || phase == 'describe') {
      columnItems.add(Text('Describe this picture!'));
    } else {
      columnItems.add(Text('Which was best?'));
    }

    return Column(children: columnItems);
  }

  Widget getDrawableArea(BuildContext context) {
    return Container(
      child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              RenderBox renderBox = context.findRenderObject();
              var pointsToAdd = details.globalPosition;
              pointsToAdd.translate(0, -400);
              pointsList.add(DrawingPoints(
                  points: renderBox.globalToLocal(details.globalPosition),
                  paint: Paint()
                    ..strokeCap = StrokeCap.butt
                    ..isAntiAlias = true
                    ..color = Colors.red.withOpacity(0.4)
                    ..strokeWidth = 5));
            });
          },
          onPanEnd: (details) {
            setState(() {
              pointsList.add(null);
            });
          },
          child: CustomPaint(
            size: Size(300, 300),
            painter: DrawingPainter(
              pointsList: pointsList,
            ),
            child: Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(border: Border.all()),
            ),
          )),
    );
  }

  Widget getRoomCode() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
      child: Column(
        children: <Widget>[
          Text(
            'Room Code:',
            style: TextStyle(
              fontSize: 12,
            ),
          ),
          Text(
            widget.roomCode,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget getUserAction(data) {
    if (data['phase'] == 'draw1' || data['phase'] == 'draw2') {
      return Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 5),
        decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: <Widget>[
            getDrawableArea(context),
            SizedBox(height: 10),
            RaisedGradientButton(
              height: 36,
              width: 90,
              child: Text('Submit'),
              gradient: LinearGradient(
                colors: <Color>[
                  Color.fromARGB(255, 255, 185, 0),
                  Color.fromARGB(255, 255, 213, 0),
                ],
              ),
              onPressed: () {
                print('yo');
              },
            ),
            SizedBox(height: 5),
          ],
        ),
      );
    } else if (data['phase'] == 'describe1' || data['phase'] == 'describe2') {
      return Text('textfield here');
    } else {
      return Text('voting mechanism here');
    }
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
                    'Bananaphone',
                  ),
                ),
                body: Container());
          }
          // all data for all components
          DocumentSnapshot data = snapshot.data;
          checkIfExit(data);
          return Scaffold(
              appBar: AppBar(
                title: Text(
                  'Bananaphone',
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
                            return BananaphoneScreenHelp();
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: 5),
                    getStatus(data),
                    SizedBox(height: 20),
                    getUserAction(data),
                    SizedBox(height: 30),
                    widget.userId == data['leader']
                        ? RaisedGradientButton(
                            child: Text(
                              'End game',
                              style: TextStyle(fontSize: 16),
                            ),
                            onPressed: () {
                              showDialog<Null>(
                                context: context,
                                builder: (BuildContext context) {
                                  return EndGameDialog(
                                    game: 'Banana Phone',
                                    sessionId: widget.sessionId,
                                    winnerAlreadyDecided: true,
                                  );
                                },
                              );
                            },
                            height: 40,
                            width: 140,
                            gradient: LinearGradient(
                              colors: <Color>[
                                Color.fromARGB(255, 255, 185, 0),
                                Color.fromARGB(255, 255, 213, 0),
                              ],
                            ),
                          )
                        : Container(),
                  ],
                ),
              ));
        });
  }
}

class BananaphoneScreenHelp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HelpScreen(
      title: 'Bananaphone: Rules',
      information: ['    rules here'],
      buttonColor: Theme.of(context).primaryColor,
    );
  }
}

class DrawingPainter extends CustomPainter {
  DrawingPainter({this.pointsList});
  List<DrawingPoints> pointsList;
  List<Offset> offsetPoints = List();
  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < pointsList.length - 1; i++) {
      if (pointsList[i] != null && pointsList[i + 1] != null) {
        canvas.drawLine(pointsList[i].points, pointsList[i + 1].points,
            pointsList[i].paint);
      } else if (pointsList[i] != null && pointsList[i + 1] == null) {
        offsetPoints.clear();
        offsetPoints.add(pointsList[i].points);
        offsetPoints.add(Offset(
            pointsList[i].points.dx + 0.1, pointsList[i].points.dy));
        canvas.drawPoints(PointMode.points, offsetPoints, pointsList[i].paint);
      }
    }
  }
  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => oldDelegate.pointsList!=pointsList;
}