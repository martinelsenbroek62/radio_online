class City_Model{

  String id,cityName;

  ///constructor
  City_Model(
      {this.id,
        this.cityName});


  ///get data
  factory City_Model.fromJson(Map<String, dynamic> parsedJson) {
    return City_Model(
        id: parsedJson['id'].toString(),
        cityName: parsedJson['city_name'].toString());
  }


}