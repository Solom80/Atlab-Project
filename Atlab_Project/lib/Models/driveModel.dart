class DriveModel {
  String? name;
  String? number;
  String? address;
  String? from;
  String? to;
  String? order;



  DriveModel({
    this.number,
    this.name,
    this.address,
    this.from,
    this.to,
    this.order

  });

  DriveModel.fromFire(Map <String, dynamic> fire){
    number = fire['number'];
    name = fire['name'];
    address = fire['address'];
    from = fire['from'];
    to = fire['to'];
    order = fire['order'];



  }

  Map <String, dynamic> toMap() {
    return {
      'number': number,
      'name' : name,
      'address' : address,
      'from' : from,
      'to' : to,
      'order' : order,

    };
  }

}
