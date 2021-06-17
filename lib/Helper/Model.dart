import 'package:flutter/material.dart';

class Model {
  String id, cat_name, image, title;

  String cat_id, name, radio_url, description, city_id;
  Widget adUnit;

  ///constructor
  Model(
      {this.id,
      this.cat_name,
      this.image,
      this.cat_id,
      this.name,
      this.radio_url,
      this.description,
      this.title,
      this.city_id,this.adUnit});

  ///get data
  factory Model.fromJson(Map<String, dynamic> parsedJson) {
    return Model(
      id: parsedJson['id'].toString(),
      cat_name: parsedJson['category_name'].toString(),
      image: parsedJson['image'].toString(),
      cat_id: parsedJson['cat_id'].toString(),
      name: parsedJson['name'].toString(),
      radio_url: parsedJson['radio_url'].toString(),
      description: parsedJson['description'].toString(),
      city_id: parsedJson['city_id'].toString(),
    );
  }

  ///get data
  factory Model.fromDB(Map<String, dynamic> parsedJson) {
    return Model(
        id: parsedJson['station_id'].toString(),
        image: parsedJson['image'].toString(),
        name: parsedJson['name'].toString(),
        radio_url: parsedJson['radio_url'].toString(),
        description: parsedJson['description'].toString());
  }
}
