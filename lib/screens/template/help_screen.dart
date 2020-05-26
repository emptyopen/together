import 'package:flutter/material.dart';
import 'package:transformer_page_view/transformer_page_view.dart';

import 'package:together/components/buttons.dart';
import 'package:together/components/misc.dart';

class HelpScreen extends StatefulWidget {
  final String title;
  final List<String> information;
  final Color buttonColor;
  final Function callback;

  HelpScreen({
    this.title = '',
    this.information,
    this.buttonColor,
    this.callback,
  });

  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int slideIndex = 0;
  final IndexController indexController = IndexController();
  List<Widget> informationList = [];
  bool firstHelp = true;

  @override
  void initState() {
    super.initState();

    if (widget.information.length > 1) {
      informationList.add(Column(
        children: <Widget>[
          Text(
            widget.information[0],
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.left,
          ),
          SizedBox(
            height: 20,
          ),
          Text(
            '(Swipe for more information)',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ));
      widget.information.sublist(1).forEach((f) {
        informationList.add(Text(
          f,
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.left,
        ));
      });
    } else {
      informationList.add(Text(
        widget.information[0],
        style: TextStyle(fontSize: 18),
        textAlign: TextAlign.left,
      ));
    }
  }

  getSlideCircles(
      int numCircles, int currentCircleIndex, Color highlightColor) {
    List<Widget> circles = [];
    for (int i = 0; i < numCircles; i++) {
      bool isCurrent = i == currentCircleIndex;
      circles.add(
        Container(
          height: isCurrent ? 14 : 10,
          width: isCurrent ? 14 : 10,
          decoration: BoxDecoration(
            color: isCurrent ? highlightColor : Colors.grey,
            borderRadius:
                isCurrent ? BorderRadius.circular(7) : BorderRadius.circular(7),
            // border: i == currentCircleIndex ? Border.all(color) : null,
          ),
        ),
      );
      circles.add(
        SizedBox(
          width: 5,
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: circles,
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    TransformerPageView transformerPageView = TransformerPageView(
      pageSnapping: true,
      onPageChanged: (index) {
        setState(() {
          slideIndex = index;
        });
      },
      loop: false,
      controller: indexController,
      transformer:
          PageTransformerBuilder(builder: (Widget child, TransformInfo info) {
        return Container(
          margin: EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(50)),
          alignment: Alignment.center,
          child: Stack(
            children: <Widget>[
              Center(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        slideIndex == 0
                            ? Column(
                                children: <Widget>[
                                  Text(
                                    widget.title,
                                    style: TextStyle(
                                      fontSize: 28,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                ],
                              )
                            : Container(),
                        slideIndex == 0 ? PageBreak(width: 80) : Container(),
                        ParallaxContainer(
                          child: informationList[info.index],
                          position: info.position,
                          translationFactor: 100,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              widget.information.length > 1
                  ? Padding(
                      padding: EdgeInsets.all(25),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: getSlideCircles(widget.information.length,
                            slideIndex, widget.buttonColor),
                      ),
                    )
                  : Container(),
            ],
          ),
        );
      }),
      itemCount: widget.information.length,
    );

    return Material(
        color: Color.fromRGBO(0, 0, 0, 0.7),
        child: Stack(
          children: <Widget>[
            Container(
              color: Colors.transparent,
              constraints: BoxConstraints.expand(),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: screenWidth * 0.9,
                    height: screenHeight * 0.65,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(5))),
                    child: transformerPageView,
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  HelpOKButton(
                    buttonColor: widget.buttonColor,
                    buttonSplashColor: widget.buttonColor,
                    callback: widget.callback,
                  )
                ],
              ),
            ),
          ],
        ));
  }
}

class HelpOKButton extends StatelessWidget {
  final Color buttonColor;
  final Color buttonSplashColor;
  final String firstHelpKey;
  final Function callback;

  HelpOKButton(
      {this.buttonColor,
      this.buttonSplashColor,
      this.firstHelpKey,
      this.callback});

  @override
  Widget build(BuildContext context) {
    return RaisedGradientButton(
      child: Text('Fine', style: TextStyle(color: Colors.white, fontSize: 22)),
      onPressed: () {
        if (callback != null) {
          callback();
        }
        Navigator.pop(context);
      },
      height: 60,
      width: 120,
      gradient: LinearGradient(
        colors: <Color>[
          Theme.of(context).primaryColor,
          Theme.of(context).accentColor,
        ],
      ),
      borderHighlight: true,
    );
  }
}
