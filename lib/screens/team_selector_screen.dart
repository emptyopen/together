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

  getSettings() {
    // pick 1 vs pick teams
    // if pick teams, how many teams (1 < x < 8)
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
            width: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(5),
            ),
            padding: EdgeInsets.all(5),
            child: Column(
              children: [
                AutoSizeText(
                  isPickTeams ? 'Pick teams' : 'Pick one',
                  maxLines: 1,
                  style: TextStyle(fontSize: 18, color: Colors.cyan[700]),
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
                          color: Colors.cyan[700],
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
        Container(
          width: 160,
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(5),
          ),
          padding: EdgeInsets.all(5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: numTeams > 2 && isPickTeams
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
                  color: numTeams > 2 && isPickTeams
                      ? Colors.cyan[700]
                      : Colors.grey,
                ),
              ),
              SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$numTeams',
                    style: TextStyle(
                      color: isPickTeams ? Colors.cyan[700] : Colors.grey,
                      fontSize: 22,
                    ),
                  ),
                  Text(
                    'teams',
                    style: TextStyle(
                      color: isPickTeams ? Colors.cyan[700] : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 10),
              GestureDetector(
                onTap: numTeams < 8 && isPickTeams
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
                  color: numTeams < 8 && isPickTeams
                      ? Colors.cyan[700]
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
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
      body: Column(
        children: [
          getSettings(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.red,
                ),
              ),
              child: Center(
                child: MultiTouchPage(
                  backgroundColor: Colors.white,
                  borderColor: Colors.amber,
                  minTouches: 2,
                  onTapCallback: (touchCount, correct) {
                    print("Touch" + touchCount.toString());
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

typedef MultiTouchGestureRecognizerCallback = void Function(
    int touchCount, bool correctNumberOfTouches);

class MultiTouchGestureRecognizer extends MultiTapGestureRecognizer {
  MultiTouchGestureRecognizerCallback onMultiTap;
  var numberOfTouches = 0;
  int minNumberOfTouches = 0;

  MultiTouchGestureRecognizer() {
    super.onTapDown = (pointer, details) => this.addTouch(pointer, details);
    super.onTapUp = (pointer, details) => this.removeTouch(pointer, details);
    super.onTapCancel = (pointer) => this.cancelTouch(pointer);
    super.onTap = (pointer) => this.captureDefaultTap(pointer);
  }

  void addTouch(int pointer, TapDownDetails details) {
    this.numberOfTouches++;
  }

  void removeTouch(int pointer, TapUpDetails details) {
    if (this.numberOfTouches == this.minNumberOfTouches) {
      this.onMultiTap(numberOfTouches, true);
    } else if (this.numberOfTouches != 0) {
      this.onMultiTap(numberOfTouches, false);
    }

    this.numberOfTouches = 0;
  }

  void cancelTouch(int pointer) {
    this.numberOfTouches = 0;
  }

  void captureDefaultTap(int pointer) {}

  @override
  set onTapDown(_onTapDown) {}

  @override
  set onTapUp(_onTapUp) {}

  @override
  set onTapCancel(_onTapCancel) {}

  @override
  set onTap(_onTap) {}
}

class MultiTouchPage extends StatefulWidget {
  final MultiTouchPageCallback onTapCallback;
  final int minTouches;
  final Color backgroundColor;
  final Color borderColor;

  MultiTouchPage(
      {this.backgroundColor,
      this.borderColor,
      this.minTouches,
      this.onTapCallback});
  @override
  _MultiTouchPageState createState() => _MultiTouchPageState();
}

class _MultiTouchPageState extends State<MultiTouchPage> {
  bool correctNumberOfTouches;
  int touchCount;
  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        MultiTouchGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<MultiTouchGestureRecognizer>(
          () => MultiTouchGestureRecognizer(),
          (MultiTouchGestureRecognizer instance) {
            instance.minNumberOfTouches = widget.minTouches;
            instance.onMultiTap = (
              touchCount,
              correctNumberOfTouches,
            ) =>
                this.onTap(touchCount, correctNumberOfTouches);
          },
        ),
      },
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Container(
                padding: EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  border: Border(
                    top: BorderSide(width: 1.0, color: widget.borderColor),
                    left: BorderSide(width: 1.0, color: widget.borderColor),
                    right: BorderSide(width: 1.0, color: widget.borderColor),
                    bottom: BorderSide(width: 1.0, color: widget.borderColor),
                  ),
                ),
                child: Text(
                    "Tap with " + this.touchCount.toString() + " finger(s).",
                    textAlign: TextAlign.center),
              ),
            ),
          ]),
    );
  }

  void onTap(int touchCount, bool correctNumberOfTouches) {
    this.correctNumberOfTouches = correctNumberOfTouches;
    setState(() {
      this.touchCount = touchCount;
    });
    print("Tapped with " + touchCount.toString() + " finger(s)");
    widget.onTapCallback(touchCount, correctNumberOfTouches);
  }
}

typedef MultiTouchPageCallback = void Function(
    int touchCount, bool correctNumberOfTouches);
