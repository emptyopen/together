import 'package:flutter/material.dart';
import 'package:together/components/scroll_view.dart';

getLog(data, context, double width) {
  var latestLog = data['log'].last;
  var secondLatestLog = data['log'][data['log'].length - 2];
  var thirdLatestLog = data['log'][data['log'].length - 3];
  var brightness = MediaQuery.of(context).platformBrightness;
  bool darkModeOn = brightness == Brightness.dark;

  List<Widget> fullLogs = [];
  data['log'].sublist(3).reversed.forEach((v) {
    fullLogs.add(
      Text(
        v,
        style: TextStyle(
          fontSize: v.startsWith('Now') && v.endsWith('turn') ? 14 : 16,
          color: v.startsWith('Now') && v.endsWith('turn')
              ? Colors.grey
              : Theme.of(context).highlightColor,
        ),
      ),
    );
  });

  showLog() {
    showDialog<Null>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logs:'),
          contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
          content: Container(
            height: 200,
            child: Column(
              children: <Widget>[
                SizedBox(height: 10),
                Container(
                  height: 190,
                  child: Container(
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: Theme.of(context).highlightColor),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.all(10),
                    child: TogetherScrollView(
                      child: Column(
                        children: fullLogs,
                      ),
                    ),
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
                child: Text('OK'),
              ),
            ),
          ],
        );
      },
    );
  }

  return Container(
    width: width,
    height: 70,
    constraints: BoxConstraints(),
    decoration: BoxDecoration(
      color: Theme.of(context).dialogBackgroundColor,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: Theme.of(context).highlightColor),
    ),
    alignment: Alignment.center,
    child: GestureDetector(
      onTap: () {
        showLog();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: 3),
          Text(
            '> ' + latestLog + ' <',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).highlightColor,
            ),
          ),
          SizedBox(height: 3),
          Text(
            secondLatestLog,
            style: TextStyle(
              fontSize: 9,
              color: darkModeOn ? Colors.grey[200] : Colors.grey[800],
            ),
          ),
          SizedBox(height: 3),
          Text(
            thirdLatestLog,
            style: TextStyle(
              fontSize: 9,
              color: darkModeOn ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          SizedBox(height: 3),
          Text(
            '(click to show full logs)',
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 3),
        ],
      ),
    ),
  );
}
