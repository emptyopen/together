import 'package:flutter/material.dart';
import 'package:together/components/misc.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:flutter/services.dart';
import 'package:together/services/speech_recognition_service.dart';

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
  SpeechRecognitionService speechRecognitionService;
  bool listening = false;

  @override
  initState() {
    super.initState();
    setupScoreboard();
  }

  setupScoreboard() async {
    await speechRecognitionService.initSpeech();
  }

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
    for (int i = 0; i < teamNames.length; i++) {
      List<Widget> teamScores = [
        Text(
          teamNames[i],
          style: TextStyle(
            fontSize: 22,
          ),
        ),
        SizedBox(height: 10),
        PageBreak(width: 50),
        Text(
          scoreValues[i].reduce((a, b) => a + b).toString(),
          style: TextStyle(fontSize: 22),
        ),
        SizedBox(height: 5),
        PageBreak(width: 50),
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
        teamScores.add(Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              v == 0
                  ? ''
                  : v > 0
                      ? '+'
                      : '-',
              style: TextStyle(
                fontSize: v > 0 ? 11 : 14,
              ),
            ),
            Text(
              v.abs().toString(),
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          ],
        ));
        teamScores.add(SizedBox(height: 5));
      });
      teamScores.removeLast();
      teamScores.removeLast();
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  print('delete team');
                },
                child: Container(
                  height: 30,
                  width: 30,
                  child: GestureDetector(
                    onTap: () {},
                    child: Icon(
                      MdiIcons.delete,
                      size: 20,
                      color: Colors.red.withAlpha(190),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  print('undo');
                },
                child: Container(
                  height: 30,
                  width: 30,
                  child: GestureDetector(
                    onTap: () {},
                    child: Icon(
                      MdiIcons.undo,
                      size: 20,
                      color: Theme.of(context).highlightColor.withAlpha(150),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  print('clear list');
                },
                child: Container(
                  height: 30,
                  width: 30,
                  child: GestureDetector(
                    onTap: () {},
                    child: Icon(
                      MdiIcons.layersOff,
                      size: 20,
                      color: Colors.orange.withAlpha(190),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  print('rename team');
                },
                child: Container(
                  height: 30,
                  width: 30,
                  child: GestureDetector(
                    onTap: () {},
                    child: Icon(
                      MdiIcons.pencil,
                      size: 20,
                      color: Colors.green.withAlpha(200),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
      scores.add(Container(
        width: 90,
        height: 460,
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
            PageBreak(width: 30),
            // buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
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
                      },
                      child: Container(
                        height: 30,
                        width: 30,
                        child: Icon(
                          MdiIcons.delete,
                          size: 20,
                          color: Colors.red.withAlpha(190),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
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
                      },
                      child: Container(
                        height: 30,
                        width: 30,
                        child: Icon(
                          MdiIcons.undo,
                          size: 20,
                          color: Colors.black.withAlpha(150),
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
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
                      },
                      child: Container(
                        height: 30,
                        width: 30,
                        child: Icon(
                          MdiIcons.layersOff,
                          size: 20,
                          color: Colors.orange.withAlpha(190),
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
    }
    scores.add(GestureDetector(
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
              color: Colors.cyan[700],
            ),
          ],
        )));
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
      speechRecognitionService.startListening();
      listening = true;
    } else {
      speechRecognitionService.stopListening();
      listening = false;
    }
    print('listening: $listening');
    setState(() {});
  }

  getScoreboard() {
    final Shader linearGradient = LinearGradient(
      colors: <Color>[
        Colors.white,
        Colors.white,
      ],
    ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 200.0));
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        getScores(),
        GestureDetector(
          onTap: () {
            toggleListen();
          },
          child: Container(
            width: 300,
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).highlightColor),
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [
                  Colors.cyan[500].withAlpha(100),
                  Colors.cyan[500].withAlpha(200),
                  Colors.cyan[500].withAlpha(100),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 290,
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).canvasColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'your wish is my command',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'SyneMono',
                      foreground: Paint()..shader = linearGradient,
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
