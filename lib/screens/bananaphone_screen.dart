import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:together/components/buttons.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:collection';

import 'package:together/models/models.dart';
import 'package:together/components/misc.dart';
import 'package:together/services/services.dart';
import 'package:together/help_screens/help_screens.dart';
import 'lobby_screen.dart';
import 'package:together/components/end_game.dart';

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
  List<DrawingPoint> pointsList = <DrawingPoint>[];
  List<int> linesList = [];
  Color strokeColor = Colors.black;
  double strokeWidth = 5;
  GlobalKey _key = GlobalKey();
  final descriptionController = TextEditingController();
  var votes = {};
  String currPhase = 'draw1';
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool isSpectator = false;

  @override
  void initState() {
    super.initState();
    setUpGame();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

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
          .setData(data.data);
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

  checkIfNewPhase(data) {
    if (currPhase != data['phase']) {
      HapticFeedback.vibrate();
      currPhase = data['phase'];
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
    } else if (currPhase == 'describe2') {
      print(
          '$currPhase | ${data['rules']['numDrawDescribe']} ${data['rules']['numDrawDescribe'] == 2}');
      if (data['rules']['numDrawDescribe'] == 2) {
        nextPhase = 'vote';
      } else {
        nextPhase = 'draw3';
      }
    } else if (currPhase == 'draw3') {
      nextPhase = 'describe3';
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
          width: 220,
          padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).highlightColor,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
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
                data['rules']['numDrawDescribe'] == 2
                    ? Text('Vote',
                        style: data['phase'] == 'vote'
                            ? TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).primaryColor)
                            : TextStyle(fontSize: 12, color: Colors.grey))
                    : Container(),
              ]),
              data['rules']['numDrawDescribe'] == 2
                  ? Container()
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: <
                      Widget>[
                      Text('Draw',
                          style: data['phase'] == 'draw3'
                              ? TextStyle(
                                  fontSize: 18,
                                  color: Theme.of(context).primaryColor)
                              : TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(' > ',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('Describe',
                          style: data['phase'] == 'describe3'
                              ? TextStyle(
                                  fontSize: 18,
                                  color: Theme.of(context).primaryColor)
                              : TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(' > ',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('Vote',
                          style: data['phase'] == 'vote'
                              ? TextStyle(
                                  fontSize: 18,
                                  color: Theme.of(context).primaryColor)
                              : TextStyle(fontSize: 12, color: Colors.grey)),
                    ]),
            ],
          ),
        ),
        SizedBox(width: 10),
        Column(
          children: <Widget>[
            getRoomCode(),
            SizedBox(height: 5),
            widget.userId == data['leader']
                ? EndGameButton(
                    gameName: 'Bananaphone',
                    sessionId: widget.sessionId,
                    fontSize: 14,
                    height: 30,
                    width: 100,
                  )
                : Container(),
          ],
        ),
      ],
    );
  }

  Widget getStatus(data) {
    // gets phase status, and prompt or picture
    List<Widget> columnItems = [];

    columnItems.add(getStatusOverview(data));
    columnItems.add(SizedBox(height: 10));

    // get index of player in order, pull prompt (or image)
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    var phase = data['phase'];
    if (phase == 'draw1' || phase == 'draw2' || phase == 'draw3') {
      if (isSpectator) {
        // do nothing
      } else {
        var promptIndex = getPromptIndex(data);
        var prompt =
            data['rules']['prompts'][data['round']]['prompts'][playerIndex];
        if (phase == 'draw2') {
          prompt = data['describe1Prompt$promptIndex'];
        }
        if (phase == 'draw3') {
          prompt = data['describe2Prompt$promptIndex'];
        }
        columnItems.add(Container(
          constraints: BoxConstraints(maxWidth: 250),
          padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).highlightColor,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: <Widget>[
              Text('Draw this prompt:',
                  style: TextStyle(fontSize: 14), textAlign: TextAlign.center),
              SizedBox(height: 5),
              Text(prompt,
                  style: TextStyle(
                      fontSize: 18, color: Theme.of(context).primaryColor),
                  textAlign: TextAlign.center),
            ],
          ),
        ));
      }
    } else if (phase == 'describe1' ||
        phase == 'describe2' ||
        phase == 'describe3') {
      if (isSpectator) {
        // do nothing
      } else {
        columnItems.add(Container(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).highlightColor,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Describe this picture!',
              style: TextStyle(fontSize: 20),
            )));
      }
    } else {
      columnItems.add(
        Container(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).highlightColor,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: <Widget>[
              Text(
                'Vote for your favorites!',
                style: TextStyle(
                    fontSize: 18, color: Theme.of(context).primaryColor),
              ),
              Text(
                'One choice per column (round).',
                style: TextStyle(
                    fontSize: 14, color: Theme.of(context).primaryColor),
              ),
              Text(
                'Long press to select your favorite!',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                'Scroll right for progression,',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                'scroll down to see all prompts.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(children: columnItems);
  }

  Widget getDrawableArea(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white),
      child: Center(
        child: GestureDetector(
            onPanStart: (details) {
              setState(() {
                RenderBox getBox = _key.currentContext.findRenderObject();
                var local = getBox.globalToLocal(details.globalPosition);
                pointsList.add(DrawingPoint(
                    point: local,
                    paint: Paint()
                      ..strokeCap = StrokeCap.round
                      ..isAntiAlias = true
                      ..color = strokeColor
                      ..strokeWidth = strokeWidth));
                linesList.add(1);
              });
            },
            onPanUpdate: (details) {
              setState(() {
                RenderBox getBox = _key.currentContext.findRenderObject();
                var local = getBox.globalToLocal(details.globalPosition);
                if (local.dx > 2 &&
                    local.dy > 2 &&
                    local.dx < 298 &&
                    local.dy < 298) {
                  linesList.add(0);
                  pointsList.add(DrawingPoint(
                      point: local,
                      paint: Paint()
                        ..strokeJoin = StrokeJoin.bevel
                        ..strokeCap = StrokeCap.round
                        ..isAntiAlias = true
                        ..color = strokeColor
                        ..strokeWidth = strokeWidth));
                }
              });
            },
            onPanEnd: (details) {
              setState(() {
                pointsList.add(null);
                linesList.add(0);
              });
            },
            child: CustomPaint(
              key: _key,
              size: Size(300, 300),
              painter: DrawingPainter(
                pointsList: pointsList,
              ),
              child: Container(
                height: 300,
                width: 300,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).highlightColor,
                  ),
                ),
              ),
            )),
      ),
    );
  }

  Widget getRoomCode() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).highlightColor),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
      child: Column(
        children: <Widget>[
          Text(
            'Room Code:',
            style: TextStyle(
              fontSize: 11,
            ),
          ),
          Text(
            widget.roomCode,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  listPointsToJson(List<DrawingPoint> list) {
    var arr = [];
    for (var point in list) {
      if (point == null) {
        arr.add({'isNull': true});
      } else {
        arr.add({
          'x': point.point.dx,
          'y': point.point.dy,
          'width': point.paint.strokeWidth,
          'color': point.paint.color.toString()
        });
      }
    }
    return arr;
  }

  submitDrawing(data) async {
    // send pointsList to Firestore sessions collection
    var promptIndex = getPromptIndex(data);
    var jsonPointsList = listPointsToJson(pointsList); // to string
    var stringPointsList = jsonEncode(jsonPointsList);

    if (data['phase'] == 'draw1') {
      data['draw1Prompt$promptIndex'] = stringPointsList;
    } else if (data['phase'] == 'draw2') {
      data['draw2Prompt$promptIndex'] = stringPointsList;
    } else {
      // it's draw3
      data['draw3Prompt$promptIndex'] = stringPointsList;
    }

    // for every player, after submitting check if all drawings are done
    if (data['phase'] == 'draw1') {
      bool allPlayersHaveDrawn = true;
      data['playerIds'].asMap().forEach((i, _) {
        if (!data.containsKey('draw1Prompt$i')) {
          allPlayersHaveDrawn = false;
        }
      });
      if (allPlayersHaveDrawn) {
        data['phase'] = 'describe1';
      }
    } else if (data['phase'] == 'draw2') {
      bool allPlayersHaveDrawn = true;
      data['playerIds'].asMap().forEach((i, _) {
        if (!data.containsKey('draw2Prompt$i')) {
          allPlayersHaveDrawn = false;
        }
      });
      if (allPlayersHaveDrawn) {
        data['phase'] = 'describe2';
      }
    } else {
      // draw3
      bool allPlayersHaveDrawn = true;
      data['playerIds'].asMap().forEach((i, _) {
        if (!data.containsKey('draw3Prompt$i')) {
          allPlayersHaveDrawn = false;
        }
      });
      if (allPlayersHaveDrawn) {
        data['phase'] = 'describe3';
      }
    }

    setState(() {
      pointsList.clear();
      // TODO: should probably also reset painting tools?
    });

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  getDrawing(data) {
    // if already submitted, show container just waiting
    var promptIndex = getPromptIndex(data);
    if ((data['phase'] == 'draw1' && data['draw1Prompt$promptIndex'] != null) ||
        (data['phase'] == 'draw2' && data['draw2Prompt$promptIndex'] != null) ||
        (data['phase'] == 'draw3' && data['draw3Prompt$promptIndex'] != null)) {
      return Container(
          decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).highlightColor),
              borderRadius: BorderRadius.circular(20)),
          padding: EdgeInsets.all(30),
          child: Text('Waiting on the slowpokes...'));
    }
    return Container(
      width: 350,
      padding: EdgeInsets.fromLTRB(20, 20, 20, 5),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).highlightColor,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: <Widget>[
          getDrawableArea(context),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedGradientButton(
                height: 40,
                width: 45,
                child: Icon(Icons.delete),
                gradient: LinearGradient(
                  colors: <Color>[
                    Colors.blue,
                    Colors.blueAccent,
                  ],
                ),
                onPressed: () {
                  setState(() {
                    pointsList.clear();
                    linesList.clear();
                  });
                },
              ),
              SizedBox(width: 10),
              RaisedGradientButton(
                height: 40,
                width: 45,
                child: Icon(Icons.undo),
                gradient: LinearGradient(
                  colors: <Color>[
                    Colors.blue,
                    Colors.blueAccent,
                  ],
                ),
                onPressed: () {
                  if (linesList.length > 1) {
                    setState(() {
                      // need to remove ranges of points
                      var i = linesList.length - 1;
                      while (linesList[i] == 0) {
                        i -= 1;
                      }
                      pointsList.removeRange(i, pointsList.length);
                      linesList.removeRange(i, linesList.length);
                    });
                  }
                },
              ),
              SizedBox(width: 10),
              RaisedGradientButton(
                height: 40,
                width: 45,
                child: DropdownButton<Color>(
                  value: strokeColor,
                  iconSize: 0,
                  style: TextStyle(color: Colors.deepPurple),
                  underline: Container(
                    height: 0,
                  ),
                  onChanged: (Color newValue) {
                    setState(() {
                      strokeColor = newValue;
                    });
                  },
                  items: <Color>[
                    Colors.black,
                    Colors.white,
                    Colors.grey,
                    Colors.red,
                    Colors.blue,
                    Colors.green,
                    Colors.purple,
                    Colors.yellow,
                    Colors.brown,
                    Colors.teal,
                    Colors.cyan,
                    Colors.lime,
                  ].map<DropdownMenuItem<Color>>((Color value) {
                    return DropdownMenuItem<Color>(
                      value: value,
                      child: Container(
                          height: 20,
                          width: 20,
                          decoration: BoxDecoration(
                            color: value,
                            border: Border.all(
                                color: Theme.of(context).highlightColor),
                            borderRadius: BorderRadius.circular(20),
                          )),
                    );
                  }).toList(),
                ),
                gradient: LinearGradient(
                  colors: <Color>[
                    Colors.blue,
                    Colors.blueAccent,
                  ],
                ),
              ),
              SizedBox(width: 10),
              RaisedGradientButton(
                height: 40,
                width: 45,
                child: DropdownButton<double>(
                  value: strokeWidth,
                  iconSize: 0,
                  style: TextStyle(color: Colors.deepPurple),
                  underline: Container(
                    height: 0,
                  ),
                  onChanged: (double newValue) {
                    setState(() {
                      strokeWidth = newValue;
                    });
                  },
                  items: <double>[3, 5, 10, 20]
                      .map<DropdownMenuItem<double>>((double value) {
                    return DropdownMenuItem<double>(
                      value: value,
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(100)),
                          height: value,
                          width: value,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                gradient: LinearGradient(
                  colors: <Color>[
                    Colors.blue,
                    Colors.blueAccent,
                  ],
                ),
              ),
              SizedBox(width: 10),
              RaisedGradientButton(
                height: 40,
                width: 70,
                child: Text(
                  'Submit',
                  style: TextStyle(color: Colors.black),
                ),
                gradient: LinearGradient(
                  colors: <Color>[
                    Color.fromARGB(255, 255, 185, 0),
                    Color.fromARGB(255, 255, 213, 0),
                  ],
                ),
                onPressed: () => submitDrawing(data),
              ),
            ],
          ),
          SizedBox(height: 5),
        ],
      ),
    );
  }

  getPromptIndex(data) {
    // establish prompt index
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    var promptIndex = playerIndex;
    switch (data['phase']) {
      case 'describe1':
        promptIndex += 1;
        break;
      case 'draw2':
        promptIndex += 2;
        break;
      case 'describe2':
        promptIndex += 3;
        break;
      case 'draw3':
        promptIndex += 4;
        break;
      case 'describe3':
        promptIndex += 5;
        break;
    }
    // handle wraparound
    while (promptIndex > data['playerIds'].length - 1) {
      promptIndex = promptIndex - data['playerIds'].length;
    }
    return promptIndex;
  }

  getDescription(data) {
    var promptIndex = getPromptIndex(data);

    // if already submitted, show container just waiting
    if ((data['phase'] == 'describe1' &&
            data['describe1Prompt$promptIndex'] != null) ||
        (data['phase'] == 'describe2' &&
            data['describe2Prompt$promptIndex'] != null) ||
        (data['phase'] == 'describe3' &&
            data['describe3Prompt$promptIndex'] != null)) {
      return Container(
          decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).highlightColor),
              borderRadius: BorderRadius.circular(20)),
          padding: EdgeInsets.all(30),
          child: Text('Waiting on the slowpokes...'));
    }

    // get appropriate drawing
    var jsonPointsList;
    if (data['phase'] == 'describe1') {
      jsonPointsList = jsonDecode(data['draw1Prompt$promptIndex']);
    } else if (data['phase'] == 'describe2') {
      jsonPointsList = jsonDecode(data['draw2Prompt$promptIndex']);
    } else if (data['phase'] == 'describe3') {
      jsonPointsList = jsonDecode(data['draw3Prompt$promptIndex']);
    }

    // decode json
    pointsList = [];
    for (var pointData in jsonPointsList) {
      if (pointData['isNull'] != null) {
        pointsList.add(null);
      } else {
        var point = Offset(pointData['x'], pointData['y']);
        var valueString = pointData['color'].split('(0x')[1].split(')')[0];
        var paint = Paint()
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true
          ..color = Color(int.parse(valueString, radix: 16))
          ..strokeWidth = pointData['width'];
        pointsList.add(DrawingPoint(point: point, paint: paint));
      }
    }

    return Column(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(color: Colors.white),
          child: CustomPaint(
            key: _key,
            size: Size(300, 300),
            painter: DrawingPainter(
              pointsList: pointsList,
            ),
            child: Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).highlightColor)),
            ),
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: 250,
          child: TextField(
            controller: descriptionController,
            textAlign: TextAlign.center,
            maxLines: null,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Describe here!',
            ),
          ),
        ),
        SizedBox(height: 10),
        RaisedGradientButton(
          child: Text(
            'Submit',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
          onPressed: () => submitDescription(data),
          height: 40,
          width: 140,
          gradient: LinearGradient(
            colors: <Color>[
              Colors.blue,
              Colors.blueAccent,
            ],
          ),
        ),
      ],
    );
  }

  submitDescription(data) async {
    var promptIndex = getPromptIndex(data);

    // send pointsList to Firestore sessions collection
    if (data['phase'] == 'describe1') {
      data['describe1Prompt$promptIndex'] = descriptionController.text;
    } else if (data['phase'] == 'describe2') {
      data['describe2Prompt$promptIndex'] = descriptionController.text;
    } else if (data['phase'] == 'describe3') {
      data['describe3Prompt$promptIndex'] = descriptionController.text;
    }

    // for every player, after submitting check if all drawings are done
    if (data['phase'] == 'describe1') {
      bool allPlayersHaveDescribed = true;
      data['playerIds'].asMap().forEach((i, _) {
        if (!data.containsKey('describe1Prompt$i')) {
          allPlayersHaveDescribed = false;
        }
      });
      if (allPlayersHaveDescribed) {
        data['phase'] = 'draw2';
      }
    } else if (data['phase'] == 'describe2') {
      if (data['rules']['numDrawDescribe'] == 2) {
        bool allPlayersHaveDescribed = true;
        data['playerIds'].asMap().forEach((i, _) {
          if (!data.containsKey('describe2Prompt$i')) {
            allPlayersHaveDescribed = false;
          }
        });
        if (allPlayersHaveDescribed) {
          data['phase'] = 'vote';
        }
      } else {
        data['phase'] = 'draw3';
      }
    } else if (data['phase'] == 'describe3') {
      bool allPlayersHaveDescribed = true;
      data['playerIds'].asMap().forEach((i, _) {
        if (!data.containsKey('describe3Prompt$i')) {
          allPlayersHaveDescribed = false;
        }
      });
      if (allPlayersHaveDescribed) {
        data['phase'] = 'vote';
      }
    }

    setState(() {
      descriptionController.text = '';
      // clear drawing
      pointsList.clear();
    });

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  indexUpdateCallback(String phase, int promptIndex, data) {
    // show snackbar and not allow voting for yourself
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    if (getSubmitterIndex(phase, promptIndex, data) == playerIndex) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('Can\'t vote for yourself!'),
        duration: Duration(seconds: 3),
      ));
    } else {
      HapticFeedback.vibrate();
      setState(() {
        votes[phase] = promptIndex;
      });
    }
  }

  List<Widget> _buildRow(int promptIndex, data) {
    List<Widget> row = [];
    // add drawing1
    var jsonPointsList = jsonDecode(data['draw1Prompt$promptIndex']);
    pointsList = [];
    for (var pointData in jsonPointsList) {
      if (pointData['isNull'] != null) {
        pointsList.add(null);
      } else {
        var point = Offset(pointData['x'] * 2 / 3, pointData['y'] * 2 / 3);
        var valueString = pointData['color'].split('(0x')[1].split(')')[0];
        var paint = Paint()
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true
          ..color = Color(int.parse(valueString, radix: 16))
          ..strokeWidth = pointData['width'];
        pointsList.add(DrawingPoint(point: point, paint: paint));
      }
    }
    row.add(
      VotableSquare(
        indexUpdateCallback: () =>
            indexUpdateCallback('draw1', promptIndex, data),
        votes: votes,
        phase: 'draw1',
        data: data,
        userId: widget.userId,
        promptIndex: promptIndex,
        child: Container(
          decoration: BoxDecoration(color: Colors.white),
          child: CustomPaint(
            size: Size(200, 200),
            painter: DrawingPainter(
              pointsList: pointsList,
            ),
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(border: Border.all()),
            ),
          ),
        ),
      ),
    );
    // add describe1
    row.add(
      VotableSquare(
        indexUpdateCallback: () =>
            indexUpdateCallback('describe1', promptIndex, data),
        votes: votes,
        phase: 'describe1',
        data: data,
        userId: widget.userId,
        promptIndex: promptIndex,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(),
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Center(
              child: Text(
                data['describe1Prompt$promptIndex'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // add drawing2
    jsonPointsList = jsonDecode(data['draw2Prompt$promptIndex']);
    pointsList = [];
    for (var pointData in jsonPointsList) {
      if (pointData['isNull'] != null) {
        pointsList.add(null);
      } else {
        var point = Offset(pointData['x'] * 2 / 3, pointData['y'] * 2 / 3);
        var valueString = pointData['color'].split('(0x')[1].split(')')[0];
        var paint = Paint()
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true
          ..color = Color(int.parse(valueString, radix: 16))
          ..strokeWidth = pointData['width'];
        pointsList.add(DrawingPoint(point: point, paint: paint));
      }
    }
    row.add(
      VotableSquare(
        indexUpdateCallback: () =>
            indexUpdateCallback('draw2', promptIndex, data),
        votes: votes,
        phase: 'draw2',
        data: data,
        userId: widget.userId,
        promptIndex: promptIndex,
        child: Container(
          decoration: BoxDecoration(color: Colors.white),
          child: CustomPaint(
            size: Size(200, 200),
            painter: DrawingPainter(
              pointsList: pointsList,
            ),
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(border: Border.all()),
            ),
          ),
        ),
      ),
    );
    // add describe2
    row.add(
      VotableSquare(
        indexUpdateCallback: () =>
            indexUpdateCallback('describe2', promptIndex, data),
        votes: votes,
        phase: 'describe2',
        data: data,
        userId: widget.userId,
        promptIndex: promptIndex,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(),
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Center(
              child: Text(
                data['describe2Prompt$promptIndex'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (data['rules']['numDrawDescribe'] == 3) {
      // add drawing3
      jsonPointsList = jsonDecode(data['draw3Prompt$promptIndex']);
      pointsList = [];
      for (var pointData in jsonPointsList) {
        if (pointData['isNull'] != null) {
          pointsList.add(null);
        } else {
          var point = Offset(pointData['x'] * 2 / 3, pointData['y'] * 2 / 3);
          var valueString = pointData['color'].split('(0x')[1].split(')')[0];
          var paint = Paint()
            ..strokeCap = StrokeCap.round
            ..isAntiAlias = true
            ..color = Color(int.parse(valueString, radix: 16))
            ..strokeWidth = pointData['width'];
          pointsList.add(DrawingPoint(point: point, paint: paint));
        }
      }
      row.add(
        VotableSquare(
          indexUpdateCallback: () =>
              indexUpdateCallback('draw3', promptIndex, data),
          votes: votes,
          phase: 'draw3',
          data: data,
          userId: widget.userId,
          promptIndex: promptIndex,
          child: Container(
            decoration: BoxDecoration(color: Colors.white),
            child: CustomPaint(
              size: Size(200, 200),
              painter: DrawingPainter(
                pointsList: pointsList,
              ),
              child: Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(border: Border.all()),
              ),
            ),
          ),
        ),
      );
      // add describe3
      row.add(
        VotableSquare(
          indexUpdateCallback: () =>
              indexUpdateCallback('describe3', promptIndex, data),
          votes: votes,
          phase: 'describe3',
          data: data,
          userId: widget.userId,
          promptIndex: promptIndex,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(),
            ),
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Center(
                child: Text(
                  data['describe3Prompt$promptIndex'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return row;
  }

  submitVotes(data) async {
    data = data.data;

    // check if all phases were voted on
    if (votes.length < (data['rules']['numDrawDescribe'] == 2 ? 4 : 6)) {
      // iterate over phases, add missing phases to list
      var missingPhases = [];
      var possiblePhases = [
        'draw1',
        'describe1',
        'draw2',
        'describe2',
      ];
      if (data['rules']['numDrawDescribe'] == 3) {
        possiblePhases.add('draw3');
        possiblePhases.add('describe3');
      }
      possiblePhases.asMap().forEach((i, v) {
        if (votes[possiblePhases[i]] == null) {
          missingPhases.add(phaseToEnglish(v));
        }
      });
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('Missing votes for: $missingPhases'),
        duration: Duration(seconds: 3),
      ));
      return;
    }

    // increment each relevant players score
    // figure out which players get incremented
    var scores = data['scores'];
    var draw1Vote = getSubmitterIndex(data['draw1'], votes['draw1'], data);
    scores[draw1Vote] += 1;
    var describe1Vote =
        getSubmitterIndex(data['describe1'], votes['describe1'], data);
    scores[describe1Vote] += 1;
    var draw2Vote = getSubmitterIndex(data['draw2'], votes['draw2'], data);
    scores[draw2Vote] += 1;
    var describe2Vote =
        getSubmitterIndex(data['describe2'], votes['describe2'], data);
    scores[describe2Vote] += 1;
    if (data['rules']['numDrawDescribe'] == 3) {
      var draw3Vote = getSubmitterIndex(data['draw3'], votes['draw3'], data);
      scores[draw3Vote] += 1;
      var describe3Vote =
          getSubmitterIndex(data['describe3'], votes['describe3'], data);
      scores[describe3Vote] += 1;
    }
    data['scores'] = scores;

    // update voted status
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    data['votes'][playerIndex] = true;

    // check if all votes are in
    var sum = scores.reduce((a, b) => a + b);
    var expectedSum = data['playerIds'].length *
        (data['rules']['numDrawDescribe'] == 2 ? 4 : 6);
    if (sum >= expectedSum * data['round']) {
      // if so, check if there is another round
      // new round = increment round and reset all submissions

      data['playerIds'].asMap().forEach((i, _) {
        data.remove('draw1Prompt$i');
        data.remove('describe1Prompt$i');
        data.remove('draw2Prompt$i');
        data.remove('describe2Prompt$i');
        data.remove('draw3Prompt$i');
        data.remove('describe3Prompt$i');
        data['votes'][playerIndex] = false;
      });
      data['round'] += 1;
      data['phase'] = 'draw1';

      if (data['round'] >= data['rules']['numRounds']) {
        // end game = final scoreboard
        data['phase'] = 'scoreboard';
      }

      await Firestore.instance
          .collection('sessions')
          .document(widget.sessionId)
          .setData(data);
    }

    setState(() {
      pointsList.clear();
      // TODO: should probably also reset painting tools?
    });
  }

  getVotes(data) {
    // construct a row of columns (scrollable left/right all together)
    // Original Prompt -> 1st Drawing -> 1st description -> 2nd Drawing -> 2nd prompt  (original prompt)
    var promptsColumn = data['rules']['prompts'][0]
        ['prompts']; // TODO: round needs to be dynamic here
    var screenWidth = MediaQuery.of(context).size.width;

    // create column items
    List<Widget> stack = [];
    stack.add(
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: List.generate(
            4,
            (index) => Container(
              height: 270,
              child: Row(
                children: _buildRow(index, data),
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      stack.add(
        Positioned(
          left: 0,
          top: i.toDouble() * 270,
          child: Container(
              width: screenWidth,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(),
                color: Theme.of(context).primaryColor,
              ),
              child: Center(
                  child: Text(
                promptsColumn[i],
                style: TextStyle(fontSize: 15, color: Colors.white),
              ))),
        ),
      );
    }

    if (isSpectator) {
      return Stack(children: stack);
    }

    var playerIndex = data['playerIds'].indexOf(widget.userId);

    if (data['votes'][playerIndex]) {
      return Container(
          decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).highlightColor),
              borderRadius: BorderRadius.circular(20)),
          padding: EdgeInsets.all(30),
          child: Text('Waiting on the slowpokes...'));
    }

    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Stack(
            children: stack,
          ),
          SizedBox(height: 30),
          RaisedGradientButton(
            child: Text('Submit votes',
                style: TextStyle(
                  color: Colors.black,
                )),
            height: 40,
            width: 140,
            gradient: LinearGradient(
              colors: <Color>[
                Color.fromARGB(255, 255, 185, 0),
                Color.fromARGB(255, 255, 213, 0),
              ],
            ),
            onPressed: () {
              submitVotes(data);
            },
          ),
          SizedBox(height: 60)
        ],
      ),
    );
  }

  Widget getUserAction(data) {
    if (data['phase'] == 'draw1' ||
        data['phase'] == 'draw2' ||
        data['phase'] == 'draw3') {
      if (isSpectator) {
        return SpectatorModeLogo();
      }
      return getDrawing(data);
    } else if (data['phase'] == 'describe1' ||
        data['phase'] == 'describe2' ||
        data['phase'] == 'describe3') {
      if (isSpectator) {
        return SpectatorModeLogo();
      }
      return getDescription(data);
    } else {
      return getVotes(data);
    }
  }

  getScoreboard(data) {
    // create mapping of name to score
    var playerScores = {};
    data['playerIds'].asMap().forEach((i, playerId) {
      playerScores[playerId] = data['scores'][i];
    });
    List<Widget> scores = [];

    var sortedKeys = playerScores.keys.toList(growable: false)
      ..sort((k1, k2) => playerScores[k2].compareTo(playerScores[k1]));
    LinkedHashMap sortedPlayerScores = new LinkedHashMap.fromIterable(
        sortedKeys,
        key: (k) => k,
        value: (k) => playerScores[k]);

    sortedPlayerScores.forEach((playerId, score) {
      scores.add(FutureBuilder(
          future: Firestore.instance
              .collection('users')
              .document(playerId.toString())
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Text('');
            }
            return Column(
              children: <Widget>[
                Text(
                  '${snapshot.data['name']}: ${playerScores[playerId].toString()}',
                  style: TextStyle(
                    fontSize: 26,
                  ),
                ),
                SizedBox(height: 10),
              ],
            );
          }));
    });
    var width = MediaQuery.of(context).size.width;
    return Column(
      children: <Widget>[
        SizedBox(height: 50),
        Container(
          width: width * 0.8,
          height: 140 + 36 * scores.length.toDouble(),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).highlightColor,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Final scoreboard:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              PageBreak(
                width: 150,
              ),
              SizedBox(height: 20),
              Column(children: scores),
            ],
          ),
        ),
        SizedBox(height: 20),
        widget.userId == data['leader']
            ? EndGameButton(
                gameName: 'Bananaphone',
                sessionId: widget.sessionId,
                fontSize: 20,
                height: 40,
                width: 140,
              )
            : Container(),
        SizedBox(height: 10),
      ],
    );
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
          if (data.data == null) {
            return Scaffold(
                appBar: AppBar(
                  title: Text(
                    'Bananaphone',
                  ),
                ),
                body: Container());
          }
          checkIfExit(data);
          // check for change in phase
          checkIfNewPhase(data);
          return Scaffold(
              key: _scaffoldKey,
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
              body: SafeArea(
                child: data['phase'] == 'draw1' ||
                        data['phase'] == 'draw2' ||
                        data['phase'] == 'draw3'
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(height: 10),
                          getStatus(data),
                          SizedBox(height: 10),
                          getUserAction(data),
                          SizedBox(height: 5),
                        ],
                      )
                    : SingleChildScrollView(
                        child: data['phase'] == 'scoreboard'
                            ? getScoreboard(data)
                            : Column(
                                children: <Widget>[
                                  SizedBox(height: 10),
                                  getStatus(data),
                                  SizedBox(height: 10),
                                  getUserAction(data),
                                  SizedBox(height: 5),
                                ],
                              )),
              ));
        });
  }
}

