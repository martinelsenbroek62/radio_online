import 'dart:async';
import 'dart:convert';

import 'package:admob_flutter/admob_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:http/http.dart' as http;

import 'Helper/Constant.dart';

///privacy policy class
class PrivacyPolicy extends StatefulWidget {
  @override
  _PrivacyPolicyState createState() => _PrivacyPolicyState();
}

class _PrivacyPolicyState extends State<PrivacyPolicy> {
  String _privacy;
  String _loading = 'true';
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
            appBar: AppBar(title: Text('Privacy Policy',),centerTitle: true,),
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          return WillPopScope(
              onWillPop: _onWillPop,
              child: WebviewScaffold(
                appBar: AppBar(title: Text('Privacy Policy'),centerTitle: true,),
                withJavascript: true,
                appCacheEnabled: true,
                url: Uri.dataFromString(_privacy, mimeType: 'text/html',encoding: utf8)
                    .toString(),
              ));
        }
      },
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

  Future<bool> _onWillPop() async {
    if (await interstitialAd.isLoaded)
      interstitialAd.show();
    else
      Navigator.pop(context, true);
  }

  Future _loadLocalHTML() async {
    var data = {
      'access_key': '6808',
    };

    var response = await http.post(privacy_api, body: data);

    var getdata = json.decode(response.body);
    var error = getdata['error'].toString();
    if (error.compareTo('false') == 0) {
      setState(() {
        _privacy = getdata['data'].toString();
        _loading = 'false';
      });
    }
  }
}
