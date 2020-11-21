import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:simple_animations/simple_animations.dart';

class TogetherScrollView extends StatefulWidget {
  final Widget child;
  final double cornerDistance;
  final double iconSize;

  TogetherScrollView(
      {this.child, this.cornerDistance = 25, this.iconSize = 24});

  @override
  _TogetherScrollViewState createState() => _TogetherScrollViewState();
}

class _TogetherScrollViewState extends State<TogetherScrollView> {
  ScrollController _controller;
  double hysteresis = 30;

  @override
  initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool showTop = _controller.hasClients &&
        _controller.offset < _controller.position.maxScrollExtent - hysteresis;
    bool showBottom = _controller.hasClients &&
        _controller.offset > _controller.position.minScrollExtent + hysteresis;
    if (showTop && showBottom) {
      // choose closer
      if (_controller.position.maxScrollExtent - _controller.offset >
          _controller.offset - _controller.position.minScrollExtent) {
        showBottom = false;
      } else {
        showTop = false;
      }
    }
    return Stack(
      children: [
        SingleChildScrollView(
          controller: _controller,
          child: widget.child,
        ),
        showTop
            ? Positioned(
                bottom: widget.cornerDistance,
                right: widget.cornerDistance,
                child: BouncingScrollWidget(
                  isUp: false,
                  size: widget.iconSize,
                ),
              )
            : Container(),
        showBottom
            ? Positioned(
                top: widget.cornerDistance,
                right: widget.cornerDistance,
                child: BouncingScrollWidget(
                  isUp: true,
                  size: widget.iconSize,
                ),
              )
            : Container(),
      ],
    );
  }
}

class BouncingScrollWidget extends StatelessWidget {
  final bool isUp;
  final double size;

  BouncingScrollWidget({
    this.isUp,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return MirrorAnimation<double>(
      tween: Tween(begin: 0, end: 5),
      duration: Duration(
        milliseconds: 500,
      ),
      builder: (context, child, value) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            5,
            value,
            5,
            value,
          ),
          child: Icon(
            isUp ? MdiIcons.chevronDoubleUp : MdiIcons.chevronDoubleDown,
            color: Theme.of(context).highlightColor.withAlpha(150),
            size: size,
          ),
        );
      },
    );
  }
}
