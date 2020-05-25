import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:together/services/authentication.dart';
import 'package:together/components/buttons.dart';

class SettingsScreen extends StatefulWidget {
  SettingsScreen({Key key, this.auth, this.logoutCallback}) : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TextEditingController _newNameController = new TextEditingController();
  String currName;
  String nameError = '';

  @override
  void initState() {
    super.initState();
    getCurrName();
  }

  getCurrName() async {
    var userId = (await FirebaseAuth.instance.currentUser()).uid;
    Map<String, dynamic> data =
        (await Firestore.instance.collection('users').document(userId).get())
            .data;
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
    var userId = (await FirebaseAuth.instance.currentUser()).uid;
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
      await Firestore.instance
          .collection('users')
          .document(userId)
          .updateData({'name': _newNameController.text}); 
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(fontFamily: 'Balsamiq'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 200,
              decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(20)),
              padding: EdgeInsets.all(15),
              child: Column(
                children: <Widget>[
                  Text('Change name', style: TextStyle(fontSize: 20), textAlign: TextAlign.left,),
                  Text('Current name: $currName', style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.left),
                  SizedBox(height: 8),
                  Container(
                    height: 40,
                    child: Center(
                      child: TextField(
                        controller: _newNameController,
                        decoration: InputDecoration(contentPadding: EdgeInsets.fromLTRB(10, 0, 10, 0), border: OutlineInputBorder()),
                      ),
                    ),
                  ),
                  SizedBox(height: 3),
                  RaisedGradientButton(
                    width: 120,
                    height: 40,
                    child: Text('Update name'),
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
            SizedBox(height: 30),
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
    );
  }
}
