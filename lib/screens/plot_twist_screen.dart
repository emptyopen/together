import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:together/services/services.dart';
import 'package:together/help_screens/help_screens.dart';
import 'lobby_screen.dart';
import 'package:together/components/end_game.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../services/plot_twist_services.dart';
import 'package:together/components/buttons.dart';

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

  @override
  void initState() {
    super.initState();
    messageController = TextEditingController();
    createCharacterNameController = TextEditingController();
    createCharacterAgeController = TextEditingController();
    createCharacterDescriptionController = TextEditingController();
    setUpGame();
  }

  @override
  void dispose() {
    messageController.dispose();
    createCharacterNameController = TextEditingController();
    createCharacterAgeController = TextEditingController();
    createCharacterDescriptionController = TextEditingController();
    super.dispose();
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
          .setData(data);
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
    var data = (await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .get())
        .data;
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
    // TODO: add some kind of retry logic for clashes

    if (messageController.text == '') {
      return;
    }

    var message = {
      'playerId': widget.userId,
      'text': messageController.text,
      'timestamp': DateTime.now(),
    };

    data['texts'].add(message);

    messageController.text = '';

    FocusScope.of(context).unfocus();

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);

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

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
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

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
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
        stream: Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
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
          var data = snapshotData.data;
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
          checkIfExit(data);
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
                    // HapticFeedback.heavyImpact();
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

class Chatbox extends StatelessWidget {
  final String text;
  final String person;
  final String timestamp;
  final String alignment;
  final Color backgroundColor;
  final Color fontColor;
  final bool suppressName;
  final bool isNarrator;

  Chatbox({
    this.text,
    this.person,
    this.timestamp,
    this.alignment,
    this.backgroundColor,
    this.fontColor,
    this.suppressName = false,
    this.isNarrator = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Column(
        children: [
          isNarrator ? SizedBox(height: 10) : Container(),
          isNarrator
              ? Text(
                  'Narrator',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                )
              : Container(),
          isNarrator ? SizedBox(height: 5) : Container(),
          suppressName || isNarrator
              ? Container()
              : Row(
                  children: [
                    ['center', 'right'].contains(alignment)
                        ? Spacer()
                        : Container(),
                    Text(
                      person,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).highlightColor.withAlpha(200),
                      ),
                    ),
                    ['center', 'left'].contains(alignment)
                        ? Spacer()
                        : Container(),
                  ],
                ),
          suppressName || isNarrator ? Container() : SizedBox(height: 2),
          Row(
            children: [
              ['center', 'right'].contains(alignment) ? Spacer() : Container(),
              Container(
                padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                constraints: BoxConstraints(maxWidth: 200),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(5),
                  color: backgroundColor,
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: fontColor,
                    fontSize: 12,
                  ),
                ),
              ),
              ['center', 'left'].contains(alignment) ? Spacer() : Container(),
            ],
          ),
        ],
      ),
    );
  }
}

class CharactersDialog extends StatefulWidget {
  CharactersDialog({this.data, this.sessionId, this.userId});

  final data;
  final String sessionId;
  final String userId;

  @override
  _CharactersDialogState createState() => _CharactersDialogState();
}

class _CharactersDialogState extends State<CharactersDialog> {
  int selectedCharacterIndex;
  int selectedPlayerIndex;

  matchColors(otherPlayers) {
    if (selectedCharacterIndex != null && selectedPlayerIndex != null) {
      print('updating color');
      widget.data['matchingGuesses'][widget.userId]
              [otherPlayers[selectedPlayerIndex]] =
          widget.data['playerColors'][otherPlayers[selectedCharacterIndex]];
      // iterate over other colors and set same colors to grey
      widget.data['playerIds'].forEach((v) {
        // not selected player, and colors match
        if (v != otherPlayers[selectedPlayerIndex] &&
            widget.data['matchingGuesses'][widget.userId][v] ==
                widget.data['playerColors']
                    [otherPlayers[selectedCharacterIndex]]) {
          print('found: $v');
          widget.data['matchingGuesses'][widget.userId][v] = null;
        }
      });
      selectedCharacterIndex = null;
      selectedPlayerIndex = null;
    }
  }

