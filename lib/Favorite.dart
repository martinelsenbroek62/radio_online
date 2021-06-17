import 'dart:io';

import 'package:admob_flutter/admob_flutter.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'BottomPanel.dart';
import 'Helper/Constant.dart';
import 'Helper/Model.dart';
import 'Home.dart';
import 'Now_Playing.dart';
import 'main.dart';

///for bottom panel
PanelController panelController;

///list of search
List<Model> searchresult = [];

///currently searching
bool isSearching;

///radio station list
List<Model> radioStationList = [];

///sub category loading
bool subloading = true;

///favorite class
class Favorite extends StatefulWidget {

  @override
  _FavoriteState createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite> {
  GlobalKey<ScaffoldState> _globalKey = GlobalKey();
  final TextEditingController _controller = TextEditingController();
  AdmobInterstitial interstitialAd;

  Icon iconSerch = Icon(
    Icons.search,
    color: Colors.white,
  );

  Widget appBarTitle = Text(
    'Favorite',
    style: TextStyle(color: Colors.white),
  );

  _FavoriteState() {
    _controller.addListener(() {
      if (_controller.text.isEmpty) {
        if (!mounted) return;
        setState(() {
          isSearching = false;
          // _searchText = "";
        });
      } else {
        if (!mounted) return;
        setState(() {
          isSearching = true;
          //_searchText = _controller.text;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    isSearching = false;
    panelController = PanelController();

    admobInitalize();
 
  }

  Future<bool> _onWillPop() async {
    if (await interstitialAd.isLoaded)
      interstitialAd.show();
    else
      Navigator.pop(context, true);
  }

  @override
  void dispose() {
    if (!panelController.isPanelClosed) {
      panelController.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    BorderRadiusGeometry radius = BorderRadius.only(
      topLeft: Radius.circular(25.0),
      topRight: Radius.circular(25.0),
    );

    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
            key: _globalKey,
            appBar: getAppbar(),
            body: SlidingUpPanel(
                borderRadius: radius,
                panel: NowPlaying(
             
               
              refresh: _refresh,
                ),
                minHeight: 65,
                controller: panelController,
                maxHeight: MediaQuery.of(context).size.height,
                backdropEnabled: true,
                backdropOpacity: 0.5,
                parallaxEnabled: true,
                collapsed: GestureDetector(
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white, borderRadius: radius),
                    child: BottomPanel(
                   
                    ),
                  ),
                  onTap: () {
                    panelController.open();
                  },
                ),
                body: getContent())));
  }

  Widget getFavorite(bool running) {
    return FutureBuilder(
      builder: (context, projectSnap) {
        if (projectSnap.connectionState == ConnectionState.none ||
            projectSnap.data == null) {
          return Center(child: CircularProgressIndicator());
        } else {
          favSize = int.parse(projectSnap.data.length.toString());
          radioStationList = projectSnap.data as List<Model>;

          return favSize == 0
              ? Material(
                  child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        child: Center(child: Text('No Favorites Found..!')),
                        height: MediaQuery.of(context).size.height -
                            150 -
                            kToolbarHeight -
                            24,
                      )),
                )
              : Padding(
                  padding: const EdgeInsets.only(bottom: 150),
                  child: ListView.builder(
                      physics: BouncingScrollPhysics(),
                      itemCount: int.parse(projectSnap.data.length.toString()),
                      shrinkWrap: true,
          

                      itemBuilder: (context, i) {
              
                        return Card(
                          elevation: 5.0,
                          child: InkWell(
                            onTap: () async {
                           
                              curPlayList = projectSnap.data as List<Model>;

                              if (!running) {
                                initializePlayer(i);
                              } else {
                                await updateQueue();
                                await AudioService.skipToQueueItem(
                                    curPlayList[i].radio_url);
                            
                              }
                       
                            },
                            child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Row(
                                  children: <Widget>[
                                    Padding(
                                        padding: EdgeInsets.all(5.0),
                                        child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            child: FadeInImage(
                                              placeholder: AssetImage(
                                                'assets/image/placeholder.png',
                                              ),
                                              image: NetworkImage(
                                                projectSnap.data[i].image
                                                    .toString(),
                                              ),
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            ))),
                                    Expanded(
                                        child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 5.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Text(
                                                  //radioList[index].name,
                                                  projectSnap.data[i].name
                                                      .toString(),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .subtitle1
                                                      .copyWith(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  // dense: true,
                                                ),
                                                Text(
                                                  projectSnap
                                                      .data[i].description
                                                      .toString(),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .caption,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  // dense: true,
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
                                                    await db.removeFav(
                                                        projectSnap.data[i].id
                                                            .toString());
                                                    setState(() {});

                                                    //widget.refresh();
                                                  })
                                              : IconButton(
                                                  icon: Icon(
                                                    Icons.favorite_border,
                                                    size: 30,
                                                    color: primary,
                                                  ),
                                                  onPressed: () async {
                                                    await db.setFav(
                                                        projectSnap.data[i].id
                                                            .toString(),
                                                        projectSnap.data[i].name
                                                            .toString(),
                                                        projectSnap
                                                            .data[i].description
                                                            .toString(),
                                                        projectSnap
                                                            .data[i].image
                                                            .toString(),
                                                        projectSnap
                                                            .data[i].radio_url
                                                            .toString());
                                                    setState(() {});

                                                    // widget.refresh();
                                                  });
                                        } else {
                                          return Container();
                                        }
                                      },
                                      future: db.getFav(
                                          projectSnap.data[i].id.toString()),
                                    ),
                                  ],
                                )),
                          ),
                        );
                      }),
                );
        }
      },
      future: db.getAllFav(),
    );
  }

  Widget radiolistItem(int index, List<Model> catRadioList, bool running) {
    return Card(
      elevation: 5.0,
      child: InkWell(
        onTap: () async {
       
          curPlayList = catRadioList;

          if (!running) {
            initializePlayer(index);
          } else {
           await updateQueue();
            await AudioService.skipToQueueItem(curPlayList[index].radio_url);
        
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
                            catRadioList[index].image,
                          ),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ))),
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Text(
                    catRadioList[index].name,
                    style: Theme.of(context)
                        .textTheme
                        .subtitle1
                        .copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    // dense: true,
                  ),
                )),
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
                                await db.removeFav(catRadioList[index].id);
                                setState(() {});
                                // widget.refresh();
                              })
                          : IconButton(
                              icon: Icon(
                                Icons.favorite_border,
                                size: 30,
                                color: primary,
                              ),
                              onPressed: () async {
                                await db.setFav(
                                    catRadioList[index].id,
                                    catRadioList[index].name,
                                    catRadioList[index].description,
                                    catRadioList[index].image,
                                    catRadioList[index].radio_url);
                                if (!mounted) return;
                                setState(() {});

                                //  widget.refresh();
                              });
                    } else {
                      return Container();
                    }
                  },
                  future: db.getFav(catRadioList[index].id),
                ),
              ],
            )),
      ),
    );
  }

  void _refresh() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void searchOperation(String searchText) {
    searchresult.clear();
    if (isSearching != null) {
      for (int i = 0; i < radioStationList.length; i++) {
        Model data = radioStationList[i];

        if (data.name.toLowerCase().contains(searchText.toLowerCase())) {
           searchresult.add(data);
        }
      }

    }
  }

  void _handleSearchStart() {
    if (!mounted) {
      return;
    }
    setState(() {
      isSearching = true;
    });
  }

  void _handleSearchEnd() {
    if (!mounted) {
      return;
    }
    setState(() {
      iconSerch = Icon(
        Icons.search,
        color: Colors.white,
      );
      appBarTitle = Text(
        appname,
        style: TextStyle(color: Colors.white),
      );
      isSearching = false;
      _controller.clear();
    });
  }

  AppBar getAppbar() {
    return AppBar(
      title: appBarTitle,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [
                secondary,
                primary.withOpacity(0.5),
                primary.withOpacity(0.8)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              // Add one stop for each color. Stops should increase from 0 to 1
              stops: [0.15, 0.5, 0.7]),
        ),
      ),
      centerTitle: true,
      actions: <Widget>[
        IconButton(
          icon: iconSerch,
          onPressed: () {
            setState(() {
              if (iconSerch.icon == Icons.search) {
                iconSerch = Icon(
                  Icons.close,
                  color: Colors.white,
                );
                appBarTitle = TextField(
                  controller: _controller,
                  style: TextStyle(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Colors.white),
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: Colors.white),
                  ),
                  onChanged: searchOperation,
                );
                _handleSearchStart();
              } else {
                _handleSearchEnd();

              }
            });
          },
        )
      ],
    );
  }

  
  void admobInitalize() {
    interstitialAd = AdmobInterstitial(
      adUnitId: getInterstitialAdUnitId(),
      listener: (AdmobAdEvent event, Map<String, dynamic> args) {
        if (event == AdmobAdEvent.closed) {
          interstitialAd.load();
          Navigator.pop(context, true);
        }
      },
    );

    interstitialAd.load();
  }

  getContent() {
    return StreamBuilder<bool>(
        stream: AudioService.runningStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.active) {
            return SizedBox();
          }

          final running = snapshot.data ?? false;

          return isSearching &&
                  (searchresult.isNotEmpty || _controller.text.isNotEmpty)
              ? ListView.builder(
                  physics: BouncingScrollPhysics(),
                  itemCount: searchresult.length,
                  itemBuilder: (context, index) {
                    return radiolistItem(index, searchresult, running);
                  },
                )
              : getFavorite(running);
        });
  }
}
