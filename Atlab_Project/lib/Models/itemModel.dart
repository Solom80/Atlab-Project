class ItemModel {
  String? name;
  String? price;
  String? details;
  String? category;

  ItemModel({
    this.name,
    this.price,
    this.details,
    this.category,
  });

  ItemModel.fromFire(Map <String, dynamic> fire){
    name = fire['name'];
    price = fire['price'];
    details = fire['details'];
    category = fire['category'];

  }


  Map <String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'details' : details,
      'category' : category,

    };
  }

}