  getCharacterTiles() {
    List otherPlayers = List.from(widget.data['playerIds']);
    otherPlayers.remove(widget.userId);
    return Container(
      height: 90.0 * (widget.data['playerIds'].length ~/ 3),
      width: 100,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).highlightColor,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: GridView.count(
        crossAxisCount: 3,
        children: List.generate(otherPlayers.length, (index) {
          return GestureDetector(
            onTap: () async {
              if (selectedCharacterIndex != index) {
                selectedCharacterIndex = index;
              } else {
                selectedCharacterIndex = null;
              }

              // check if character and player is selected, if so set player color (and clear the color elsewhere)
              matchColors(otherPlayers);

              setState(() {});

              await Firestore.instance
                  .collection('sessions')
                  .document(widget.sessionId)
                  .setData(widget.data);
            },
            child: Center(
              child: Container(
                height: 75,
                width: 75,
                padding:
                    EdgeInsets.all(selectedCharacterIndex == index ? 6 : 8),
                decoration: BoxDecoration(
                  color: getPlayerColor(otherPlayers[index], widget.data),
                  border: Border.all(
                    width: selectedCharacterIndex == index ? 3 : 1,
                    color: selectedCharacterIndex == index
                        ? Colors.blue
                        : Theme.of(context).highlightColor,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  child: AutoSizeText(
                    widget.data['characters'][otherPlayers[index]]['name'],
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    minFontSize: 5,
                    maxFontSize: 13,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  getPlayerTiles() {
    List otherPlayers = List.from(widget.data['playerIds']);
    otherPlayers.remove(widget.userId);
    return Container(
      height: 90.0 * (widget.data['playerIds'].length ~/ 3),
      width: 100,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).highlightColor,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: GridView.count(
        crossAxisCount: 3,
        children: List.generate(otherPlayers.length, (index) {
          Color color = Colors.grey;
          if (widget.data['matchingGuesses'][widget.userId]
                  [otherPlayers[index]] !=
              null) {
            color = stringToColor(widget.data['matchingGuesses'][widget.userId]
                [otherPlayers[index]]);
          }
          return GestureDetector(
            onTap: () async {
              if (selectedPlayerIndex != index) {
                selectedPlayerIndex = index;
              } else {
                selectedPlayerIndex = null;
              }

              // check if character and player is selected, if so set player color (and clear the color elsewhere)
              matchColors(otherPlayers);

              setState(() {});

              await Firestore.instance
                  .collection('sessions')
                  .document(widget.sessionId)
                  .setData(widget.data);
            },
            child: Center(
              child: Container(
                height: 75,
                width: 75,
                padding: EdgeInsets.all(selectedPlayerIndex == index ? 6 : 8),
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(
                    width: selectedPlayerIndex == index ? 3 : 1,
                    color: selectedPlayerIndex == index
                        ? Colors.blue
                        : Theme.of(context).highlightColor,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  child: Text(
                    widget.data['playerNames'][otherPlayers[index]],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return AlertDialog(
      title: Text('Match players to characters!'),
      contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
      content: Container(
        height: 160 + 180.0 * (widget.data['playerIds'].length ~/ 3),
        width: width * 0.95,
        child: ListView(
          children: <Widget>[
            SizedBox(height: 20),
            Text(
              'Characters:',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            SizedBox(height: 5),
            getCharacterTiles(),
            SizedBox(height: 20),
            Text(
              'Players:',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            SizedBox(height: 5),
            getPlayerTiles(),
            SizedBox(height: 20),
            Text(
              '(Click a character and then a player to match colors)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
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
              'OK',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class CharacterDescriptionsDialog extends StatefulWidget {
  CharacterDescriptionsDialog({this.data, this.userId});

  final data;
  final userId;

  @override
  _CharacterDescriptionsDialogState createState() =>
      _CharacterDescriptionsDialogState();
}

class _CharacterDescriptionsDialogState
    extends State<CharacterDescriptionsDialog> {
  getCharacterFromPlayer(player) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).highlightColor),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
      child: widget.data['narrators'].contains(player)
          ? Column(
              children: [
                Text(
                  'Narrator',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
                Row(),
              ],
            )
          : Column(
              children: [
                Text(
                  'Name:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  widget.data['characters'][player]['name'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 5,
                      width: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: getPlayerColor(player, widget.data),
                      ),
                    ),
                    SizedBox(width: 30),
                    Column(
                      children: [
                        Text(
                          'Age:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          "${widget.data['characters'][player]['age']}",
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 30),
                    Container(
                      height: 5,
                      width: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: getPlayerColor(player, widget.data),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Description:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  widget.data['characters'][player]['description'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
    );
  }

  getOtherCharacters() {
    List<Widget> others = [];

    var otherPlayers = List.from(widget.data['playerIds']);
    otherPlayers.remove(widget.userId);

    otherPlayers.forEach((v) {
      others.add(getCharacterFromPlayer(v));
      others.add(
        SizedBox(height: 5),
      );
    });

    return Column(children: others);
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return AlertDialog(
      title: Text('Character Descriptions:'),
      contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
      content: Container(
        height: 130 + 180.0 * (widget.data['playerIds'].length ~/ 3),
        width: width * 0.95,
        child: ListView(
          children: <Widget>[
            SizedBox(height: 40),
            Text(
              'Your Character:',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            SizedBox(height: 5),
            getCharacterFromPlayer(widget.userId),
            SizedBox(height: 20),
            Text('Others: '),
            SizedBox(height: 5),
            getOtherCharacters(),
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
              'OK',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class GameStateDialog extends StatefulWidget {
  GameStateDialog({this.data});

  final data;

  @override
  _GameStateDialogState createState() => _GameStateDialogState();
}

class _GameStateDialogState extends State<GameStateDialog> {
  getPlayerVotes() {
    List<Widget> votes = [];

    var players = [];
    widget.data['playerIds'].forEach((v) {
      if (!widget.data['narrators'].contains(v)) {
        players.add(v);
      }
    });
    players.forEach((v) {
      votes.add(
        Text(
          '${widget.data['playerNames'][v]} votes ${widget.data['readyToEnd'][v] ? 'YES' : 'NO'}',
          style: TextStyle(
            color: widget.data['readyToEnd'][v] ? Colors.green : Colors.red,
          ),
        ),
      );
    });
    return Column(children: votes);
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return AlertDialog(
      title: Text('Players voting to end:'),
      contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
      content: Container(
        height: 130 + 180.0 * (widget.data['playerIds'].length ~/ 3),
        width: width * 0.95,
        child: ListView(
          children: <Widget>[
            SizedBox(height: 40),
            getPlayerVotes(),
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
              'OK',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
