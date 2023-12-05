
import 'package:talabatak/Models/itemModel.dart';

class AdminModel {
  String? name;
  String? number;
  String? address;


  AdminModel({
    this.name,
    this.number,
    this.address,
  });

  AdminModel.fromFire(Map <String, dynamic> fire){
    name = fire['name'];
    number = fire['number'];
    address = fire['address'];

  }


  Map <String, dynamic> toMap() {
    return {
      'name': name,
      'number': number,
      'address' : address,

    };
  }

}
