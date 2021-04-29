import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:together/components/misc.dart';
import 'package:together/constants/values.dart';

class ClubSelectionTile extends StatefulWidget {
  final data;
  final Function callback;
  final String answer;
  final bool selected;
  final bool showMembers;
  final List members;
  final bool isTheClub;
  final bool isWouldYouRather;

  ClubSelectionTile({
    this.data,
    this.callback,
    this.answer,
    this.selected,
    this.showMembers = false,
    this.members = const [],
    this.isTheClub = false,
    this.isWouldYouRather = false,
  });

  @override
  _ClubSelectionTileState createState() => _ClubSelectionTileState();
}

class _ClubSelectionTileState extends State<ClubSelectionTile> {
  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;

    List<Widget> clubMembers = [Container()];
    widget.members.forEach((member) {
      clubMembers.add(AutoSizeText(
        widget.data['playerNames'][member],
        maxLines: 1,
      ));
    });
    clubMembers.add(Container());

    return GestureDetector(
      onTap: widget.callback,
      child: Stack(
        children: [
          Container(
            height: height * 0.3,
            width: width * 0.38,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).highlightColor,
                width: widget.showMembers
                    ? 3
                    : widget.selected
                        ? 3
                        : 1,
              ),
              borderRadius: BorderRadius.circular(15),
              gradient: widget.showMembers
                  ? widget.isTheClub
                      ? LinearGradient(
                          colors: [
                            Colors.lightGreen,
                            Colors.lightGreen[300],
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.grey,
                            Colors.grey[300],
                          ],
                        )
                  : widget.selected
                      ? LinearGradient(
                          colors: [
                            Colors.lightBlue[400],
                            Colors.lightBlue[200],
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.lightBlue[300].withAlpha(40),
                            Colors.lightBlue[100].withAlpha(40),
                          ],
                        ),
            ),
            padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Stack(
              children: [
                widget.showMembers
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            AutoSizeText(
                              widget.answer,
                              maxLines: 3,
                              wrapWords: false,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                              ),
                            ),
                            SizedBox(height: 3),
                            clubMembers.length > 2
                                ? PageBreak(width: 40)
                                : Container(),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: clubMembers,
                            ),
                          ])
                    : Center(
                        child: Container(
                          padding: EdgeInsets.fromLTRB(0, 50, 0, 50),
                          child: AutoSizeText(
                            widget.answer,
                            wrapWords: false,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 200,
                            ),
                          ),
                        ),
                      ),
                widget.isTheClub && widget.showMembers
                    ? Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(5),
                              bottomRight: Radius.circular(5),
                            ),
                            color: Colors.black,
                          ),
                          padding: EdgeInsets.fromLTRB(4, 2, 4, 4),
                          child: Shimmer.fromColors(
                            period: Duration(seconds: 2),
                            baseColor: Colors.grey,
                            highlightColor: Colors.white,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  gameIcons[inTheClubString],
                                  size: 18,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'the club',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Icon(
                                  gameIcons[inTheClubString],
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Container(),
                widget.showMembers
                    ? Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(5),
                              topRight: Radius.circular(5),
                            ),
                            color: Colors.black,
                          ),
                          padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
                          child: widget.isTheClub
                              ? Shimmer.fromColors(
                                  period: Duration(seconds: 2),
                                  baseColor: Colors.grey,
                                  highlightColor: Colors.white,
                                  child: Text(
                                    widget.isWouldYouRather
                                        ? '+${(widget.members.length + 1) * 2} pts'
                                        : '+${widget.members.length + 1} pts',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  widget.isWouldYouRather
                                      ? '+${widget.members.length * 2} pts'
                                      : '+${widget.members.length} pts',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      )
                    : Container(),
              ],
            ),
          ),
          Container(
            height: height * 0.3,
            width: width * 0.38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: widget.members.length > 0 || !widget.showMembers
                  ? Colors.white.withAlpha(0)
                  : Colors.grey.withAlpha(120),
            ),
          ),
        ],
      ),
    );
  }
}
