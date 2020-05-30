import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:together/components/buttons.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:together/components/misc.dart';
import 'package:together/components/dialogs.dart';
import 'package:together/models/models.dart';
import 'package:together/services/services.dart';
import 'template/help_screen.dart';
import 'lobby_screen.dart';

class AbstractScreen extends StatefulWidget {
  AbstractScreen({this.sessionId, this.userId, this.roomCode, this.isLeader});

  final String sessionId;
  final String userId;
  final String roomCode;
  final bool isLeader;

  @override
  _AbstractScreenState createState() => _AbstractScreenState();
}

class _AbstractScreenState extends State<AbstractScreen> {
  int numTeams;
  bool isLoading = true;
  String userTeamLeader = '';
  String userTeam = '';
  // TODO: consolidate into single 2d array?
  List<dynamic> words = [];
  List<List<Color>> colors = [];
  List<List<bool>> flipped = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    setUpGame();
  }

  @override
  dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  checkIfExit() async {
    // run async func to check if game is back to lobby or deleted (main menu)
    var data = (await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .get())
        .data;
    if (data == null) {
      print('game was deleted');

      // navigate to main menu
      Navigator.of(context).pop();
    } else if (data['state'] == 'lobby') {
      // reset first player
      String firstPlayer = data['playerIds'][0];
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

  setUpGame() async {
    var data = (await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .get())
        .data;

    var userData = (await Firestore.instance
            .collection('users')
            .document(widget.userId)
            .get())
        .data;

    print('setting up game...');

    setState(() {
      numTeams = data['rules']['numTeams'];
      userTeamLeader = userData['abstractTeamLeader'];
      userTeam = userData['abstractTeam'];
    });

    setState(() {
      // get words
      words = data['rules']['words'];
      isLoading = false;
    });
  }

  updateTurn() async {
    Map<String, dynamic> sessionData = (await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .get())
        .data;
    var currActiveTeam = sessionData['turn'];
    var nextActiveTeam = '';
    if (currActiveTeam == 'green') {
      nextActiveTeam = 'orange';
    } else if (currActiveTeam == 'orange') {
      if (numTeams == 2) {
        nextActiveTeam = 'green';
      } else {
        nextActiveTeam = 'purple';
      }
    } else {
      // must be purple
      nextActiveTeam = 'green';
    }
    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .updateData({'turn': nextActiveTeam});
  }

  fakeCallback() {}

  stringToColor(String teamName) {
    switch (teamName) {
      case 'green':
        return Colors.green;
        break;
      case 'orange':
        return Colors.orange;
        break;
      case 'purple':
        return Colors.purple;
        break;
      default:
        return Colors.white;
        break;
    }
  }

  StreamBuilder<QuerySnapshot> getTurn(BuildContext context) {
    return StreamBuilder(
        stream: Firestore.instance
            .collection('sessions')
            .where('roomCode', isEqualTo: widget.roomCode)
            .snapshots(),
        builder: (context, snapshot) {
          // check if exit here, only on update
          // TODO: this should be moved to it's own future/listener? confusing placement
          checkIfExit();
          if (!snapshot.hasData || snapshot.data.documents.length == 0) {
            return Text(
              'No Data...',
            );
          } else {
            DocumentSnapshot items = snapshot.data.documents[0];
            var activeTeam = items['turn'];
            return Row(
              children: <Widget>[
                Text(
                  'It\'s ',
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  activeTeam,
                  style:
                      TextStyle(fontSize: 18, color: stringToColor(activeTeam)),
                ),
                Text(
                  ' team\'s turn!',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            );
          }
        });
  }

  getPlayerStatus() {
    if (userTeamLeader == '') {
      return Row(
        children: <Widget>[
          Text(
            '(You are a commoner on ',
            style: TextStyle(fontSize: 14),
          ),
          Text(
            '$userTeam',
            style: TextStyle(
              fontSize: 14,
              color: stringToColor(userTeam),
            ),
          ),
          Text(
            ' team)',
            style: TextStyle(fontSize: 14),
          ),
        ],
      );
    }
    return Row(
      children: <Widget>[
        Text(
          '(You are the glorious leader of ',
          style: TextStyle(fontSize: 14),
        ),
        Text(
          '$userTeam',
          style: TextStyle(
            fontSize: 14,
            color: stringToColor(userTeam),
          ),
        ),
        Text(
          ' team)',
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  getBoard() {
    if (isLoading) {
      return Container();
    }
    int numCols = words.length;
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: numCols,
          childAspectRatio: MediaQuery.of(context).size.width /
              (MediaQuery.of(context).size.height - 200),
        ),
        itemBuilder: _buildGridItems,
        itemCount: numCols * numCols,
      ),
    );
  }

  getColorFromString(String colorName, bool isLeaderAndNotFlipped) {
    if (isLeaderAndNotFlipped) {
      switch (colorName) {
        case 'white':
          return Colors.white;
          break;
        case 'green':
          return Colors.green[100];
          break;
        case 'orange':
          return Colors.orange[100];
          break;
        case 'purple':
          return Colors.purple[100];
          break;
        case 'black':
          return Colors.grey[800];
          break;
        case 'grey':
          return Colors.white;
          break;
        default:
          return Colors.grey[300];
          break;
      }
    } else {
      switch (colorName) {
        case 'white':
          return Colors.white;
          break;
        case 'green':
          return Colors.green;
          break;
        case 'orange':
          return Colors.orange;
          break;
        case 'purple':
          return Colors.purple;
          break;
        case 'black':
          return Colors.black;
          break;
        default:
          return Colors.grey[300];
          break;
      }
    }
  }

  flipCard(int x, int y) async {
    var data = (await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .get())
        .data;

    // check if it is player's turn
    if (data['turn'] != userTeam) {
      print('cannot flip when it is not your turn');
      return;
    }

    // flip card
    setState(() {
      words[x]['rowWords'][y]['flipped'] = true;
    });
    data['rules']['words'] = words;
    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .updateData({'rules': data['rules']});

    // if card is bad, update turn
    if (words[x]['rowWords'][y]['color'] != userTeam) {
      print('bad card, switching turns');
      if (data['turn'] == 'green') {
        await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .updateData({'turn': 'orange'});
      } else if (data['turn'] == 'green' && data['numTeams'] == 2) {
        await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .updateData({'turn': 'green'});
      } else if (data['turn'] == 'green' && data['numTeams'] == 3) {
        await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .updateData({'turn': 'purple'});
      } else {
        await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .updateData({'turn': 'green'});
      }
    }

    // check if either team is done

    // check if death card loss

    // update status of game to "complete"

    // game over update status in Turn widget
  }

  Widget _buildGridItems(BuildContext context, int index) {
    int gridStateLength = words.length;
    int x, y = 0;
    x = (index / gridStateLength).floor();
    y = (index % gridStateLength);
    bool tileIsVisible =
        userTeamLeader != '' || words[x]['rowWords'][y]['flipped'];
    return GridTile(
      child: Container(
        decoration: BoxDecoration(
          color: tileIsVisible
              ? getColorFromString(
                  words[x]['rowWords'][y]['color'],
                  userTeamLeader != '' && !words[x]['rowWords'][y]['flipped']
                      ? true
                      : false)
              : Colors.white,
          border: Border.all(color: Colors.black, width: 0.5),
        ),
        child: Center(
          child: FlatButton(
            onPressed: () => flipCard(x, y),
            child: words[x]['rowWords'][y]['color'] == 'black'
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      words[x]['rowWords'][y]['flipped']
                          ? Row(
                            children: <Widget>[
                              Icon(
                                  MdiIcons.skull,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 5),
                            ],
                          )
                          : Container(),
                      Text(
                        words[x]['rowWords'][y]['name'],
                        style: TextStyle(
                            color: tileIsVisible &&
                                    words[x]['rowWords'][y]['color'] == 'black'
                                ? Colors.white
                                : Colors.black),
                      ),
                      words[x]['rowWords'][y]['flipped']
                          ? Row(
                            children: <Widget>[
                              SizedBox(width: 5),
                              Icon(
                                  MdiIcons.skull,
                                  color: Colors.white,
                                ),
                            ],
                          )
                          : Container(),
                    ],
                  )
                : Text(
                    words[x]['rowWords'][y]['name'],
                    style: TextStyle(
                        color: tileIsVisible &&
                                words[x]['rowWords'][y]['color'] == 'black'
                            ? Colors.white
                            : Colors.black),
                  ),
          ),
        ),
      ),
    );
  }

  getScores() {
    return StreamBuilder(
        stream: Firestore.instance
            .collection('sessions')
            .where('roomCode', isEqualTo: widget.roomCode)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Text(
              'No Data...',
            );
          } else {
            DocumentSnapshot data = snapshot.data.documents[0];
            var words = data['rules']['words'];
            int totalGreen = 0;
            int totalOrange = 0;
            int totalPurple = 0;
            int flippedGreen = 0;
            int flippedOrange = 0;
            int flippedPurple = 0;
            for (var row in words) {
              for (var m in row['rowWords']) {
                if (m['color'] == 'green') {
                  totalGreen += 1;
                  if (m['flipped']) {
                    flippedGreen += 1;
                  }
                }
                if (m['color'] == 'orange') {
                  totalOrange += 1;
                  if (m['flipped']) {
                    flippedOrange += 1;
                  }
                }
                if (m['color'] == 'purple') {
                  totalPurple += 1;
                  if (m['flipped']) {
                    flippedPurple += 1;
                  }
                }
              }
            };
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('Completed cards  -->    '),
                Text(
                  'Green: $flippedGreen/$totalGreen  ',
                  style: TextStyle(color: Colors.green),
                ),
                Text(
                  'Orange: $flippedOrange/$totalOrange  ',
                  style: TextStyle(color: Colors.orange),
                ),
                numTeams == 3
                    ? Text(
                        'Purple: $flippedPurple/$totalPurple',
                        style: TextStyle(color: Colors.purple),
                      )
                    : Container(),
              ],
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'Abstract',
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
                      return AbstractScreenHelp();
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
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        getTurn(context),
                        getPlayerStatus(),
                      ],
                    ),
                    SizedBox(width: 50),
                    Column(
                      children: <Widget>[
                        Text(
                          'Room Code:',
                          style: TextStyle(
                            fontSize: 14,
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
                    SizedBox(width: 50),
                    widget.isLeader
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
                                    game: 'Abstract',
                                    sessionId: widget.sessionId,
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
                  ],
                ),
                SizedBox(height: 10),
                getScores(),
                SizedBox(height: 10),
                getBoard(),
              ],
            ),
          ),
        ));
  }
}

class AbstractScreenHelp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HelpScreen(
      title: 'Abstract: Rules',
      information: ['    Help goes here'],
      buttonColor: Theme.of(context).primaryColor,
    );
  }
}
