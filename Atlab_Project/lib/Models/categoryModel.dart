class CategoryModel {
  String? name;
  String? number;
  String? address;
  String? order;



  CategoryModel({
    this.number,
    this.name,
    this.address,
    this.order,
  });

  CategoryModel.fromFire(Map <String, dynamic> fire){
    number = fire['number'];
    name = fire['name'];
    address = fire['address'];
    order = fire['order'];


  }

  Map <String, dynamic> toMap() {
    return {
      'number': number,
      'name' : name,
      'address' : address,
      'order' : order,

    };
  }

}
