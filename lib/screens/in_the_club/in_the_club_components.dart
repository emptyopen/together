import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class ClubSelectionTile extends StatefulWidget {
  final Function callback;
  final String answer;
  final bool selected;

  ClubSelectionTile({
    this.callback,
    this.answer,
    this.selected,
  });

  @override
  _ClubSelectionTileState createState() => _ClubSelectionTileState();
}

class _ClubSelectionTileState extends State<ClubSelectionTile> {
  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: widget.callback,
      child: Container(
        height: height * 0.23,
        width: width * 0.36,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).highlightColor,
            width: widget.selected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(15),
          gradient: widget.selected
              ? LinearGradient(
                  colors: [
                    Colors.lightBlue[300],
                    Colors.lightBlue[100],
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.lightBlue[300].withAlpha(40),
                    Colors.lightBlue[100].withAlpha(40),
                  ],
                ),
        ),
        padding: EdgeInsets.all(10),
        child: Center(
          child: AutoSizeText(
            widget.answer,
            maxLines: 3,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
            ),
          ),
        ),
      ),
    );
  }
}
