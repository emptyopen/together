import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:together/components/buttons.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import 'package:flutter/services.dart';

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
  Timer _timer;
  DateTime _now;
  bool isUpdating = false;
  String currTeam = '';

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    setUpGame();
    _timer = Timer.periodic(Duration(milliseconds: 100), (Timer t) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });
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

  checkIfVibrate(data) {
    if (currTeam != data['turn']) {
      currTeam = data['turn'];
      if (currTeam == userTeam) {
        HapticFeedback.vibrate();
      }
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
    if (data['state'] == 'complete') {
      print('game is over, not updating');
      return;
    }

    // get number of remaining words for team
    var increment = data['rules']['turnTimer'];
    int unflippedGreen = 0;
    int unflippedOrange = 0;
    int unflippedPurple = 0;
    for (var row in data['rules']['words']) {
      for (var m in row['rowWords']) {
        if (m['color'] == 'green') {
          if (!m['flipped']) {
            unflippedGreen += 1;
          }
        }
        if (m['color'] == 'orange') {
          if (!m['flipped']) {
            unflippedOrange += 1;
          }
        }
        if (m['color'] == 'purple') {
          if (!m['flipped']) {
            unflippedPurple += 1;
          }
        }
      }
    }

    // figure out next team and update cumulative team times
    var currActiveTeam = data['turn'];
    var nextActiveTeam = '';
    if (currActiveTeam == 'green') {
      nextActiveTeam = 'orange';
      await Firestore.instance
          .collection('sessions')
          .document(widget.sessionId)
          .updateData({
        'greenTime': data['greenTime'] +
            _now.difference(data['greenStart'].toDate()).inMilliseconds,
        'orangeStart': DateTime.now(),
      });
    } else if (currActiveTeam == 'orange') {
      if (numTeams == 2) {
        nextActiveTeam = 'green';
        await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .updateData({
          'orangeTime': data['orangeTime'] +
              _now.difference(data['orangeStart'].toDate()).inMilliseconds,
          'greenStart': DateTime.now(),
        });
      } else {
        nextActiveTeam = 'purple';
        await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .updateData({
          'orangeTime': data['orangeTime'] +
              _now.difference(data['orangeStart'].toDate()).inMilliseconds,
          'purpleStart': DateTime.now(),
        });
      }
    } else {
      await Firestore.instance
          .collection('sessions')
          .document(widget.sessionId)
          .updateData({
        'purpleTime': data['purpleTime'] +
            _now.difference(data['purpleStart'].toDate()).inMilliseconds,
        'purpleStart': DateTime.now(),
      });
      nextActiveTeam = 'green';
    }
    var numUnflipped = unflippedGreen;
    if (nextActiveTeam == 'orange') {
      numUnflipped = unflippedOrange;
    }
    if (nextActiveTeam == 'purple') {
      numUnflipped = unflippedPurple;
    }

    // update timer
    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .updateData({
      'turn': nextActiveTeam,
      'timer': DateTime.now().add(
          Duration(seconds: 10 + int.parse(increment) * numUnflipped))
    });

    isUpdating = false;
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
        height: 220,
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
    data['rules']['words'][x]['rowWords'][y]['flippedTurns'] = 5;

    // reduce recently flipped cards
    for (var x = 0; x < (numTeams == 2 ? 5 : 6); x++) {
      for (var y = 0; y < (numTeams == 2 ? 5 : 6); y++) {
        if (data['rules']['words'][x]['rowWords'][y]['flippedTurns'] > 0) {
          data['rules']['words'][x]['rowWords'][y]['flippedTurns'] -= 1;
        }
      }
    }
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

    // update turns if relevant (i.e. green has won and it is green's team)
    bool freshTurnOnThisFlip = false;
    if (greenGotAll && data['turn'] == 'green') {
      await updateTurn(data);
      freshTurnOnThisFlip = true;
    } else if (orangeGotAll && data['turn'] == 'orange') {
      await updateTurn(data);
      freshTurnOnThisFlip = true;
    } else if (purpleGotAll && data['turn'] == 'purple') {
      await updateTurn(data);
      freshTurnOnThisFlip = true;
    }

    data = (await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .get())
        .data;

    // end game if there is a winner and turn has just become green, OR if the black card was drawn, OR all teams have won
    if ((thereIsWinner && data['turn'] == 'green' && freshTurnOnThisFlip) ||
        deathCardDrawn ||
        winners.length == data['numTeams']) {
      print('game has ended!');

      // determine winner if there is a tie
      if (winners.length > 1) {
        print('resolving tie with amount of time spent');
      } else {
        print('not a tie');
      }
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
        child: Stack(
          children: <Widget>[
            Center(
              child: FlatButton(
                onPressed: () => flipCard(x, y),
                child: words[x]['rowWords'][y]['color'] == 'black'
                    ? Stack(
                        children: <Widget>[
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.center,
                              child: words[x]['rowWords'][y]['flipped']
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Icon(
                                          MdiIcons.skull,
                                          color: Colors.grey[700],
                                        ),
                                        SizedBox(width: 20),
                                        Icon(
                                          MdiIcons.skull,
                                          color: Colors.grey[700],
                                        ),
                                        SizedBox(width: 20),
                                        Icon(
                                          MdiIcons.skull,
                                          color: Colors.grey[700],
                                        ),
                                      ],
                                    )
                                  : Container(),
                            ),
                          ),
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                words[x]['rowWords'][y]['name'],
                                style: TextStyle(
                                    color: tileIsVisible &&
                                            words[x]['rowWords'][y]['color'] ==
                                                'black'
                                        ? Colors.white
                                        : Colors.black),
                              ),
                            ),
                          ),
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
            words[x]['rowWords'][y]['flippedTurns'] > 0
                ? Positioned(
                    child: Icon(MdiIcons.sproutOutline,
                        size: 16,
                        color: Colors
                            .black.withAlpha(255 - (5 - words[x]['rowWords'][y]['flippedTurns']) * 50)), // alertDecagramOutline, magnifyPlusOutline
                    right: 5,
                    bottom: 5)
                : Container(),
          ],
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
        SizedBox(width: 10),
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
        SizedBox(width: 10),
        userTeam == data['turn'] && data['state'] != 'complete'
            ? Row(
                children: <Widget>[
                  RaisedGradientButton(
                    child: Text(
                      'End turn',
                      style: TextStyle(fontSize: 16),
                    ),
                    onPressed: () => updateTurn(data),
                    height: 35,
                    width: 100,
                    gradient: LinearGradient(
                      colors: <Color>[
                        Colors.blue,
                        Colors.blue[200],
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
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
                        winnerAlreadyDecided: true,
                      );
                    },
                  );
                },
                height: 35,
                width: 110,
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
      height: 30,
      width: 110,
      gradient: LinearGradient(
        colors: <Color>[
          Colors.blue,
          Colors.blue[200],
        ],
      ),
    );
  }

  secondsToTimeString(int seconds) {
    var minutes = seconds ~/ 60;
    seconds = seconds - minutes * 60;
    if (minutes == 0) {
      return '$seconds seconds';
    }
    return '${minutes}m ${seconds}s';
  }

  getTimer(data) {
    var seconds = data['timer'].toDate().difference(_now).inSeconds;
    // if seconds is negative, turn needs to switch and timer needs to be updated
    if (seconds < 0 && widget.userId == data['leader'] && !isUpdating) {
      isUpdating = true;
      updateTurn(data);
    }
    return Container(
      width: 150,
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
      child: data['state'] == 'complete'
          ? Center(child: Text('Game over!'))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                seconds < 0
                    ? Text('')
                    : Text(
                        'Time: ${secondsToTimeString(seconds)}',
                        style: TextStyle(
                            color: seconds <= 30 ? Colors.red : Colors.black),
                      ),
              ],
            ),
    );
  }

  getSubHeaders(data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        getTimer(data),
        SizedBox(width: 10),
        getScores(data),
        SizedBox(width: 10),
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
          // check if vibrate
          checkIfVibrate(data);
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: 20),
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
      information: [
        '    The objective of this game is to flip all cards for your team. '
            'Leaders of teams take turns giving a clue to their team which should tie different words on the board together. '
            'A clue can be anything that has a Wikipedia page. '
            'The timer is shared for the leader giving the clue and the leader\'s team guessing.',
        '    If a team wins, teams that didn\'t initially start before the winning team get chance for rebuttal. In '
            'case of ties, the team that used the least time throughout the game wins.',
      ],
      buttonColor: Theme.of(context).primaryColor,
    );
  }
}
