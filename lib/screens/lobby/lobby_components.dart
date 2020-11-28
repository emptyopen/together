import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:together/components/layouts.dart';

import 'package:together/screens/plot_twist/plot_twist_services.dart';
import 'lobby_services.dart';
import 'package:together/services/firestore.dart';

class EditRulesDialog extends StatefulWidget {
  EditRulesDialog({this.sessionId, this.game});

  final String sessionId;
  final String game;

  @override
  _EditRulesDialogState createState() => _EditRulesDialogState();
}

class _EditRulesDialogState extends State<EditRulesDialog> {
  // Map<String, dynamic> rules = {};
  bool isLoading = true;
  List<dynamic> possibleLocations;
  List<dynamic> subList1;
  List<dynamic> subList2;
  List<List<bool>> strikethroughs;
  int numLocationsEnabled = 0;
  var data;

  @override
  void initState() {
    super.initState();
    getCurrentRules();
  }

  getCurrentRules() async {
    if (widget.game == 'The Hunt') {
      // get possible locations
      var locationData = (await FirebaseFirestore.instance
              .collection('locations')
              .doc('possible')
              .get())
          .data();
      setState(() {
        possibleLocations = locationData['locations'];
        subList2 = possibleLocations.sublist(0, possibleLocations.length ~/ 2);
        subList1 = possibleLocations.sublist(possibleLocations.length ~/ 2);
      });
    }
    var sessionData = (await FirebaseFirestore.instance
            .collection('sessions')
            .doc(widget.sessionId)
            .get())
        .data();
    if (widget.game == 'The Hunt') {
      getChosenLocations(sessionData);
    }
    setState(() {
      isLoading = false;
    });
  }

  updateRules(data, rule, newValue) async {
    // if the requested team size doesn't allow for current number of players, revert it
    // if (data['playerIds'].length >
    //     data['rules']['numTeams'] * data['rules']['maxTeamSize']) {
    //   return;
    // }

    data['rules'][rule] = newValue;
    var T = Transactor(sessionId: widget.sessionId);

    // remove teams until existing teams equals numTeamsTeams, then distribute deleted players
    List displacedPlayers = [];
    while (data['teams'].length > data['rules']['numTeams']) {
      print('will redistribute');
      displacedPlayers.addAll(data['teams'].last['players']);
      data['teams'].removeLast();
    }
    print('displaced $displacedPlayers');
    displacedPlayers.forEach((v) {
      data['playerIds'].remove(v);
    });
    addPlayers(data, displacedPlayers, T);

    // add teams until existing teams equals numTeams
    while (data['teams'].length < data['rules']['numTeams']) {
      data['teams'].add({
        'players': [],
      });
    }

    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .update({
      'rules': data['rules'],
      'teams': data['teams'],
    });
  }

  locationCallback(data) {
    // update the rules, they will be saved when update is pressed
    // check strikethroughs, add all non striked to new rules value
    data['rules']['locations'] = [];
    numLocationsEnabled = 0;
    subList1.asMap().forEach((index, value) {
      if (!strikethroughs[0][index]) {
        data['rules']['locations'].add(value);
        numLocationsEnabled += 1;
      }
    });
    subList2.asMap().forEach((index, value) {
      if (!strikethroughs[1][index]) {
        data['rules']['locations'].add(value);
        numLocationsEnabled += 1;
      }
    });
    setState(() {
      numLocationsEnabled = numLocationsEnabled;
    });
  }

