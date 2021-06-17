import 'dart:convert';

import 'package:admob_flutter/admob_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'Helper/Constant.dart';
import 'Helper/Model.dart';
import 'Home.dart';
import 'SubCategory.dart';
import 'main.dart';

///for managing cat, sub-cat visibility in single layout
bool catVisible = false;

///category sub-cat claass
class Category extends StatefulWidget {
  final VoidCallback _refresh;

  ///constructor
  Category({
    VoidCallback refresh,
  }) : _refresh = refresh;

  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Category>
    with AutomaticKeepAliveClientMixin<Category> {
  ScrollController _controller;
  List<Model> _catRadioList = [];
  bool _errorExist = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(body: catLayout());
  }

  Widget catLayout() {
    return catloading
        ? getLoader()
        : _errorExist
            ? getErrorMsg()
            : getCatGrid();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  Widget listItem(int index) {
    return Card(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      elevation: 5.0,
      child: Stack(alignment: Alignment.bottomCenter, children: <Widget>[
        ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: FadeInImage(
              placeholder: AssetImage(
                'assets/image/placeholder.png',
              ),
              image: NetworkImage(
                catList[index].image,
              ),
              height: double.maxFinite,
              width: double.maxFinite,
              fit: BoxFit.cover,
            )),
        Container(
          width: double.infinity,
          color: Colors.black.withOpacity(0.6),
          padding: const EdgeInsets.all(5.0),
          child: Text(
            catList[index].cat_name,
            style: Theme.of(context)
                .textTheme
                .subtitle1
                .copyWith(color: Colors.white),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        new Positioned.fill(
            child: new Material(
                color: Colors.transparent,
                child: InkWell(onTap: () {
                  if (!mounted) return;

                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SubCategory(
                                catId: catList[index].id,
                                cityId: "",
                              )));
                }))),
      ]),
    );
  }

  Future<void> getRadioCat(String catId) async {
    var data = {'access_key': '6808', 'category_id': catId};
    var response = await http.post(radio_bycat_api, body: data);


    var getdata = json.decode(response.body);

    var error = getdata['error'].toString();
    if (!mounted) return null;
    setState(() {
      //_subloading = false;
      if (error == 'false') {
        var data1 = getdata['data'] as List;

        _catRadioList = data1
            .map((data) => Model.fromJson(data as Map<String, dynamic>))
            .toList();
      } else {
        // _errorRadio = true;
      }
    });
  }

  getLoader() {
    return Container(
        height: 200, child: Center(child: CircularProgressIndicator()));
  }

  getErrorMsg() {
    return Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.only(top: 20),
        child: Text(
          'No Category Available..!!',
          textAlign: TextAlign.center,
        ));
  }

  getCatGrid() {
    return Padding(
        padding: const EdgeInsets.only(bottom: 200.0),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3),
                  physics: BouncingScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: catList.length,
                  controller: _controller,
                  itemBuilder: (context, index) {
                    return listItem(index);
                  },
                ),
              ),
            ),
            //  Spacer(),
            AdmobBanner(
              adUnitId: getBannerAdUnitId(),
              adSize: AdmobBannerSize.BANNER,
            ),
          ],
        ));
  }
}
