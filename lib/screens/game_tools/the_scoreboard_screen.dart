import 'package:flutter/material.dart';
import 'package:together/components/misc.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:shimmer/shimmer.dart';
import 'package:string_similarity/string_similarity.dart';

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
  String transcription = '';
  String lastError = '';
  String lastStatus = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  List<Widget> completedAction = [];

  addScoreToTeam(teamIndex, scoreString) {
    HapticFeedback.vibrate();
    // ensure score is number
    scoreString = scoreString.replaceAll("[^\\d]", "");
    int score = int.parse(scoreString);
    scoreValues[teamIndex].add(score);
    setState(() {});
  }

  String capitalize(String string) {
    if (string == null) {
      throw ArgumentError.notNull('string');
    }

    if (string.isEmpty) {
      return string;
    }

    return string[0].toUpperCase() + string.substring(1);
  }

  capitalizeName(String name) {
    var words = name.split(' ');
    var capitalizedWords = [];
    for (var i = 0; i < words.length; i++) {
      capitalizedWords.add(capitalize(words[i]));
    }
    return capitalizedWords.join(' ');
  }

  updateTeamName(teamIndex, name) {
    HapticFeedback.vibrate();
    teamNames[teamIndex] = capitalizeName(name);
    setState(() {});
  }

  addTeam(name) {
    HapticFeedback.vibrate();
    teamNames.add(capitalizeName(name));
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
                              ? Theme.of(context).highlightColor.withAlpha(150)
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

  void errorListener(SpeechRecognitionError error) {
    setState(() {
      lastError = "${error.errorMsg} - ${error.permanent}";
    });
  }

  void statusListener(String status) {
    setState(() {
      lastStatus = "$status";
    });
  }

  Future<void> initializeSpeech() async {
    bool hasSpeech = await _speech.initialize(
        onError: errorListener, onStatus: statusListener);
    if (hasSpeech) {
      // _localeNames = await speech.locales();

      // var systemLocale = await speech.systemLocale();
      // _currentLocaleId = systemLocale.localeId;
    }

    if (!mounted) return;

    setState(() {
      speechAvailable = hasSpeech;
    });
  }

  bool isInt(String s) {
    if (s == null) {
      return false;
    }
    return double.parse(s, (e) => null) != null;
  }

  pointsReferenceToInt(List pointsReference) {
    // need to do some cool stuff here
    // strip points if it exists
    if (pointsReference.last == 'points') {
      pointsReference.remove('points');
    }
    if (pointsReference.length > 1) {
      return null;
    }
    if (pointsReference.length == 1 && isInt(pointsReference[0])) {
      return int.parse(pointsReference[0]);
    }
    switch (pointsReference[0]) {
      case 'zero':
        return 0;
        break;
      case 'one':
      case 'won':
        return 1;
        break;
      case 'two':
      case 'too':
        return 2;
        break;
      case 'three':
        return 3;
        break;
      case 'four':
      case 'for':
        return 4;
        break;
      case 'five':
        return 5;
        break;
      case 'six':
        return 6;
      case 'seven':
        return 7;
      case 'eight':
      case 'ate':
        return 8;
        break;
      case '9':
        return 9;
        break;
    }
    return null;
  }

  sanitizeTeamName(String teamName) {
    teamName = teamName.replaceAll('0', 'zero');
    teamName = teamName.replaceAll('1', 'one');
    teamName = teamName.replaceAll('2', 'two');
    teamName = teamName.replaceAll('3', 'three');
    teamName = teamName.replaceAll('4', 'four');
    teamName = teamName.replaceAll('5', 'five');
    teamName = teamName.replaceAll('6', 'six');
    teamName = teamName.replaceAll('7', 'seven');
    teamName = teamName.replaceAll('8', 'eight');
    return teamName.toLowerCase();
  }

  teamReferenceToIndex(String teamReference) {
    // team reference could be team index, or team name.
    // need to not allow team name to be exactly one of these key words
    int number;
    switch (teamReference) {
      case 'zero':
      case '0':
        number = 0;
        break;
      case 'one':
      case '1':
      case 'won':
        number = 1;
        break;
      case 'two':
      case 'too':
      case '2':
        number = 2;
        break;
      case 'three':
      case '3':
        number = 3;
        break;
      case 'four':
      case 'for':
      case '4':
        number = 4;
        break;
      case 'five':
      case '5':
        number = 5;
        break;
      case 'six':
      case '6':
        number = 6;
        break;
      case 'seven':
      case '7':
        number = 7;
        break;
      case 'eight':
      case '8':
        number = 8;
        break;
    }
    if (number != null) {
      return number - 1;
    } else {
      // compare against all team names, record highest match
      // if match is higher than some basic threshold, return team index
      double match = 0;
      int bestMatchIndex;
      teamNames.asMap().forEach((i, v) {
        var tempMatch = StringSimilarity.compareTwoStrings(
            sanitizeTeamName(v), sanitizeTeamName(teamReference));
        print('$v $teamReference $tempMatch');
        if (tempMatch > match) {
          match = tempMatch;
          bestMatchIndex = i;
        }
      });
      if (match > 0.5) {
        // good enough match
        return bestMatchIndex;
      } else {
        return null;
      }
    }
  }

  computeCommand() {
    // possible actions: add team {x}, remove/delete team {x}, edit/rename team {x},
    //   add {x} to {y}, remove/subtract {x} from {y}
    //   clear {x}, undo {x}

    // split by all 'and's and foreach them
    List commands = transcription.toLowerCase().split('and');

    commands.forEach((command) {
      List words = command.split(' ');
      if (words[0] == '') {
        words.removeAt(0);
      }
      int toIndex = words.indexOf('to');
      int fromIndex = words.indexOf('from');
      if (words[0] == 'add' && words[1] == 'team') {
        String teamName = words.sublist(2).join(' ');
        addTeam(teamName);
        completedAction = [
          ActionText(text: 'Added team ', color: Colors.blue),
          ActionText(text: teamName, color: Colors.white),
        ];
      } else if (['remove', 'delete'].contains(words[0]) &&
          words[1] == 'team') {
        String teamReference = words.sublist(2).join(' ');
        int teamIndex = teamReferenceToIndex(teamReference);
        if (teamIndex != null) {
          completedAction = [
            ActionText(text: 'Removed team ', color: Colors.blue),
            ActionText(text: '${teamNames[teamIndex]}', color: Colors.white),
          ];
          deleteTeam(teamIndex);
        } else {
          completedAction = [
            ActionText(text: 'Invalid team reference: ', color: Colors.red),
            ActionText(text: teamReference, color: Colors.white),
          ];
        }
      } else if (['edit', 'rename'].contains(words[0]) &&
          words[1] == 'team' &&
          words.contains('to') &&
          words.indexOf('to') < words.length - 1) {
        int toIndex = words.indexOf('to');
        String teamReference = words.sublist(2, toIndex).join(' ');
        int teamIndex = teamReferenceToIndex(teamReference);
        String teamName = words.sublist(toIndex + 1).join(' ');
        if (teamIndex != null) {
          completedAction = [
            ActionText(text: 'Edited team name ', color: Colors.blue),
            ActionText(text: '${teamNames[teamIndex]} ', color: Colors.white),
            ActionText(
              text: 'to ',
              color: Colors.grey,
            ),
            ActionText(text: teamName),
          ];
          updateTeamName(teamIndex, teamName);
        } else {
          completedAction = [
            ActionText(text: 'Invalid team reference: ', color: Colors.red),
            ActionText(text: teamReference, color: Colors.white),
          ];
        }
      } else if (['give', 'add'].contains(words[0]) &&
          toIndex != -1 &&
          toIndex < words.length - 1) {
        List pointsReference = words.sublist(1, toIndex);
        int points = pointsReferenceToInt(pointsReference);
        String teamReference = words.sublist(toIndex + 1).join(' ');
        int teamIndex = teamReferenceToIndex(teamReference);
        if (points == null) {
          completedAction = [
            ActionText(text: 'Can\'t parse amount: ', color: Colors.red),
            ActionText(text: pointsReference.join(' '), color: Colors.white),
          ];
        } else if (teamIndex != null) {
          completedAction = [
            ActionText(text: 'Added ', color: Colors.blue),
            ActionText(text: '$points ', color: Colors.white),
            ActionText(text: 'points ', color: Colors.blue),
            ActionText(text: 'to ', color: Colors.grey),
            ActionText(text: '${teamNames[teamIndex]}', color: Colors.white),
          ];
          addScoreToTeam(teamIndex, points.toString());
        } else {
          completedAction = [
            ActionText(text: 'Invalid team reference: ', color: Colors.red),
            ActionText(text: teamReference, color: Colors.white),
          ];
        }
      } else if (['subtract', 'remove'].contains(words[0]) &&
          fromIndex != -1 &&
          fromIndex < words.length - 1) {
        List pointsReference = words.sublist(1, fromIndex);
        int points = pointsReferenceToInt(pointsReference);
        String teamReference = words.sublist(fromIndex + 1).join(' ');
        int teamIndex = teamReferenceToIndex(teamReference);
        if (teamIndex != null) {
          completedAction = [
            ActionText(text: 'Removed ', color: Colors.blue),
            ActionText(text: '$points ', color: Colors.white),
            ActionText(text: 'points ', color: Colors.blue),
            ActionText(text: 'from ', color: Colors.grey),
            ActionText(text: '${teamNames[teamIndex]}', color: Colors.white),
          ];
          addScoreToTeam(teamIndex, '-' + points.toString());
        } else {
          completedAction = [
            ActionText(text: 'Invalid team reference: ', color: Colors.red),
            ActionText(text: teamReference, color: Colors.white),
          ];
        }
      } else if (['clear', 'reset'].contains(words[0])) {
        String teamReference = words.sublist(1).join(' ');
        int teamIndex = teamReferenceToIndex(teamReference);
        if (teamIndex != null) {
          completedAction = [
            ActionText(text: 'Cleared ', color: Colors.blue),
            ActionText(text: '${teamNames[teamIndex]}', color: Colors.white),
          ];
          clearTeamScore(teamIndex);
        } else {
          completedAction = [
            ActionText(text: 'Invalid team reference: ', color: Colors.red),
            ActionText(text: teamReference, color: Colors.white),
          ];
        }
      } else if (['undo'].contains(words[0])) {
        String teamReference = words.sublist(1).join(' ');
        int teamIndex = teamReferenceToIndex(teamReference);
        if (teamIndex != null) {
          completedAction = [
            ActionText(text: 'Undid one for ', color: Colors.blue),
            ActionText(text: '${teamNames[teamIndex]}', color: Colors.white),
          ];
          undoLast(teamIndex);
        } else {
          completedAction = [
            ActionText(text: 'Invalid team reference: ', color: Colors.red),
            ActionText(text: teamReference, color: Colors.white),
          ];
        }
      } else {
        completedAction = [
          ActionText(text: 'Invalid command. ', color: Colors.red),
          ActionText(
              text: 'Check info for available commands.', color: Colors.white),
        ];
      }

      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Row(children: completedAction),
        backgroundColor: Colors.black,
        duration: Duration(seconds: 3),
      ));
    });
  }

  toggleListen() async {
    if (!listening) {
      listening = true;
      transcription = '';
      setState(() {});
      if (!speechAvailable) {
        await initializeSpeech();
      }
      if (speechAvailable) {
        _speech.listen(
          onResult: (val) => setState(() {
            transcription = val.recognizedWords;
          }),
        );
      } else {
        print('Speech recognition is not available.');
      }
    } else {
      _speech.stop();
      listening = false;
      computeCommand();
    }
    setState(() {});
  }

  getGenieBar() {
    return Column(
      children: [
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
        SizedBox(height: 5),
        transcription == ''
            ? Text('')
            : Container(
                width: 250,
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).highlightColor),
                  borderRadius: BorderRadius.circular(10),
                  // color: Theme.of(context).dialogBackgroundColor,
                ),
                padding: EdgeInsets.all(10),
                child: AutoSizeText(
                  transcription.toLowerCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: listening
                        ? Colors.grey
                        : Theme.of(context).highlightColor,
                  ),
                  minFontSize: 10,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
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
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        body: getScoreboard());
  }
}

class ActionText extends StatelessWidget {
  final String text;
  final Color color;

  ActionText({this.text, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: color == null ? TextStyle() : TextStyle(color: color),
    );
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
