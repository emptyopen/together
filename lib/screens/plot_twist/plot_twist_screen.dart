import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import 'package:together/services/services.dart';
import 'package:together/services/firestore.dart';
import 'package:together/help_screens/help_screens.dart';
import 'package:together/components/end_game.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:together/components/buttons.dart';
import 'package:together/components/scroll_view.dart';

import 'plot_twist_services.dart';
import 'plot_twist_components.dart';

class PlotTwistScreen extends StatefulWidget {
  PlotTwistScreen({this.sessionId, this.userId, this.roomCode});

  final String sessionId;
  final String userId;
  final String roomCode;

  @override
  _PlotTwistScreenState createState() => _PlotTwistScreenState();
}

class _PlotTwistScreenState extends State<PlotTwistScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool isSpectator = false;
  TextEditingController messageController;
  TextEditingController createCharacterNameController;
  TextEditingController createCharacterAgeController;
  TextEditingController createCharacterDescriptionController;
  List<bool> collapseSampleCharacter = [false, false];
  String characterSelection;
  // vibrate states
  bool allDone = false;
  int chatLength = 0;
  var T;

  @override
  void initState() {
    super.initState();
    messageController = TextEditingController();
    createCharacterNameController = TextEditingController();
    createCharacterAgeController = TextEditingController();
    createCharacterDescriptionController = TextEditingController();
    T = Transactor(sessionId: widget.sessionId);
    setUpGame();
  }

  @override
  void dispose() {
    messageController.dispose();
    createCharacterNameController.dispose();
    createCharacterAgeController.dispose();
    createCharacterDescriptionController.dispose();
    super.dispose();
  }

  checkIfVibrate(data) {
    bool isNewVibrateData = false;

    bool newAllDone = true;
    data['readyToEnd'].forEach((i, v) {
      if (v) {
        newAllDone = false;
      }
    });
    if (newAllDone != allDone && data['narrators'].contains(widget.userId)) {
      allDone = newAllDone;
      isNewVibrateData = true;
    }

    if (chatLength != data['texts'].length) {
      chatLength = data['texts'].length;
      isNewVibrateData = true;
    }

    if (isNewVibrateData) {
      HapticFeedback.vibrate();
    }
  }

  setUpGame() async {
    // get session info for locations
    var data = (await FirebaseFirestore.instance
            .collection('sessions')
            .doc(widget.sessionId)
            .get())
        .data();
    setState(() {
      isSpectator = data['spectatorIds'].contains(widget.userId);
    });
  }

  getChatBoxes(data) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;
    List<Widget> chatboxes = [];
    String lastPlayer = 'narrator';
    data['texts'].reversed.forEach((v) {
      String alignment = 'left';
      bool isRepeated = lastPlayer == v['playerId'];
      bool isNarrator = false;
      if (data['narrators'].contains(v['playerId'])) {
        alignment = 'center';
        isNarrator = true;
      } else if (widget.userId == v['playerId']) {
        alignment = 'right';
      }
      chatboxes.add(
        Chatbox(
          text: v['text'],
          timestamp: v['timestamp'].toString(),
          person: data['characters'][v['playerId']]['name'],
          alignment: alignment,
          backgroundColor: getPlayerColor(v['playerId'], data),
          fontColor: Colors.white,
          suppressName: isRepeated,
          isNarrator: isNarrator,
        ),
      );
      lastPlayer = v['playerId'];
    });
    return Container(
        width: screenWidth * 0.8,
        height: screenHeight * 0.5,
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).highlightColor,
          ),
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).dialogBackgroundColor,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.grey,
            ),
          ),
          padding: EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: chatboxes,
            ),
          ),
        ));
  }

  getInputBox(data) {
    var screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth * 0.8,
      height: 90,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).highlightColor,
        ),
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).dialogBackgroundColor,
      ),
      child: Row(
        children: [
          Container(
            height: 70,
            width: screenWidth * 0.8 - 20 - 50 - 15,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.grey,
              ),
            ),
            padding: EdgeInsets.fromLTRB(10, 2, 10, 2),
            child: TextField(
              maxLines: null,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintText: 'type here',
              ),
              controller: messageController,
            ),
          ),
          SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              sendMessage(data);
            },
            child: Container(
              width: 50,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(colors: [
                  Colors.blue,
                  Colors.lightBlue,
                ]),
                border: Border.all(
                  color: Colors.grey,
                ),
              ),
              child: Icon(MdiIcons.send),
            ),
          ),
        ],
      ),
    );
  }

  sendMessage(data) async {
    if (messageController.text == '') {
      return;
    }

    var message = {
      'playerId': widget.userId,
      'text': messageController.text,
      'timestamp': DateTime.now(),
    };

    T.transactPlotTwistMessage(message);

    messageController.text = '';
    FocusScope.of(context).unfocus();
    HapticFeedback.vibrate();
  }

  getSampleCharacters(data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        getSampleCharacterTile(0, data),
        SizedBox(width: 10),
        getSampleCharacterTile(1, data),
      ],
    );
  }

  getSampleCharacterTile(index, data) {
    var sampleCharacterNames = data['sampleCharacters'][widget.userId];
    var sampleCharacter = exampleCharacters[sampleCharacterNames[index]];

    bool highlighted = characterSelection == 'sample$index';

    return GestureDetector(
      onTap: () async {
        closeKeyboardIfOpen(context);
        if (collapseSampleCharacter[index] == false) {
          collapseSampleCharacter[index] = !collapseSampleCharacter[index];
        } else if (characterSelection != 'sample$index') {
          characterSelection = 'sample$index';
        } else {
          characterSelection = null;
        }
        setState(() {});
        HapticFeedback.vibrate();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: highlighted ? Colors.blue : Theme.of(context).highlightColor,
            width: highlighted ? 3 : 1,
          ),
        ),
        padding: EdgeInsets.all(highlighted ? 3 : 5),
        child: Container(
          width: 150,
          child: Column(
            children: [
              Text(
                'Name: ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                sampleCharacter['name'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
              collapseSampleCharacter[index]
                  ? Column(
                      children: [
                        SizedBox(height: 5),
                        Text(
                          'Age: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          sampleCharacter['age'].toString(),
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Description: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          sampleCharacter['description'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }

  getCreateCharacter(data) {
    return GestureDetector(
      onTap: () {
        if (characterSelection != 'create') {
          characterSelection = 'create';
        } else {
          characterSelection = null;
        }

        setState(() {});
      },
      child: Container(
        constraints: BoxConstraints(maxWidth: 240),
        padding: EdgeInsets.all(characterSelection == 'create' ? 6 : 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: characterSelection == 'create'
                ? Colors.blue
                : Theme.of(context).highlightColor,
            width: characterSelection == 'create' ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Name:'),
            Container(
              height: 30,
              width: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Center(
                child: TextField(
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: 'name here',
                  ),
                  style: TextStyle(
                    fontSize: 14,
                  ),
                  controller: createCharacterNameController,
                ),
              ),
            ),
            SizedBox(height: 10),
            Text('Age:'),
            Container(
              height: 30,
              width: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Center(
                child: TextFormField(
                  maxLines: 1,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: 'XX',
                  ),
                  style: TextStyle(
                    fontSize: 14,
                  ),
                  controller: createCharacterAgeController,
                ),
              ),
            ),
            SizedBox(height: 10),
            Text('Description:'),
            Container(
              height: 70,
              width: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              child: TextField(
                maxLines: null,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hintText: 'description here',
                ),
                style: TextStyle(
                  fontSize: 11,
                ),
                controller: createCharacterDescriptionController,
              ),
            ),
          ],
        ),
      ),
    );
  }

  setCharacter(data) async {
    // save character
    if (characterSelection == 'create') {
      print('saving custom character');
      data['characters'][widget.userId] = {
        'name': createCharacterNameController.text,
        'age': createCharacterAgeController.text,
        'description': createCharacterDescriptionController.text,
      };
    } else if (characterSelection == 'sample0') {
      print('saving 0');
      var sampleCharacterNames = data['sampleCharacters'][widget.userId];
      var sampleCharacter = exampleCharacters[sampleCharacterNames[0]];
      data['characters'][widget.userId] = {
        'name': sampleCharacter['name'],
        'age': sampleCharacter['age'],
        'description': sampleCharacter['description'],
      };
    } else {
      print('saving 1');
      var sampleCharacterNames = data['sampleCharacters'][widget.userId];
      var sampleCharacter = exampleCharacters[sampleCharacterNames[1]];
      data['characters'][widget.userId] = {
        'name': sampleCharacter['name'],
        'age': sampleCharacter['age'],
        'description': sampleCharacter['description'],
      };
    }

    // check if everyone is done, if so change internal state to chat
    bool allPlayersSelectedCharacter = true;
    data['playerIds'].forEach((v) {
      if (!data['characters'].containsKey(v)) {
        allPlayersSelectedCharacter = false;
      }
    });
    if (allPlayersSelectedCharacter) {
      data['internalState'] = 'chat';
    }

    T.transact(data);
  }

  getCharacterSelection(data) {
    // if narrator, show waiting screen with narrator
    if (data['narrators'].contains(widget.userId)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'You are a narrator!',
              style: TextStyle(
                fontSize: 30,
              ),
            ),
            SizedBox(height: 30),
            Text(
              'Waiting on the others\nto pick characters...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            SizedBox(height: 20),
            widget.userId == data['leader']
                ? EndGameButton(
                    sessionId: widget.sessionId,
                    fontSize: 14,
                    height: 30,
                    width: 100,
                  )
                : Container(),
          ],
        ),
      );
    }
    // if already selected, show waiting screen with selected character
    if (data['characters'].containsKey(widget.userId)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Waiting on others...',
              style: TextStyle(
                fontSize: 30,
              ),
            ),
            SizedBox(height: 30),
            Text(
              'Get into character while you wait!',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            SizedBox(height: 50),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).highlightColor,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              padding: EdgeInsets.all(15),
              width: 240,
              child: Column(
                children: [
                  Text(
                    'Name:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    data['characters'][widget.userId]['name'],
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Age:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '${data['characters'][widget.userId]['age']}',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Description:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    data['characters'][widget.userId]['description'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            widget.userId == data['leader']
                ? EndGameButton(
                    sessionId: widget.sessionId,
                    fontSize: 14,
                    height: 30,
                    width: 100,
                  )
                : Container(),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: () {
        closeKeyboardIfOpen(context);
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Character Selection',
              style: TextStyle(
                fontSize: 30,
              ),
            ),
            Text('Create or pick your character!'),
            SizedBox(height: 20),
            Text(
              'Create',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 5),
            getCreateCharacter(data),
            SizedBox(height: 20),
            Text(
              'Pick',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 5),
            getSampleCharacters(data),
            SizedBox(height: 20),
            RaisedGradientButton(
              child: Text(
                'Confirm',
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
              height: 50,
              width: 120,
              gradient: LinearGradient(
                  colors: characterSelection != null
                      ? [
                          Colors.blue,
                          Colors.lightBlue,
                        ]
                      : [
                          Colors.grey,
                          Colors.grey,
                        ]),
              onPressed: characterSelection != null
                  ? () {
                      setCharacter(data);
                    }
                  : null,
            ),
            SizedBox(height: 20),
            widget.userId == data['leader']
                ? EndGameButton(
                    sessionId: widget.sessionId,
                    fontSize: 14,
                    height: 30,
                    width: 100,
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  toggleReadyToEnd(data) async {
    data['readyToEnd'][widget.userId] = !data['readyToEnd'][widget.userId];

    T.transact(data);
  }

  getGameboard(data) {
    bool allReadyToEnd = true;
    data['readyToEnd'].forEach((i, v) {
      if (v) {
        allReadyToEnd = false;
      }
    });
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              data['rules']['location'],
              style: TextStyle(
                fontSize: 24,
              ),
            ),
            SizedBox(height: 10),
            getInputBox(data),
            SizedBox(height: 10),
            getChatBoxes(data),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RaisedGradientButton(
                  child: Text(
                    'Character\nDescriptions',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  height: 50,
                  width: 110,
                  onPressed: () {
                    showDialog<Null>(
                      context: context,
                      builder: (BuildContext context) {
                        return CharacterDescriptionsDialog(
                          userId: widget.userId,
                          data: data,
                        );
                      },
                    );
                  },
                  gradient: LinearGradient(colors: [
                    Colors.blue,
                    Colors.blueAccent,
                  ]),
                ),
                SizedBox(width: 20),
                RaisedGradientButton(
                  child: Text(
                    'Matching',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  height: 50,
                  width: 100,
                  onPressed: () {
                    showDialog<Null>(
                      context: context,
                      builder: (BuildContext context) {
                        return CharactersDialog(
                          data: data,
                          sessionId: widget.sessionId,
                          userId: widget.userId,
                        );
                      },
                    );
                  },
                  gradient: LinearGradient(
                    colors: [Colors.pink, Colors.pinkAccent],
                  ),
                ),
                SizedBox(width: 20),
                !data['narrators'].contains(widget.userId)
                    ? RaisedGradientButton(
                        child: Text(
                          'Ready\nto end',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        height: 50,
                        width: 80,
                        onPressed: () {
                          toggleReadyToEnd(data);
                        },
                        gradient: LinearGradient(
                          colors: data['readyToEnd'][widget.userId]
                              ? [Colors.purple, Colors.purpleAccent]
                              : [Colors.grey, Colors.grey],
                        ),
                      )
                    : RaisedGradientButton(
                        child: Text(
                          'Game Status',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        gradient: LinearGradient(
                          colors: allReadyToEnd
                              ? [Colors.purple, Colors.purple[300]]
                              : [Colors.green, Colors.green[300]],
                        ),
                        height: 50,
                        width: 80,
                        onPressed: () {
                          showDialog<Null>(
                            context: context,
                            builder: (BuildContext context) {
                              return GameStateDialog(
                                data: data,
                              );
                            },
                          );
                        },
                      ),
              ],
            ),
            SizedBox(height: 20),
            widget.userId == data['leader']
                ? EndGameButton(
                    sessionId: widget.sessionId,
                    fontSize: 14,
                    height: 30,
                    width: 100,
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  getScoreboard(data) {
    return Column(
      children: [
        Text('Scoreboard'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .doc(widget.sessionId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  'Plot Twist',
                ),
              ),
              body: Container(),
            );
          }
          // all data for all components
          DocumentSnapshot snapshotData = snapshot.data;
          var data = snapshotData.data();
          if (data == null) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  'Plot Twist',
                ),
              ),
              body: Container(),
            );
          }
          checkIfExit(data, context, widget.sessionId, widget.roomCode);
          checkIfVibrate(data);
          return Scaffold(
            key: _scaffoldKey,
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              title: Text(
                'Plot Twist',
              ),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.info),
                  onPressed: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (BuildContext context, _, __) {
                          return PlotTwistScreenHelp();
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
            body: data['internalState'] == 'characterSelection'
                ? getCharacterSelection(data)
                : data['internalState'] == 'chat'
                    ? getGameboard(data)
                    : getScoreboard(data),
          );
        });
  }
}
