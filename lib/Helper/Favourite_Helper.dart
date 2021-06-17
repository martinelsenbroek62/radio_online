import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'Model.dart';

///class for favourite
class Favourite_Helper {
  static final Favourite_Helper _instance = Favourite_Helper.internal();

  ///get instance
  factory Favourite_Helper() => _instance;

  ///your table name
  final String tblFav = 'Fav';

  ///column id name
  final String ID = 'id';

  ///column station id
  final String STATION_ID = 'station_id';

  ///column name
  final String NAME = 'name';

  ///column descsription
  final String DESC = 'description';

  ///column image
  final String IMAGE = 'image';

  ///column radio url
  final String RADIO_URL = 'radio_url';

  static Database _db;

  Favourite_Helper.internal();

  ///get database
  Future<Database> get db async {
    if (_db != null) {
      return _db;
    }
    _db = await initDb();

    return _db;
  }

  ///initialise favourite database
  Future<Database> initDb() async {
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, 'Favorites.db');

// Check if the database exists
    var exists = await databaseExists(path);

    if (!exists) {
      // print("database***Creating new copy from asset");

      // Make sure the parent directory exists
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Copy from asset
      ByteData data = await rootBundle.load(join('assets', 'Favorites.db'));
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      // Write and flush the bytes written
      await File(path).writeAsBytes(bytes, flush: true);
    } else {
      //print("database***Opening existing database");
    }
// open the database
    var db = await openDatabase(path, readOnly: false);

    return db;
  }

  ///get favourite list from database
  Future<List<Model>> getAllFav() async {
    List<Model> modelList = [];

    var dbClient = await db;
    List<Map> result = await dbClient.rawQuery('SELECT * from $tblFav');

    if (result.isNotEmpty) {
      modelList = result.map((item) {
        return Model.fromDB(item as Map<String, dynamic>);
      }).toList();
    }
    return modelList;
  }

  Future<int> setFav(String station_id, String name, String desc, String image,
      String radio_url) async {
    var dbClient = await db;

    var result = await dbClient.rawInsert(
        'INSERT INTO $tblFav ($STATION_ID,$NAME,$DESC,$IMAGE,$RADIO_URL) VALUES (\'$station_id\',\'$name\',\'$desc\',\'$image\',\'$radio_url\')');

    return result;
  }

  ///remove favourite from database
  Future<void> removeFav(String id) async {
    // Get a reference to the database.
    final dbClient = await db;

    await dbClient.rawQuery('delete from $tblFav where $STATION_ID = $id');


  }

  ///get favourite by id
  Future<bool> getFav(String station_id) async {
    Database dbClient = await db;
    bool isfav = false;

    var result = await dbClient
        .rawQuery('SELECT * FROM $tblFav WHERE $STATION_ID = $station_id');

    if (result.isNotEmpty) {
      isfav = true;
    } else {
      isfav = false;
    }

    return isfav;
  }

  Future<void> close() async {
    Database dbClient = await db;
    return dbClient.close();
  }
}
