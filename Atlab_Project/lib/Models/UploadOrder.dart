import 'package:talabatak/Models/adminModel.dart';
import 'package:talabatak/Models/orderModel.dart';

class UploadOrder {
  Map? userData;
  List <dynamic>? orderData;

  UploadOrder({
    this.orderData,
    this.userData,
  });


  UploadOrder.fromFire(Map <String , dynamic> fire)
  {
    userData = fire['userData'];
    orderData = fire['orderData'];
  }

  Map <String, dynamic> toMap() {
    return {
      'userData' : userData,
      'orderData' : orderData,
    };
  }



}