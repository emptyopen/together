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
  var votes = {};

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
      var promptIndex = getPromptIndex(data);
      var prompt =
          data['rules']['prompts'][data['round']]['prompts'][playerIndex];
      if (phase == 'draw2') {
        prompt = data['describe1Prompt$promptIndex'];
      }
      print('prompt is from pI $promptIndex');
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
      columnItems.add(
        Container(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
          decoration: BoxDecoration(
            border: Border.all(),
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
                'One choice per round (column).',
                style: TextStyle(fontSize: 12, color: Colors.grey),
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
    var promptIndex = getPromptIndex(data);
    var jsonPointsList = listPointsToJson(pointsList);

    if (data['phase'] == 'draw1') {
      await Firestore.instance
          .collection('sessions')
          .document(widget.sessionId)
          .updateData({'draw1Prompt$promptIndex': jsonPointsList});
    } else {
      // it's draw2
      await Firestore.instance
          .collection('sessions')
          .document(widget.sessionId)
          .updateData({'draw2Prompt$promptIndex': jsonPointsList});
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
        if (!newData.containsKey('draw1Prompt$i')) {
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
        if (!newData.containsKey('draw2Prompt$i')) {
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
      pointsList.clear();
      // TODO: should probably also reset painting tools?
    });
  }

  getDrawing(data) {
    // if already submitted, show container just waiting
    var promptIndex = getPromptIndex(data);
    if ((data['phase'] == 'draw1' && data['draw1Prompt$promptIndex'] != null) ||
        data['draw2Prompt$promptIndex'] != null) {
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
    }
    // handle wraparound
    if (promptIndex > data['playerIds'].length - 1) {
      promptIndex = promptIndex - data['playerIds'].length;
    }
    return promptIndex;
  }

  getDescription(data) {
    var promptIndex = getPromptIndex(data);

    // if already submitted, show container just waiting
    if ((data['phase'] == 'describe1' &&
            data['describe1Prompt$promptIndex'] != null) ||
        data['describe2Prompt$promptIndex'] != null) {
      return Container(
          decoration: BoxDecoration(
              border: Border.all(), borderRadius: BorderRadius.circular(20)),
          padding: EdgeInsets.all(30),
          child: Text('Waiting on the slowpokes...'));
    }

    // get appropriate drawing
    var jsonPointsList;
    if (data['phase'] == 'describe1') {
      jsonPointsList = data['draw1Prompt$promptIndex'];
    } else {
      jsonPointsList = data['draw2Prompt$promptIndex'];
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

  submitDescription(data) async {
    var promptIndex = getPromptIndex(data);

    // send pointsList to Firestore sessions collection
    if (data['phase'] == 'describe1') {
      await Firestore.instance
          .collection('sessions')
          .document(widget.sessionId)
          .updateData(
              {'describe1Prompt$promptIndex': descriptionController.text});
    } else {
      await Firestore.instance
          .collection('sessions')
          .document(widget.sessionId)
          .updateData(
              {'describe2Prompt$promptIndex': descriptionController.text});
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
        if (!newData.containsKey('describe1Prompt$i')) {
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
        if (!newData.containsKey('describe2Prompt$i')) {
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
      // clear drawing
      pointsList.clear();
    });
  }

  updateVotingIndex(String phase, int promptIndex) {
    setState(() {
      votes[phase] = promptIndex;
    });
  }

  List<Widget> _buildRow(int promptIndex, data) {
    List<Widget> row = [];
    // add drawing1
    var jsonPointsList = data['draw1Prompt$promptIndex'];
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
        indexUpdateCallback: () => updateVotingIndex('draw1', promptIndex),
        votes: votes,
        phase: 'draw1', 
        promptIndex: promptIndex,
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
    );
    // add describe1
    row.add(
      VotableSquare(
        indexUpdateCallback: () => updateVotingIndex('describe1', promptIndex),
        votes: votes,
        phase: 'describe1', 
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
    jsonPointsList = data['draw2Prompt$promptIndex'];
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
        indexUpdateCallback: () => updateVotingIndex('draw2', promptIndex),
        votes: votes,
        phase: 'draw2', 
        promptIndex: promptIndex,
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
    );
    // add describe2
    row.add(
      VotableSquare(
        indexUpdateCallback: () => updateVotingIndex('describe2', promptIndex),
        votes: votes,
        phase: 'describe2', 
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
    return row;
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
              height: 250,
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
          top: i.toDouble() * 250,
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

    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Stack(
            children: stack,
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

class VotableSquare extends StatelessWidget {
  final Widget child;
  final Function indexUpdateCallback;
  final Map votes;
  final String phase;
  final int promptIndex;

  VotableSquare({this.child, this.indexUpdateCallback, this.votes, this.phase, this.promptIndex});

  @override
  Widget build(BuildContext context) {
    // check if this cell is in the map
    bool isVoted = false;
    if (votes.containsKey(phase) && votes[phase] == promptIndex) {
      isVoted = true;
    }

    Color color = Colors.greenAccent;
    switch(phase) {
      case 'describe1':
        color = Colors.amberAccent;
        break;
      case 'draw2':
        color = Colors.blueAccent;
        break;
      case 'describe2':
        color = Colors.deepPurpleAccent;
        break;
    }

    return GestureDetector(
      onLongPress: indexUpdateCallback,
      child: Column(
        children: <Widget>[
          SizedBox(height: 40),
          Container(
              decoration: BoxDecoration(
                  border: Border.all(width: 5, color: isVoted ? color : Colors.white)),
              child: child),
        ],
      ),
    );
  }
}
