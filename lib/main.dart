import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:admob_flutter/admob_flutter.dart';
import 'package:app_review/app_review.dart';
import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share/share.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'About_Us.dart';
import 'All_Radio_Station.dart';
import 'BottomPanel.dart';
import 'Category.dart';
import 'City.dart';
import 'Favorite.dart';
import 'Helper/Constant.dart';
import 'Helper/Favourite_Helper.dart';
import 'Helper/Model.dart';
import 'Helper/PushNotificationService.dart';
import 'Home.dart';
import 'Now_Playing.dart';
import 'Privacy_Policy.dart';
import 'Splash.dart';
import 'Terms.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(myForgroundMessageHandler);

  Admob.initialize();
  runApp(MyApp());
}

///root of your application, starting point of execution
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radio App',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: Directionality(
        textDirection: direction, // set this property
        child: Splash(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

///all radio station is loading
bool loading = true;

///offset for load more
int offset = 0;

///total radio station
int total = 0;

///no of item to load in one time
int perPage = 10;

///temp radio list for load more
List<Model> tempSongList = [];

///is error exist
bool errorExist = false;

///search list
List<Model> searchList = [];

///favorite database
var db = Favourite_Helper();

///bottom panel
PanelController panelController;

///after search result list
List<Model> searchresult = [];

///currently is searching
bool isSearching;

///home tab controller
TabController tabController;

///main contianer of app
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  GlobalKey<ScaffoldState> _globalKey = GlobalKey();
  final TextEditingController _controller = TextEditingController();
  DateTime _currentBackPressTime;
  bool call = false;

  Icon iconSearch = Icon(
    Icons.search,
    color: Colors.white,
  );

  Widget appBarTitle = Text(
    appname,
    style: TextStyle(color: Colors.white),
  );

  _MyHomePageState() {
    _controller.addListener(() {
      if (_controller.text.isEmpty) {
        if (!mounted) return;
        setState(() {
          isSearching = false;
        });
      } else {
        isSearching = true;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    isSearching = false;
    panelController = PanelController();

    tabController = TabController(length: 3, vsync: this);

    offset = 0;
    total = 0;
    tempSongList.clear();
    radioList.clear();

    getRadioStation();
  }

  @override
  void dispose() {
    if (!panelController.isPanelClosed) {
      panelController.close();
    }
    // Dispose of the Tab Controller
    tabController.dispose();

    super.dispose();
  }

  Future onDidReceiveLocalNotification(
      int id, String title, String body, String payload) {
    return showDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Ok'),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyApp(),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Future onSelectNotification(String payload) async {
    if (payload != null) {}
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyApp()),
    );
  }

  @override
  Widget build(BuildContext context) {
    BorderRadiusGeometry radius = BorderRadius.only(
      topLeft: Radius.circular(25.0),
      topRight: Radius.circular(25.0),
    );

    return AudioServiceWidget(
        child: WillPopScope(
            onWillPop: _onWillPop,
            child: Directionality(
                textDirection: direction,
                child: Scaffold(
                    key: _globalKey,
                    appBar: getAppbar(),
                    drawer: getDrawer(),
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
                            child: BottomPanel(),
                          ),
                          onTap: () {
                            panelController.open();
                          },
                        ),
                        body: getTabBarView(<Widget>[
                          Directionality(
                            textDirection: direction, // set this property
                            child: Home(),
                          ),
                          Directionality(
                            textDirection: direction,
                            // set this property
                            child: cityMode
                                ? City(
                                    refresh: _refresh,
                                  )
                                : Category(
                                    refresh: _refresh,
                                  ),
                          ),
                          Directionality(
                            textDirection: direction, // set this property
                            child: RadioStation(
                              getCat: getRadioStation,
                              refresh: _refresh,
                              textController: _controller,
                            ),
                          ),
                        ]))))));
  }

  Future<bool> _onWillPop() async {
    if (!panelController.isPanelClosed) {
      panelController.close();
      return Future<bool>.value(false);
    } else if (_globalKey.currentState.isDrawerOpen) {
      Navigator.pop(context); // closes the drawer if opened
      return Future.value(false); // won't exit the app
    } else {
      var now = DateTime.now();
      if (_currentBackPressTime == null ||
          now.difference(_currentBackPressTime) > Duration(seconds: 2)) {
        _currentBackPressTime = now;
        _globalKey.currentState.showSnackBar(SnackBar(
          content: Text(
            'Double tap to exit app',
            textAlign: TextAlign.center,
          ),
          backgroundColor: primary,
          behavior: SnackBarBehavior.floating,
          elevation: 1.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50.0),
          ),
        ));
        return Future.value(false);
      }
      dispose();
      return Future.value(true);
    }
  }

  TabBarView getTabBarView(List<Widget> tabs) {
    return TabBarView(
      // Add tabs as widgets
      children: tabs,
      // set the controller
      controller: tabController,
      //  dragStartBehavior: DragStartBehavior.down,
    );
  }

  TabBar getTabBar() {
    return TabBar(
      indicatorColor: Colors.white,
      tabs: <Tab>[
        Tab(
          text: 'Home',
        ),
        Tab(
          text: cityMode ? 'City' : 'Category',
        ),
        Tab(
          text: 'All Radio',
        ),
      ],
      // setup the controller
      controller: tabController,
    );
  }

  void getRadioStation() async {
    var data = {
      'access_key': '6808',
      'limit': perPage.toString(),
      'offset': offset.toString()
    };
    var response = await http.post(radio_station, body: data);

    var getdata = json.decode(response.body);
    total = int.parse(getdata['total'].toString());
    var error = getdata['error'].toString();

    setState(() {
      if (error == 'true' || (total) == 0) {
        loading = false;
        errorExist = true;
      } else {
        var gData = getdata['data'];

        loading = false;

        if ((offset) < total) {
          tempSongList.clear();

          tempSongList = (gData as List)
              .map((data) => Model.fromJson(data as Map<String, dynamic>))
              .toList();

          radioList.addAll(tempSongList);

          curPlayList = radioList;

          offset = offset + perPage;
        }
      }
    });
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> searchOperation(String searchText) async {
    if (isSearching != null) {
      var data = {'access_key': '6808', 'keyword': searchText};

      var response = await http.post(search_api, body: data);
      var getdata = json.decode(response.body);

      var error = getdata['error'].toString();

      if (error == 'false') {
        searchresult.clear();
        searchList.clear();

        var data = (getdata['data']);

        searchList = (data as List)
            .map((data) => Model.fromJson(data as Map<String, dynamic>))
            .toList();
      }

      for (var i = 0; i < searchList.length; i++) {
        Model data = searchList[i];

        if (data.name.toLowerCase().contains(searchText.toLowerCase())) {
          searchresult.add(data);
        }
      }
      if (!mounted) return;
      setState(() {});
    }
  }

  void _handleSearchStart() {
    if (!mounted) return;
    setState(() {
      isSearching = true;
      tabController.animateTo(2);
    });
  }

  void _handleSearchEnd() {
    if (!mounted) return;
    setState(() {
      iconSearch = Icon(
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
              stops: [0.15, 0.5, 0.7]),
        ),
      ),
      centerTitle: true,
      bottom: getTabBar(),
      actions: <Widget>[
        IconButton(
          icon: iconSearch,
          onPressed: () {
            //print("call search");
            if (!mounted) return;
            setState(() {
              if (iconSearch.icon == Icons.search) {
                iconSearch = Icon(
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

  Drawer getDrawer() {
    return Drawer(
      child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [
                  secondary,
                  primary.withOpacity(0.5),
                  primary.withOpacity(0.8)
                ],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                // Add one stop for each color. Stops should increase from 0 to 1
                stops: [0.2, 0.4, 0.9],
                tileMode: TileMode.clamp),
          ),
          child: ListView(
            physics: BouncingScrollPhysics(),
            children: <Widget>[
              Image.asset(
                'assets/image/logo.png',
                width: 150,
                height: 150,
              ),
              ListTile(
                  leading: Icon(Icons.home, color: Colors.white),
                  title: Text(
                    'Home',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    tabController.animateTo(0);
                  }),
              ListTile(
                  leading: Icon(Icons.category, color: Colors.white),
                  title: Text(
                    cityMode ? 'City' : 'Category',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    tabController.animateTo(1);
                  }),
              ListTile(
                  leading: Icon(Icons.radio, color: Colors.white),
                  title: Text(
                    'All Radio',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    tabController.animateTo(2);
                  }),
              ListTile(
                  leading: Icon(Icons.favorite, color: Colors.white),
                  title: Text(
                    'Favourite',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Directionality(
                            textDirection: direction,
                            child: Favorite(),
                          ),
                        ));
                  }),
              Divider(),
              ListTile(
                  leading: Icon(Icons.share, color: Colors.white),
                  title: Text(
                    'Share App',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (Platform.isAndroid) {
                      Share.share('I am listening to-\n'
                          '$appname\n'
                          'https://play.google.com/store/apps/details?id=$androidPackage&hl=en');
                    } else {
                      Share.share('I am listening to-\n'
                          '$appname\n'
                          '$iosPackage');
                    }
                  }),
              ListTile(
                  leading: Icon(Icons.security, color: Colors.white),
                  title: Text(
                    'Privacy Policy',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Directionality(
                              textDirection: direction,
                              // set this property
                              child: PrivacyPolicy()),
                        ));
                  }),
              ListTile(
                  leading: Icon(Icons.warning, color: Colors.white),
                  title: Text(
                    'Terms & Conditions',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Directionality(
                              textDirection: direction,
                              // set this property
                              child: Terms()),
                        ));
                  }),
              ListTile(
                  leading: Icon(Icons.info, color: Colors.white),
                  title: Text(
                    'About Us',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Directionality(
                              textDirection: direction,
                              // set this property
                              child: AboutUS()),
                        ));
                  }),
              ListTile(
                  leading: Icon(Icons.star, color: Colors.white),
                  title: Text(
                    'Rate App',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    AppReview.requestReview.then((onValue) {});
                  }),
            ],
          )),
    );
  }
}
