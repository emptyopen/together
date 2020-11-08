import 'package:flutter/material.dart';
import 'package:together/components/misc.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:shimmer/shimmer.dart';

class TheScoreboardScreen extends StatefulWidget {
  TheScoreboardScreen({this.userId});

  final String userId;

  @override
  _TheScoreboardScreenState createState() => _TheScoreboardScreenState();
}

class _TheScoreboardScreenState extends State<TheScoreboardScreen> {
  var teamNames = ['Team 1', 'Team 2'];
  var scoreValues = [
    [0],
    [0],
  ];
  stt.SpeechToText _speech = stt.SpeechToText();
  bool listening = false;
  bool speechAvailable = false;
  String transcription;

  addScoreToTeam(teamIndex, scoreString) {
    HapticFeedback.vibrate();
    // ensure score is number
    scoreString = scoreString.replaceAll("[^\\d]", "");
    int score = int.parse(scoreString);
    scoreValues[teamIndex].add(score);
    setState(() {});
  }

  updateTeamName(teamIndex, name) {
    HapticFeedback.vibrate();
    teamNames[teamIndex] = name;
    setState(() {});
  }

  addTeam(name) {
    HapticFeedback.vibrate();
    teamNames.add(name);
    scoreValues.add([0]);
    setState(() {});
  }

  deleteTeam(teamIndex) {
    HapticFeedback.vibrate();
    teamNames.removeAt(teamIndex);
    scoreValues.removeAt(teamIndex);
    setState(() {});
  }

  clearTeamScore(teamIndex) {
    HapticFeedback.vibrate();
    scoreValues[teamIndex] = [0];
    setState(() {});
  }

  undoLast(teamIndex) {
    HapticFeedback.vibrate();
    if (scoreValues[teamIndex].length > 1) {
      scoreValues[teamIndex].removeLast();
    }
    setState(() {});
  }

