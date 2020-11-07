import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:auto_size_text/auto_size_text.dart';

class TeamSelectorScreen extends StatefulWidget {
  TeamSelectorScreen({this.userId});

  final String userId;

  @override
  _TeamSelectorScreenState createState() => _TeamSelectorScreenState();
}

class _TeamSelectorScreenState extends State<TeamSelectorScreen> {
  bool isPickTeams = true;
  int numTeams = 2;
  int numSome = 1;

  getTeamSizePicker() {
    return Container(
      width: 160,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(5),
        color: Theme.of(context).canvasColor.withAlpha(200),
      ),
      padding: EdgeInsets.all(5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: numTeams > 2
                ? () {
                    setState(() {
                      numTeams -= 1;
                    });
                    HapticFeedback.vibrate();
                  }
                : null,
            child: Icon(
              MdiIcons.chevronLeftBoxOutline,
              size: 35,
              color: numTeams > 2 ? Colors.purple : Colors.grey,
            ),
          ),
          SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$numTeams',
                style: TextStyle(
                  color: Colors.purple,
                  fontSize: 22,
                ),
              ),
              Text(
                'teams',
                style: TextStyle(
                  color: Colors.purple,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(width: 10),
          GestureDetector(
            onTap: numTeams < 5
                ? () {
                    setState(() {
                      numTeams += 1;
                    });
                    HapticFeedback.vibrate();
                  }
                : null,
            child: Icon(
              MdiIcons.chevronRightBoxOutline,
              size: 35,
              color: numTeams < 5 ? Colors.purple : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  getSomeSizePicker() {
    return Container(
      width: 160,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(5),
        color: Theme.of(context).canvasColor.withAlpha(200),
      ),
      padding: EdgeInsets.all(5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: numSome > 1
                ? () {
                    setState(() {
                      numSome -= 1;
                    });
                    HapticFeedback.vibrate();
                  }
                : null,
            child: Icon(
              MdiIcons.chevronLeftBoxOutline,
              size: 35,
              color: numSome > 1 ? Colors.orange : Colors.grey,
            ),
          ),
          SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Pick',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 14,
                ),
              ),
              Text(
                '$numSome',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 22,
                ),
              ),
              Text(
                'player' + (numSome == 1 ? '' : 's'),
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(width: 10),
          GestureDetector(
            onTap: numSome < 5
                ? () {
                    setState(() {
                      numSome += 1;
                    });
                    HapticFeedback.vibrate();
                  }
                : null,
            child: Icon(
              MdiIcons.chevronRightBoxOutline,
              size: 35,
              color: numSome < 5 ? Colors.orange : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  getSettings() {
    // pick some vs pick teams
    // if pick teams, how many teams (1 < x < 5)
    // if pick some, choose how many to pick (1 <= x <= 5)
    // (max 10 touch points)
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.vibrate();
            setState(() {
              isPickTeams = !isPickTeams;
            });
          },
          child: Container(
            height: 60,
            width: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(5),
              color: Theme.of(context).canvasColor.withAlpha(200),
            ),
            padding: EdgeInsets.all(5),
            child: Column(
              children: [
                AutoSizeText(
                  isPickTeams ? 'Pick teams' : 'Pick some',
                  maxLines: 1,
                  style: TextStyle(
                      fontSize: 18,
                      color: isPickTeams ? Colors.purple : Colors.orange),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 5),
                Container(
                  width: 50,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.withAlpha(100),
                  ),
                  child: Row(
                    mainAxisAlignment: isPickTeams
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      Container(
                        height: 20,
                        width: 25,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: isPickTeams ? Colors.purple : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 20),
        isPickTeams ? getTeamSizePicker() : getSomeSizePicker(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan[700],
        title: Text(
          'Team Selector',
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                ),
              ),
              child: Center(
                child: TeamSelectorArea(
                  isPickTeams: isPickTeams,
                  numSome: numSome,
                  numTeams: numTeams,
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: RotatedBox(
                quarterTurns: 1,
                child: getSettings(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------

class TeamSelectorArea extends StatefulWidget {
  final isPickTeams;
  final numSome;
  final numTeams;

  TeamSelectorArea({this.isPickTeams, this.numSome, this.numTeams});

  @override
  _TeamSelectorAreaState createState() => _TeamSelectorAreaState();
}

class _TeamSelectorAreaState extends State<TeamSelectorArea> {
  Map touches = {};
  Map colors = {};
  GlobalKey _key = GlobalKey();

  getCoords() {
    List<Widget> pointerPositions = [];
    touches.forEach((i, v) {
      pointerPositions.add(
        Text(
          (i + 1).toString(),
          style: TextStyle(
            color: getColorFromString(colors[i]),
          ),
        ),
      );
    });
    return Column(children: pointerPositions);
  }

  getColorFromString(String colorString) {
    switch (colorString) {
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      case 'yellow':
        return Colors.yellow;
      case 'blue':
        return Colors.blue;
      case 'pink':
        return Colors.pink;
      case 'grey':
        return Colors.grey;
    }
    return Colors.white;
  }

  getColorAccentFromString(String colorString) {
    switch (colorString) {
      case 'green':
        return Colors.greenAccent;
      case 'purple':
        return Colors.purpleAccent;
      case 'yellow':
        return Colors.yellowAccent;
      case 'blue':
        return Colors.blueAccent;
      case 'pink':
        return Colors.pinkAccent;
      case 'grey':
        return Colors.grey;
    }
    return Colors.white;
  }

  getPointerIndicators() {
    double indicatorRadius = 140;
    List<Widget> indicators = [];
    touches.forEach((i, v) {
      indicators.add(Positioned(
        left: v.dx - indicatorRadius / 2,
        top: v.dy - indicatorRadius / 2,
        child: IgnorePointer(
          child: Container(
            height: indicatorRadius,
            width: indicatorRadius,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(indicatorRadius),
              border: Border.all(
                width: 10,
                color: getColorFromString(colors[i]),
              ),
            ),
            child: Center(
              child: Container(
                height: indicatorRadius - 30,
                width: indicatorRadius - 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(indicatorRadius),
                  border: Border.all(
                    width: 10,
                    color: getColorAccentFromString(colors[i]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ));
    });
    return Stack(children: indicators);
  }

  setColors() async {
    var possibleColors = ['purple', 'green', 'yellow', 'blue', 'pink'];
    possibleColors.shuffle();
    // if isPickTeams, create colors for numTeams teams, and distribute existing players
    if (widget.isPickTeams) {
      var teamColors = possibleColors.sublist(0, widget.numTeams);
      int index = 0;
      colors.forEach((i, v) {
        colors[i] = teamColors[index];
        index += 1;
        if (index == teamColors.length) {
          index = 0;
        }
      });
      setState(() {});
    }
    // otherwise is pick some. one random selection of numSome players get colored
    else {
      int colorCounter = 0;
      var list = new List<int>.generate(colors.length, (i) => i);
      list.shuffle();
      list.forEach((i) {
        if (colorCounter < widget.numSome) {
          colors[i] = 'green';
        } else {
          colors[i] = 'grey';
        }
        colorCounter += 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      key: _key,
      gestures: <Type, GestureRecognizerFactory>{
        ImmediateMultiDragGestureRecognizer:
            new GestureRecognizerFactoryWithHandlers<
                ImmediateMultiDragGestureRecognizer>(
          () => new ImmediateMultiDragGestureRecognizer(),
          (ImmediateMultiDragGestureRecognizer instance) {
            instance
              ..onStart = (Offset offset) {
                // start
                touches[touches.length] = Offset(0, 0);
                colors[colors.length] = 'grey';
                setColors();
                setState(() {});

                onDrag(DragUpdateDetails d, touchIndex, colorIndex) {
                  RenderBox getBox = _key.currentContext.findRenderObject();
                  var local = getBox.globalToLocal(d.globalPosition);
                  touches[colorIndex] = local;
                  setState(() {});
                }

                endDrag(DragEndDetails d, touchIndex, colorIndex) {
                  touches.remove(touchIndex);
                  colors.remove(colorIndex);
                  setState(() {});
                }

                return ItemDrag(
                    onDrag, endDrag, touches.length - 1, colors.length - 1);
              };
          },
        ),
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border.all(),
                    ),
                    child: getCoords(),
                  ),
                ),
              ],
            ),
          ),
          getPointerIndicators(),
        ],
      ),
    );
  }
}

class ItemDrag extends Drag {
  final Function onUpdate;
  final Function onEnd;
  final itemNum;
  final colorNum;

  ItemDrag(this.onUpdate, this.onEnd, this.itemNum, this.colorNum);

  @override
  void update(DragUpdateDetails details) {
    super.update(details);
    onUpdate(details, itemNum, colorNum);
  }

  @override
  void end(DragEndDetails details) {
    super.end(details);
    onEnd(details, itemNum, colorNum);
  }
}
