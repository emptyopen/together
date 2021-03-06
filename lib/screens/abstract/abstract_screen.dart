import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:together/components/buttons.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:together/services/services.dart';
import 'package:together/help_screens/help_screens.dart';
import 'package:together/components/misc.dart';
import 'package:together/components/end_game.dart';
import 'package:together/components/scroll_view.dart';
import 'package:together/services/firestore.dart';

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
  bool userIsTeamLeader = false;
  String userTeam = '';
  Timer _timer;
  DateTime _now;
  bool isUpdating = false;
  String currTeam = '';
  bool isSpectator = false;
  var T;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    T = Transactor(sessionId: widget.sessionId);
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

  checkIfVibrate(data) {
    if (currTeam != data['turn']) {
      currTeam = data['turn'];
      if (currTeam == userTeam) {
        HapticFeedback.vibrate();
      }
    }
  }

  setUpGame() async {
    var data = (await FirebaseFirestore.instance
            .collection('sessions')
            .doc(widget.sessionId)
            .get())
        .data();

    setState(() {
      numTeams = data['rules']['numTeams'];
      isSpectator = data['spectatorIds'].contains(widget.userId);

      // determine user team and isTeamLeader
      if (data['rules']['numTeams'] == 2) {
        userIsTeamLeader = data['greenLeader'] == widget.userId ||
            data['orangeLeader'] == widget.userId;
        if (data['greenTeam'].contains(widget.userId)) {
          userTeam = 'green';
        } else {
          userTeam = 'orange';
        }
      } else {
        userIsTeamLeader = data['greenLeader'] == widget.userId ||
            data['orangeLeader'] == widget.userId ||
            data['purpleLeader'] == widget.userId;
        if (data['greenTeam'].contains(widget.userId)) {
          userTeam = 'green';
        } else if (data['rules']['orangeTeam'].contains(widget.userId)) {
          userTeam = 'orange';
        } else {
          userTeam = 'purple';
        }
      }
    });
  }

  updateTurn(data) async {
    if (data['state'] == 'complete') {
      return;
    }

    // get number of remaining words for team
    var increment = data['rules']['turnTimer'];
    int unflippedGreen = 0;
    int unflippedOrange = 0;
    int unflippedPurple = 0;
    for (var row in data['words']) {
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
      data['greenTime'] = data['greenTime'] +
          _now.difference(data['roundStart'].toDate()).inMilliseconds;
    } else if (currActiveTeam == 'orange') {
      if (numTeams == 2) {
        nextActiveTeam = 'green';
      } else {
        nextActiveTeam = 'purple';
      }
      data['orangeTime'] = data['orangeTime'] +
          _now.difference(data['roundStart'].toDate()).inMilliseconds;
    } else {
      nextActiveTeam = 'green';
      data['purpleTime'] = data['purpleTime'] +
          _now.difference(data['roundStart'].toDate()).inMilliseconds;
    }
    // count remaining unflipped for timer
    var numUnflipped = unflippedGreen;
    if (nextActiveTeam == 'orange') {
      numUnflipped = unflippedOrange;
    }
    if (nextActiveTeam == 'purple') {
      numUnflipped = unflippedPurple;
    }

    data['turn'] = nextActiveTeam;
    data['roundStart'] = DateTime.now();
    data['roundExpiration'] =
        DateTime.now().add(Duration(seconds: 10 + increment * numUnflipped));

    T.transact(data);

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
    if (!userIsTeamLeader) {
      return Row(
        children: <Widget>[
          Text(
            '(You are a commoner on ',
            style: TextStyle(fontSize: 12, color: Colors.grey),
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
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      );
    }
    return Row(
      children: <Widget>[
        Text(
          '(You are the glorious leader of ',
          style: TextStyle(fontSize: 12, color: Colors.grey),
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
          style: TextStyle(fontSize: 12, color: Colors.grey),
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

  getColorFromString(data, String colorName, bool isLeaderAndNotFlipped) {
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

  checkGameOver(data, isBadCard) async {
    // check if any team is done, or if black card is flipped
    int totalGreen = 0;
    int totalOrange = 0;
    int totalPurple = 0;
    int flippedGreen = 0;
    int flippedOrange = 0;
    int flippedPurple = 0;
    bool deathCardFlipped = false;
    List<String> winningTeams = [];
    for (var row in data['words']) {
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
        if (m['color'] == 'black' && m['flipped']) {
          deathCardFlipped = true;
        }
      }
    }
    bool greenGotAll = totalGreen == flippedGreen;
    bool orangeGotAll = totalOrange == flippedOrange;
    bool purpleGotAll = totalPurple == flippedPurple && flippedPurple > 1;
    if (greenGotAll) {
      winningTeams.add('green');
    }
    if (orangeGotAll) {
      winningTeams.add('orange');
    }
    if (purpleGotAll) {
      winningTeams.add('purple');
    }

    // check if death card ends game
    if (deathCardFlipped) {
      winningTeams = ['green', 'orange'];
      if (numTeams == 3) {
        winningTeams.add('purple');
      }
      winningTeams.removeWhere((item) => item == userTeam);
      data['deathCard'] = true;
    }

    bool isLastTeamTurn = false;
    if (numTeams == 2) {
      isLastTeamTurn = data['turn'] == 'orange';
    } else {
      isLastTeamTurn = data['turn'] == 'purple';
    }

    // end game if there is a winner and it is the last team's turn and it was a mistake OR if the black card was drawn
    if ((winningTeams.length > 0 && isLastTeamTurn && isBadCard) ||
        (data['rules']['numTeams'] == 2 && orangeGotAll) ||
        (data['rules']['numTeams'] == 3 && purpleGotAll) ||
        deathCardFlipped) {
      // determine winner if there is a tie
      if (winningTeams.length > 1) {
        // TODO: tiebreaker
      } else {
        print('not a tie');
      }

      // update winning players scores
      for (String team in winningTeams) {
        for (String playerId in data['playerIds']) {
          if (data['${team}Team'].contains(playerId)) {
            incrementPlayerScore('abstract', playerId);
          }
        }
      }

      data['state'] = 'complete';
      data['winners'] = winningTeams;

      await T.transact(data);
    }

    // if card is bad or current team got all, update turn
    if (isBadCard ||
        (data['turn'] == 'green' && greenGotAll) ||
        (data['turn'] == 'orange' && orangeGotAll)) {
      updateTurn(data);
    }
  }

  flipCard(data, int x, int y) async {
    // check if game is over
    if (data['state'] == 'complete') {
      return;
    }

    // check if it is player's turn
    if (data['turn'] != userTeam) {
      print('cannot flip when it is not your turn');
      return;
    }

    HapticFeedback.vibrate();

    // flip card
    data['words'][x]['rowWords'][y]['flipped'] = true;
    data['words'][x]['rowWords'][y]['flippedTurns'] = 5;

    // reduce recently flipped cards
    for (var x = 0; x < (numTeams == 2 ? 5 : 6); x++) {
      for (var y = 0; y < (numTeams == 2 ? 5 : 6); y++) {
        if (data['words'][x]['rowWords'][y]['flippedTurns'] > 0) {
          data['words'][x]['rowWords'][y]['flippedTurns'] -= 1;
        }
      }
    }
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .update({'rules': data['rules']});

    bool isBadCard = data['words'][x]['rowWords'][y]['color'] != userTeam;

    checkGameOver(data, isBadCard);

    T.transact(data);

    setState(() {});
  }

  getTeamIcon(x, y, data) {
    // alertDecagramOutline, magnifyPlusOutline
    var icon = MdiIcons.circleDouble;
    switch (data['words'][x]['rowWords'][y]['color']) {
      case 'green':
        icon = MdiIcons.sproutOutline;
        break;
      case 'orange':
        icon = MdiIcons.fire;
        break;
      case 'purple':
        icon = MdiIcons.wizardHat;
        break;
    }
    return icon;
  }

  Widget _buildGridItems(BuildContext context, int index, dynamic data) {
    var words = data['words'];
    int gridStateLength = words.length;
    int x, y = 0;
    x = (index / gridStateLength).floor();
    y = (index % gridStateLength);
    bool tileIsVisible = userIsTeamLeader ||
        words[x]['rowWords'][y]['flipped'] ||
        data['state'] == 'complete';
    // update words here
    return GridTile(
      child: GestureDetector(
        onTap: () => flipCard(data, x, y),
        child: Container(
          decoration: BoxDecoration(
            color: tileIsVisible
                ? getColorFromString(
                    data,
                    words[x]['rowWords'][y]['color'],
                    (userIsTeamLeader || data['state'] == 'complete') &&
                            !words[x]['rowWords'][y]['flipped']
                        ? true
                        : false)
                : Colors.white,
            border: Border.all(color: Colors.grey, width: 0.5),
          ),
          child: Stack(
            children: <Widget>[
              Center(
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
                              child: AutoSizeText(
                                words[x]['rowWords'][y]['name'],
                                style: TextStyle(
                                    fontSize: 12,
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
                    : AutoSizeText(
                        words[x]['rowWords'][y]['name'],
                        style: TextStyle(
                            fontSize: 12,
                            color: tileIsVisible &&
                                    words[x]['rowWords'][y]['color'] == 'black'
                                ? Colors.white
                                : Colors.black),
                      ),
              ),
              words[x]['rowWords'][y]['flippedTurns'] > 0
                  ? Positioned(
                      child: Icon(
                        getTeamIcon(x, y, data),
                        size: 18 +
                            words[x]['rowWords'][y]['flippedTurns'].toDouble() *
                                0.5,
                        color: words[x]['rowWords'][y]['color'] == 'grey'
                            ? Colors.black
                            : Colors.black.withAlpha(255 -
                                (5 - words[x]['rowWords'][y]['flippedTurns']) *
                                    50),
                      ),
                      right: 5,
                      bottom: 5)
                  : Container(),
            ],
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
            border: Border.all(color: Theme.of(context).highlightColor),
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
            border: Border.all(color: Theme.of(context).highlightColor),
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
            ? EndGameButton(
                sessionId: widget.sessionId,
                fontSize: 16,
                height: 35,
                width: 110,
              )
            : Container()
      ],
    );
  }

  getScores(data) {
    var words = data['words'];
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
        border: Border.all(color: Theme.of(context).highlightColor),
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
      ),
      SizedBox(height: 10),
    ];
    List<Widget> orangeTeam = [
      Text(
        'Orange Team',
        style: TextStyle(color: Colors.orange),
      ),
      SizedBox(height: 10),
    ];
    List<Widget> purpleTeam = [
      Text(
        'Purple Team',
        style: TextStyle(color: Colors.purple),
      ),
      SizedBox(height: 10),
    ];

    for (var playerId in data['greenTeam']) {
      greenTeam.add(FutureBuilder(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(playerId)
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }
            if (playerId == data['greenLeader']) {
              return Row(
                children: [
                  Text(
                    snapshot.data['name'],
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    ' (leader)',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  )
                ],
              );
            } else {
              return Text(snapshot.data['name'],
                  style: TextStyle(fontSize: 18));
            }
          }));
    }
    for (var playerId in data['orangeTeam']) {
      orangeTeam.add(FutureBuilder(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(playerId)
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }
            if (playerId == data['orangeLeader']) {
              return Row(
                children: [
                  Text(
                    snapshot.data['name'],
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    ' (leader)',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  )
                ],
              );
            } else {
              return Text(snapshot.data['name'],
                  style: TextStyle(fontSize: 18));
            }
          }));
    }
    if (numTeams == 3) {
      for (var playerId in data['purpleTeam']) {
        purpleTeam.add(FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(playerId)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container();
              }
              if (playerId == data['purpleLeader']) {
                return Row(
                  children: [
                    Text(
                      snapshot.data['name'],
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      ' (leader)',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    )
                  ],
                );
              } else {
                return Text(snapshot.data['name'],
                    style: TextStyle(fontSize: 18));
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
    var seconds = data['roundExpiration'].toDate().difference(_now).inSeconds;
    // if seconds is negative, turn needs to switch and timer needs to be updated
    if (seconds < 0 && !isUpdating) {
      isUpdating = true;
      updateTurn(data);
    }
    return Container(
      width: 170,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).highlightColor),
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
                        'Remaining: ',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                seconds < 0
                    ? Text('')
                    : AutoSizeText(
                        '${secondsToTimeString(seconds)}',
                        style: TextStyle(
                            fontSize: 12,
                            color: seconds <= 30
                                ? Colors.red
                                : Theme.of(context).highlightColor),
                        maxLines: 1,
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
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .doc(widget.sessionId)
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
          DocumentSnapshot snapshotData = snapshot.data;
          var data = snapshotData.data();
          if (data == null) {
            return Scaffold(
                appBar: AppBar(
                  title: Text(
                    'Abstract',
                  ),
                ),
                body: Container());
          }
          checkIfExit(data, context, widget.sessionId, widget.roomCode);
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
              body: Stack(
                children: <Widget>[
                  TogetherScrollView(
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
                  ),
                  isSpectator
                      ? Positioned(
                          bottom: 20, right: 20, child: SpectatorModeLogo())
                      : Container()
                ],
              ));
        });
  }
}
