import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:together/components/buttons.dart';
import 'package:flutter/services.dart';

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
  int boardSize;
  bool isLoading = true;
  // TODO: consolidate into single 2d array?
  List<List<String>> words = [];
  List<List<String>> colors = [];
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
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
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
          .updateData({'turn': firstPlayer});

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
    // game should be completely set up by the time people enter
    // 2 teams: green / orange. 3 teams: green / orange / purple
    // board size, number of teams, and words, and assign player to a team
    // should anyone be able to click / change turns?
    var data = (await Firestore.instance.collection('sessions').document(widget.sessionId).get()).data;
    boardSize = data['rules']['boardSize'];

    print('setting up game...');

    setState(() {
      List<dynamic> wordsJSON = data['rules']['words'];
      words = [];
      for (var row in wordsJSON) {
        words.add(row['rowWords'].cast<String>());
      }
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
                  'It\'s  ',
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  activeTeam,
                  style:
                      TextStyle(fontSize: 22, color: stringToColor(activeTeam)),
                ),
                Text(
                  '  team\'s turn!',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            );
          }
        });
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

  Widget _buildGridItems(BuildContext context, int index) {
    int gridStateLength = words.length;
    int x, y = 0;
    x = (index / gridStateLength).floor();
    y = (index % gridStateLength);
    return GridTile(
      child: Container(
        decoration:
            BoxDecoration(border: Border.all(color: Colors.black, width: 0.5)),
        child: Center(
          child: FlatButton(onPressed: () {print('hi');}, child: Text(words[x][y])),
        ),
      ),
    );
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
                    getTurn(context),
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
