import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'Helper/AudioPlayerTask.dart';
import 'Helper/Constant.dart';

///now playing bottom panel
class BottomPanel extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    return getBottomPanelLayout();
  }

  ///bottom panel layout
  Widget getBottomPanelLayout() {
    return
     Directionality(
                        textDirection: direction,
                        child:
     Container(
        // Add box decoration
        decoration: getBackGradient(),
        child: curPlayList.isNotEmpty ? getRowLayout() : Container()));
  }

  getBackGradient() {
    return BoxDecoration(
      // Box decoration takes a gradient
      gradient: LinearGradient(
        // Where the linear gradient begins and ends
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        // Add one stop for each color. Stops should increase from 0 to 1
        stops: [0.2, 0.5, 0.9],
        colors: [
          secondary,
          primary.withOpacity(0.7),
          primary,
        ],
      ),
    );
  }

  getRowLayout() {
   
    return StreamBuilder<QueueState>(
        stream: queueStateStream,
        builder: (context, snapshot) {
          final queueState = snapshot.data;
          final queue = queueState?.queue ?? [];
          final mediaItem = queueState?.mediaItem;



       
          return Row(
            children: <Widget>[
              Expanded(
                child: Row(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(right: 20, left: 10),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: FadeInImage(
                            placeholder:
                                AssetImage('assets/image/placeholder.png'),
                            image: NetworkImage(mediaItem == null
                                ? curPlayList[0].image
                                : mediaItem.artUri.toString()),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )),
                    ),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              mediaItem == null
                                  ? curPlayList[0].name
                                  : mediaItem.title,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  TextStyle(fontSize: 15, color: Colors.white),
                            ),
                          ),
                          MarqueeWidget(
                              direction: Axis.horizontal,
                              child: Text(
                                mediaItem == null
                                    ? curPlayList[0].description
                                    : mediaItem.artist,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.white),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: StreamBuilder<bool>(
                        stream: AudioService.runningStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.active) {
                            return SizedBox();
                          }

                          final running = snapshot.data ?? false;
                  
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!running) ...[
                                // UI to show when we're not running, i.e. a menu.
                                audioPlayerButton(
                                    Icon(Icons.play_circle_outline)),
                              ] else ...[
                                StreamBuilder<bool>(
                                  stream: AudioService.playbackStateStream
                                      .map((state) => state.playing)
                                      .distinct(),
                                  builder: (context, snapshot) {
                                    final playing = snapshot.data ?? false;

                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (playing)
                                          pauseButton(
                                              Icon(Icons.pause_circle_outline))
                                        else
                                          playButton(
                                              Icon(Icons.play_circle_outline)),
                                      ],
                                    );
                                  },
                                ),
                              ]
                            ],
                          );
                        })),
              )
            ],
          );
        });
  }
}

///current playing song name marquee
class MarqueeWidget extends StatefulWidget {
  final Widget _child;
  final Axis _direction;
  final Duration _animationDuration = const Duration(milliseconds: 3000),
      _backDuration = const Duration(milliseconds: 800),
      _pauseDuration = const Duration(milliseconds: 800);

  ///constructor
  MarqueeWidget({
    Widget child,
    Axis direction,
  })  : _child = child,
        _direction = direction;

  @override
  _MarqueeWidgetState createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget> {
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    scroll();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: widget._child,
      scrollDirection: widget._direction,
      controller: _scrollController,
    );
  }

  void scroll() async {
    //while (true) {
    if (!mounted) {
      return;
    }
    await Future.delayed(widget._pauseDuration);
    await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: widget._animationDuration,
        curve: Curves.easeIn);

    await Future.delayed(widget._pauseDuration);
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(0.0,
            duration: widget._backDuration, curve: Curves.easeOut);
      }
    });
    //}
  }
}
