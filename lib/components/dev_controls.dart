import 'package:flutter/material.dart';
import 'package:together/components/buttons.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DevControls extends StatefulWidget {
  @override
  _DevControlsState createState() => _DevControlsState();
}

class _DevControlsState extends State<DevControls> {
  bool hidden = true;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).highlightColor,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: EdgeInsets.all(5),
      child: hidden
          ? DevButton(
              onPressed: () {
                setState(() {
                  hidden = !hidden;
                });
              },
              text: 'Show',
              width: 80,
            )
          : Column(
              children: [
                DevButton(
                  onPressed: () {
                    setState(() {
                      hidden = !hidden;
                    });
                  },
                  text: 'Hide',
                  width: 80,
                ),
                SizedBox(height: 5),
                DevButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _firebaseAuth.signOut();
                    await _firebaseAuth.signInWithEmailAndPassword(
                        email: 'markus@g.com', password: 'valnme');
                    // rejoin game
                  },
                  text: 'Login Markus',
                  width: 100,
                ),
                SizedBox(height: 5),
                DevButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _firebaseAuth.signOut();
                    await _firebaseAuth.signInWithEmailAndPassword(
                        email: 'vanessa@g.com', password: 'valnme');
                    // rejoin game
                  },
                  text: 'Login Vanessa',
                  width: 105,
                ),
              ],
            ),
    );
  }
}

class DevButton extends StatelessWidget {
  final onPressed;
  final String text;
  final double width;

  DevButton({
    this.onPressed,
    this.text,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return RaisedGradientButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
        ),
      ),
      gradient: LinearGradient(
        colors: [
          Colors.grey[700],
          Colors.grey[600],
        ],
      ),
      width: width,
      height: 22,
    );
  }
}
