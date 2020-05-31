import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:together/components/buttons.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shimmer/shimmer.dart';

import 'package:together/components/dialogs.dart';
import 'package:together/services/services.dart';
import 'template/help_screen.dart';
import 'lobby_screen.dart';

class AbstractScreen extends StatefulWidget {
  AbstractScreen({this.sessionId, this.userId, this.roomCode});

  final String sessionId;
  final String userId;
  final String roomCode;

  @override
  _AbstractScreenState createState() => _AbstractScreenState();
}

class _AbstractScreenState extends State<AbstractScreen> {
  int numTeams;
  bool isLoading = true;
  String userTeamLeader = '';
  String userTeam = '';

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

  checkIfExit(data) async {
    // run async func to check if game is over, or back to lobby or deleted (main menu)
    if (data == null) {
      print('game was deleted');

      // navigate to main menu
      Navigator.of(context).pop();
    } else if (data['state'] == 'lobby') {
      // reset first team to green
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

    setState(() {
      numTeams = data['rules']['numTeams'];
      userTeamLeader = userData['abstractTeamLeader'];
      userTeam = userData['abstractTeam'];
    });
  }

  updateTurn(data) async {
    var currActiveTeam = data['turn'];
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

  Widget getTurn(BuildContext context, data) {
    var activeTeam = data['turn'];
    return Row(
      children: <Widget>[
        Text(
          'It\'s ',
          style: TextStyle(fontSize: 16),
        ),
        Text(
          activeTeam,
          style: TextStyle(fontSize: 16, color: stringToColor(activeTeam)),
        ),
        Text(
          ' team\'s turn!',
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  getPlayerStatus() {
    if (userTeamLeader == '') {
      return Row(
        children: <Widget>[
          Text(
            '(You are a commoner on ',
            style: TextStyle(fontSize: 12),
          ),
          Text(
            '$userTeam',
            style: TextStyle(
              fontSize: 12,
              color: stringToColor(userTeam),
            ),
          ),
          Text(
            ' team)',
            style: TextStyle(fontSize: 12),
          ),
        ],
      );
    }
    return Row(
      children: <Widget>[
        Text(
          '(You are the glorious leader of ',
          style: TextStyle(fontSize: 12),
        ),
        Text(
          '$userTeam',
          style: TextStyle(
            fontSize: 12,
            color: stringToColor(userTeam),
          ),
        ),
        Text(
          ' team)',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  getBoard(data) {
    int numCols = 5;
    if (numTeams == 3) {
      numCols = 6;
    }
    return SafeArea(
      child: Container(
        height: 200,
        child: GridView.builder(
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: numCols,
            childAspectRatio: MediaQuery.of(context).size.width /
                (MediaQuery.of(context).size.height - 200),
          ),
          itemBuilder: (context, index) =>
              _buildGridItems(context, index, data),
          itemCount: numCols * numCols,
        ),
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

    // check if game is over
    if (data['state'] == 'complete') {
      print('game is over!');
      return;
    }

    // check if it is player's turn
    if (data['turn'] != userTeam) {
      print('cannot flip when it is not your turn');
      return;
    }

    // flip card
    data['rules']['words'][x]['rowWords'][y]['flipped'] = true;
    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .updateData({'rules': data['rules']});

    // if card is bad, update turn
    if (data['rules']['words'][x]['rowWords'][y]['color'] != userTeam) {
      print('bad card, switching turns');
      updateTurn(data);
    }

    // check if any team is done
    int totalGreen = 0;
    int totalOrange = 0;
    int totalPurple = 0;
    int flippedGreen = 0;
    int flippedOrange = 0;
    int flippedPurple = 0;
    for (var row in data['rules']['words']) {
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
    }

    // end game check
    bool thereIsWinner = false;
    bool deathCardDrawn = false;
    List<String> winners = [];

    // check for winners, if so end game (this will be run until it is orange/purple's turn)
    bool greenGotAll = totalGreen == flippedGreen;
    bool orangeGotAll = totalOrange == flippedOrange;
    bool purpleGotAll = totalPurple == flippedPurple && flippedPurple > 1;
    if (greenGotAll) {
      thereIsWinner = true;
      winners.add('green');
    }
    if (orangeGotAll) {
      thereIsWinner = true;
      winners.add('orange');
    }
    if (purpleGotAll) {
      thereIsWinner = true;
      winners.add('purple');
    }

    // check if death card ends game
    if (data['rules']['words'][x]['rowWords'][y]['color'] == 'black') {
      winners = ['green', 'orange'];
      if (numTeams == 3) {
        winners.add('purple');
      }
      winners.removeWhere((item) => item == userTeam);
      print('winners by black card are: $winners');
      thereIsWinner = true;
      deathCardDrawn = true;
    }

    // end game if there is a winner and everyone has had a chance for rebuttal, OR if the black card was drawn
    if ((thereIsWinner &&
            ((numTeams == 2 &&
                data['turn'] == 'green' &&
                data['rules']['greenAlreadyWon'] == true))) ||
        deathCardDrawn) {
      print('game has ended! xy');
      await Firestore.instance
          .collection('sessions')
          .document(widget.sessionId)
          .updateData(deathCardDrawn
              ? {'state': 'complete', 'winners': winners, 'deathCard': true}
              : {'state': 'complete', 'winners': winners});
    }

    // update turns if relevant (i.e. green has won and it is green's team)
    if (greenGotAll && data['turn'] == 'green') {
      data['rules']['greenAlreadyWon'] = true;
      await Firestore.instance
          .collection('sessions')
          .document(widget.sessionId)
          .updateData({
        'rules': data['rules'],
      });
      updateTurn(data);
    } else if (orangeGotAll && data['turn'] == 'orange') {
      updateTurn(data);
    } else if (purpleGotAll && data['turn'] == 'purple') {
      updateTurn(data);
    }

    // one last check for a win
    if ((numTeams == 2 && greenGotAll && orangeGotAll) ||
        (numTeams == 3 && greenGotAll && orangeGotAll && purpleGotAll)) {
      print('game has ended, all win!');
      await Firestore.instance
          .collection('sessions')
          .document(widget.sessionId)
          .updateData(deathCardDrawn
              ? {'state': 'complete', 'winners': winners, 'deathCard': true}
              : {'state': 'complete', 'winners': winners});
    }
  }

  Widget _buildGridItems(BuildContext context, int index, dynamic data) {
    var words = data['rules']['words'];
    int gridStateLength = words.length;
    int x, y = 0;
    x = (index / gridStateLength).floor();
    y = (index % gridStateLength);
    bool tileIsVisible = userTeamLeader != '' ||
        words[x]['rowWords'][y]['flipped'] ||
        data['state'] == 'complete';
    // update words here
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

  colorStringToWidget(String color) {
    switch (color) {
      case 'green':
        return Text('Green', style: TextStyle(color: Colors.green));
        break;
      case 'orange':
        return Text('Orange', style: TextStyle(color: Colors.orange));
        break;
      case 'purple':
        return Text('Purple', style: TextStyle(color: Colors.purple));
        break;
    }
  }

  winnersToEnglish(List<dynamic> winners) {
    if (winners.length == 1) {
      return Row(
        children: <Widget>[
          colorStringToWidget(winners[0]),
          Text(' team wins!'),
        ],
      );
    }
    if (winners.length == 2) {
      return Row(
        children: <Widget>[
          colorStringToWidget(winners[0]),
          Text(' and '),
          colorStringToWidget(winners[1]),
          Text(' teams win!'),
        ],
      );
    }
    return Row(
      children: <Widget>[
        Text('All ', style: TextStyle(color: Colors.green)),
        Text('teams ', style: TextStyle(color: Colors.orange)),
        Text('win!', style: TextStyle(color: Colors.purple)),
      ],
    );
  }

  getHeaders(data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            border: Border.all(),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
          child: data['state'] == 'complete'
              ? Column(
                  children: <Widget>[
                    Shimmer.fromColors(
                      period: Duration(seconds: 5),
                      baseColor: Theme.of(context).primaryColor,
                      highlightColor: Colors.blue[100],
                      child: Text('Game over!', style: TextStyle(fontSize: 20)),
                    ),
                    winnersToEnglish(data['winners'])
                  ],
                )
              : Column(
                  children: <Widget>[
                    getTurn(context, data),
                    getPlayerStatus(),
                  ],
                ),
        ),
        SizedBox(width: 30),
        Container(
          decoration: BoxDecoration(
            border: Border.all(),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
          child: Column(
            children: <Widget>[
              Text(
                'Room Code:',
                style: TextStyle(
                  fontSize: 12,
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
        ),
        SizedBox(width: 30),
        userTeam == data['turn']
            ? Row(
                children: <Widget>[
                  RaisedGradientButton(
                    child: Text(
                      'End turn',
                      style: TextStyle(fontSize: 16),
                    ),
                    onPressed: () => updateTurn(data),
                    height: 40,
                    width: 110,
                    gradient: LinearGradient(
                      colors: <Color>[
                        Colors.blue,
                        Colors.blue[200],
                      ],
                    ),
                  ),
                  SizedBox(width: 30),
                ],
              )
            : Container(),
        widget.userId == data['leader']
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
    );
  }

  getScores(data) {
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
    }
    return Container(
      width: numTeams == 3 ? 360 : 280,
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Completed:   '),
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
      ),
    );
  }

  showTeams(data) {
    // set up teams
    List<Widget> greenTeam = [
      Text(
        'Green Team:',
        style: TextStyle(color: Colors.green),
      )
    ];
    List<Widget> orangeTeam = [
      Text(
        'Orange Team',
        style: TextStyle(color: Colors.orange),
      )
    ];
    List<Widget> purpleTeam = [
      Text(
        'Purple Team',
        style: TextStyle(color: Colors.purple),
      )
    ];

    for (var playerId in data['rules']['greenTeam']) {
      greenTeam.add(FutureBuilder(
          future:
              Firestore.instance.collection('users').document(playerId).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }
            if (playerId == data['rules']['greenLeader']) {
              return Text(snapshot.data['name'] + ' (leader)');
            } else {
              return Text(snapshot.data['name']);
            }
          }));
    }
    for (var playerId in data['rules']['orangeTeam']) {
      orangeTeam.add(FutureBuilder(
          future:
              Firestore.instance.collection('users').document(playerId).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }
            if (playerId == data['rules']['orangeLeader']) {
              return Text(snapshot.data['name'] + ' (leader)');
            } else {
              return Text(snapshot.data['name']);
            }
          }));
    }
    if (numTeams == 3) {
      for (var playerId in data['rules']['purpleTeam']) {
        purpleTeam.add(FutureBuilder(
            future:
                Firestore.instance.collection('users').document(playerId).get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container();
              }
              if (playerId == data['rules']['purpleLeader']) {
                return Text(snapshot.data['name'] + ' (leader)');
              } else {
                return Text(snapshot.data['name']);
              }
            }));
      }
    }

    var width = MediaQuery.of(context).size.width;
    return RaisedGradientButton(
      child: Text(
        'Show teams',
        style: TextStyle(fontSize: 14),
      ),
      onPressed: () {
        showDialog<Null>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Teams:'),
              contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
              content: Container(
                height: 100,
                width: width * 0.95,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Column(
                      children: greenTeam,
                    ),
                    SizedBox(width: 30),
                    Column(children: orangeTeam),
                    numTeams == 3
                        ? Row(
                            children: <Widget>[
                              SizedBox(width: 30),
                              Column(children: purpleTeam),
                            ],
                          )
                        : Container(),
                  ],
                ),
              ),
              actions: <Widget>[
                Container(
                  child: FlatButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ),
              ],
            );
          },
        );
      },
      height: 36,
      width: 110,
      gradient: LinearGradient(
        colors: <Color>[
          Colors.blue,
          Colors.blue[200],
        ],
      ),
    );
  }

  getSubHeaders(data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        getScores(data),
        SizedBox(width: 30),
        showTeams(data),
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
                    'Abstract',
                  ),
                ),
                body: Container());
          }
          // all data for all components
          DocumentSnapshot data = snapshot.data;
          checkIfExit(data);
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
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: 5),
                    getHeaders(data),
                    SizedBox(height: 5),
                    getSubHeaders(data),
                    SizedBox(height: 10),
                    getBoard(data),
                  ],
                ),
              ));
        });
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