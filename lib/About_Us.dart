import 'dart:async';
import 'dart:convert';

import 'package:admob_flutter/admob_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:http/http.dart' as http;

import 'Helper/Constant.dart';

class AboutUS extends StatefulWidget {
  @override
  _aboutState createState() => _aboutState();
}

class _aboutState extends State<AboutUS> {
  String _privacy;
  String _loading = "true";
  AdmobInterstitial interstitialAd;

  @override
  void initState() {
    super.initState();
    admobInitalize();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadLocalHTML(),
      builder: (context, snapshot) {
        if (_loading.compareTo('true') == 0) {
          return Scaffold(
            appBar: AppBar(
              title: Text('About Us'),
              centerTitle: true,
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          return WillPopScope(
              onWillPop: _onWillPop,
              child: WebviewScaffold(
                appBar: AppBar(
                  title: Text('About Us'),
                  centerTitle: true,
                ),
                withJavascript: true,
                appCacheEnabled: true,
                url: Uri.dataFromString(_privacy,
                        mimeType: 'text/html', encoding: utf8)
                    .toString(),
              ));
        }
      },
    );
  }

  Future _loadLocalHTML() async {
    Map data = {
      'access_key': "6808",
    };

    var response = await http.post(about_api, body: data);

    var getdata = json.decode(response.body);
    String error = getdata['error'].toString();
    if (error.compareTo('false') == 0) {
      setState(() {
        _loading = 'false';
        _privacy = getdata['data'].toString();
      });
    }
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

  Future<bool> _onWillPop() async {
    if (await interstitialAd.isLoaded)
      interstitialAd.show();
    else
      Navigator.pop(context, true);
  }
}
