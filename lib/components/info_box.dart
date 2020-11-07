import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class InfoBox extends StatelessWidget {
  final String text;
  final String infoKey;
  final userData;
  final String userId;
  final List<String> dependentInfoKeys;

  InfoBox({
    this.text,
    this.infoKey,
    this.userData,
    this.userId,
    this.dependentInfoKeys = const [],
  });

  setInfoKey() async {
    HapticFeedback.vibrate();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({infoKey: true});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container();
          }
          var data = snapshot.data.data();
          // don't display until all dependent keys exist
          bool dependentInfoKeysSatisfied = true;
          dependentInfoKeys.forEach((v) {
            if (!data.containsKey(v)) {
              dependentInfoKeysSatisfied = false;
            }
          });
          if (data.containsKey(infoKey) || !dependentInfoKeysSatisfied) {
            return Container();
          }
          return MirrorAnimation<double>(
              // <-- specify type of animated variable
              tween: Tween(begin: 0, end: 5),
              duration: Duration(
                milliseconds: 500,
              ),
              builder: (context, child, value) {
                // <-- builder function
                return Container(
                  padding: EdgeInsets.fromLTRB(
                    5,
                    value,
                    5,
                    value,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setInfoKey();
                    },
                    child: Stack(
                      children: [
                        Container(
                          height: 60,
                          padding: EdgeInsets.fromLTRB(20, 10, 15, 5),
                          decoration: BoxDecoration(
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(5),
                            color: Colors.black.withAlpha(140),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                text,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '(tap to never see again)',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              )
                            ],
                          ),
                        ),
                        // add arrow
                        Positioned(
                          top: 2,
                          right: 8,
                          child: Icon(
                            MdiIcons.chevronUp,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
        });
  }
}