  getScores() {
    List<Widget> scores = [];
    var screenWidth = MediaQuery.of(context).size.width;
    var containerWidth =
        (screenWidth - 5 * teamNames.length - 30) / (teamNames.length + 1);
    for (int i = 0; i < teamNames.length; i++) {
      List<Widget> teamScores = [
        Container(
          height: 30,
          child: Center(
            child: AutoSizeText(
              teamNames[i],
              maxLines: 2,
              style: TextStyle(
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(height: 10),
        PageBreak(width: 50, color: Colors.grey),
        Container(
          height: 30,
          child: Center(
            child: AutoSizeText(
              scoreValues[i].reduce((a, b) => a + b).toString(),
              maxLines: 1,
              minFontSize: 6,
              style: TextStyle(fontSize: 22),
            ),
          ),
        ),
        SizedBox(height: 5),
        PageBreak(width: 50, color: Colors.grey),
      ];
      teamScores.add(GestureDetector(
        onTap: () {
          HapticFeedback.vibrate();
          showDialog<Null>(
            context: context,
            builder: (BuildContext context) {
              return AddScoreDialog(
                callback: addScoreToTeam,
                teamIndex: i,
              );
            },
          );
        },
        child: Icon(
          MdiIcons.plusBox,
          size: 30,
          color: Colors.cyan[700],
        ),
      ));
      teamScores.add(SizedBox(height: 10));
      var visibleScores = scoreValues[i];
      if (scoreValues[i].length > 10) {
        visibleScores = visibleScores.sublist(
            visibleScores.length - 11, visibleScores.length);
      }
      visibleScores.reversed.forEach((v) {
        teamScores.add(Container(
          height: 18,
          child: Center(
            child: AutoSizeText(
              (v == 0
                      ? ''
                      : v > 0
                          ? '+'
                          : '-') +
                  v.abs().toString(),
              style: TextStyle(
                fontSize: 18,
              ),
              minFontSize: 7,
              maxLines: 1,
            ),
          ),
        ));
        teamScores.add(SizedBox(height: 5));
      });
      teamScores.removeLast();
      teamScores.removeLast();
      scores.add(Container(
        width: containerWidth,
        height: 480,
        padding: EdgeInsets.fromLTRB(5, 15, 5, 10),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dialogBackgroundColor),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    children: teamScores,
                  ),
                  IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).canvasColor.withAlpha(0),
                            Theme.of(context).canvasColor.withAlpha(0),
                            Theme.of(context).canvasColor,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PageBreak(width: 30, color: Colors.grey),
            // buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: teamNames.length > 1
                          ? () {
                              HapticFeedback.vibrate();
                              showDialog<Null>(
                                context: context,
                                builder: (BuildContext context) {
                                  return ConfirmDialog(
                                      callback: deleteTeam,
                                      teamIndex: i,
                                      title: 'Delete team?');
                                },
                              );
                            }
                          : null,
                      child: Container(
                        height: 30,
                        width: 30,
                        child: Icon(
                          MdiIcons.delete,
                          size: 20,
                          color: teamNames.length > 1
                              ? Colors.red.withAlpha(190)
                              : Colors.grey.withAlpha(100),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: scoreValues[i].length > 1
                          ? () {
                              HapticFeedback.vibrate();
                              showDialog<Null>(
                                context: context,
                                builder: (BuildContext context) {
                                  return ConfirmDialog(
                                      callback: undoLast,
                                      teamIndex: i,
                                      title: 'Undo?');
                                },
                              );
                            }
                          : null,
                      child: Container(
                        height: 30,
                        width: 30,
                        child: Icon(
                          MdiIcons.undo,
                          size: 20,
                          color: scoreValues[i].length > 1
                              ? Colors.black.withAlpha(150)
                              : Colors.grey.withAlpha(100),
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: scoreValues[i].length > 1
                          ? () {
                              HapticFeedback.vibrate();
                              showDialog<Null>(
                                context: context,
                                builder: (BuildContext context) {
                                  return ConfirmDialog(
                                      callback: clearTeamScore,
                                      teamIndex: i,
                                      title: 'Clear team score?');
                                },
                              );
                            }
                          : null,
                      child: Container(
                        height: 30,
                        width: 30,
                        child: Icon(
                          MdiIcons.layersOff,
                          size: 20,
                          color: scoreValues[i].length > 1
                              ? Colors.orange.withAlpha(190)
                              : Colors.grey.withAlpha(100),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.vibrate();
                        showDialog<Null>(
                          context: context,
                          builder: (BuildContext context) {
                            return EditNameDialog(
                              callback: updateTeamName,
                              teamIndex: i,
                            );
                          },
                        );
                      },
                      child: Container(
                        height: 30,
                        width: 30,
                        child: Icon(
                          MdiIcons.pencil,
                          size: 20,
                          color: Colors.green.withAlpha(200),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ));
      scores.add(SizedBox(width: 5));
    }
    scores.add(Container(
      width: containerWidth,
      padding: EdgeInsets.fromLTRB(5, 15, 5, 15),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dialogBackgroundColor),
        borderRadius: BorderRadius.circular(5),
      ),
      child: GestureDetector(
          onTap: () {
            HapticFeedback.vibrate();
            showDialog<Null>(
              context: context,
              builder: (BuildContext context) {
                return AddTeamDialog(
                  callback: addTeam,
                );
              },
            );
          },
          child: Column(
            children: [
              Text(
                '(new team)',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 5),
              Icon(
                MdiIcons.plusBox,
                color: Colors.cyan[700].withAlpha(70),
                size: 40,
              ),
            ],
          )),
    ));
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: scores,
        ),
      ],
    );
  }

  toggleListen() async {
    if (!listening) {
      listening = true;
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        print('hey');
        _speech.listen(
          onResult: (val) => setState(() {
            transcription = val.recognizedWords;
            print(val.recognizedWords);
          }),
        );
        print('yo');
      } else {
        print("The user has denied the use of speech recognition.");
      }
    } else {
      _speech.stop();
      listening = false;
    }
    print('listening: $listening');
    setState(() {});
  }

  getGenieBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$listening', style: TextStyle(color: Colors.red)),
            Text(transcription != null ? transcription : 'nothing'),
          ],
        ),
        GestureDetector(
          onTap: () {
            toggleListen();
          },
          child: Container(
            width: 300,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [
                  listening ? Colors.cyan[200] : Colors.cyan[200],
                  listening ? Colors.cyan[500] : Colors.cyan[500],
                  listening ? Colors.cyan[200] : Colors.cyan[200],
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.4),
                  spreadRadius: listening ? 0 : 1,
                  blurRadius: listening ? 2 : 4,
                  offset: listening ? Offset(1, 1) : Offset(3, 3),
                ),
              ],
            ),
            child: Center(
              child: Shimmer.fromColors(
                period: Duration(seconds: 3),
                baseColor: Colors.white,
                highlightColor:
                    listening ? Colors.black.withAlpha(10) : Colors.white,
                child: Container(
                  width: 290,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).canvasColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: listening
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                MdiIcons.chevronDoubleRight,
                                color: Colors.white.withAlpha(200),
                                size: 30,
                              ),
                              Icon(
                                MdiIcons.microphone,
                                color: Colors.white.withAlpha(200),
                                size: 30,
                              ),
                              Icon(
                                MdiIcons.chevronDoubleLeft,
                                color: Colors.white.withAlpha(200),
                                size: 30,
                              ),
                            ],
                          )
                        : Icon(
                            MdiIcons.microphone,
                            color: Colors.white,
                            size: 30,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  getScoreboard() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        getScores(),
        getGenieBar(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.cyan[700],
          title: Text(
            'The Scoreboard',
          ),
        ),
        resizeToAvoidBottomPadding: false,
        body: getScoreboard());
  }
}

