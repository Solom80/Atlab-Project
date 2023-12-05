class UserModel {
  String? name;
  String? email;
  String? phone;
  String? uId;
  String? address;
  String? image;


  UserModel({
    this.name,
    this.email,
    this.phone,
    this.uId,
    this.address,
    this.image,
  });

  UserModel.fromFire(Map <String , dynamic> fire ){
    name = fire['name'];
    email = fire['email'];
    phone = fire['phone'];
    uId = fire['uId'];
    address = fire['address'];
    image = fire['image'];


  }


  Map <String , dynamic> toMap (){
    return {
      'name' : name ,
      'email' : email ,
      'phone' : phone ,
      'uId' : uId ,
      'address': address ,
      'image': image ,

    };
  }


}