class DrawingPainter extends CustomPainter {
  DrawingPainter({this.pointsList});
  List<DrawingPoint> pointsList;
  List<Offset> offsetPoints = List();
  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < pointsList.length - 1; i++) {
      if (pointsList[i] != null && pointsList[i + 1] != null) {
        canvas.drawLine(
            pointsList[i].point, pointsList[i + 1].point, pointsList[i].paint);
      } else if (pointsList[i] != null && pointsList[i + 1] == null) {
        offsetPoints.clear();
        canvas.drawPoints(PointMode.points, offsetPoints, pointsList[i].paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) =>
      oldDelegate.pointsList != pointsList;
}

class VotableSquare extends StatelessWidget {
  final Widget child;
  final Function indexUpdateCallback;
  final Map votes;
  final String phase;
  final int promptIndex;
  final data;
  final String userId;

  VotableSquare(
      {this.child,
      this.indexUpdateCallback,
      this.votes,
      this.phase,
      this.promptIndex,
      this.data,
      this.userId});

  @override
  Widget build(BuildContext context) {
    // check if this cell is in the map
    bool isVoted = false;
    if (votes.containsKey(phase) && votes[phase] == promptIndex) {
      isVoted = true;
    }

    // check if this cell is voted by self
    bool isSelf = false;
    var playerIndex = data['playerIds'].indexOf(userId);
    if (getSubmitterIndex(phase, promptIndex, data) == playerIndex) {
      isSelf = true;
    }
    bool isSpectator = data['spectatorIds'].contains(userId);
    if (isSpectator) {
      isSelf = false;
    }

    Color color = Colors.greenAccent;
    switch (phase) {
      case 'describe1':
        color = Colors.amberAccent;
        break;
      case 'draw2':
        color = Colors.blueAccent;
        break;
      case 'describe2':
        color = Colors.lime;
        break;
      case 'draw3':
        color = Colors.deepOrangeAccent;
        break;
      case 'describe3':
        color = Colors.deepPurpleAccent;
        break;
    }

    return GestureDetector(
      onLongPress: indexUpdateCallback,
      child: Column(
        children: <Widget>[
          SizedBox(height: 40),
          Container(
            height: 20,
            width: 210,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
            ),
            child: Text(
              phaseToEnglish(phase),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Stack(
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                    border: Border.all(
                        width: 5,
                        color: isSelf
                            ? Colors.grey
                            : isVoted ? color : Colors.white)),
                child: child,
              ),
              isVoted
                  ? Positioned(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(),
                          color: color.withAlpha(100),
                        ),
                        padding: EdgeInsets.all(3),
                        child: Text(
                          'Voted best for ${phaseToEnglish(phase)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      top: 8,
                      left: 8,
                    )
                  : Container(),
            ],
          ),
        ],
      ),
    );
  }
}

getSubmitterIndex(String phase, int promptIndex, data) {
  var submitterIndex = promptIndex;
  switch (phase) {
    case 'draw1':
      // do nothing
      break;
    case 'describe1':
      submitterIndex -= 1;
      break;
    case 'draw2':
      submitterIndex -= 2;
      break;
    case 'describe2':
      submitterIndex -= 3;
      break;
    case 'draw3':
      submitterIndex -= 4;
      break;
    case 'describe3':
      submitterIndex -= 5;
      break;
  }
  while (submitterIndex < 0) {
    submitterIndex += data['playerIds'].length;
  }
  return submitterIndex;
}

phaseToEnglish(phase) {
  switch (phase) {
    case 'draw1':
      return 'Draw (#1)';
      break;
    case 'describe1':
      return 'Describe (#1)';
      break;
    case 'draw2':
      return 'Draw (#2)';
      break;
    case 'describe2':
      return 'Describe (#2)';
      break;
    case 'draw3':
      return 'Draw (#3)';
      break;
    case 'describe3':
      return 'Describe (#3)';
      break;
  }
  return 'should never get this';
}
