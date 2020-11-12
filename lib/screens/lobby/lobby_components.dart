import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:together/components/layouts.dart';

import 'package:together/screens/plot_twist/plot_twist_services.dart';

class EditRulesDialog extends StatefulWidget {
  EditRulesDialog({this.sessionId, this.game});

  final String sessionId;
  final String game;

  @override
  _EditRulesDialogState createState() => _EditRulesDialogState();
}

class _EditRulesDialogState extends State<EditRulesDialog> {
  Map<String, dynamic> rules = {};
  bool isLoading = true;
  List<dynamic> possibleLocations;
  List<dynamic> subList1;
  List<dynamic> subList2;
  List<List<bool>> strikethroughs;
  int numLocationsEnabled = 0;

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
    switch (widget.game) {
      case 'The Hunt':
        rules['numSpies'] = sessionData['rules']['numSpies'];
        rules['locations'] = sessionData['rules']['locations'];
        rules['accusationsPerTurn'] =
            sessionData['rules']['accusationsPerTurn'];
        rules['accusationCooldown'] =
            sessionData['rules']['accusationCooldown'];
        break;
      case 'Abstract':
        rules['numTeams'] = sessionData['rules']['numTeams'];
        rules['turnTimer'] = sessionData['rules']['turnTimer'];
        rules['generalWordsOn'] = sessionData['rules']['generalWordsOn'];
        rules['peopleWordsOn'] = sessionData['rules']['peopleWordsOn'];
        rules['locationsWordsOn'] = sessionData['rules']['peopleWordsOn'];
        break;
      case 'Bananaphone':
        rules['numRounds'] = sessionData['rules']['numRounds'];
        rules['numDrawDescribe'] = sessionData['rules']['numDrawDescribe'];
        break;
      case 'Three Crowns':
        rules['minWordLength'] = sessionData['rules']['minWordLength'];
        rules['maxWordLength'] = sessionData['rules']['maxWordLength'];
        break;
      case 'Rivers':
        rules['cardRange'] = sessionData['rules']['cardRange'];
        rules['handSize'] = sessionData['rules']['handSize'];
        break;
      case 'Plot Twist':
        rules['location'] = sessionData['rules']['location'];
        rules['numNarrators'] = sessionData['rules']['numNarrators'];
        break;
      case 'Charáde à Trois':
        rules['numTeams'] = sessionData['rules']['numTeams'];
        rules['playerWords'] = sessionData['rules']['playerWords'];
        rules['collectionWordLimit'] =
            sessionData['rules']['collectionWordLimit'];
        rules['collectionTimeLimit'] =
            sessionData['rules']['collectionTimeLimit'];
        rules['roundTimeLimit'] = sessionData['rules']['roundTimeLimit'];
        break;
    }
    if (widget.game == 'The Hunt') {
      getChosenLocations();
    }
    setState(() {
      isLoading = false;
    });
  }

  updateRules() async {
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .update({'rules': rules});
    Navigator.of(context).pop();
  }

  locationCallback() {
    // update the rules, they will be saved when update is pressed
    // check strikethroughs, add all non striked to new rules value
    rules['locations'] = [];
    numLocationsEnabled = 0;
    subList1.asMap().forEach((index, value) {
      if (!strikethroughs[0][index]) {
        rules['locations'].add(value);
        numLocationsEnabled += 1;
      }
    });
    subList2.asMap().forEach((index, value) {
      if (!strikethroughs[1][index]) {
        rules['locations'].add(value);
        numLocationsEnabled += 1;
      }
    });
    setState(() {
      numLocationsEnabled = numLocationsEnabled;
    });
  }

  Widget getChosenLocations() {
    // this only runs on init
    setState(() {
      subList2 = possibleLocations.sublist(0, possibleLocations.length ~/ 2);
      subList1 = possibleLocations.sublist(possibleLocations.length ~/ 2);
    });
    strikethroughs = [
      List.filled(subList1.length, true),
      List.filled(subList2.length, true),
    ];
    // for each current location, mark as false for strikethrough (find indexes of possible location)
    numLocationsEnabled = 0;
    for (var location in rules['locations']) {
      if (subList1.contains(location)) {
        strikethroughs[0][subList1.indexOf(location)] = false;
        numLocationsEnabled += 1;
      } else {
        strikethroughs[1][subList2.indexOf(location)] = false;
        numLocationsEnabled += 1;
      }
    }
    setState(() {
      numLocationsEnabled = numLocationsEnabled;
    });
    return LocationBoard(
      subList1: subList1,
      subList2: subList2,
      strikethroughs: strikethroughs,
      contentsOnly: true,
      callback: locationCallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    if (isLoading) {
      return AlertDialog();
    }
    switch (widget.game) {
      case 'The Hunt':
        return AlertDialog(
          title: Text('Edit game rules:'),
          contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
          content: Container(
            height:
                subList2 != null ? 140 + 40 * subList1.length.toDouble() : 100,
            width: width * 0.95,
            child: ListView(
              children: <Widget>[
                SizedBox(height: 20),
                Text('Number of spies:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['numSpies'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['numSpies'] = newValue;
                      });
                    },
                    items: <int>[1, 2, 3, 4, 5]
                        .map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString(),
                            style: TextStyle(fontFamily: 'Balsamiq')),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 10),
                Text('Accusations allowed per turn:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['accusationsPerTurn'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['accusationsPerTurn'] = newValue;
                      });
                    },
                    items:
                        <int>[1, 2, 3].map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString(),
                            style: TextStyle(fontFamily: 'Balsamiq')),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                    'Number of other accusations before one can accuse again:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['accusationCooldown'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['accusationCooldown'] = newValue;
                      });
                    },
                    items: <int>[0, 1, 2, 3, 4, 5, 6, 7]
                        .map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString(),
                            style: TextStyle(fontFamily: 'Balsamiq')),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                    'Locations: $numLocationsEnabled/${possibleLocations.length}'),
                SizedBox(height: 5),
                getChosenLocations(),
              ],
            ),
          ),
          actions: <Widget>[
            Container(
              child: FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
            ),
            FlatButton(
              onPressed: () {
                updateRules();
              },
              child: Text('Update'),
            )
          ],
        );
        break;
      case 'Abstract':
        return AlertDialog(
          title: Text('Edit game rules:'),
          contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
          content: Container(
            height: 310,
            width: width * 0.95,
            child: ListView(
              children: <Widget>[
                SizedBox(height: 20),
                Text('Num teams:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['numTeams'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['numTeams'] = newValue;
                      });
                    },
                    items: <int>[2, 3].map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString(),
                            style: TextStyle(fontFamily: 'Balsamiq')),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 20),
                Text('Turn timer:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['turnTimer'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['turnTimer'] = newValue;
                      });
                    },
                    items: <int>[20, 30, 40, 50]
                        .map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString(),
                            style: TextStyle(fontFamily: 'Balsamiq')),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 20),
                Text('Words:'),
                Container(
                  width: 80,
                  child: Column(
                    children: <Widget>[
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            rules['generalWordsOn'] = !rules['generalWordsOn'];
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: rules['generalWordsOn']
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
                          setState(() {
                            rules['peopleWordsOn'] = !rules['peopleWordsOn'];
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: rules['peopleWordsOn']
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
                          setState(() {
                            rules['locationsWordsOn'] =
                                !rules['locationsWordsOn'];
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: rules['locationsWordsOn']
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
              ],
            ),
          ),
          actions: <Widget>[
            Container(
              child: FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
            ),
            FlatButton(
              onPressed: () {
                updateRules();
              },
              child: Text('Update'),
            )
          ],
        );
        break;
      case 'Bananaphone':
        return AlertDialog(
          title: Text('Edit game rules:'),
          contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
          content: Container(
            height: 180,
            width: width * 0.95,
            child: ListView(
              children: <Widget>[
                SizedBox(height: 20),
                Text('Number of rounds:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['numRounds'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['numRounds'] = newValue;
                      });
                    },
                    items: <int>[1, 2, 3, 4, 5]
                        .map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString(),
                            style: TextStyle(fontFamily: 'Balsamiq')),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 20),
                Text('Number of draw/describes:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['numDrawDescribe'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['numDrawDescribe'] = newValue;
                      });
                    },
                    items: <int>[2, 3].map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString(),
                            style: TextStyle(fontFamily: 'Balsamiq')),
                      );
                    }).toList(),
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
                child: Text('Cancel'),
              ),
            ),
            FlatButton(
              onPressed: () {
                updateRules();
              },
              child: Text('Update'),
            )
          ],
        );
        break;
      case 'Three Crowns':
        return AlertDialog(
          title: Text('Edit game rules:'),
          contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
          content: Container(
            // decoration: BoxDecoration(border: Border.all()),
            height: 180,
            width: width * 0.95,
            child: ListView(
              children: <Widget>[
                SizedBox(height: 20),
                Text('Minimum word length:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['minWordLength'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['minWordLength'] = newValue;
                      });
                    },
                    items: <int>[3, 4, 5, 6, 7, 8]
                        .map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString(),
                            style: TextStyle(fontFamily: 'Balsamiq')),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 20),
                Text('Maximum word length:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['maxWordLength'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['maxWordLength'] = newValue;
                      });
                    },
                    items: <int>[5, 6, 7, 8, 9, 10]
                        .map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString(),
                            style: TextStyle(fontFamily: 'Balsamiq')),
                      );
                    }).toList(),
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
                child: Text('Cancel'),
              ),
            ),
            FlatButton(
              onPressed: () {
                updateRules();
              },
              child: Text('Update'),
            )
          ],
        );
        break;
      case 'Rivers':
        return AlertDialog(
          title: Text('Edit game rules:'),
          contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
          content: Container(
            // decoration: BoxDecoration(border: Border.all()),
            height: 170,
            width: width * 0.95,
            child: ListView(
              children: <Widget>[
                SizedBox(height: 20),
                Text('Maximum word length:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['cardRange'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['cardRange'] = newValue;
                      });
                    },
                    items: <int>[80, 100, 120, 140]
                        .map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString(),
                            style: TextStyle(fontFamily: 'Balsamiq')),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 20),
                Text('Maximum hand size:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['handSize'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['handSize'] = newValue;
                      });
                    },
                    items:
                        <int>[5, 6, 7].map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString(),
                            style: TextStyle(fontFamily: 'Balsamiq')),
                      );
                    }).toList(),
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
                child: Text('Cancel'),
              ),
            ),
            FlatButton(
              onPressed: () {
                updateRules();
              },
              child: Text('Update'),
            )
          ],
        );
        break;
      case 'Plot Twist':
        return AlertDialog(
          title: Text('Edit game rules:'),
          contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
          content: Container(
            // decoration: BoxDecoration(border: Border.all()),
            height: 170,
            width: width * 0.95,
            child: ListView(
              children: <Widget>[
                SizedBox(height: 20),
                Text('Location:'),
                Container(
                  width: 80,
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: rules['location'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (String newValue) {
                      setState(() {
                        rules['location'] = newValue;
                      });
                    },
                    items: storyBeginnings.keys
                        .toList()
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
                Text('Number of narrators:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['numNarrators'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['numNarrators'] = newValue;
                      });
                    },
                    items: <int>[1, 2, 3, 4]
                        .map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString(),
                            style: TextStyle(fontFamily: 'Balsamiq')),
                      );
                    }).toList(),
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
                child: Text('Cancel'),
              ),
            ),
            FlatButton(
              onPressed: () {
                updateRules();
              },
              child: Text('Update'),
            )
          ],
        );
        break;
      case 'Charáde à Trois':
        return AlertDialog(
          title: Text('Edit game rules:'),
          contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
          content: Container(
            // decoration: BoxDecoration(border: Border.all()),
            height: 460,
            width: width * 0.95,
            child: ListView(
              children: <Widget>[
                SizedBox(height: 20),
                Text('Number of teams:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['numTeams'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['numTeams'] = newValue;
                      });
                    },
                    items:
                        <int>[2, 3, 4].map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString(),
                            style: TextStyle(fontFamily: 'Balsamiq')),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 20),
                Text('Round time limit:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['roundTimeLimit'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['roundTimeLimit'] = newValue;
                      });
                    },
                    items: <int>[40, 50, 60, 70, 80, 90, 100, 110, 120]
                        .map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString(),
                            style: TextStyle(fontFamily: 'Balsamiq')),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 20),
                Text('Number of words:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['collectionWordLimit'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['collectionWordLimit'] = newValue;
                      });
                    },
                    items: <int>[
                      10,
                      15,
                      20,
                      25,
                      30,
                      40,
                      50,
                      60,
                      70,
                      80,
                      90,
                      100
                    ].map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString(),
                            style: TextStyle(fontFamily: 'Balsamiq')),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 20),
                Text('Player chosen or random words:'),
                Container(
                  width: 80,
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: rules['playerWords'] ? 'Player' : 'Random',
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (String newValue) {
                      setState(() {
                        rules['playerWords'] = newValue == 'Player';
                      });
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
                Text('Word collection time limit:'),
                Container(
                  width: 80,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: rules['collectionTimeLimit'],
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        rules['collectionTimeLimit'] = newValue;
                      });
                    },
                    items: <int>[60, 120, 180, 240, 300, 360, 420, 480]
                        .map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString(),
                            style: TextStyle(fontFamily: 'Balsamiq')),
                      );
                    }).toList(),
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
                child: Text('Cancel'),
              ),
            ),
            FlatButton(
              onPressed: () {
                updateRules();
              },
              child: Text('Update'),
            )
          ],
        );
        break;
      default:
        return AlertDialog(
          title: Text('Edit Rules (unknown game)'),
          content: ListView(
            children: <Widget>[
              Text('Getting here is a bug lol, let Matt know')
            ],
          ),
        );
    }
  }
}
