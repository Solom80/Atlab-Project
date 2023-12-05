class RestaurantModel {
  String? name;
  String? category;
  String? distance;
  String? image;

  RestaurantModel({
    this.name,
    this.category,
    this.distance,
    this.image,
  });

  RestaurantModel.fromFire(Map <String , dynamic> fire ){
    name = fire['name'];
    category = fire['category'];
    distance = fire['distance'];
    image = fire['image'];
  }


  Map <String , dynamic> toMap (){
    return {
      'name' : name ,
      'category' : category ,
      'distance' : distance ,
      'image' : image ,
    };
  }


}