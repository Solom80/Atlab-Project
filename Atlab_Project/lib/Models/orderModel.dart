class OrderModel {
  String? name;
  int? number;
  String? size;
  String? restaurantName;
  String? category;
  String? price;
  String? uid;


  OrderModel({
    this.number,
    this.name,
    this.price,
    this.category,
    this.size,
    this.restaurantName,
    this.uid,

  });

  OrderModel.fromFire(Map <String, dynamic> fire){
    number = fire['number'];
    name = fire['name'];
    price = fire['price'];
    category = fire['category'];
    size = fire['size'];
    restaurantName = fire['restaurantName'];
    uid = fire['uid'];

  }

  Map <String, dynamic> toMap() {
    return {
      'number': number,
      'name' : name,
      'price' : price,
      'category' : category,
      'size' : size,
      'restaurantName' : restaurantName,
      'uid' : uid,

    };
  }

}
