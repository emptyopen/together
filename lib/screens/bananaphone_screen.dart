import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:together/components/buttons.dart';
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
  List<DrawingPoint> pointsList = <DrawingPoint>[];
  List<int> linesList = [];
  Color strokeColor = Colors.black;
  double strokeWidth = 5;
  GlobalKey _key = GlobalKey();
  final descriptionController = TextEditingController();

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

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
          width: 220,
          padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
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
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    var phase = data['phase'];
    if (phase == 'draw1' || phase == 'draw2') {
      var prompt =
          data['rules']['prompts'][data['round']]['prompts'][playerIndex];
      if (phase == 'draw2') {
        // get previous description: 4 players: player2 describes player1 drawing. then player3 draws player2 drawing, and player4 describes player3 drawing.
        var nextPlayerIndex = playerIndex + 1;
        if (playerIndex == data['playerIds'].length - 1) {
          nextPlayerIndex = 0;
        }
        prompt = data['describe1Player$nextPlayerIndex'];
      }
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
            Text(prompt,
                style: TextStyle(
                    fontSize: 18, color: Theme.of(context).primaryColor),
                textAlign: TextAlign.center),
          ],
        ),
      ));
    } else if (phase == 'describe1' || phase == 'describe2') {
      columnItems.add(Container(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
          decoration: BoxDecoration(
            border: Border.all(),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Describe this picture!',
            style: TextStyle(fontSize: 20),
          )));
    } else {
      columnItems.add(Container(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
          decoration: BoxDecoration(
            border: Border.all(),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Vote for your favorites!',
            style: TextStyle(fontSize: 20),
          )));
    }

    return Column(children: columnItems);
  }

  Widget getDrawableArea(BuildContext context) {
    return Container(
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
                decoration: BoxDecoration(border: Border.all()),
              ),
            )),
      ),
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
    print('submitting drawing...');
    var playerTurn = data['playerIds'].indexOf(widget.userId);
    var jsonPointsList = listPointsToJson(pointsList);

    if (data['phase'] == 'draw1') {
      await Firestore.instance
          .collection('sessions')
          .document(widget.sessionId)
          .updateData({'draw1Player$playerTurn': jsonPointsList});
    } else {
      // it's draw2
      await Firestore.instance
          .collection('sessions')
          .document(widget.sessionId)
          .updateData({'draw2Player$playerTurn': jsonPointsList});
    }

    // for every player, after submitting check if all drawings are done
    var newData = (await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .get())
        .data;
    if (data['phase'] == 'draw1') {
      bool allPlayersHaveDrawn = true;
      data['playerIds'].asMap().forEach((i, _) {
        if (!newData.containsKey('draw1Player$i')) {
          print('setting false for $i');
          allPlayersHaveDrawn = false;
        }
      });
      if (allPlayersHaveDrawn) {
        // update phase to describe1
        print('will update phase to describe1');
        await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .updateData({'phase': 'describe1'});
      }
    } else {
      bool allPlayersHaveDrawn = true;
      data['playerIds'].asMap().forEach((i, _) {
        if (!newData.containsKey('draw2Player$i')) {
          allPlayersHaveDrawn = false;
        }
      });
      if (allPlayersHaveDrawn) {
        await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .updateData({'phase': 'describe2'});
      }
    }

    setState(() {
      pointsList = [];
      // TODO: should probably also reset painting tools?
    });
  }

  getDrawing(data) {
    // if already submitted, show container just waiting
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    if ((data['phase'] == 'draw1' && data['draw1Player$playerIndex'] != null) ||
        data['draw2Player$playerIndex'] != null) {
      return Container(
          decoration: BoxDecoration(
              border: Border.all(), borderRadius: BorderRadius.circular(20)),
          padding: EdgeInsets.all(30),
          child: Text('Waiting on the slowpokes...'));
    }
    return Container(
      width: 350,
      padding: EdgeInsets.fromLTRB(20, 20, 20, 5),
      decoration: BoxDecoration(
        border: Border.all(),
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
                    Colors.red,
                    Colors.blue,
                    Colors.green,
                    Colors.purple,
                    Colors.white
                  ].map<DropdownMenuItem<Color>>((Color value) {
                    return DropdownMenuItem<Color>(
                      value: value,
                      child: Container(
                          height: 20,
                          width: 20,
                          decoration: BoxDecoration(
                            color: value,
                            border: Border.all(),
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
                child: Text('Submit'),
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

  getDescription(data) {
    // if already submitted, show container just waiting
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    if ((data['phase'] == 'describe1' &&
            data['describe1Player$playerIndex'] != null) ||
        data['describe2Player$playerIndex'] != null) {
      return Container(
          decoration: BoxDecoration(
              border: Border.all(), borderRadius: BorderRadius.circular(20)),
          padding: EdgeInsets.all(30),
          child: Text('Waiting on the slowpokes...'));
    }

    // get appropriate drawing
    var jsonPointsList;
    var nextPlayerIndex = playerIndex + 1;
    if (playerIndex == data['playerIds'].length - 1) {
      // close the loop
      nextPlayerIndex = 0;
    }
    if (data['phase'] == 'describe1') {
      jsonPointsList = data['draw1Player$nextPlayerIndex'];
    } else {
      jsonPointsList = data['draw2Player$nextPlayerIndex'];
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
          ..color = Color(
              int.parse(valueString, radix: 16)) //Colors.black // TODO: fix
          ..strokeWidth = pointData['width'];
        pointsList.add(DrawingPoint(point: point, paint: paint));
      }
    }

    submitDescription(data) async {
      // send pointsList to Firestore sessions collection
      print('submitting description...');
      var playerTurn = data['playerIds'].indexOf(widget.userId);
      if (data['phase'] == 'describe1') {
        await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .updateData(
                {'describe1Player$playerTurn': descriptionController.text});
      } else {
        await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .updateData(
                {'describe2Player$playerTurn': descriptionController.text});
      }

      // for every player, after submitting check if all drawings are done
      var newData = (await Firestore.instance
              .collection('sessions')
              .document(widget.sessionId)
              .get())
          .data;
      if (data['phase'] == 'describe1') {
        bool allPlayersHaveDescribed = true;
        data['playerIds'].asMap().forEach((i, _) {
          if (!newData.containsKey('describe1Player$i')) {
            allPlayersHaveDescribed = false;
          }
        });
        if (allPlayersHaveDescribed) {
          print('will update phase to draw2');
          await Firestore.instance
              .collection('sessions')
              .document(widget.sessionId)
              .updateData({'phase': 'draw2'});
        }
      } else {
        bool allPlayersHaveDescribed = true;
        data['playerIds'].asMap().forEach((i, _) {
          if (!newData.containsKey('describe2Player$i')) {
            allPlayersHaveDescribed = false;
          }
        });
        if (allPlayersHaveDescribed) {
          print('will update phase to vote');
          await Firestore.instance
              .collection('sessions')
              .document(widget.sessionId)
              .updateData({'phase': 'vote'});
        }
      }

      setState(() {
        descriptionController.text = '';
      });
    }

    return Column(
      children: <Widget>[
        CustomPaint(
          key: _key,
          size: Size(300, 300),
          painter: DrawingPainter(
            pointsList: pointsList,
          ),
          child: Container(
            height: 300,
            width: 300,
            decoration: BoxDecoration(border: Border.all()),
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

  List<Widget> _buildCells(int playerIndex) {
    return List.generate(
      4,
      (index) => Container(
        decoration: BoxDecoration(
          border: Border.all(),
        ),
        alignment: Alignment.center,
        width: 200.0,
        height: 240.0,
        child: Text("${index + 1}"),
      ),
    );
  }

  getVotes(data) {
    // construct a row of columns (scrollable left/right all together)
    // Original Prompt -> 1st Drawing -> 1st description -> 2nd Drawing -> 2nd prompt  (original prompt)
    var promptsColumn = [];
    var draw1Column = [];
    var describe1Column = [];
    var draw2Column = [];
    var describe2Column = [];
    data['playerIds'].asMap().forEach((i, val) {
      promptsColumn.add('prompt $i');
    });
    return SingleChildScrollView(
      child: Stack(
        children: <Widget>[

        Container(height: 10, width: 10, decoration: BoxDecoration(border: Border.all()),),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                4,
                (index) => Row(
                  children: _buildCells(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget getUserAction(data) {
    if (data['phase'] == 'draw1' || data['phase'] == 'draw2') {
      return getDrawing(data);
    } else if (data['phase'] == 'describe1' || data['phase'] == 'describe2') {
      return getDescription(data);
    } else {
      return getVotes(data);
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
              body: SingleChildScrollView(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: 20),
                      getStatus(data),
                      SizedBox(height: 10),
                      getUserAction(data),
                      SizedBox(height: 10),
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
                                      game: 'Bananaphone',
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
                      SizedBox(height: 40),
                    ],
                  ),
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