class AddScoreDialog extends StatefulWidget {
  AddScoreDialog({this.callback, this.teamIndex});

  final callback;
  final teamIndex;

  @override
  _AddScoreDialogState createState() => _AddScoreDialogState();
}

class _AddScoreDialogState extends State<AddScoreDialog> {
  TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return AlertDialog(
      title: Text('Add score'),
      contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
      content: Container(
        height: 100,
        width: width * 0.95,
        child: ListView(
          children: <Widget>[
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        Container(
          child: FlatButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        Container(
          child: FlatButton(
            onPressed: () {
              widget.callback(widget.teamIndex, controller.text);
              Navigator.of(context).pop();
            },
            child: Text(
              'Add',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class AddTeamDialog extends StatefulWidget {
  AddTeamDialog({this.callback});

  final callback;

  @override
  _AddTeamDialogState createState() => _AddTeamDialogState();
}

class _AddTeamDialogState extends State<AddTeamDialog> {
  TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return AlertDialog(
      title: Text('Add team'),
      contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
      content: Container(
        height: 100,
        width: width * 0.95,
        child: ListView(
          children: <Widget>[
            TextField(
              autofocus: true,
              controller: controller,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        Container(
          child: FlatButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        Container(
          child: FlatButton(
            onPressed: () {
              widget.callback(controller.text);
              Navigator.of(context).pop();
            },
            child: Text(
              'Add',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class EditNameDialog extends StatefulWidget {
  EditNameDialog({this.callback, this.teamIndex});

  final callback;
  final teamIndex;

  @override
  _EditNameDialogState createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<EditNameDialog> {
  TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit team name'),
      contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
      content: TextField(
        autofocus: true,
        controller: controller,
      ),
      actions: <Widget>[
        Container(
          child: FlatButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        Container(
          child: FlatButton(
            onPressed: () {
              widget.callback(widget.teamIndex, controller.text);
              Navigator.of(context).pop();
            },
            child: Text(
              'Save',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class ConfirmDialog extends StatefulWidget {
  ConfirmDialog({this.title, this.teamIndex, this.callback});

  final title;
  final teamIndex;
  final callback;

  @override
  _ConfirmDialogState createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<ConfirmDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
      actions: <Widget>[
        Container(
          child: FlatButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        Container(
          child: FlatButton(
            onPressed: () {
              widget.callback(widget.teamIndex);
              Navigator.of(context).pop();
            },
            child: Text(
              'Confirm',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.normal,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
