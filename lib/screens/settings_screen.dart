import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:together/services/authentication.dart';
import 'package:together/components/buttons.dart';
import 'package:together/constants/users.dart';

class SettingsScreen extends StatefulWidget {
  SettingsScreen({Key key, this.auth, this.logoutCallback}) : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  TextEditingController _newNameController = new TextEditingController();
  String currName;
  String nameError = '';
  String userId = '';
  List<String> reservedGames = ['001', '002', '003'];
  int sessionDeletionDaysThreshold = 1;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  TabController _tabController;
  final List<Tab> myTabs = <Tab>[
    Tab(
      text: 'Settings',
    ),
    Tab(
      text: 'About the Developer',
    ),
  ];

  @override
  void initState() {
    super.initState();
    getCurrName();
    _tabController = TabController(vsync: this, length: myTabs.length);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  getCurrName() async {
    userId = FirebaseAuth.instance.currentUser.uid;
    setState(() {
      userId = userId;
    });
    Map<String, dynamic> data =
        (await FirebaseFirestore.instance.collection('users').doc(userId).get())
            .data();
    setState(() {
      currName = data['name'];
    });
  }

  signOut() async {
    Navigator.pop(context);
    try {
      await widget.auth.signOut();
      widget.logoutCallback();
    } catch (e) {
      print(e);
    }
  }

  updateName() async {
    if (_newNameController.text.length < 3) {
      setState(() {
        nameError = 'Name too short (3 or more letters)';
      });
    } else if (_newNameController.text == currName) {
      setState(() {
        nameError = 'Name must be different';
      });
    } else {
      setState(() {
        currName = _newNameController.text;
      });
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'name': _newNameController.text});
    }
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text('Name updated!'),
      duration: Duration(seconds: 3),
    ));
  }

  getNameBox() {
    return Column(
      children: <Widget>[
        Container(
          width: 200,
          decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).highlightColor),
              borderRadius: BorderRadius.circular(20)),
          padding: EdgeInsets.all(15),
          child: Column(
            children: <Widget>[
              Text(
                'Change name',
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              Text('Current name: $currName',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                  textAlign: TextAlign.center),
              SizedBox(height: 8),
              Container(
                height: 40,
                child: Center(
                  child: TextField(
                    controller: _newNameController,
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                        border: OutlineInputBorder()),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: 10),
              RaisedGradientButton(
                width: 120,
                height: 40,
                child: Text(
                  'Update name',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                onPressed: () => updateName(),
                gradient: LinearGradient(
                  colors: <Color>[
                    Theme.of(context).primaryColor,
                    Theme.of(context).accentColor,
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  destroyOldGames() async {
    List sessionsToDelete = [];
    await FirebaseFirestore.instance
        .collection("sessions")
        .get()
        .then((QuerySnapshot snapshot) {
      snapshot.docs.forEach((f) {
        if (!f.data().containsKey('dateCreated')) {
          print('didnt have date created: ${f.data()["roomCode"]}');
        } else {
          var date = new DateTime.fromMicrosecondsSinceEpoch(
              f.data()['dateCreated'].seconds * 1000000);
          var daysSince = DateTime.now().difference(date);
          if (!reservedGames.contains(f.data()['roomCode']) &&
              daysSince.compareTo(
                      Duration(days: sessionDeletionDaysThreshold)) >=
                  0) {
            sessionsToDelete.add(f.reference);
          }
        }
      });
    });
    var destroyedGamesCnt = 0;
    sessionsToDelete.forEach((v) {
      FirebaseFirestore.instance
          .runTransaction((Transaction myTransaction) async {
        myTransaction.delete(v);
      });
      destroyedGamesCnt++;
    });
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text('Destroyed $destroyedGamesCnt games.'),
      duration: Duration(seconds: 3),
    ));
  }

  getMattBox() {
    return Column(
      children: <Widget>[
        Container(
          width: 200,
          decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).highlightColor),
              borderRadius: BorderRadius.circular(20)),
          padding: EdgeInsets.all(15),
          child: Column(
            children: <Widget>[
              Text(
                'Admin',
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              RaisedGradientButton(
                width: 160,
                height: 40,
                child: Text(
                  'Destroy old games',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                onPressed: () => destroyOldGames(),
                gradient: LinearGradient(
                  colors: <Color>[
                    Theme.of(context).primaryColor,
                    Theme.of(context).accentColor,
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(fontFamily: 'Balsamiq'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: myTabs,
        ),
      ),
      resizeToAvoidBottomInset: false,
      key: _scaffoldKey,
      body: TabBarView(
        controller: _tabController,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                getNameBox(),
                SizedBox(height: 30),
                isAdmin(userId) ? getMattBox() : Container(),
                RaisedGradientButton(
                    child: Text(
                      'Main Menu',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    height: 50,
                    width: 180,
                    gradient: LinearGradient(
                      colors: <Color>[
                        Colors.blue[500],
                        Colors.blue[100],
                      ],
                    ),
                    onPressed: () => Navigator.of(context).pop()),
                SizedBox(height: 10),
                RaisedGradientButton(
                    child: Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    height: 50,
                    width: 180,
                    gradient: LinearGradient(
                      colors: <Color>[
                        Colors.pink[500],
                        Colors.pink[100],
                      ],
                    ),
                    onPressed: () => signOut()),
              ],
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(50),
              child: Column(
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).highlightColor,
                        ),
                        borderRadius: BorderRadius.circular(20)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: Image(
                        height: 200,
                        image: AssetImage(
                          'assets/images/matt_aki.jpg',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    '    Matt and Aki live in LA and are always having a good time with friends and family. ',
                    style: TextStyle(
                      color: Theme.of(context).highlightColor,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 30),
                  Container(
                    height: 50,
                    width: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border:
                          Border.all(color: Theme.of(context).highlightColor),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.yellow[200],
                          Colors.yellow[700],
                        ], // whitish to gray
                        tileMode: TileMode
                            .repeated, // repeats the gradient over the canvas
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                    child: Center(
                      child: InkWell(
                        child: AutoSizeText(
                          'Give Matt coffee money!',
                          maxLines: 1,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        onTap: () => launch('http://paypal.me/takaomatt'),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Donating does not unlock any\nadditional features or functionality.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
