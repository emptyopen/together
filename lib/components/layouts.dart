import 'package:flutter/material.dart';

import 'package:together/components/misc.dart';

class LocationBoard extends StatefulWidget {
  LocationBoard({
    this.subList1,
    this.subList2,
    this.strikethroughs,
    this.contentsOnly = false,
    this.callback
  });

  final List<dynamic> subList1;
  final List<dynamic> subList2;
  final List<List<bool>> strikethroughs;
  final bool contentsOnly;
  final Function callback;

  @override
  _LocationBoardState createState() => _LocationBoardState();
}

class _LocationBoardState extends State<LocationBoard> {
  Widget getListWidgets(List<dynamic> strings, int columnIndex) {
    return Column(
        children: strings
            .asMap()
            .entries
            .map(
              (entry) => Column(
                children: <Widget>[
                  Container(
                    height: 35,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]),
                      borderRadius: BorderRadius.circular(20),
                      color: widget.strikethroughs[columnIndex]
                                  [entry.key] ? Colors.grey[700] : Colors.white,
                    ),
                    child: FlatButton(
                      splashColor: Color.fromARGB(0, 1, 1, 1),
                      highlightColor: Color.fromARGB(0, 1, 1, 1),
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: widget.contentsOnly ? 13 : 16,
                          color: widget.strikethroughs[columnIndex]
                                  [entry.key] ? Colors.white : Colors.black,
                          decoration: widget.strikethroughs[columnIndex]
                                  [entry.key]
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          widget.strikethroughs[columnIndex][entry.key] =
                              !widget.strikethroughs[columnIndex][entry.key];
                        });
                        widget.callback();
                      },
                    ),
                  ),
                  SizedBox(height: 5),
                ],
              ),
            )
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.contentsOnly) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          getListWidgets(widget.subList1, 0),
          getListWidgets(widget.subList2, 1),
        ],
      );
    }
    return Container(
      width: 280,
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 10,
          ),
          Text(
            'Location Scratchboard',
            style: TextStyle(fontSize: 21),
          ),
          PageBreak(width: 170),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              getListWidgets(widget.subList1, 0),
              getListWidgets(widget.subList2, 1),
            ],
          ),
        ],
      ),
    );
  }
}
