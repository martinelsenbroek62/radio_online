import 'dart:collection';

import 'package:admob_flutter/admob_flutter.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';

import 'Helper/Constant.dart';
import 'Helper/Model.dart';
import 'main.dart';

///get radio station lilst
List<Model> radioList = [];

///all radios
class RadioStation extends StatefulWidget {
  final VoidCallback _getCat, _refresh;
  final TextEditingController _textController;

  ///constructor
  RadioStation(
      {VoidCallback getCat,
      VoidCallback refresh,
      TextEditingController textController})
      : _getCat = getCat,
        _refresh = refresh,
        _textController = textController;

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<RadioStation> {
  ScrollController _controller;
  bool last = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: loading
            ? getLoader()
            : errorExist
                ? getNotFound()
                : getList());
  }

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _controller.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_controller.offset >= _controller.position.maxScrollExtent &&
        !_controller.position.outOfRange) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (offset < total) {
          widget._getCat();
        } else if (offset == total) {
          last = true;
        }
      });
    }
  }

  Widget listItem(int index, List<Model> radioList, bool running) {
    return index < radioList.length
        ? Card(
            elevation: 5.0,
            child: InkWell(
              onTap: () async {
                curPlayList = radioList;
                if (!running) {
                await  initializePlayer(index);
                } else {
                await  updateQueue();

               await AudioService.skipToQueueItem( curPlayList[index].radio_url);
                 
                
                }
              },
              child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.all(5.0),
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: FadeInImage(
                                placeholder: AssetImage(
                                  'assets/image/placeholder.png',
                                ),
                                image: NetworkImage(
                                  radioList[index].image,
                                ),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ))),
                      Expanded(
                          child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    radioList[index].name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle1
                                        .copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    radioList[index].description,
                                    style: Theme.of(context).textTheme.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ))),
                      IconButton(
                          icon: Icon(
                            Icons.play_arrow,
                            size: 40,
                            color: primary,
                          ),
                          onPressed: null),
                      FutureBuilder(
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return snapshot.data == true
                                ? IconButton(
                                    icon: Icon(
                                      Icons.favorite,
                                      size: 30,
                                      color: primary,
                                    ),
                                    onPressed: () async {
                                      await db.removeFav(radioList[index].id);
                                      if (!mounted) return;
                                      setState(() {});

                                      widget._refresh();
                                    })
                                : IconButton(
                                    icon: Icon(
                                      Icons.favorite_border,
                                      size: 30,
                                      color: primary,
                                    ),
                                    onPressed: () async {
                                      await db.setFav(
                                          radioList[index].id,
                                          radioList[index].name,
                                          radioList[index].description,
                                          radioList[index].image,
                                          radioList[index].radio_url);
                                      if (!mounted) return;
                                      setState(() {});

                                      widget._refresh();
                                    });
                          } else {
                            return Container();
                          }
                        },
                        future: db.getFav(radioList[index].id),
                      ),
                    ],
                  )),
            ),
          )
        : Container();
  }

  getNotFound() {
    return Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.only(top: 20),
        child: Text(
          'No Radio Station Available..!!',
          textAlign: TextAlign.center,
        ));
  }

  getList() {
    return StreamBuilder<bool>(
        stream: AudioService.runningStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.active) {
            return SizedBox();
          }

          final running = snapshot.data ?? false;
          return Padding(
              padding: const EdgeInsets.only(bottom: 200.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: isSearching &&
                        (searchresult.isNotEmpty ||
                            widget._textController.text.isNotEmpty)
                    ? ListView.builder(
                        physics: BouncingScrollPhysics(),
                        controller: _controller,
                        itemCount: searchresult.length,
                        itemBuilder: (context, index) {
                          if (index != 0 && index % AD_AFTER_ITEM == 0) {
                            return Column(
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(bottom: 20.0),
                                  child: AdmobBanner(
                                    adUnitId: getBannerAdUnitId(),
                                    adSize: AdmobBannerSize.BANNER,
                                  ),
                                ),
                                listItem(index, searchresult, running)
                              ],
                            );
                          } else
                            return listItem(index, searchresult, running);
                        },
                      )
                    : ListView.builder(
                        physics: BouncingScrollPhysics(),
                        controller: _controller,
                        itemCount: (offset <= total)
                            ? radioList.length + 1
                            : radioList.length,
                        itemBuilder: (context, index) {
                          return (index == radioList.length && !last)
                              ? Center(child: CircularProgressIndicator())
                              : (index != 0 && index % AD_AFTER_ITEM == 0)
                                  ? Column(
                                      children: <Widget>[
                                        Container(
                                          margin: EdgeInsets.symmetric(
                                              vertical: 10.0),
                                          child: AdmobBanner(
                                            adUnitId: getBannerAdUnitId(),
                                            adSize: AdmobBannerSize.BANNER,
                                          ),
                                        ),
                                        listItem(index, radioList, running)
                                      ],
                                    )
                                  : listItem(index, radioList, running);
                        },
                      ),
              ));
        });
  }

  getLoader() {
    return Container(
        height: 200, child: Center(child: CircularProgressIndicator()));
  }
}