  Widget getChosenLocations(data) {
    // this only runs on init
    subList2 = possibleLocations.sublist(0, possibleLocations.length ~/ 2);
    subList1 = possibleLocations.sublist(possibleLocations.length ~/ 2);
    strikethroughs = [
      List.filled(subList1.length, true),
      List.filled(subList2.length, true),
    ];
    // for each current location, mark as false for strikethrough (find indexes of possible location)
    numLocationsEnabled = 0;
    for (var location in data['rules']['locations']) {
      if (subList1.contains(location)) {
        strikethroughs[0][subList1.indexOf(location)] = false;
        numLocationsEnabled += 1;
      } else {
        strikethroughs[1][subList2.indexOf(location)] = false;
        numLocationsEnabled += 1;
      }
    }
    numLocationsEnabled = numLocationsEnabled;
    return LocationBoard(
      subList1: subList1,
      subList2: subList2,
      strikethroughs: strikethroughs,
      contentsOnly: true,
      callback: () => locationCallback(data),
    );
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    if (isLoading) {
      return AlertDialog();
    }
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .doc(widget.sessionId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return AlertDialog();
          }
          // all data for all components
          data = snapshot.data.data();

          List<Widget> ruleWidgets = [
            Text('Getting here is a bug lol, let Matt know')
          ];

          switch (widget.game) {
            case 'The Hunt':
              ruleWidgets = [
                SizedBox(height: 20),
                EditRulesDropdown(
                  data: data,
                  title: 'Number of spies:',
                  rule: 'numSpies',
                  updateRules: updateRules,
                  choices: [1, 2, 3, 4, 5],
                ),
                SizedBox(height: 20),
                EditRulesDropdown(
                  data: data,
                  title: 'Accusations allowed per turn:',
                  rule: 'accusationsPerTurn',
                  updateRules: updateRules,
                  choices: [1, 2, 3],
                ),
                SizedBox(height: 20),
                EditRulesDropdown(
                  data: data,
                  title:
                      'Number of other accusations before one can accuse again:',
                  rule: 'accusationCooldown',
                  updateRules: updateRules,
                  choices: [0, 1, 2, 3, 4, 5, 6, 7],
                ),
                SizedBox(height: 20),
                Text(
                    'Locations: $numLocationsEnabled/${possibleLocations.length}'),
                SizedBox(height: 5),
                getChosenLocations(data),
              ];
              break;
            case 'Abstract':
              ruleWidgets = [
                SizedBox(height: 20),
                EditRulesDropdown(
                  data: data,
                  title: 'Number of teams:',
                  rule: 'numTeams',
                  updateRules: updateRules,
                  choices: [2, 3],
                ),
                SizedBox(height: 20),
                EditRulesDropdown(
                  data: data,
                  title: 'Turn timer:',
                  rule: 'turnTimer',
                  updateRules: updateRules,
                  choices: [20, 30, 40, 50],
                ),
                SizedBox(height: 20),
                Text('Words:'),
                Container(
                  width: 80,
                  child: Column(
                    children: <Widget>[
                      GestureDetector(
                        onTap: () {
                          updateRules(data, 'generalWordsOn',
                              !data['rules']['generalWordsOn']);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: data['rules']['generalWordsOn']
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                          ),
                          padding: EdgeInsets.all(5),
                          child: Text(
                            'General',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
                      GestureDetector(
                        onTap: () {
                          updateRules(data, 'peopleWordsOn',
                              !data['rules']['peopleWordsOn']);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: data['rules']['peopleWordsOn']
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                          ),
                          padding: EdgeInsets.all(5),
                          child: Text(
                            'People',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
                      GestureDetector(
                        onTap: () {
                          updateRules(data, 'locationsWordsOn',
                              !data['rules']['locationsWordsOn']);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: data['rules']['locationsWordsOn']
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                          ),
                          padding: EdgeInsets.all(5),
                          child: Text(
                            'Locations',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ];
              break;
            case 'Bananaphone':
              ruleWidgets = [
                SizedBox(height: 20),
                EditRulesDropdown(
                  data: data,
                  title: 'Number of game rounds:',
                  rule: 'numRounds',
                  updateRules: updateRules,
                  choices: [1, 2, 3, 4, 5],
                ),
                SizedBox(height: 20),
                EditRulesDropdown(
                  data: data,
                  title: 'Number of draw/describe phases:',
                  rule: 'numDrawDescribe',
                  updateRules: updateRules,
                  choices: [2, 3],
                ),
              ];
              break;
            case 'Three Crowns':
              ruleWidgets = [
                SizedBox(height: 20),
                EditRulesDropdown(
                  data: data,
                  title: 'Minimum word length:',
                  rule: 'minWordLength',
                  updateRules: updateRules,
                  choices: [3, 4, 5, 6, 7, 8],
                ),
                SizedBox(height: 20),
                EditRulesDropdown(
                  data: data,
                  title: 'Maximum word length:',
                  rule: 'maxWordLength',
                  updateRules: updateRules,
                  choices: [5, 6, 7, 8, 9, 10],
                ),
              ];
              break;
            case 'Rivers':
              ruleWidgets = [
                SizedBox(height: 20),
                EditRulesDropdown(
                  data: data,
                  title: 'Card range:',
                  rule: 'cardRange',
                  updateRules: updateRules,
                  choices: [80, 100, 120, 140],
                ),
                SizedBox(height: 20),
                EditRulesDropdown(
                  data: data,
                  title: 'Maximum hand size:',
                  rule: 'handSize',
                  updateRules: updateRules,
                  choices: [5, 6, 7],
                ),
              ];
              break;
            case 'Plot Twist':
              ruleWidgets = [
                SizedBox(height: 20),
                EditRulesDropdown(
                  data: data,
                  title: 'Location:',
                  rule: 'location',
                  updateRules: updateRules,
                  choices: storyBeginnings.keys.toList(),
                ),
                SizedBox(height: 20),
                EditRulesDropdown(
                  data: data,
                  title: 'Number of narrators:',
                  rule: 'numNarrators',
                  updateRules: updateRules,
                  choices: [1, 2, 3, 4],
                ),
              ];
              break;
            case 'Charáde à Trois':
              ruleWidgets = [
                SizedBox(height: 20),
                EditRulesDropdown(
                  data: data,
                  title: 'Number of teams:',
                  rule: 'numTeams',
                  updateRules: updateRules,
                  choices: [2, 3, 4],
                ),
                SizedBox(height: 20),
                EditRulesDropdown(
                  data: data,
                  title: 'Round time limit:',
                  rule: 'roundTimeLimits',
                  updateRules: updateRules,
                  choices: [40, 50, 60, 70, 80, 90, 100, 110, 120],
                ),
                SizedBox(height: 20),
                EditRulesDropdown(
                  data: data,
                  title: 'Number of words:',
                  rule: 'collectionWordLimit',
                  updateRules: updateRules,
                  choices: [20, 25, 30, 40, 50, 60, 70, 80, 90, 100],
                ),
                SizedBox(height: 20),
                Text('Player chosen or random words:'),
                Container(
                  width: 80,
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: data['rules']['playerWords'] ? 'Player' : 'Random',
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (String newValue) {
                      updateRules(data, 'playerWords', newValue == 'Player');
                    },
                    items: <String>['Player', 'Random']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value.toString(),
                            style: TextStyle(fontFamily: 'Balsamiq')),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 20),
                EditRulesDropdown(
                  data: data,
                  title: 'Word collection time limit:',
                  rule: 'collectionTimeLimit',
                  updateRules: updateRules,
                  choices: [30, 45, 60, 90, 120, 180, 240, 300, 360],
                  locked: data['rules']['playerWords'] == 'Player',
                ),
              ];
              break;
            case 'Samesies':
              ruleWidgets = [
                SizedBox(height: 20),
                EditRulesDropdown(
                  data: data,
                  title: 'Number of teams:',
                  rule: 'numTeams',
                  updateRules: updateRules,
                  choices: [1, 2, 3, 4, 5, 6, 7, 8],
                ),
                SizedBox(height: 20),
                EditRulesDropdown(
                  data: data,
                  title: 'Round time limit:',
                  rule: 'roundTimeLimit',
                  updateRules: updateRules,
                  choices: [30, 45, 60, 70, 80, 90, 100, 120],
                ),
                SizedBox(height: 20),
                EditRulesDropdown(
                  data: data,
                  title: 'Survival mode (2 player only)',
                  rule: 'mode',
                  updateRules: updateRules,
                  choices: ['High Score', 'Survival'],
                  locked: data['rules']['numTeams'] > 1,
                ),
              ];
              break;
          }
          return AlertDialog(
            title: Text('Edit game rules:'),
            contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
            content: Container(
              width: width * 0.95,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: ruleWidgets,
              ),
            ),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Done'),
              ),
            ],
          );
        });
  }
}

class EditRulesDropdown extends StatelessWidget {
  final data;
  final String title;
  final String rule;
  final Function updateRules;
  final List choices;
  final bool locked;

  EditRulesDropdown(
      {this.data,
      this.title,
      this.rule,
      this.updateRules,
      this.choices,
      this.locked = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title),
        Container(
          width: 80,
          child: DropdownButton<int>(
            isExpanded: true,
            value: data['rules'][rule],
            iconSize: 24,
            elevation: 16,
            style: TextStyle(
                color: locked ? Colors.grey : Theme.of(context).highlightColor),
            underline: Container(
              height: 2,
              color: Theme.of(context).highlightColor,
            ),
            onChanged: (newValue) {
              if (locked) {
                return;
              }
              updateRules(data, rule, newValue);
            },
            items: choices.map<DropdownMenuItem<int>>((value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text('$value', style: TextStyle(fontFamily: 'Balsamiq')),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
