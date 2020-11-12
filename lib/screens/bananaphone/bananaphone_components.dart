import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:together/models/models.dart';

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
                            : isVoted
                                ? color
                                : Colors.white)),
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
