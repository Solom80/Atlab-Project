
import 'dart:io';
import 'dart:math';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import 'package:talabatak/Componants/componant.dart';
import 'package:talabatak/Componants/constants.dart';
import 'package:talabatak/Models/RestaurantModel.dart';
import 'package:talabatak/Models/UploadOrder.dart';
import 'package:talabatak/Models/UserModel.dart';
import 'package:talabatak/Models/adminModel.dart';
import 'package:talabatak/Models/categoryModel.dart';
import 'package:talabatak/Models/driveModel.dart';
import 'package:talabatak/Models/itemModel.dart';
import 'package:talabatak/Models/orderModel.dart';
import 'package:talabatak/Modules/AdminScreen/adminScreen.dart';
import 'package:talabatak/Modules/MenuScreen/TabScreens/Screen1.dart';
import 'package:talabatak/Modules/ProfileScreen/profileScreen.dart';
import 'package:talabatak/SharedPreference/CacheHelper.dart';
import 'package:talabatak/talabatak_bloc/states.dart';

class AppCubit extends Cubit<AppStates>{
  AppCubit() : super(intailstate());

  static AppCubit get(context)=> BlocProvider.of(context);

  UserModel ?userModel;

  var currentLocation = '';
  void getCurrentLocation () async
  {
    var position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    var lastPosition = await Geolocator.getLastKnownPosition();
    print(lastPosition.toString());
   // currentLocation = '${position.latitude.toString() + ', ' + position.longitude.toString()}';
    print(currentLocation.toString());

    var coordinates = new Coordinates(position.latitude, position.longitude);

    var address = await Geocoder.local.findAddressesFromCoordinates(coordinates);
    currentLocation = address.first.addressLine;
    print(address.first.addressLine);
    emit(AppGetUserLocation());
  }



  List <String> places = ['كشري و طواجن','مشويات','اسماك','كل الفئات','لحوم و خضروات','كريب/سوري','بيتزا','Restaurant','كل المطاعم'];

  String ?selectedPlace='كل المطاعم';

  void SelectedPlace(newvalue){

    selectedPlace=newvalue;
    emit(SelectedPlaceState());
  }

  List <String>Areas = ['كفر الشوبك','كفر شبين','طحا','شبين','كل المناطق'];

  String? selectedarea = 'كل المناطق';

  void selectedArea(newValue){

    selectedarea = newValue;
    emit(SelectedAreaState());
  }

  var numberOfItem = 1;


  void plusNumberOfItem(){
    numberOfItem+=1;

    emit(PlusNumberOfItemState());
  }

  void minesNumberOfItem(){
    numberOfItem>1?numberOfItem-=1:numberOfItem=1;
    emit(MinesNumberOfItemState());
  }



  void addItemToUserOrders (OrderModel model )
  {
    userOrders.add(model);
    finishOrders.add(model.toMap());
   // itemNumber.add(itemNum);
    numberOfItem = 1;
    emit(AppAddItemToUserOredersState());
  }



  void removeItemFromUserOrders (index)
  {
    userOrders.removeAt(index);
    finishOrders.removeAt(index);
    //itemNumber.removeAt(index);
    getTotalPrice();
    emit(AppRemoveItemFromUserOredersState());
  }

  int totalPrice = 0;
  void getTotalPrice ()
  {
    totalPrice = 0;
    userOrders.forEach((element) {
      totalPrice += int.parse(element.price!);
    });

    emit(AppGetTotalPriceState());
  }

  void getCurrentRestaurant (RestaurantModel model)
  {
    currentRestaurant = model.name!;
    emit(AppGetCurrentRestaurantState());
  }


  void getUser(context) {
    emit(AppGetUserLoadingState());

    FirebaseFirestore.instance
        .collection('users')
        .doc(CacheHelper.getData(key: 'uId'))
        .get()
        .then((value) {
         userModel=UserModel.fromFire(value.data()!);
         if(vistorLogin==false){
           navigateTo(context: context, widget: ProfileScreen());
         }
         emit(AppGetUserSuccessState());
    }).catchError((error) {
      print('Error when Register : ${error.toString()}');
      emit(AppGetUserErrorState(error.toString()));
    });
  }

  late Database database ;

  void createDatabase ()
  {
    openDatabase(
      'userOrders.db',
      version: 1,
      onCreate: (database , version){
        database.execute('CREATE TABLE orders (id INTEGER PRIMARY KEY , name TEXT , price TEXT , category TEXT , details TEXT )').then((value)
        {
          print('database created successful');
        }).catchError((error)
        {
          print('error when creating database ${error.toString()}');
        });
      },

      onOpen: (database){
        print('database opened');
        getDataFromDatabase(database);
      },
    ).then((value)
    {
      database = value ;
      emit(AppCreateDatabaseState());
    }
    );
  }

  insertDatabase ({
    required String name ,
    required String price ,
    required String category ,
    required String details ,
  }) async
  {
    await database.transaction((txn) {

      txn.rawInsert(
          'INSERT INTO orders(name , price , category , details) VALUES("$name" , "$price" , "$category" , "$details")'
      ).then((value)
      {
        print('$value : insert successfully');
        emit(AppInsertDatabaseState());
        getDataFromDatabase(database);

      }).catchError((error){
        print('error when insert row ${error.toString()}');
      });

      return null;
    }
    );
  }

  List <Map> orders = [];
  void getDataFromDatabase (database) async {
    orders = [];
    emit(AppInsertDatabaseLoadingState());

    database.rawQuery('SELECT * FROM orders').then((value)
    {
      // tasks = value ;
      value.forEach((element)
      {
        orders.add(element);
      });

      emit(AppGetDatabaseState());
    }
    );

  }

  void deleteDatabase ({
    required int id ,
  })
  {
    database.rawDelete(
        'DELETE FROM orders  WHERE id = ?' , [id] ).then((value)
    {
      emit(AppDeleteDatabaseState());
      getDataFromDatabase(database);
    }
    );
  }



  bool ?isConnected;


    Future<void> checkInternetConnection() async {
      try {
        final response = await InternetAddress.lookup('www.kindacode.com');
        if (response.isNotEmpty) {
            isConnected = true;
            emit(AppInternetConnectionSuccessState());
        }
      } on SocketException catch (err) {
          isConnected = false;
          emit(AppInternetConnectionErrorState());
         print(err);
      }
    }




  RestaurantModel ?itemModel;

  List <RestaurantModel> restaurantsDetails=[];

  void getItemKafrShaben({
    required String resName,
    // required String areaName
  })
  {
    emit(AppGetItemDetailLoadingState());


    if(resName=='كل المطاعم' ){

        emit(AppGetItemDetailLoadingState());


        FirebaseFirestore.instance
            .collection('كفر شبين')
            .doc('كل الفئات')
            .collection('الاصيل')
            .doc('details')
            .get()
            .then((value) {
          print(value.data());
          restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;
          emit(AppGetItemDetailSuccessState());
        }).catchError((error) {
          print('Error when Get : ${error.toString()}');
          emit(AppGetItemDetailErrorState(error.toString()));
        });


        FirebaseFirestore.instance
            .collection('كفر شبين')
            .doc('كل الفئات')
            .collection('حضرموت المهندسين')
            .doc('details')
            .get()
            .then((value) {

          print(value.data());
          restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));

          emit(AppGetItemDetailSuccessState());
        }).catchError((error) {
          print('Error when Get  : ${error.toString()}');
          emit(AppGetItemDetailErrorState(error.toString()));
        });


        FirebaseFirestore.instance
            .collection('كفر شبين')
            .doc('كل الفئات')
            .collection('مطعم و كشري حماده المحطه')
            .doc('details')
            .get()
            .then((value) {

          print(value.data());
          restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));

          emit(AppGetItemDetailSuccessState());
        }).catchError((error) {
          print('Error when Get : ${error.toString()}');
          emit(AppGetItemDetailErrorState(error.toString()));
        });



        FirebaseFirestore.instance
            .collection('كفر شبين')
            .doc('اسماك')
            .collection('اسماك ابو مريم')
            .doc('details')
            .get()
            .then((value) {

          print(value.data());
          restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

          emit(AppGetItemDetailSuccessState());
        }).catchError((error) {
          print('Error when Get : ${error.toString()}');
          emit(AppGetItemDetailErrorState(error.toString()));
        });


        FirebaseFirestore.instance
            .collection('كفر شبين')
            .doc('كشري و طواجن')
            .collection('كشري حماده')
            .doc('details')
            .get()
            .then((value) {

          print(value.data());
          restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

          emit(AppGetItemDetailSuccessState());
        }).catchError((error) {
          print('Error when Get : ${error.toString()}');
          emit(AppGetItemDetailErrorState(error.toString()));
        });


        FirebaseFirestore.instance
            .collection('كفر شبين')
            .doc('مشويات')
            .collection('حاتي التكيه')
            .doc('details')
            .get()
            .then((value) {

          print(value.data());
          restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

          emit(AppGetItemDetailSuccessState());
        }).catchError((error) {
          print('Error when Get : ${error.toString()}');
          emit(AppGetItemDetailErrorState(error.toString()));
        });


        emit(AppGetItemDetailLoadingState());


        FirebaseFirestore.instance
            .collection('كفر شبين')
            .doc('بيتزا')
            .collection('بيتزا المهدي')
            .doc('details')
            .get()
            .then((value) {

          print(value.data());
          restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

          emit(AppGetItemDetailSuccessState());
        }).catchError((error) {
          print('Error when Get : ${error.toString()}');
          emit(AppGetItemDetailErrorState(error.toString()));
        });


        FirebaseFirestore.instance
            .collection('كفر شبين')
            .doc('بيتزا')
            .collection('بيتزا هم')
            .doc('details')
            .get()
            .then((value) {

          print(value.data());
          restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

          emit(AppGetItemDetailSuccessState());
        }).catchError((error) {
          print('Error when Get : ${error.toString()}');
          emit(AppGetItemDetailErrorState(error.toString()));
        });

        FirebaseFirestore.instance
            .collection('كفر شبين')
            .doc('بيتزا')
            .collection('بيتزا الاميره')
            .doc('details')
            .get()
            .then((value) {

          print(value.data());
          restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

          emit(AppGetItemDetailSuccessState());
        }).catchError((error) {
          print('Error when Get : ${error.toString()}');
          emit(AppGetItemDetailErrorState(error.toString()));
        });

        FirebaseFirestore.instance
            .collection('كفر شبين')
            .doc('بيتزا')
            .collection('بيتزا الحوت')
            .doc('details')
            .get()
            .then((value) {

          print(value.data());
          restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

          emit(AppGetItemDetailSuccessState());
        }).catchError((error) {
          print('Error when Get : ${error.toString()}');
          emit(AppGetItemDetailErrorState(error.toString()));
        });


        FirebaseFirestore.instance
            .collection('كفر شبين')
            .doc('بيتزا')
            .collection('بيتزا السفير')
            .doc('details')
            .get()
            .then((value) {

          print(value.data());
          restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

          emit(AppGetItemDetailSuccessState());
        }).catchError((error) {
          print('Error when Get : ${error.toString()}');
          emit(AppGetItemDetailErrorState(error.toString()));
        });


        FirebaseFirestore.instance
            .collection('كفر شبين')
            .doc('بيتزا')
            .collection('بيتزا البوله')
            .doc('details')
            .get()
            .then((value) {

          print(value.data());
          restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

          emit(AppGetItemDetailSuccessState());
        }).catchError((error) {
          print('Error when Get : ${error.toString()}');
          emit(AppGetItemDetailErrorState(error.toString()));
        });


        FirebaseFirestore.instance
            .collection('كفر شبين')
            .doc('بيتزا')
            .collection('بيتزا بوله')
            .doc('details')
            .get()
            .then((value) {

          print(value.data());
          restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

          emit(AppGetItemDetailSuccessState());
        }).catchError((error) {
          print('Error when Get : ${error.toString()}');
          emit(AppGetItemDetailErrorState(error.toString()));
        });


        FirebaseFirestore.instance
            .collection('كفر شبين')
            .doc('بيتزا')
            .collection('Crazy Pizza')
            .doc('details')
            .get()
            .then((value) {

          print(value.data());
          restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

          emit(AppGetItemDetailSuccessState());
        }).catchError((error) {
          print('Error when Get : ${error.toString()}');
          emit(AppGetItemDetailErrorState(error.toString()));
        });


        restaurantsDetails=[];

    }

    else if(resName=='كشري و طواجن' ){

      emit(AppGetItemDetailLoadingState());

      FirebaseFirestore.instance
          .collection('كفر شبين')
          .doc('كشري و طواجن')
          .collection('كشري حماده')
          .doc('details')
          .get()
          .then((value) {

        print(value.data());
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

        emit(AppGetItemDetailSuccessState());
      }).catchError((error) {
        print('Error when Get : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });

      restaurantsDetails=[];

    }

    else if(resName=='مشويات' ){

      emit(AppGetItemDetailLoadingState());

      FirebaseFirestore.instance
          .collection('كفر شبين')
          .doc('مشويات')
          .collection('حاتي التكيه')
          .doc('details')
          .get()
          .then((value) {

        print(value.data());
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

        emit(AppGetItemDetailSuccessState());
      }).catchError((error) {
        print('Error when Get : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });

      restaurantsDetails=[];

    }

    else if(resName=='اسماك'){

      emit(AppGetItemDetailLoadingState());

      FirebaseFirestore.instance
          .collection('كفر شبين')
          .doc('اسماك')
          .collection('اسماك ابو مريم')
          .doc('details')
          .get()
          .then((value) {

        print(value.data());
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

        emit(AppGetItemDetailSuccessState());
      }).catchError((error) {
        print('Error when Get : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });

      restaurantsDetails=[];

    }

    else if(resName=='كل الفئات' ){

      emit(AppGetItemDetailLoadingState());


      FirebaseFirestore.instance
          .collection('كفر شبين')
          .doc('كل الفئات')
          .collection('الاصيل')
          .doc('details')
          .get()
          .then((value) {

        print(value.data());
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

        emit(AppGetItemDetailSuccessState());
      }).catchError((error) {
        print('Error when Get : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });


      FirebaseFirestore.instance
          .collection('كفر شبين')
          .doc('كل الفئات')
          .collection('حضرموت المهندسين')
          .doc('details')
          .get()
          .then((value) {

        print(value.data());
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));

        emit(AppGetItemDetailSuccessState());
      }).catchError((error) {
        print('Error when Get  : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });


      FirebaseFirestore.instance
          .collection('كفر شبين')
          .doc('كل الفئات')
          .collection('مطعم و كشري حماده المحطه')
          .doc('details')
          .get()
          .then((value) {

        print(value.data());
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));

        emit(AppGetItemDetailSuccessState());
      }).catchError((error) {
        print('Error when Get : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });

      restaurantsDetails=[];



    }

    else if(resName=='لحوم و خضروات' ){

      restaurantsDetails=[];
    }

    else if(resName=='كريب/سوري' ){

      restaurantsDetails=[];
    }

    else if(resName=='بيتزا' ){

      emit(AppGetItemDetailLoadingState());


      FirebaseFirestore.instance
          .collection('كفر شبين')
          .doc('بيتزا')
          .collection('بيتزا المهدي')
          .doc('details')
          .get()
          .then((value) {

        print(value.data());
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

        emit(AppGetItemDetailSuccessState());
      }).catchError((error) {
        print('Error when Get Error Internet Connection : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });


      FirebaseFirestore.instance
          .collection('كفر شبين')
          .doc('بيتزا')
          .collection('بيتزا هم')
          .doc('details')
          .get()
          .then((value) {

        print(value.data());
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

        emit(AppGetItemDetailSuccessState());
      }).catchError((error) {
        print('Error when Get : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });

      FirebaseFirestore.instance
          .collection('كفر شبين')
          .doc('بيتزا')
          .collection('بيتزا الاميره')
          .doc('details')
          .get()
          .then((value) {

        print(value.data());
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

        emit(AppGetItemDetailSuccessState());
      }).catchError((error) {
        print('Error when Get : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });

      FirebaseFirestore.instance
          .collection('كفر شبين')
          .doc('بيتزا')
          .collection('بيتزا الحوت')
          .doc('details')
          .get()
          .then((value) {

        print(value.data());
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

        emit(AppGetItemDetailSuccessState());
      }).catchError((error) {
        print('Error when Get : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });


      FirebaseFirestore.instance
          .collection('كفر شبين')
          .doc('بيتزا')
          .collection('بيتزا السفير')
          .doc('details')
          .get()
          .then((value) {

        print(value.data());
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

        emit(AppGetItemDetailSuccessState());
      }).catchError((error) {
        print('Error when Get : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });


      FirebaseFirestore.instance
          .collection('كفر شبين')
          .doc('بيتزا')
          .collection('بيتزا البوله')
          .doc('details')
          .get()
          .then((value) {

        print(value.data());
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

        emit(AppGetItemDetailSuccessState());
      }).catchError((error) {
        print('Error when Get : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });


      FirebaseFirestore.instance
          .collection('كفر شبين')
          .doc('بيتزا')
          .collection('بيتزا بوله')
          .doc('details')
          .get()
          .then((value) {

        print(value.data());
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

        emit(AppGetItemDetailSuccessState());
      }).catchError((error) {
        print('Error when Get : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });


      FirebaseFirestore.instance
          .collection('كفر شبين')
          .doc('بيتزا')
          .collection('Crazy Pizza')
          .doc('details')
          .get()
          .then((value) {

        print(value.data());
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

        emit(AppGetItemDetailSuccessState());
      }).catchError((error) {
        print('Error when Get : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });



      restaurantsDetails=[];

    }

    else if(resName=='Restaurant' ){

      restaurantsDetails=[];
    }

    else{print('error');}

  }

  double xOffcet = 0;
  double yOffcet = 0;
  double scale = 1;
  bool factor = false;

  void doSmallScreen() {
    if (factor == false) {
      xOffcet =-20;
      yOffcet = 175;
      scale = .55;
      factor = true;
      emit(SmallScreenState());
    }
    else{
      xOffcet=0;
      yOffcet=0;
      scale=1;
      factor=false;
      emit(NormalScreenState());
    }
  }

  void getItemKafrShobak({
    required String resName,
  })
  {

    if(resName=='كل المطاعم'){

      emit(AppGetItemDetailLoadingState());


      FirebaseFirestore.instance
          .collection('كفر الشوبك')
          .doc('بينزا')
          .collection('بينزا العمده')
          .doc('details')
          .get()
          .then((value) {

        print(value.data());
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

        emit(AppGetItemDetailSuccessState());
      }).catchError((error) {
        print('Error when Get : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });


      restaurantsDetails=[];


    }

    else if(resName=='بيتزا'){

      emit(AppGetItemDetailLoadingState());


      FirebaseFirestore.instance
          .collection('كفر الشوبك')
          .doc('بينزا')
          .collection('بينزا العمده')
          .doc('details')
          .get()
          .then((value) {

        print(value.data());
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!)) ;

        emit(AppGetItemDetailSuccessState());
      }).catchError((error) {
        print('Error when Get : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });


      restaurantsDetails=[];

    }

    else if(resName=='لحوم و خضروات' ){

      restaurantsDetails=[];
    }

    else if(resName=='Restaurant' ){

      restaurantsDetails=[];
    }

    else if(resName=='كريب/سوري' ){

      restaurantsDetails=[];
    }

    else if(resName=='كل الفئات' ){

      restaurantsDetails=[];
    }

    else if(resName=='اسماك' ){

      restaurantsDetails=[];
    }

    else if(resName=='مشويات' ){

      restaurantsDetails=[];
    }

    else if(resName=='كشري و طواجن' ){

      restaurantsDetails=[];
    }

    else{print('error');}

  }


  //List<RestaurantModel> restaurantsDetails = [];

  void getShbinRestaurantDetails (
  {
     required String resName,
  })
  {

    if(resName=='كل المطاعم'){


      FirebaseFirestore.instance
          .collection('شبين')
          .doc('Restaurant')
          .collection('Wings')
          .doc('details')
          .get()
          .then((value) {
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));
        print(value.data());
        emit(AppGetItemDetailSuccessState());
      }).catchError((error){
        print('Error when get Wings : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });

      FirebaseFirestore.instance
          .collection('شبين')
          .doc('Restaurant')
          .collection('البيك')
          .doc('details')
          .get()
          .then((value) {
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));
        print(value.data());
        emit(AppGetItemDetailSuccessState());
      }).catchError((error){
        print('Error when get البيك : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });

      FirebaseFirestore.instance
          .collection('شبين')
          .doc('مشويات')
          .collection('مطعم جوستو')
          .doc('details')
          .get()
          .then((value) {
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));
        print(value.data());
        emit(AppGetItemDetailSuccessState());
      }).catchError((error){
        print('Error when get مطعم جوستو : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });


      FirebaseFirestore.instance
          .collection('شبين')
          .doc('بيتزا')
          .collection('بيتزا بريمو')
          .doc('details')
          .get()
          .then((value) {
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));
        print(value.data());
        emit(AppGetItemDetailSuccessState());
      }).catchError((error){
        print('Error when get بيتزا بريمو : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });


      FirebaseFirestore.instance
          .collection('شبين')
          .doc('كريب')
          .collection('طبوش السورى')
          .doc('details')
          .get()
          .then((value) {
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));
        print(value.data());
        emit(AppGetItemDetailSuccessState());
      }).catchError((error){
        print('Error when get طبوش السورى  : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });


      FirebaseFirestore.instance
          .collection('شبين')
          .doc('كشرى')
          .collection('كشرى هند')
          .doc('details')
          .get()
          .then((value) {
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));
        print(value.data());
        emit(AppGetItemDetailSuccessState());
      }).catchError((error){
        print('Error when get كشرى هند  : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });


      FirebaseFirestore.instance
          .collection('شبين')
          .doc('كل الفئات')
          .collection('fresco')
          .doc('details')
          .get()
          .then((value) {
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));
        print(value.data());
        emit(AppGetItemDetailSuccessState());
      }).catchError((error){
        print('Error when get fresco  : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });


      FirebaseFirestore.instance
          .collection('شبين')
          .doc('كل الفئات')
          .collection('السلطان')
          .doc('details')
          .get()
          .then((value) {
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));
        print(value.data());
        emit(AppGetItemDetailSuccessState());
      }).catchError((error){
        print('Error when get السلطان  : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });



      FirebaseFirestore.instance
          .collection('شبين')
          .doc('كل الفئات')
          .collection('بيت الكنافة')
          .doc('details')
          .get()
          .then((value) {
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));
        print(value.data());
        emit(AppGetItemDetailSuccessState());
      }).catchError((error){
        print('Error when get بيت الكنافة  : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });

      FirebaseFirestore.instance
          .collection('شبين')
          .doc('كل الفئات')
          .collection('مطعم الأندلس')
          .doc('details')
          .get()
          .then((value) {
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));
        print(value.data());
        emit(AppGetItemDetailSuccessState());
      }).catchError((error){
        print('Error when get مطعم الأندلس  : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });


      restaurantsDetails=[];


    }

    else if(resName=='Restaurant'){

      FirebaseFirestore.instance
          .collection('شبين')
          .doc('Restaurant')
          .collection('Wings')
          .doc('details')
          .get()
          .then((value) {
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));
        print(value.data());
        emit(AppGetItemDetailSuccessState());
      }).catchError((error){
        print('Error when get Wings : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });

      FirebaseFirestore.instance
          .collection('شبين')
          .doc('Restaurant')
          .collection('البيك')
          .doc('details')
          .get()
          .then((value) {
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));
        print(value.data());
        emit(AppGetItemDetailSuccessState());
      }).catchError((error){
        print('Error when get البيك : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });


      restaurantsDetails=[];


    }

    else if( resName == 'بيتزا'){

      FirebaseFirestore.instance
          .collection('شبين')
          .doc('بيتزا')
          .collection('بيتزا بريمو')
          .doc('details')
          .get()
          .then((value) {
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));
        print(value.data());
        emit(AppGetItemDetailSuccessState());
      }).catchError((error){
        print('Error when get بيتزا بريمو : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });

      restaurantsDetails=[];

    }

    else if (resName == 'مشويات')
    {
      FirebaseFirestore.instance
          .collection('شبين')
          .doc('مشويات')
          .collection('مطعم جوستو')
          .doc('details')
          .get()
          .then((value) {
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));
        print(value.data());
        emit(AppGetItemDetailSuccessState());
      }).catchError((error){
        print('Error when get مطعم جوستو : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });

      restaurantsDetails=[];
    }

    else if(resName=='كريب/سوري'){

      FirebaseFirestore.instance
          .collection('شبين')
          .doc('كريب')
          .collection('طبوش السورى')
          .doc('details')
          .get()
          .then((value) {
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));
        print(value.data());
        emit(AppGetItemDetailSuccessState());
      }).catchError((error){
        print('Error when get طبوش السورى  : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });
      restaurantsDetails=[];

    }

    else if(resName=='لحوم و خضروات' ){

      restaurantsDetails=[];
    }

    else if(resName=='اسماك' ){

      restaurantsDetails=[];
    }

    else if(resName=='مشويات' ){

      restaurantsDetails=[];
    }

    else if(resName =='كشري و طواجن'){


      FirebaseFirestore.instance
          .collection('شبين')
          .doc('كشرى')
          .collection('كشرى هند')
          .doc('details')
          .get()
          .then((value) {
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));
        print(value.data());
        emit(AppGetItemDetailSuccessState());
      }).catchError((error){
        print('Error when get كشرى هند  : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });
      restaurantsDetails=[];

    }

   else if(resName=='كل الفئات'){


      FirebaseFirestore.instance
          .collection('شبين')
          .doc('كل الفئات')
          .collection('fresco')
          .doc('details')
          .get()
          .then((value) {
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));
        print(value.data());
        emit(AppGetItemDetailSuccessState());
      }).catchError((error){
        print('Error when get fresco  : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });


      FirebaseFirestore.instance
          .collection('شبين')
          .doc('كل الفئات')
          .collection('السلطان')
          .doc('details')
          .get()
          .then((value) {
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));
        print(value.data());
        emit(AppGetItemDetailSuccessState());
      }).catchError((error){
        print('Error when get السلطان  : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });



      FirebaseFirestore.instance
          .collection('شبين')
          .doc('كل الفئات')
          .collection('بيت الكنافة')
          .doc('details')
          .get()
          .then((value) {
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));
        print(value.data());
        emit(AppGetItemDetailSuccessState());
      }).catchError((error){
        print('Error when get بيت الكنافة  : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });

      FirebaseFirestore.instance
          .collection('شبين')
          .doc('كل الفئات')
          .collection('مطعم الأندلس')
          .doc('details')
          .get()
          .then((value) {
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));
        print(value.data());
        emit(AppGetItemDetailSuccessState());
      }).catchError((error){
        print('Error when get مطعم الأندلس  : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });


      restaurantsDetails=[];

    }

    else{
      print('error');
    }


  }


  void getTahaRestaurantDetails ({
  required String resName,
})
  {
    if(resName=='كل المطاعم'){

      FirebaseFirestore.instance
          .collection('طحا')
          .doc('Restaurant')
          .collection('مشويات حمزه')
          .doc('details')
          .get()
          .then((value) {
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));
        print(value.data());
        emit(AppGetItemDetailSuccessState());
      }).catchError((error){
        print('Error when get مشويات حمزه : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });

      restaurantsDetails=[];

    }

   else if(resName=='Restaurant'){

      FirebaseFirestore.instance
          .collection('طحا')
          .doc('Restaurant')
          .collection('مشويات حمزه')
          .doc('details')
          .get()
          .then((value) {
        restaurantsDetails.add(RestaurantModel.fromFire(value.data()!));
        print(value.data());
        emit(AppGetItemDetailSuccessState());
      }).catchError((error){
        print('Error when get مشويات حمزه : ${error.toString()}');
        emit(AppGetItemDetailErrorState(error.toString()));
      });

      restaurantsDetails=[];

    }

    else if(resName=='لحوم و خضروات' ){

      restaurantsDetails=[];
    }

    else if(resName=='بيتزا' ){

      restaurantsDetails=[];
    }

    else if(resName=='كريب/سوري' ){

      restaurantsDetails=[];
    }

    else if(resName=='كل الفئات' ){

      restaurantsDetails=[];
    }

    else if(resName=='اسماك' ){

      restaurantsDetails=[];
    }

    else if(resName=='مشويات' ){

      restaurantsDetails=[];
    }

    else if(resName=='كشري و طواجن' ){

      restaurantsDetails=[];
    }


  }


  List<String> tabs = [];
  List<Widget> tabsScreens = [];
  List<ItemModel> foodsScreen1=[];
  List<ItemModel> foodsScreen2=[];
  List<ItemModel> foodsScreen3=[];
  List<ItemModel> foodsScreen4=[];
  List<ItemModel> foodsScreen5=[];
  List<ItemModel> foodsScreen6=[];
  List<ItemModel> foodsScreen7=[];
  List<ItemModel> foodsScreen8=[];
  List<ItemModel> foodsScreen9=[];
  List<ItemModel> foodsScreen10=[];
  List<ItemModel> foodsScreen11=[];
  List<ItemModel> foodsScreen12=[];

  Future <void> changeTabs (
      {
    required String restaurantName
  })
  async {

    foodsScreen1=[];
    foodsScreen2=[];
    foodsScreen3=[];
    foodsScreen4=[];
    foodsScreen5=[];
    foodsScreen6=[];
    foodsScreen7=[];
    foodsScreen8=[];
    foodsScreen9=[];
    foodsScreen10=[];
    foodsScreen11=[];
    foodsScreen12=[];

    if(restaurantName == 'بيتزا بؤله')
    {
      tabs = pizzaPoalaTabs;
      tabsScreens = pizzaPoalaScreens;
      getPizzaBola();

    }
    else if (restaurantName == 'حاتى التكيه')
    {
        tabs = hatyEltkehTabs;
        tabsScreens = hatyEltkehScreens;
        getHatyeEltakya();

      }
    else if (restaurantName == 'مشويات حمزة')
    {
      tabs = mashwatHamzaTabs;
      tabsScreens = mashwatHamzaScreens;
      getMashweatHamza();
    }
    else if (restaurantName == 'بيتزا الحوت')
    {
      tabs = pizzaElhootTabs;
      tabsScreens = pizzaElhootScreens;
      getPizzaElhowt();


    }
    else if (restaurantName == 'السلطان')
    {
      tabs = elSoltanTabs;
      tabsScreens = elSoltanScreens;
      getElsoltan();
    }
    else if (restaurantName == 'مطعم و كشرى حمادة المحطة')
    {
      tabs = hamdaElmahataTabs;
      tabsScreens = hamdaElmahataScreens;
      getHamdaElmahta();
    }
    else if (restaurantName == 'طبوش السورى')
    {
      tabs = taboshElsoryTabs;
      tabsScreens = taboshElsoryScreens;
      getTaboshElsory();
    }
    else if (restaurantName == 'مطعم الأندلس')
    {
      tabs = elAndalosTabs;
      tabsScreens = elAndalosScreens;
      getElandalos();
    }
    else if (restaurantName == 'Crazy Pizza')
    {
      tabs = crazyPizzaTabs;
      tabsScreens = crazyPizzaScreens;
      getCrazyPizza();
    }
    else if (restaurantName == 'بيت الكنافة')
    {
      tabs = batElknafaTabs;
      tabsScreens = batElknafaScreens;
      getBatElkonafa();
    }
    else if (restaurantName == 'بيتزا السفير')
    {
      tabs = pizzaElsafirTabs;
      tabsScreens = pizzaElsafirScreens;
      getPizzaElsafer();
    }
    else if (restaurantName == 'بيتزا العمدة')
    {
      tabs = pizzaElomdaTabs;
      tabsScreens = pizzaElomdaScreens;
      getPizzaElomda();
    }
    // else if (restaurantName == 'بيتزا بريمو')
    // {
    //   tabs = pizzaBremoTabs;
    //   tabsScreens = pizzaBremoScreens;
    // }
    else if (restaurantName == 'اسماك ابو مريم')
    {
      tabs = asmakAboMarimTabs;
      tabsScreens = asmakAboMarimScreens;
      getFishAbuMarim();


    }
    else if (restaurantName == 'بيتزا الأميرة')
    {
      tabs = pizzaElamiraTabs;
      tabsScreens = pizzaElamiraScreens;
      getPizzaElamira();

    }
    else if (restaurantName == 'كشرى هند')
    {
      tabs = kosharyHendTabs;
      tabsScreens = kosharyHendScreens;
      getKosharyHend();
    }
    else if (restaurantName == 'حضر موت المهندسين')
    {
      tabs = hadrMotTabs;
      tabsScreens = hadrMotScreens;
      getHadrMot();
    }
    else if (restaurantName == 'بيتزا هم')
    {
      tabs = pizzaHumTabs;
      tabsScreens = pizzaHumScreens;
      getPizzaHam();
    }
    else if (restaurantName == 'Wings')
    {
      tabs = wingsTabs;
      tabsScreens = wingsScreens;
      getWings();
    }
    else if (restaurantName == 'بيتزا بريمو')
    {
      tabs = pizzaBremoTabs;
      tabsScreens = pizzaBremoScreens;
      getPizzaPremo();
    }
    else if (restaurantName == 'بيتزا المهدى')
    {
      tabs = pizzaElmahdyTabs;
      tabsScreens = pizzaElmahdyScreens;
      getPizzaElmahdy();
    }
    else if (restaurantName == 'البيك')
    {
      tabs = elBakTabs;
      tabsScreens = elBakScreens;
      getElbak();
    }
    else if (restaurantName == 'Fresco - فريسكو')
    {
      tabs = frescoTabs;
      tabsScreens = frescoScreens;
      getFresco();
    }
    else if (restaurantName == 'كشرى حمادة')
    {
      tabs = kosharyHamadaTabs;
      tabsScreens = kosharyHamadaScreens;
      getKoshryHamada();

    }
    else if (restaurantName == 'الأصيل')
    {
      tabs = elAselTabs;
      tabsScreens = elAselScreens;
      getElasil();
    }
    else if (restaurantName == 'مطعم جوستوم')
    {
      tabs = gostom;
      tabsScreens = gostomScreens;
      getGosto();
    }

    emit(AppChangeTabsState());

  }




  void getPizzaBola(){

    // شرقي

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('شرقي')
        .collection('بسطرمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('شرقي')
        .collection('لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('شرقي')
        .collection('مشروم')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('شرقي')
        .collection('بوله')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('شرقي')
        .collection('بيف')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('شرقي')
        .collection('جبنه رومي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('شرقي')
        .collection('تونه قطع')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('تونه مفتته')
        .doc('شرقي')
        .collection('لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('شرقي')
        .collection('سجق اسكندراني')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('شرقي')
        .collection('سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('شرقي')
        .collection('فاهيتا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('شرقي')
        .collection('فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('شرقي')
        .collection('مشكل جبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('شرقي')
        .collection('مشكل لحوم')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    // ايطالي

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('ايطالي')
        .collection('مارجريتا')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('ايطالي')
        .collection('مشروم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('ايطالي')
        .collection('بسطرمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('ايطالي')
        .collection('بوله')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('ايطالي')
        .collection('بيفي')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('ايطالي')
        .collection('تشكين بربكيو')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('ايطالي')
        .collection('تونه قطع')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('ايطالي')
        .collection('تونه مفتته')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('ايطالي')
        .collection('خضروات')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('ايطالي')
        .collection('سجق اسكندراني')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('ايطالي')
        .collection('سوبر سوبريم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('ايطالي')
        .collection('سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('ايطالي')
        .collection('فاهيتا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('ايطالي')
        .collection('فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('ايطالي')
        .collection('لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('ايطالي')
        .collection('مشكل جبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('ايطالي')
        .collection('مشكل لحوم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    // الحلو

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('الحلو')
        .collection('بغاشه')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('الحلو')
        .collection('سكر')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('الحلو')
        .collection('شيكولاته')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('الحلو')
        .collection('قشطه و عسل')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('الحلو')
        .collection('كاستر')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    // حواوشي

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('حواوشي')
        .collection('سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا بوله')
        .doc('حواوشي')
        .collection('لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaBolaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaBolaErrorState());
    });


    foodsScreen1=[];
    foodsScreen2=[];
    foodsScreen3=[];
    foodsScreen4=[];
    foodsScreen5=[];
    foodsScreen6=[];
    foodsScreen7=[];
    foodsScreen8=[];
    foodsScreen9=[];
    foodsScreen10=[];
    foodsScreen11=[];
    foodsScreen12=[];


  }

  void getPizzaElamira(){

    // شرقي

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('شرقي')
        .collection('بيتزا تونه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('شرقي')
        .collection('بيتزا جبنه رومي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('شرقي')
        .collection('بيتزا سجق اسكندراني')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('شرقي')
        .collection('بيتزا سجق شرقي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('شرقي')
        .collection('بيتزا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('شرقي')
        .collection('بيتزا لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('شرقي')
        .collection('بيتزا مشروم')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('شرقي')
        .collection('بيتزا مكس جبنه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });

    // ايطالي


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('ايطالي')
        .collection('بيتزا تونه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('ايطالي')
        .collection('بيتزا خضار')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('ايطالي')
        .collection('بيتزا سجق اسكندراني')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('ايطالي')
        .collection('بيتزا سوبر سوبريم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('ايطالي')
        .collection('بيتزا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('ايطالي')
        .collection('بيتزا لحمه مفرومه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('ايطالي')
        .collection('بيتزا مارجريتا')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('ايطالي')
        .collection('بيتزا مشروم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('ايطالي')
        .collection('بيتزا مكس جبنه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });

    // الحلو



    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('الحلو')
        .collection('فطيره بسبوسه')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('الحلو')
        .collection('فطيره بسبوسه + كنافه')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('الحلو')
        .collection('فطيره بغاشه')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('الحلو')
        .collection('فطيره سكر ساده')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('الحلو')
        .collection('فطيره شكولاته')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('الحلو')
        .collection('فطيره قشطه و عسل')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('الحلو')
        .collection('فطيره كاستر')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الاميره')
        .doc('الحلو')
        .collection('فطيره كنافه')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElamiraSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElamiraErrorState());
    });


    foodsScreen1 = [];
    foodsScreen2 = [];
    foodsScreen3 = [];
    foodsScreen4 = [];
    foodsScreen5 = [];
    foodsScreen6 = [];
    foodsScreen7 = [];
    foodsScreen8 = [];
    foodsScreen9 = [];
    foodsScreen10 = [];
    foodsScreen11 = [];
    foodsScreen12 = [];


  }

  void getCrazyPizza(){

    // ايطالي

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('Crazy Pizza')
        .doc('ايطالي')
        .collection('Pizza Margherita')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetCrazyPizzaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetCrazyPizzaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('Crazy Pizza')
        .doc('ايطالي')
        .collection('cheese lovers')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetCrazyPizzaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetCrazyPizzaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('Crazy Pizza')
        .doc('ايطالي')
        .collection('meat')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetCrazyPizzaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetCrazyPizzaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('Crazy Pizza')
        .doc('ايطالي')
        .collection('prawn')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetCrazyPizzaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetCrazyPizzaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('Crazy Pizza')
        .doc('ايطالي')
        .collection('sausage')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetCrazyPizzaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetCrazyPizzaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('Crazy Pizza')
        .doc('ايطالي')
        .collection('super supreme')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetCrazyPizzaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetCrazyPizzaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('Crazy Pizza')
        .doc('ايطالي')
        .collection('tuna')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetCrazyPizzaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetCrazyPizzaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('Crazy Pizza')
        .doc('ايطالي')
        .collection('vegetarian')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetCrazyPizzaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetCrazyPizzaErrorState());
    });

    foodsScreen1 = [];
    foodsScreen2 = [];
    foodsScreen3 = [];
    foodsScreen4 = [];
    foodsScreen5 = [];
    foodsScreen6 = [];
    foodsScreen7 = [];
    foodsScreen8 = [];
    foodsScreen9 = [];
    foodsScreen10 = [];
    foodsScreen11 = [];
    foodsScreen12 = [];

  }

  void getPizzaElhowt(){

    // شرقي

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('شرقي')
        .collection('بيتزا بسطرمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('شرقي')
        .collection('بيتزا بيف')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('شرقي')
        .collection('بيتزا تونه قطع')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('شرقي')
        .collection('بيتزا تونه مفتته')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('شرقي')
        .collection('بيتزا جبنه رومي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('شرقي')
        .collection('بيتزا جمبري')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('شرقي')
        .collection('بيتزا سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('شرقي')
        .collection('بيتزا سي فود')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('شرقي')
        .collection('بيتزا فاهيتا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('شرقي')
        .collection('بيتزا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('شرقي')
        .collection('بيتزا كورند بيف')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('شرقي')
        .collection('بيتزا لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('شرقي')
        .collection('بيتزا مشروم')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('شرقي')
        .collection('بيتزا مشكل جبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('شرقي')
        .collection('بيتزا مشكل لحوم')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('شرقي')
        .collection('سجق اسكندراني')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('شرقي')
        .collection('بيتزا شرقي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    // ايطالي

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('ايطالي')
        .collection('بيتزا بسطرمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('ايطالي')
        .collection('بيتزا تشكين باربكيو')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('ايطالي')
        .collection('بيتزا تونه قطع')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('ايطالي')
        .collection('بيتزا تونه مفتته')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('ايطالي')
        .collection('بيتزا جمبري')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('ايطالي')
        .collection('بيتزا خضار')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('ايطالي')
        .collection('بيتزا سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('ايطالي')
        .collection('بيتزا سلامي')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('ايطالي')
        .collection('بيتزا سوبر سوبريم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('ايطالي')
        .collection('بيتزا سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('ايطالي')
        .collection('بيتزا سي فود')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('ايطالي')
        .collection('بيتزا فاهيتا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('ايطالي')
        .collection('بيتزا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('ايطالي')
        .collection('بيتزا لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('ايطالي')
        .collection('بيتزا مارجريتا')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('ايطالي')
        .collection('بيتزا مشروم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('ايطالي')
        .collection('بيتزا مشكل جبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('ايطالي')
        .collection('بيتزا مشكل لحوم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    // كريب

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('كريب')
        .collection('كريب استربس')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('كريب')
        .collection('كريب الحوت')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('كريب')
        .collection('كريب بانيه')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('كريب')
        .collection('كريب بطاطس')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('كريب')
        .collection('كريب زنجر')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('كريب')
        .collection('كريب سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('كريب')
        .collection('كريب سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('كريب')
        .collection('كريب شاورما فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('كريب')
        .collection('كريب شاورما لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('كريب')
        .collection('كريب كبده')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('كريب')
        .collection('كريب كفته')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    // الحلو

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('الحلو')
        .collection('فطيره بغاشه')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('الحلو')
        .collection('فطيره سكر')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('الحلو')
        .collection('فطيره شيكولاته')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('الحلو')
        .collection('فطيره قشطه و عسل')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('الحلو')
        .collection('فطيره قنبله')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا الحوت')
        .doc('الحلو')
        .collection('فطيره كاستر')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElhowtSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElhowtErrorState());
    });

    foodsScreen1 = [];
    foodsScreen2 = [];
    foodsScreen3 = [];
    foodsScreen4 = [];
    foodsScreen5 = [];
    foodsScreen6 = [];
    foodsScreen7 = [];
    foodsScreen8 = [];
    foodsScreen9 = [];
    foodsScreen10 = [];
    foodsScreen11 = [];
    foodsScreen12 = [];

  }

  void getPizzaElsafer(){

    // شرقي


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('شرقي')
        .collection('بيتزا بسطرمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('شرقي')
        .collection('بيتزا تونه مفتته')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('شرقي')
        .collection('بيتزا جبنه رومي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('شرقي')
        .collection('بيتزا جمبري')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('شرقي')
        .collection('بيتزا خضار')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('شرقي')
        .collection('بيتزا سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('شرقي')
        .collection('بيتزا سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('شرقي')
        .collection('بيتزا سي فود')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('شرقي')
        .collection('بيتزا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('شرقي')
        .collection('بيتزا لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('شرقي')
        .collection('بيتزا مشروم')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('شرقي')
        .collection('بيتزا مشكل لحوم')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    // ايطالي

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('ايطالي')
        .collection('بيتزا بسطرمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('ايطالي')
        .collection('بيتزا بلوبيف')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('ايطالي')
        .collection('بيتزا تونه قطع')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('ايطالي')
        .collection('بيتزا جمبري')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('ايطالي')
        .collection('بيتزا خضار')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('ايطالي')
        .collection('بيتزا سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('ايطالي')
        .collection('بيتزا سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('ايطالي')
        .collection('بيتزا سي فود')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('ايطالي')
        .collection('بيتزا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('ايطالي')
        .collection('بيتزا لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('ايطالي')
        .collection('بيتزا مارجريتا')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('ايطالي')
        .collection('بيتزا مشروم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('ايطالي')
        .collection('بيتزا مشكل لحوم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('ايطالي')
        .collection('بيتزا ميكس جبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    // حواوشي

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('حواوشي')
        .collection('حواوشي سجق ايطالي')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('حواوشي')
        .collection('حواوشي فراخ ايطالي')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('حواوشي')
        .collection('حواوشي لحمه ايطالي')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('حواوشي')
        .collection('صاروخ سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('حواوشي')
        .collection('صاروخ فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('حواوشي')
        .collection('صاروخ لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

// المكرونات
//
//     FirebaseFirestore.instance.collection('كفر شبين')
//         .doc('بيتزا')
//         .collection('بيتزا السفير')
//         .doc('مكرونات')
//         .collection('اسباجتي جمبري')
//         .doc('detail')
//         .get().then((value) {
//       foodsScreen4.add(ItemModel.fromFire(value.data()!));
//       emit(AppGetPizzaElsaferSuccessState());
//
//     }).catchError((error){
//       print('Error');
//       emit(AppGetPizzaElsaferErrorState());
//     });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('مكرونات')
        .collection('اسباجتي سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('مكرونات')
        .collection('اسباجتي فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('مكرونات')
        .collection('اسباجتي لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    // اضافات

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('اضافات')
        .collection('اضافه جبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    // الحلو

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('الحلو')
        .collection('بيتزا تونه مفتته')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('الحلو')
        .collection('فطيره بسبوسه')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('الحلو')
        .collection('فطيره بسبوسه و كنافه')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('الحلو')
        .collection('فطيره بلوبيف')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('الحلو')
        .collection('فطيره تونه قطع')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('الحلو')
        .collection('فطيره سكر')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('الحلو')
        .collection('فطيره سكر و لبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('الحلو')
        .collection('فطيره شيكولاته')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('الحلو')
        .collection('فطيره شيكولاته موز')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('الحلو')
        .collection('فطيره قشطه و عسل')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('الحلو')
        .collection('فطيره كاستر')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('الحلو')
        .collection('فطيره كريمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('الحلو')
        .collection('فطيره كنافه')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('الحلو')
        .collection('فطيره مربي')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا السفير')
        .doc('الحلو')
        .collection('فطيره موز و كريمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElsaferSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElsaferErrorState());
    });

    foodsScreen1 = [];
    foodsScreen2 = [];
    foodsScreen3 = [];
    foodsScreen4 = [];
    foodsScreen5 = [];
    foodsScreen6 = [];
    foodsScreen7 = [];
    foodsScreen8 = [];
    foodsScreen9 = [];
    foodsScreen10 = [];
    foodsScreen11 = [];
    foodsScreen12 = [];

  }

  void getPizzaElmahdy(){

    // شرقي


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('شرقي')
        .collection('بسطرمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('شرقي')
        .collection('تونه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('شرقي')
        .collection('تونه قطع')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('شرقي')
        .collection('جبنه رومي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('شرقي')
        .collection('جبنه موتزاريلا')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('شرقي')
        .collection('سجق اسكندراني')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('شرقي')
        .collection('سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('شرقي')
        .collection('فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('شرقي')
        .collection('بسطرمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('شرقي')
        .collection('لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('شرقي')
        .collection('مشروم')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('شرقي')
        .collection('مشكل المهدي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا جبن')
        .doc('شرقي')
        .collection('بسطرمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    // ايطالي

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('ايطالي')
        .collection('بسطرمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('ايطالي')
        .collection('بيتزا بالخضار')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('ايطالي')
        .collection('تونه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('ايطالي')
        .collection('تونه قطع')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('ايطالي')
        .collection('سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('ايطالي')
        .collection('سوبر سوبريم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('ايطالي')
        .collection('سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('ايطالي')
        .collection('عشاق الجبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('ايطالي')
        .collection('فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('ايطالي')
        .collection('لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('ايطالي')
        .collection('مشروم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('ايطالي')
        .collection('مشكل المهدي')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    // الحلو

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('الحلو')
        .collection('فطيره كاستر')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('الحلو')
        .collection('فطيره بسبوسه و قشطه')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('الحلو')
        .collection('فطيره بسبوسه و كنافه')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('الحلو')
        .collection('فطيره بغاشه')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('الحلو')
        .collection('فطيره سكر ساده')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('الحلو')
        .collection('فطيره قشطه و سكر')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('الحلو')
        .collection('فطيره قشطه و عسل')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('الحلو')
        .collection('فطيره كاستر و قشطه')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('الحلو')
        .collection('فطيره نوتيلا')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    // اضافات


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('اضافات')
        .collection('جبنه نيسته')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا المهدي')
        .doc('اضافات')
        .collection('موتزاريلا')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    foodsScreen1 = [];
    foodsScreen2 = [];
    foodsScreen3 = [];
    foodsScreen4 = [];
    foodsScreen5 = [];
    foodsScreen6 = [];
    foodsScreen7 = [];
    foodsScreen8 = [];
    foodsScreen9 = [];
    foodsScreen10 = [];
    foodsScreen11 = [];
    foodsScreen12 = [];



  }

  void getPizzaHam(){

    // شرقي

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('شرقي')
        .collection('بيتزا بسطرمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('شرقي')
        .collection('بيتزا بيف')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('شرقي')
        .collection('بيتزا تونه قطع')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('شرقي')
        .collection('بيتزا تونه مفتته')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('شرقي')
        .collection('بيتزا سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('شرقي')
        .collection('بيتزا سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('شرقي')
        .collection('بيتزا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('شرقي')
        .collection('بيتزا لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('شرقي')
        .collection('بيتزا مشروم')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('شرقي')
        .collection('بيتزا مشكل جبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('شرقي')
        .collection('بيتزا هم')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    // ايطالي


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('ايطالي')
        .collection('بيتزا بسطرمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });




    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('ايطالي')
        .collection('بيتزا بيف')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('ايطالي')
        .collection('بيتزا تشكين باربكيو')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('ايطالي')
        .collection('بيتزا تونه قطع')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('ايطالي')
        .collection('بيتزا تونه مفتت')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('ايطالي')
        .collection('بيتزا سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('ايطالي')
        .collection('بيتزا سوبر سوبريم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('ايطالي')
        .collection('بيتزا سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('ايطالي')
        .collection('بيتزا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('ايطالي')
        .collection('بيتزا لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('ايطالي')
        .collection('بيتزا مارجريتا')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('ايطالي')
        .collection('بيتزا مشروم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('ايطالي')
        .collection('بيتزا مشكل جبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('ايطالي')
        .collection('بيتزا هم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    // بريك


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('بريك')
        .collection('بريك بسطرمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('بريك')
        .collection('بريك سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('بريك')
        .collection('بريك جبنه مشكل')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('بريك')
        .collection('بريك سوبر سوبريم')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('بريك')
        .collection('بريك سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('بريك')
        .collection('بريك فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('بريك')
        .collection('بريك لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('بريك')
        .collection('هم')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    // الحلو

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('الحلو')
        .collection('فطيره بغاشه')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('الحلو')
        .collection('فطيره شيكولاته')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('الحلو')
        .collection('فطيره قشطه + عسل')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('الحلو')
        .collection('فطيره كاستر')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    // اضافات

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('اضافات')
        .collection('اضافه جبنه موتزريلا')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('بيتزا')
        .collection('بيتزا هم')
        .doc('اضافات')
        .collection('اضافه جبنه نيستو')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElmahdySuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElmahdyErrorState());
    });

    foodsScreen1 = [];
    foodsScreen2 = [];
    foodsScreen3 = [];
    foodsScreen4 = [];
    foodsScreen5 = [];
    foodsScreen6 = [];
    foodsScreen7 = [];
    foodsScreen8 = [];
    foodsScreen9 = [];
    foodsScreen10 = [];
    foodsScreen11 = [];
    foodsScreen12 = [];


  }

  void getElasil(){

    // مشويات


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('مشويات')
        .collection('جوز حمام')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('مشويات')
        .collection('طرب')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('مشويات')
        .collection('فرخه علي الفحم')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('مشويات')
        .collection('كباب ضاني')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('مشويات')
        .collection('كفته ضاني')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('مشويات')
        .collection('كفته كندوز')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });



    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('مشويات')
        .collection('مشكل')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });


    // مكرونات


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('مكرونات')
        .collection('ارز بسمتي ساده')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('مكرونات')
        .collection('باسته باللحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('مكرونات')
        .collection('باسته شاورما فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('مكرونات')
        .collection('باسته شاورما لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    // وجبات

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('وجبات')
        .collection('وجبه اسكالوب')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('وجبات')
        .collection('وجبه زنجر')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('وجبات')
        .collection('وجبه فاهيتا')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('وجبات')
        .collection('وجبه كرانش')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('وجبات')
        .collection('وجبه كريسبي')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('وجبات')
        .collection('وجبه مكسيكي')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });


    // كريب



    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('كريب')
        .collection('بانيه فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('كريب')
        .collection('بطاطس')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('كريب')
        .collection('جمبري')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('كريب')
        .collection('سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('كريب')
        .collection('سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('كريب')
        .collection('شاورما فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('كريب')
        .collection('شاورما لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('كريب')
        .collection('شيش طاووق')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('كريب')
        .collection('فاهيتا')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('كريب')
        .collection('كبده اسكندراني')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('كريب')
        .collection('كفته')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('كريب')
        .collection('لحمه مفرومه')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('كريب')
        .collection('مشكل جبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('كريب')
        .collection('مكسيكانو')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    // فتات

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('فتات')
        .collection('فته زنجر')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('فتات')
        .collection('فته شاورما')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('فتات')
        .collection('فته شيش طاووق')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('فتات')
        .collection('فته فاهيتا')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('فتات')
        .collection('فته كبده')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('فتات')
        .collection('فته كرانشي')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('فتات')
        .collection('فته كرسبي')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('فتات')
        .collection('فته مكسيكانو')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    // شاورما

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('شاورما')
        .collection('شاورما')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    // سندوتشات

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('سندوتشات')
        .collection('اسكلوب فارخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('سندوتشات')
        .collection('بطاطس عادي')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('سندوتشات')
        .collection('بطاطس موزاريلا')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('سندوتشات')
        .collection('زنجر')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('سندوتشات')
        .collection('سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('سندوتشات')
        .collection('سوبر كرانشي')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('سندوتشات')
        .collection('شاورما فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('سندوتشات')
        .collection('شيش طاووق')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('سندوتشات')
        .collection('فاهيتا')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('سندوتشات')
        .collection('كبده')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('سندوتشات')
        .collection('كفته سيخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('سندوتشات')
        .collection('مكسيكي')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });


    // حواوشي

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('حواوشي')
        .collection('حواوشي بلدي')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('حواوشي')
        .collection('حواوشي سوري الاصيل')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('حواوشي')
        .collection('حواوشي ضاني')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('حواوشي')
        .collection('سندوتش كبده')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('حواوشي')
        .collection('حواوشي كفته')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });


    // اضافات

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('اضافات')
        .collection('بطاطس')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('اضافات')
        .collection('توميه')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('اضافات')
        .collection('سلطه')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('اضافات')
        .collection('طحينه')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('اضافات')
        .collection('كول سول')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('الاصيل')
        .doc('اضافات')
        .collection('مسبحه')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetElasilSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetElasilErrorState());
    });

    foodsScreen1 = [];
    foodsScreen2 = [];
    foodsScreen3 = [];
    foodsScreen4 = [];
    foodsScreen5 = [];
    foodsScreen6 = [];
    foodsScreen7 = [];
    foodsScreen8 = [];
    foodsScreen9 = [];
    foodsScreen10 = [];
    foodsScreen11 = [];
    foodsScreen12 = [];

  }

  void getHadrMot(){

    // سندوتشات


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('سندوتشات')
        .collection('حواوشي ضاني')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('سندوتشات')
        .collection('حواوشي كندوز')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('سندوتشات')
        .collection('سندوتش كفته ضاني')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('سندوتشات')
        .collection('سندوتش كفته كندوز')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });

    // مشويات


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('مشويات')
        .collection('طرب ضاني')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('مشويات')
        .collection('طرب كندوز')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('مشويات')
        .collection('فراخ شوايه فحم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('مشويات')
        .collection('فراخ شيش')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('مشويات')
        .collection('كباب ضاني')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('مشويات')
        .collection('كفته ضاني')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('مشويات')
        .collection('كفته كندوز')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });

    // وجبات


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('وجبات')
        .collection('ربع فرخه + ثمن كفته + ارز + سلطات')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });



    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('وجبات')
        .collection('ربع فرخه + ربع كفته + ارز + سلطات')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('وجبات')
        .collection('ربع فرخه كبسه + ارز + سلطات')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('وجبات')
        .collection('ربع فرخه مشوي + ارز + سلطات')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('وجبات')
        .collection('ربع كفته + ارز + سلطات')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('وجبات')
        .collection('نص فرخه + ثمن كفته + ارز + سلطات')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('وجبات')
        .collection('نص فرخه +ربع كفته + ارز + سلطات')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('وجبات')
        .collection('نص فرخه برياني + ارز + سلطات')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('وجبات')
        .collection('نص كفته + ارز + سلطات')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('وجبات')
        .collection('نصف فرخه مشوي + ارز + سلطات')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('وجبات')
        .collection('نفر لحم سوبر + ارز + سلطات')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('وجبات')
        .collection('وجبه لحمه كبيره + ارز + سلطات')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });

    // المطبخ

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('المطبخ')
        .collection('بطاطس محمره')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('المطبخ')
        .collection('جوز حمام محشي')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('المطبخ')
        .collection('خضار مشكل ساده')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('المطبخ')
        .collection('شوربه لسان عصفور')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('المطبخ')
        .collection('طبق ارز')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('المطبخ')
        .collection('فرد حمام محشي')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('المطبخ')
        .collection('ملوخيه ساده')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });

    // اضافات

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('اضافات')
        .collection('بابا غنوج')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('اضافات')
        .collection('سلطه خضراء')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('حضرموت المهندسين')
        .doc('اضافات')
        .collection('سلطه طحينه')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHadrMotSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHadrMotErrorState());
    });

    foodsScreen1 = [];
    foodsScreen2 = [];
    foodsScreen3 = [];
    foodsScreen4 = [];
    foodsScreen5 = [];
    foodsScreen6 = [];
    foodsScreen7 = [];
    foodsScreen8 = [];
    foodsScreen9 = [];
    foodsScreen10 = [];
    foodsScreen11 = [];
    foodsScreen12 = [];
  }

  void getPizzaElomda(){

    // شرقي

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('شرقي')
        .collection('بيتزا بسطرمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('شرقي')
        .collection('بيتزا تونه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('شرقي')
        .collection('بيتزا سجق اسكندراني')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('شرقي')
        .collection('بيتزا سجق بلدي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('شرقي')
        .collection('بيتزا سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('شرقي')
        .collection('بيتزا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('شرقي')
        .collection('بيتزا لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('شرقي')
        .collection('بيتزا بسطرمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('شرقي')
        .collection('بيتزا ميكس جبنه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('شرقي')
        .collection('بيتزا ميكس لحوم')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('شرقي')
        .collection('ميكس لحوم و جبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    // ايطالي

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('ايطالي')
        .collection('بيتزا بسطرمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('ايطالي')
        .collection('بيتزا تونه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('ايطالي')
        .collection('بيتزا سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('ايطالي')
        .collection('بيتزا سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });



    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('ايطالي')
        .collection('بيتزا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('ايطالي')
        .collection('بيتزا لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('ايطالي')
        .collection('بيتزا مارجريتا')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('ايطالي')
        .collection('بيتزا ميكس جبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('ايطالي')
        .collection('بيتزا ميكس لحوم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('ايطالي')
        .collection('ميكس لحوم و جبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    // المكرونات


    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('المكرونات')
        .collection('مكرونه العمده')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('المكرونات')
        .collection('مكرونه سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('المكرونات')
        .collection('مكرونه فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('المكرونات')
        .collection('مكرونه لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    // الفطائر

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('الفطائر')
        .collection('فطيره بسطرمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('الفطائر')
        .collection('فطيره تونه')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('الفطائر')
        .collection('فطيره سجق اسكندراني')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('الفطائر')
        .collection('فطيره سجق بلدي')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('الفطائر')
        .collection('فطيره سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('الفطائر')
        .collection('فطيره فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('الفطائر')
        .collection('فطيره لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('الفطائر')
        .collection('فطيره بسطرمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('الفطائر')
        .collection('فطيره مشلتت')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('الفطائر')
        .collection('فطيره ميكس جبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('الفطائر')
        .collection('فطيره ميكس لحوم')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    // الحلو

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('الحلو')
        .collection('فطيره سكر')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('الحلو')
        .collection('فطيره شكولاته بني')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('الحلو')
        .collection('فطيره شكولاته بيضاء')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('الحلو')
        .collection('فطيره شهر العسل')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('الحلو')
        .collection('فطيره فواكه')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('الحلو')
        .collection('فطيره قشطه و عسل')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('الحلو')
        .collection('فطيره ميكس شكولاته')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    // بريك

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('البريك')
        .collection('بريك بسطرمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('البريك')
        .collection('بريك سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('البريك')
        .collection('بريك سجق اسكندراني')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('البريك')
        .collection('بريك فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر الشوبك')
        .doc('بينزا')
        .collection('بينزا العمده')
        .doc('البريك')
        .collection('بريك لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetPizzaElomdaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetPizzaElomdaErrorState());
    });

    foodsScreen1=[];
    foodsScreen2=[];
    foodsScreen3=[];
    foodsScreen4=[];
    foodsScreen5=[];
    foodsScreen6=[];
    foodsScreen7=[];
    foodsScreen8=[];
    foodsScreen9=[];
    foodsScreen10=[];
    foodsScreen11=[];
    foodsScreen12=[];










  }

  void getHamdaElmahta(){

    // سندوتشات


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('سندوتشات')
        .collection('برجر لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('سندوتشات')
        .collection('برجر لحمه ميكس')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('سندوتشات')
        .collection('ساندوتش زنجر')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('سندوتشات')
        .collection('سندوتش بانيه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('سندوتشات')
        .collection('سندوتش بانيه فرنساوي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('سندوتشات')
        .collection('سندوتش بانيه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('سندوتشات')
        .collection('سندوتش بطاطس')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('سندوتشات')
        .collection('سندوتش بطاطس بالجبنه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('سندوتشات')
        .collection('سندوتش سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('سندوتشات')
        .collection('سندوتش سجق عيش بلدي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('سندوتشات')
        .collection('سندوتش سجق فينو')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('سندوتشات')
        .collection('سندوتش شاورما لحمه فرنساوي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('سندوتشات')
        .collection('سندوتش شيش طاووق')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('سندوتشات')
        .collection('سندوتش فراخ شاورما فرنساوي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('سندوتشات')
        .collection('سندوتش كبده صاج')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('سندوتشات')
        .collection('سندوتش كبده فينو')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('سندوتشات')
        .collection('كبده عيش بلدي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });


    // شاورما

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('شاورما')
        .collection('شاورما فراخ سوري')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('شاورما')
        .collection('شاورما لحم سوري')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('شاورما')
        .collection('فته شاورما فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('شاورما')
        .collection('فته شاورما لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('شاورما')
        .collection('وجبه فراخ اكستر')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('شاورما')
        .collection('وجبه فراخ عربي')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    // طواجن

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('طواجن')
        .collection('طاجن شاورما فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('طواجن')
        .collection('طاجن شاورما لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('طواجن')
        .collection('طاجن فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('طواجن')
        .collection('طاجن كبده')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('طواجن')
        .collection('طاجن لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });


    // كريب

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('كريب')
        .collection('كريب بانيه')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('كريب')
        .collection('كريب بطاطس')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('كريب')
        .collection('كريب زنجر')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('كريب')
        .collection('كريب سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('كريب')
        .collection('كريب شاورما فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('كريب')
        .collection('كريب شاورما لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('كريب')
        .collection('كريب شاورما لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('كريب')
        .collection('كريب شيش طاووق')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('كريب')
        .collection('كريب فاهيتا فراخ بالمشروم')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('كريب')
        .collection('كريب فاهيتا لحمه بالمشروم')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('كريب')
        .collection('كريب كبده')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('كريب')
        .collection('كريب كرانشي')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('كريب')
        .collection('كريب كرسبي')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('كريب')
        .collection('كريب كفته')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('كريب')
        .collection('كريب مشكل جبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('كريب')
        .collection('كريب مشكل لحوم')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    // كشري


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('كشري')
        .collection('علبه حماده جامبو')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('كشري')
        .collection('علبه حماده كبير')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('كشري')
        .collection('علبه حماده وسط')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('كشري')
        .collection('علبه دبل')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('كشري')
        .collection('علبه شبح')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('كشري')
        .collection('علبه كماله')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    // وجبات

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('وجبات')
        .collection('ربع فرخه فقط')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('وجبات')
        .collection('فرخه شوايه')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    // حواوشي

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('حواوشي')
        .collection('حواوشي اسكندراني')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('حواوشي')
        .collection('حواوشي اسكندراني موتزريلا')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('حواوشي')
        .collection('حواوشي عادي')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    // الحلو

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('الحلو')
        .collection('ارز بلبن عادي')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('الحلو')
        .collection('ارز بلبن فرن')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('الحلو')
        .collection('كريب نوتيلا')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    // اضافات

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('اضافات')
        .collection('ارز بستمي')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('اضافات')
        .collection('بطاطس')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('اضافات')
        .collection('توميه')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('اضافات')
        .collection('طحينه')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('اضافات')
        .collection('عيش توست')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('اضافات')
        .collection('مخلل')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('اضافات')
        .collection('كبده اضافات للكشري او الطواجن')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كل الفئات')
        .collection('مطعم و كشري حماده المحطه')
        .doc('اضافات')
        .collection('شاورما لحمه او فراخ اضافات للكشري او الطاجن')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHamdaElmahtaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHamdaElmahtaErrorState());
    });

    foodsScreen1=[];
    foodsScreen2=[];
    foodsScreen3=[];
    foodsScreen4=[];
    foodsScreen5=[];
    foodsScreen6=[];
    foodsScreen7=[];
    foodsScreen8=[];
    foodsScreen9=[];
    foodsScreen10=[];
    foodsScreen11=[];
    foodsScreen12=[];

  }

  void getHatyeEltakya(){


    // سندوتشات

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('سندوتشات')
        .collection('رغيف حواوشي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('سندوتشات')
        .collection('برجر جبنه فرنساوي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('سندوتشات')
        .collection('برجر التكيه فرنساوي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('سندوتشات')
        .collection('سندوتش بانيه فرنساوي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('سندوتشات')
        .collection('سندوتش برجر ساده - فرنساوي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('سندوتشات')
        .collection('سندوتش زنجر فرنساوي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('سندوتشات')
        .collection('سندوتش شيش فرنساوي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('سندوتشات')
        .collection('سندوتش فاهيتا فرنساوي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('سندوتشات')
        .collection('سندوتش كبده')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('سندوتشات')
        .collection('سندوتش كرسبي فرنساوي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('سندوتشات')
        .collection('سندوتش كوردن بلو فرنساوي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    // المطبخ


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('المطبخ')
        .collection('سمبوسك جبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('المطبخ')
        .collection('سمبوسك لحم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('المطبخ')
        .collection('كريمه بالفراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('المطبخ')
        .collection('كوارع مخليه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('المطبخ')
        .collection('لسان عصفور')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('المطبخ')
        .collection('ورق عنب')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    // باستا

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('باستا')
        .collection('مكرونه الفريدو')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('باستا')
        .collection('مكرونه بالسجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('باستا')
        .collection('مكرونه بالكبده')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('باستا')
        .collection('مكرونه بشاميل')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('باستا')
        .collection('مكرونه بولونيز')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('باستا')
        .collection('مكرونه نجرسكو')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });


    // سلاطات

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('سلاطات')
        .collection('بابا غنوج')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('سلاطات')
        .collection('توميه')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('سلاطات')
        .collection('سلطه بلدي')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('سلاطات')
        .collection('سلطه طحينه')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('سلاطات')
        .collection('طماطم مشوي')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('سلاطات')
        .collection('مخلل')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    // طواجن


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('طواجن')
        .collection('طاجن ارز معمر ساده')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('طواجن')
        .collection('طاجن ارز معمر لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('طواجن')
        .collection('طاجن التكيه')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('طواجن')
        .collection('طاجن باميه باللحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('طواجن')
        .collection('طاجن تورلي لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('طواجن')
        .collection('طاجن سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('طواجن')
        .collection('طاجن عكاوي')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('طواجن')
        .collection('طاجن ملوخيه')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('طواجن')
        .collection('طاجن ورق عنب كوارع')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    // فتات

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('فتات')
        .collection('فته كوارع')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('فتات')
        .collection('فته لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('فتات')
        .collection('فته موزه')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    // كريب


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('كريب')
        .collection('كريب بانيه')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('كريب')
        .collection('كريب برجر')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('كريب')
        .collection('كريب بطاطس')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('كريب')
        .collection('كريب زنجر')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('كريب')
        .collection('كريب سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('كريب')
        .collection('كريب سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('كريب')
        .collection('كريب شيش طاووق')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('كريب')
        .collection('كريب فاهيتا')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('كريب')
        .collection('كريب كرسبي')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('كريب')
        .collection('كريب كفته')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('كريب')
        .collection('كريب مكس جبنه')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    // مشويات

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('مشويات')
        .collection('ريش')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('مشويات')
        .collection('شيش طاووق')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('مشويات')
        .collection('طرب')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('مشويات')
        .collection('طلب نيفه')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('مشويات')
        .collection('فراخ تكا')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('مشويات')
        .collection('فراخ مشويه شيش')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('مشويات')
        .collection('كباب')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('مشويات')
        .collection('كبده')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('مشويات')
        .collection('حاتي التكيه')
        .doc('مشويات')
        .collection('كفته')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetHatyeEltakiaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetHatyeEltakiaErrorState());
    });


    foodsScreen1=[];
    foodsScreen2=[];
    foodsScreen3=[];
    foodsScreen4=[];
    foodsScreen5=[];
    foodsScreen6=[];
    foodsScreen7=[];
    foodsScreen8=[];
    foodsScreen9=[];
    foodsScreen10=[];
    foodsScreen11=[];
    foodsScreen12=[];

  }

  void getFishAbuMarim(){

    // أسماك أبو مريم

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('اسماك')
        .collection('جمبري')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('اسماك')
        .collection('سبيط بلدي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('اسماك')
        .collection('سمك بربوني')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('اسماك')
        .collection('سمك بلطي')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('اسماك')
        .collection('سمك بوري')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('اسماك')
        .collection('سمك تونه ماكريال')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('اسماك')
        .collection('سمك دنيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('اسماك')
        .collection('سمك فيليه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('اسماك')
        .collection('سمك قاروص')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('اسماك')
        .collection('سمك مكرونه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('اسماك')
        .collection('سمك قشر بياض')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    // سندوتشات

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('سندوتشات')
        .collection('سندوتش جمبري')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('سندوتشات')
        .collection('سندوتش سبيط')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });



    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('سندوتشات')
        .collection('سندوتش فيليه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('سندوتشات')
        .collection('سندوتش كفته جمبري')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('سندوتشات')
        .collection('سندوتش ميكس')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });

    // شوربه


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('شوربه')
        .collection('شوربه جمبري بطارخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('شوربه')
        .collection('شوربه جمبري حمراء')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('شوربه')
        .collection('شوربه جمبري ميكس')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('شوربه')
        .collection('شوربه جمبري سي فود')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('شوربه')
        .collection('شوربه جمبري سي فود مخليه')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('شوربه')
        .collection('ملوخيه بالجمبري')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });

    // طواجن

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('طواجن')
        .collection('طاجن بطارخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('طواجن')
        .collection('طاجن جمبري صوص ابيض')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('طواجن')
        .collection('طاجن جمبري صوص احمر')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('طواجن')
        .collection('طاجن سبيط')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('طواجن')
        .collection('طاجن فيليه صوص ابيض')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('طواجن')
        .collection('طاجن فيليه صوص احمر')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('طواجن')
        .collection('طاجن ميكس')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('طواجن')
        .collection('طاجن مقطش')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });

    // وجبات

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('وجبات')
        .collection('وجبه جمبري فسفور')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('وجبات')
        .collection('وجبه تونه ماكريال')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('وجبات')
        .collection('وجبه بوري')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('وجبات')
        .collection('وجبه بلطي')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('وجبات')
        .collection('وجبه الفردين')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('وجبات')
        .collection('وجبه العائله')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    // المطبخ

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('المطبخ')
        .collection('ارز سي فود')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('المطبخ')
        .collection('ارز صياديه ساده')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('المطبخ')
        .collection('مكرونه صوص ابيض')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('المطبخ')
        .collection('مكرونه صوص احمر')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('المطبخ')
        .collection('ارز بالجمبري')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('المطبخ')
        .collection('ارز بالسبيط')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('المطبخ')
        .collection('ارز بالفليه')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    // الحلو


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('الحلو')
        .collection('وجبه ابو مريم')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });

    // اضافات

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('اضافات')
        .collection('سلطه خضراء')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('اضافات')
        .collection('سلطه طحينه')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('اضافات')
        .collection('خيار مخلل')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('اسماك')
        .collection('اسماك ابو مريم')
        .doc('اضافات')
        .collection('بابا غنوج')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetAbuMariamFishSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetAbuMariamFishErrorState());
    });

    foodsScreen1=[];
    foodsScreen2=[];
    foodsScreen3=[];
    foodsScreen4=[];
    foodsScreen5=[];
    foodsScreen6=[];
    foodsScreen7=[];
    foodsScreen8=[];
    foodsScreen9=[];
    foodsScreen10=[];
    foodsScreen11=[];
    foodsScreen12=[];


  }

  void getKoshryHamada(){


    // كشري

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كشري و طواجن')
        .collection('كشري حماده')
        .doc('كشري')
        .collection('علبه كماله')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetKosharyHamadaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetKosharyHamadaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كشري و طواجن')
        .collection('كشري حماده')
        .doc('كشري')
        .collection('علبه حماده')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetKosharyHamadaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetKosharyHamadaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كشري و طواجن')
        .collection('كشري حماده')
        .doc('كشري')
        .collection('علبه محمد صلاح')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetKosharyHamadaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetKosharyHamadaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كشري و طواجن')
        .collection('كشري حماده')
        .doc('كشري')
        .collection('علبه الشبح')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetKosharyHamadaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetKosharyHamadaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كشري و طواجن')
        .collection('كشري حماده')
        .doc('كشري')
        .collection('علبه ميكس')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetKosharyHamadaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetKosharyHamadaErrorState());
    });

    //طواجن

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كشري و طواجن')
        .collection('كشري حماده')
        .doc('طواجن')
        .collection('طاجن لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetKosharyHamadaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetKosharyHamadaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كشري و طواجن')
        .collection('كشري حماده')
        .doc('طواجن')
        .collection('طاجن لحمه كبير')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetKosharyHamadaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetKosharyHamadaErrorState());
    });

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كشري و طواجن')
        .collection('كشري حماده')
        .doc('طواجن')
        .collection('طاجن فراخ عادي')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetKosharyHamadaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetKosharyHamadaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كشري و طواجن')
        .collection('كشري حماده')
        .doc('طواجن')
        .collection('طاجن فراخ كبير')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetKosharyHamadaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetKosharyHamadaErrorState());
    });


    // حواوشي

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كشري و طواجن')
        .collection('كشري حماده')
        .doc('حواوشي')
        .collection('حواوشي بلدي')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetKosharyHamadaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetKosharyHamadaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كشري و طواجن')
        .collection('كشري حماده')
        .doc('حواوشي')
        .collection('حواوشي فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetKosharyHamadaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetKosharyHamadaErrorState());
    });


    // الحلو

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كشري و طواجن')
        .collection('كشري حماده')
        .doc('الحلو')
        .collection('ارز باللبن حلو')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetKosharyHamadaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetKosharyHamadaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كشري و طواجن')
        .collection('كشري حماده')
        .doc('الحلو')
        .collection('بليله')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetKosharyHamadaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetKosharyHamadaErrorState());
    });


    // اضافات

    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كشري و طواجن')
        .collection('كشري حماده')
        .doc('اضافات')
        .collection('عيش توست')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetKosharyHamadaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetKosharyHamadaErrorState());
    });


    FirebaseFirestore.instance.collection('كفر شبين')
        .doc('كشري و طواجن')
        .collection('كشري حماده')
        .doc('اضافات')
        .collection('سلطه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetKosharyHamadaSuccessState());

    }).catchError((error){
      print('Error');
      emit(AppGetKosharyHamadaErrorState());
    });

    foodsScreen1=[];
    foodsScreen2=[];
    foodsScreen3=[];
    foodsScreen4=[];
    foodsScreen5=[];
    foodsScreen6=[];
    foodsScreen7=[];
    foodsScreen8=[];
    foodsScreen9=[];
    foodsScreen10=[];
    foodsScreen11=[];
    foodsScreen12=[];


  }

  void getWings (){

    // وجبات

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('Wings')
        .doc('برجر')
        .collection('دينر بوكس')
        .doc('detail')
        .get()
        .then((value){
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('Error when get wings Meals');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('Wings')
        .doc('برجر')
        .collection('سناك بوكس')
        .doc('detail')
        .get()
        .then((value){
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('Error when get wings Meals');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('Wings')
        .doc('برجر')
        .collection('سوبر دينر')
        .doc('detail')
        .get()
        .then((value){
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('Error when get wings Meals');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('Wings')
        .doc('برجر')
        .collection('سوبر ستربس')
        .doc('detail')
        .get()
        .then((value){
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('Error when get wings Meals');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('Wings')
        .doc('برجر')
        .collection('كيدز ميل')
        .doc('detail')
        .get()
        .then((value){
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('Error when get wings Meals');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('Wings')
        .doc('برجر')
        .collection('لايت استريس')
        .doc('detail')
        .get()
        .then((value){
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('Error when get wings Meals');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('Wings')
        .doc('برجر')
        .collection('مكس بوكس')
        .doc('detail')
        .get()
        .then((value){
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('Error when get wings Meals');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('Wings')
        .doc('برجر')
        .collection('ميجا ستربس')
        .doc('detail')
        .get()
        .then((value){
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('Error when get wings Meals');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('Wings')
        .doc('برجر')
        .collection('وجبة التوفير')
        .doc('detail')
        .get()
        .then((value){
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('Error when get wings Meals');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('Wings')
        .doc('برجر')
        .collection('وجبة وينجز')
        .doc('detail')
        .get()
        .then((value){
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      print('menu : ${value.data()}');
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('Error when get wings Meals');
      emit(AppGetMenusErrorState());
    });

    // برجر

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('Wings')
        .doc('وجبات')
        .collection('اونيون وينج')
        .doc('detail')
        .get()
        .then((value){
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('Error when get wings Meals');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('Wings')
        .doc('وجبات')
        .collection('بيج وينج طبقتين')
        .doc('detail')
        .get()
        .then((value){
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('Error when get wings Meals');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('Wings')
        .doc('وجبات')
        .collection('فيينا وينج')
        .doc('detail')
        .get()
        .then((value){
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('Error when get wings Meals');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('Wings')
        .doc('وجبات')
        .collection('كلاسيك وينج')
        .doc('detail')
        .get()
        .then((value){
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('Error when get wings Meals');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('Wings')
        .doc('وجبات')
        .collection('لاف تشيز')
        .doc('detail')
        .get()
        .then((value){
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('Error when get wings Meals');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('Wings')
        .doc('وجبات')
        .collection('موتز وينج')
        .doc('detail')
        .get()
        .then((value){
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('Error when get wings Meals');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('Wings')
        .doc('وجبات')
        .collection('موتزريلا لاف')
        .doc('detail')
        .get()
        .then((value){
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('Error when get wings Meals');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('Wings')
        .doc('وجبات')
        .collection('هوت وينج')
        .doc('detail')
        .get()
        .then((value){
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('Error when get wings Meals');
      emit(AppGetMenusErrorState());
    });


    // وجبات عائليه


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('Wings')
        .doc('وجبات عائلية')
        .collection('وجبة 12 قطعة')
        .doc('detail')
        .get()
        .then((value){
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('Error when get wings Meals : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('Wings')
        .doc('وجبات عائلية')
        .collection('وجبة 16 قطعة')
        .doc('detail')
        .get()
        .then((value){
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('Error when get wings Meals : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('Wings')
        .doc('وجبات عائلية')
        .collection('وجبة 8 قطع')
        .doc('detail')
        .get()
        .then((value){
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('Error when get wings Meals : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    foodsScreen1=[];
    foodsScreen2=[];
    foodsScreen3=[];
    foodsScreen4=[];
    foodsScreen5=[];
    foodsScreen6=[];
    foodsScreen7=[];
    foodsScreen8=[];


  }

  void getElbak ()
  {
    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('اضافات')
        .collection('ارز')
        .doc('detail')
        .get().then((value) {
          foodsScreen1.add(ItemModel.fromFire(value.data()!));
          emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('اضافات')
        .collection('بطاطس')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('اضافات')
        .collection('ثومية')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('اضافات')
        .collection('خبز')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('اضافات')
        .collection('ريزو دجاج')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('اضافات')
        .collection('كلو سلو')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('اضافات')
        .collection('كومبو بطاطس + كولا')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // سندوتشات

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('شندوتشات')
        .collection('برجر دجاج')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('شندوتشات')
        .collection('بطاطس كبير')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('شندوتشات')
        .collection('تويستر البيك')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('شندوتشات')
        .collection('جمبرى البيك')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('شندوتشات')
        .collection('زنجر راوند')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('شندوتشات')
        .collection('زنجر سوبريم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('شندوتشات')
        .collection('سندوتش اطفال')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('شندوتشات')
        .collection('مسحب')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('شندوتشات')
        .collection('مطافى')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('شندوتشات')
        .collection('يرجر لحم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // وجبات


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('وجبات')
        .collection('الوجبة الخاصة')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('وجبات')
        .collection('الوجبة الشقية')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('وجبات')
        .collection('كومبو ميل')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('وجبات')
        .collection('وجبة اطفال استربس')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('وجبات')
        .collection('وجبة اطفال دجاج')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('وجبات')
        .collection('وجبة البيك')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('وجبات')
        .collection('وجبة التوفير')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('وجبات')
        .collection('وجبة شخصية')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('وجبات')
        .collection('وجبة شخصية استربس')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('وجبات')
        .collection('وجبة فردية استربس')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    // وجبات عائلية


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('وجبات عائلية')
        .collection('الوجبة الاقتصادية استربس')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('وجبات عائلية')
        .collection('الوجبة الاقتصادية دجاج')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('وجبات عائلية')
        .collection('سوبر ميل استربس')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('وجبات عائلية')
        .collection('سوبر ميل دجاج')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('وجبات عائلية')
        .collection('مينى فاملى استربس')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('وجبات عائلية')
        .collection('وجبة الاسرة استربس')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('وجبات عائلية')
        .collection('وجبة التربو استربس')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('وجبات عائلية')
        .collection('وجبة التربو دجاج')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('وجبات عائلية')
        .collection('وجبة السرة دجاج')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('وجبات عائلية')
        .collection('وجبة الوليمة استربس')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('وجبات عائلية')
        .collection('وجبة الوليمة دجاج')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('وجبات عائلية')
        .collection('وجبة عائلية استربس')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('Restaurant')
        .collection('البيك')
        .doc('وجبات عائلية')
        .collection('وجبة عائلية دجاج')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el bak : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    foodsScreen5=[];
    foodsScreen6=[];
    foodsScreen7=[];
    foodsScreen8=[];

  }

  void getPizzaPremo ()
  {
    FirebaseFirestore.instance.collection('شبين')
        .doc('بيتزا')
        .collection('بيتزا بريمو')
        .doc('شرقى')
        .collection('بيتزا سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get pizza premo : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    foodsScreen2=[];
    foodsScreen3=[];
    foodsScreen4=[];
    foodsScreen5=[];
    foodsScreen6=[];
    foodsScreen7=[];
    foodsScreen8=[];

  }

  void getTaboshElsory()
  {

    // وجبات

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('وجبات')
        .collection('3 أفراد')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('وجبات')
        .collection('6 أفراد')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('وجبات')
        .collection('دبل شاورما عربى')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('وجبات')
        .collection('شاورما عربى قطع')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('وجبات')
        .collection('مكس طبوش')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('وجبات')
        .collection('وجبة اكسترا شاورما موتزريلا')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('وجبات')
        .collection('وجبة زنجر عائلى')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('وجبات')
        .collection('وجبه اطفال')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // فراخ

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('فراخ')
        .collection('اصابع زنجر')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('فراخ')
        .collection('تشيكن باربكيو')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('فراخ')
        .collection('تشيكن بافلو')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('فراخ')
        .collection('شيش طاووق على الجريل')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('فراخ')
        .collection('صدور على الجريل')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('فراخ')
        .collection('فاهيتا')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('فراخ')
        .collection('فراخ مكسيكى')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('فراخ')
        .collection('كوردن بلو')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('فراخ')
        .collection('مكس فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // فتات

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('فتات')
        .collection('فتة أصابع زنجر')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('فتات')
        .collection('فتة تسيكن باربكيو')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('فتات')
        .collection('فتة تشيكن بافلو')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('فتات')
        .collection('فتة تشيكن مكسيكى')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('فتات')
        .collection('فتة شاورما فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('فتات')
        .collection('فتة شيش طاووق')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('فتات')
        .collection('فتة صدور عالجريل')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('فتات')
        .collection('فتة فهيتا مشروم')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('فتات')
        .collection('فتة مكس')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('فتات')
        .collection('فته سجق اسكندرانى')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('فتات')
        .collection('فته كبده اسكندرانى')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('فتات')
        .collection('فته كفته على الجريل')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    // شاورما


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('شاورما')
        .collection('صاروخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('شاورما')
        .collection('فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('شاورما')
        .collection('فراخ موتزريلا')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('شاورما')
        .collection('لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // سندوتشات

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('سندوتشات')
        .collection('اومليت جبنه')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('سندوتشات')
        .collection('اومليت جبنه سورى')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('سندوتشات')
        .collection('اومليت مكس جبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('سندوتشات')
        .collection('اومليت مكس جبن سورى')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('سندوتشات')
        .collection('بانيه')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('سندوتشات')
        .collection('بانيه سورى')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('سندوتشات')
        .collection('بطاطس بوم فارم موتزريلا')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('سندوتشات')
        .collection('بطاطس بوم فريت')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('سندوتشات')
        .collection('بطاطس بوم فريت سورى')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('سندوتشات')
        .collection('بطاطس بوم فريت موتزريلا')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('سندوتشات')
        .collection('بطاطس بوم فريت ميكس جبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('سندوتشات')
        .collection('بطاطس بوم فريت ميكس جبن سورى')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('سندوتشات')
        .collection('بطاطس مكس مدخن')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('سندوتشات')
        .collection('بطاطس مكس مدخن سورى')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('سندوتشات')
        .collection('بيض اومليت')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('سندوتشات')
        .collection('بيض اومليت سورى')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('سندوتشات')
        .collection('بيض بالبسطرمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('سندوتشات')
        .collection('بيض بالبسطرمه سورى')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('سندوتشات')
        .collection('سجق اسكندرانى')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('سندوتشات')
        .collection('سندوتش سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('سندوتشات')
        .collection('كبده اسكندرانى')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('سندوتشات')
        .collection('كفته سيخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('سندوتشات')
        .collection('مكس جبن سورى')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('سندوتشات')
        .collection('هوت دوج')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // برجر


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('برجر')
        .collection('برجر بالموتزريلا')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('برجر')
        .collection('برجر سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('برجر')
        .collection('برجر فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('برجر')
        .collection('برجر لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('برجر')
        .collection('برجر مكس لحوم')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('برجر')
        .collection('مكس برجر بيض بالجبنه')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // الحلو

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('الحلو')
        .collection('تورتيلا نوتيلا فواكه')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('الحلو')
        .collection('حلاوه قشطة')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('الحلو')
        .collection('ساندوتش نوتيلا')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('الحلو')
        .collection('عسل قشطه')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('الحلو')
        .collection('مربى قشطه')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // البروست


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('البروست')
        .collection('فراخ بروست')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('البروست')
        .collection('فراخ زنجر')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // اضافات

    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('اضافات')
        .collection('اضافه جبنه')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('اضافات')
        .collection('اضافه مشروم')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('اضافات')
        .collection('بطاطس باكيت')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('اضافات')
        .collection('بطاطس جبنه و هالبينو')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('اضافات')
        .collection('بطاطس مكس')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('اضافات')
        .collection('ثوميه')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('اضافات')
        .collection('رغيف عيش')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('اضافات')
        .collection('علبة سبايسى')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('اضافات')
        .collection('علبه مشكل')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كريب')
        .collection('طبوش السورى')
        .doc('اضافات')
        .collection('كلو سلو')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get TaboshElsory : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    foodsScreen10 = [];

  }

  void getKosharyHend ()
  {

    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('كشرى')
        .collection('علبة سوبر')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('كشرى')
        .collection('علبة لوكس')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('كشرى')
        .collection('فويل جامبو')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('كشرى')
        .collection('فويل عائلى')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('كشرى')
        .collection('فويل مدور')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('كشرى')
        .collection('فويل هند')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    // طواجن

    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('طواجن')
        .collection('طاجن فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('طواجن')
        .collection('طاجن لحمة بلدى')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // شرقى


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('شرقى')
        .collection('بيتزا باللحمه البلدى')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('شرقى')
        .collection('بيتزا بسطرمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('شرقى')
        .collection('بيتزا بلوبيف')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('شرقى')
        .collection('بيتزا تونة قطع')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('شرقى')
        .collection('بيتزا تونة مفتتة')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('شرقى')
        .collection('بيتزا جبنه رومى')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('شرقى')
        .collection('بيتزا جمبرى')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('شرقى')
        .collection('بيتزا سلامى')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('شرقى')
        .collection('بيتزا سوبر سوبريوم')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('شرقى')
        .collection('بيتزا سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('شرقى')
        .collection('بيتزا عشاق الجبنة')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('شرقى')
        .collection('بيتزا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('شرقى')
        .collection('بيتزا لحمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('شرقى')
        .collection('بيتزا مشروم')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('شرقى')
        .collection('سى فود')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // سندوتشات

    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('سندوتشات')
        .collection('سندوتش اومليت بالجبنة')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('سندوتشات')
        .collection('سندوتش بطاطس بالموزاريلا')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('سندوتشات')
        .collection('سندوتش بطاطس بوم فريت')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('سندوتشات')
        .collection('سندوتش بيض اومليت')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('سندوتشات')
        .collection('سندوتش سنبش اومليت')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('سندوتشات')
        .collection('سندوتش شيدر بطاطس')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('سندوتشات')
        .collection('سندوتش ميكس جبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // حواوشى


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('حواوشى')
        .collection('حواوشى اسكندرانى')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('حواوشى')
        .collection('حواوشى سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('حواوشى')
        .collection('حواوشى فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('حواوشى')
        .collection('حواوشى لحمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // ايطالى


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('ايطالى')
        .collection('بيتزا باللحمة البلدى')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('ايطالى')
        .collection('بيتزا بسطرمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('ايطالى')
        .collection('بيتزا بلوبيف')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('ايطالى')
        .collection('بيتزا تونة قطع')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('ايطالى')
        .collection('بيتزا تونة مفتته')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('ايطالى')
        .collection('بيتزا جبنة رومى')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('ايطالى')
        .collection('بيتزا سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('ايطالى')
        .collection('بيتزا سلامى')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('ايطالى')
        .collection('بيتزا سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('ايطالى')
        .collection('بيتزا عشاق الجبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('ايطالى')
        .collection('بيتزا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('ايطالى')
        .collection('بيتزا مرجريتا')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('ايطالى')
        .collection('بيتزا مشروم')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    //  الحلو

    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('الحلو')
        .collection('ارز باللبن سادة')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('الحلو')
        .collection('ارز باللبن فرن')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('الحلو')
        .collection('فطيرة بغاشة')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('الحلو')
        .collection('فطيرة سكر')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('الحلو')
        .collection('فطيرة شيكولاتة')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('الحلو')
        .collection('فطيرة فواكه')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('الحلو')
        .collection('فطيرة قشطة و عسل')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('الحلو')
        .collection('فطيرة كنافة')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('الحلو')
        .collection('فطيرة مكسرات')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('الحلو')
        .collection('مهلبية')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // اضافات

    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('اضافات')
        .collection('اضافة جبنة موزاريلا')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('اضافات')
        .collection('اضافة جبنه رومى')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('اضافات')
        .collection('تقلية')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('اضافات')
        .collection('سلطة')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كشرى')
        .collection('كشرى هند')
        .doc('اضافات')
        .collection('عيش توست')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get koshary hend  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    foodsScreen10 = [];
    foodsScreen9 = [];

  }


  void getFresco ()
  {
    // وجبات

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('وجبات')
        .collection('تشكين كارى')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('وجبات')
        .collection('فته شاورما فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('وجبات')
        .collection('فته شاورما لحمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('وجبات')
        .collection('فته شاورما لحمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('وجبات')
        .collection('فريسكو')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('وجبات')
        .collection('وجبة استربس')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('وجبات')
        .collection('وجبة بيف بتلو')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('وجبات')
        .collection('وجبة تشيكن باربكيو')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('وجبات')
        .collection('وجبة شاورما عربى فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('وجبات')
        .collection('وجبة شاورما عربى لحمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // مشويات


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('مشويات')
        .collection('شيش طاووق')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('مشويات')
        .collection('فرخة مسحب')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('مشويات')
        .collection('فرخة مشويه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('مشويات')
        .collection('كباب')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('مشويات')
        .collection('كفتة تركى')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // كريب

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('كريب')
        .collection('اورينتال')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('كريب')
        .collection('بيف')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('كريب')
        .collection('تشيكن')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('كريب')
        .collection('فايترز')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('كريب')
        .collection('فريسكو')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('كريب')
        .collection('فرينش فرايز')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('كريب')
        .collection('فور سيزون')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('كريب')
        .collection('فيستفال')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('كريب')
        .collection('نوتيلا')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // طواجن

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('طواجن')
        .collection('أرز بسمتى بالخضار')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('طواجن')
        .collection('أرز بسمتى بالمكسرات')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('طواجن')
        .collection('أرز بسمتى ساده')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('طواجن')
        .collection('طاجن بامية باللحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('طواجن')
        .collection('طاجن فته فريسكو')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('طواجن')
        .collection('مكرونه')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // شاورما

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('شاورما')
        .collection('اكسترا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('شاورما')
        .collection('اكسترا لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('شاورما')
        .collection('سندوتش بطاطس')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('شاورما')
        .collection('فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('شاورما')
        .collection('لحمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('شاورما')
        .collection('وجبة عربى قطع لحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('شاورما')
        .collection('وجبه عربى قطع فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // سلاطات

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('سلاطات')
        .collection('سلطة بلدى')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('سلاطات')
        .collection('سلطه طحينه')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('سلاطات')
        .collection('سلطة كول سلو')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // بيتزا


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('بيتزا')
        .collection('برجر')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('بيتزا')
        .collection('بيتزا بافلو')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('بيتزا')
        .collection('بيتزا بولو')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('بيتزا')
        .collection('بيتزا تشكين باربيكيو')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('بيتزا')
        .collection('بيتزا تشكين رانش')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('بيتزا')
        .collection('بيتزا تونة')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('بيتزا')
        .collection('بيتزا خضراوات')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('بيتزا')
        .collection('بيتزا سجق بلدى')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('بيتزا')
        .collection('بيتزا سوبريم')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('بيتزا')
        .collection('بيتزا مارجريتا')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('بيتزا')
        .collection('بيتزا ميكس تشيز')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('بيتزا')
        .collection('بيتزا ميكس لحوم')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('بيتزا')
        .collection('بيتزا هوت دوج')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('بيتزا')
        .collection('بيتزاسى فود')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('بيتزا')
        .collection('بيف برجر')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('بيتزا')
        .collection('بيف بيكون')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('بيتزا')
        .collection('تشكين برجر')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('بيتزا')
        .collection('جمبرى')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('بيتزا')
        .collection('فواكه بحر')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


   // برجر


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('برجر')
        .collection('باربيكيو')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('برجر')
        .collection('تشكين استربس')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('برجر')
        .collection('تشكين برجر')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('برجر')
        .collection('تشكين فاهيتا')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('برجر')
        .collection('تشكين كرسبى')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('برجر')
        .collection('تشكين كرسبى رول')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('برجر')
        .collection('تشيز لافا')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('برجر')
        .collection('دا بومبا')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('برجر')
        .collection('دودج بيف')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('برجر')
        .collection('فريسكو')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('برجر')
        .collection('فياجرا')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('برجر')
        .collection('ميجا سى فود')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('برجر')
        .collection('ميكس تشيز')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('برجر')
        .collection('ميكسيكان')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // باستا


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('باستا')
        .collection('اسباجتى ريد')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('باستا')
        .collection('اسباجتى وايت')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('باستا')
        .collection('الفريدو')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('باستا')
        .collection('بولونيز')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('باستا')
        .collection('تشكين كرسبى')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('باستا')
        .collection('فيسولى جمبرى')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('باستا')
        .collection('فيسولى سجق بلدى')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('باستا')
        .collection('نجرسكو')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // اضافات

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('اضافات')
        .collection('اصابع موزاريلا')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('اضافات')
        .collection('بطاطس باكين')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('اضافات')
        .collection('ثومية')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('اضافات')
        .collection('جبنة صوص')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('اضافات')
        .collection('حلقات بصل')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('اضافات')
        .collection('ستافت كراست')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('اضافات')
        .collection('فراخ كرسبى')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('اضافات')
        .collection('قطعة برجر')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('اضافات')
        .collection('مخلل')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('fresco')
        .doc('اضافات')
        .collection('مشروم')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get fresco  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


  }


  void getElsoltan ()
  {

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('مكرونات')
        .collection('باستا السلطان')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('مكرونات')
        .collection('باستا توريانو')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('مكرونات')
        .collection('باستا سى فود')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('مكرونات')
        .collection('باستا نجرسكو فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('مكرونات')
        .collection('باستا نجرسكو لحمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    // مشويات



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('مشويات')
        .collection('طرب')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('مشويات')
        .collection('طلب كفته')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('مشويات')
        .collection('فراخ مشويه على الفحم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('مشويات')
        .collection('كباب ضانى')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('مشويات')
        .collection('كباب مشكل')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('مشويات')
        .collection('كفتة على الفحم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // كشرى



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('كشرى')
        .collection('علبة كشرى السلطان')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('كشرى')
        .collection('علبة كشرى دوبل')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('كشرى')
        .collection('كشرى صاروخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // كريب

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('كريب')
        .collection('كريب بانية')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('كريب')
        .collection('كريب بطاطس')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('كريب')
        .collection('كريب جبنة')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('كريب')
        .collection('كريب سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('كريب')
        .collection('كريب شاورما فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('كريب')
        .collection('كريب شاورما لحمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('كريب')
        .collection('كريب شيش طاووق')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('كريب')
        .collection('كريب فاهيتا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('كريب')
        .collection('كريب فراخ كرسبى')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('كريب')
        .collection('كريب كفتة')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('كريب')
        .collection('كريب كوكتيل حلو')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('كريب')
        .collection('كريب كوكتيل لحوم')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // طواجن


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('طواجن')
        .collection('طاجن مكرونة عادى')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('طواجن')
        .collection('طاجن مكرونه بالفراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('طواجن')
        .collection('طاجن مكرونه بالكبدة')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('طواجن')
        .collection('طاجن مكرونه بالكفته')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('طواجن')
        .collection('طاجن مكرونه باللحمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // شرقى


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('شرقى')
        .collection('بيتزا بسطرمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('شرقى')
        .collection('بيتزا تونة')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('شرقى')
        .collection('بيتزا جبنة رومى')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('شرقى')
        .collection('بيتزا جمبرى')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('شرقى')
        .collection('بيتزا سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('شرقى')
        .collection('بيتزا سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('شرقى')
        .collection('بيتزا شاورما فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('شرقى')
        .collection('بيتزا شاورما لحمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('شرقى')
        .collection('بيتزا عشاق الجبنة')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('شرقى')
        .collection('بيتزا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('شرقى')
        .collection('بيتزا لحمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('شرقى')
        .collection('بيتزا مكس لحوم')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // شاورما


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('شاورما')
        .collection('بطاطس')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('شاورما')
        .collection('بطاطس بالجبنة')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('شاورما')
        .collection('شاورما فراخ سورى')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('شاورما')
        .collection('شاورما فراخ فرنساوى')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('شاورما')
        .collection('شاورما لحمة سورى')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('شاورما')
        .collection('شاورما لحمة فرنساوى')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('شاورما')
        .collection('فتة شاورما فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('شاورما')
        .collection('فته شاورما لحمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    // سندوتشات


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('سندوتشات')
        .collection('برجر بالبيض')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('سندوتشات')
        .collection('برجر بالجبنة')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('سندوتشات')
        .collection('برجر سادة')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('سندوتشات')
        .collection('برجر ماكس')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('سندوتشات')
        .collection('سندوتش فراخ بانيه')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('سندوتشات')
        .collection('سندوتش كفته ع الفحم')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('سندوتشات')
        .collection('سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('سندوتشات')
        .collection('شيش طاووق')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('سندوتشات')
        .collection('طبق فويل')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('سندوتشات')
        .collection('فاهيتا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('سندوتشات')
        .collection('فاهيتا لحمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    // حواوشى


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('حواوشى')
        .collection('حواوشى اسكندرى سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('حواوشى')
        .collection('حواوشى تونة اسكندرانى')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('حواوشى')
        .collection('حواوشى جبنه اسكندرانى')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('حواوشى')
        .collection('حواوشى فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('حواوشى')
        .collection('حواوشى عادى')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('حواوشى')
        .collection('حواوشى كفته ع الفحم')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('حواوشى')
        .collection('حواوشى كفته ع الفحم الاسكندرانى')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('حواوشى')
        .collection('حواوشى لحمة اسكندرانى')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    // ايطالى


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('ايطالى')
        .collection('بيتزا اسكامبس')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('ايطالى')
        .collection('بيتزا بلونيز')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('ايطالى')
        .collection('بيتزا بولو')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('ايطالى')
        .collection('بيتزا تشيكن')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('ايطالى')
        .collection('بيتزا روما')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('ايطالى')
        .collection('بيتزا سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('ايطالى')
        .collection('بيتزا سى فود')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('ايطالى')
        .collection('بيتزا فور تشيز')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('ايطالى')
        .collection('بيتزا فولجى')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('ايطالى')
        .collection('بيتزا فينيسيا')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('ايطالى')
        .collection('بيتزا مارجريتا')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('ايطالى')
        .collection('بيتزا ميكس')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('ايطالى')
        .collection('بيتزا نابولى')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // الحلو


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('الحلو')
        .collection('ارز باللبن سادة')
        .doc('detail')
        .get().then((value) {
      foodsScreen11.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('الحلو')
        .collection('ارز باللبن فرن')
        .doc('detail')
        .get().then((value) {
      foodsScreen11.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('الحلو')
        .collection('ارز باللبن فرن مشكل')
        .doc('detail')
        .get().then((value) {
      foodsScreen11.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('الحلو')
        .collection('ارز باللبن مشكل')
        .doc('detail')
        .get().then((value) {
      foodsScreen11.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('الحلو')
        .collection('ام على سادة')
        .doc('detail')
        .get().then((value) {
      foodsScreen11.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('الحلو')
        .collection('ام على مشكل')
        .doc('detail')
        .get().then((value) {
      foodsScreen11.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('الحلو')
        .collection('بطاطس فرايز')
        .doc('detail')
        .get().then((value) {
      foodsScreen11.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('الحلو')
        .collection('كريب شوكلاتة')
        .doc('detail')
        .get().then((value) {
      foodsScreen11.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    // اضافات


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('اضافات')
        .collection('اضافة جبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen12.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('اضافات')
        .collection('تقلية')
        .doc('detail')
        .get().then((value) {
      foodsScreen12.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('اضافات')
        .collection('عيش توست')
        .doc('detail')
        .get().then((value) {
      foodsScreen12.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('السلطان')
        .doc('اضافات')
        .collection('مخلل')
        .doc('detail')
        .get().then((value) {
      foodsScreen12.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get el soultan  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });




  }


  void getBatElkonafa ()
  {

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('بيت الكنافة')
        .doc('شرقى')
        .collection('بيتزا بسطرمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el konafa  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('بيت الكنافة')
        .doc('شرقى')
        .collection('بيتزا تونة قطع')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el konafa  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('بيت الكنافة')
        .doc('شرقى')
        .collection('بيتزا تونة مفتته')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el konafa  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('بيت الكنافة')
        .doc('شرقى')
        .collection('بيتزا جمبرى')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el konafa  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('بيت الكنافة')
        .doc('شرقى')
        .collection('بيتزا سجق اسكندرانى')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el konafa  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('بيت الكنافة')
        .doc('شرقى')
        .collection('بيتزا سجق بلدى')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el konafa  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('بيت الكنافة')
        .doc('شرقى')
        .collection('بيتزا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el konafa  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('بيت الكنافة')
        .doc('شرقى')
        .collection('بيتزا كفته الحاتى')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el konafa  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('بيت الكنافة')
        .doc('شرقى')
        .collection('بيتزا لحمة بلدى')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el konafa  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('بيت الكنافة')
        .doc('شرقى')
        .collection('بيتزا مشكل جبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el konafa  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    foodsScreen2 = [];
    foodsScreen3 = [];
    foodsScreen4 = [];
    foodsScreen5 = [];
    foodsScreen6 = [];
    foodsScreen7 = [];
    foodsScreen8 = [];
    foodsScreen9 = [];
    foodsScreen10 = [];
    foodsScreen11 = [];
    foodsScreen12 = [];
  }


  void getElandalos ()
  {

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('فراخ')
        .collection('فراخ كرسبى 2 قطعة')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('فراخ')
        .collection('فراخ كرسبى 4 قطعة')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('فراخ')
        .collection('فراخ كرسبى 8 قطع')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('فراخ')
        .collection('فراخ مشوية على الفحم')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // طواجن

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('طواجن')
        .collection('طاجن تونة')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('طواجن')
        .collection('طاجن سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('طواجن')
        .collection('طاجن سوبر سوبريم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('طواجن')
        .collection('طاجن فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('طواجن')
        .collection('طاجن لحمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // شرقى

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('شرقى')
        .collection('بيتزا بالجبنة')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('شرقى')
        .collection('بيتزا باللحم البلدى')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('شرقى')
        .collection('بيتزا بسطرمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('شرقى')
        .collection('بيتزا تونة قطع')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('شرقى')
        .collection('بيتزا تونة مفتتة')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('شرقى')
        .collection('بيتزا جمبرى')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('شرقى')
        .collection('بيتزا سجق اسكندرانى')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('شرقى')
        .collection('بيتزا سوبر سوبريم')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('شرقى')
        .collection('بيتزا سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('شرقى')
        .collection('بيتزا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('شرقى')
        .collection('بيتزا فواكه البحر')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('شرقى')
        .collection('بيتزا مشروم')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // ايطالى

    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('ايطالى')
        .collection('بيتزا باللحمة البلدى')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('ايطالى')
        .collection('بيتزا بسطرمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('ايطالى')
        .collection('بيتزا تونة قطع')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('ايطالى')
        .collection('بيتزا جمبرى')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('ايطالى')
        .collection('بيتزا سجق اسكندرانى')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('ايطالى')
        .collection('بيتزا سوبر سوبريم')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('ايطالى')
        .collection('بيتزا سوسيس')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('ايطالى')
        .collection('بيتزا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('ايطالى')
        .collection('بيتزا مارجريتا جبنة')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('ايطالى')
        .collection('بيتزا مشروم')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('ايطالى')
        .collection('تونة مفتتة')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // سندويشات



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('سندويشات')
        .collection('سندوتش برجر فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('سندويشات')
        .collection('سندوتش برجر فراخ و بيض + جبنة')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('سندويشات')
        .collection('سندوتش برجر لحمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('سندويشات')
        .collection('سندوتش برجر لحمة و بيض و جبنة')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('سندويشات')
        .collection('سندوتش شاورما فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('سندويشات')
        .collection('سندوتش فراخ بانية')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('سندويشات')
        .collection('سندوتش كفتة')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // حواوشى


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('حواوشى')
        .collection('حواوشى سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('حواوشى')
        .collection('حواوشى سوبر سوبريم')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('حواوشى')
        .collection('حواوشى فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('حواوشى')
        .collection('حواوشى لحمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('حواوشى')
        .collection('صاروخ سوبر سوبريم')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('حواوشى')
        .collection('صاروخ فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('حواوشى')
        .collection('صاروخ لحمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('حواوشى')
        .collection('صاورخ سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // الحلو


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('الحلو')
        .collection('فطيرة فواكة')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('الحلو')
        .collection('فطيرة بسبوسة')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('الحلو')
        .collection('فطيرة بسبوسة + قشطة + لبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('الحلو')
        .collection('فطيرة بسبوسة و كنافة مكسرات')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('الحلو')
        .collection('فطيرة سكر فقط')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('الحلو')
        .collection('فطيرة سكر و قشطة و لبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('الحلو')
        .collection('فطيرة شيكولاته نيوتيلا')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('الحلو')
        .collection('فطيرة كاستر')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });




    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('الحلو')
        .collection('فطيرة كريمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('الحلو')
        .collection('فطيرة كنافة')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('كل الفئات')
        .collection('مطعم الأندلس')
        .doc('الحلو')
        .collection('فطيرة كنافة + قشطة + لبن')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get bat el andalos  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    foodsScreen8 = [] ;
    foodsScreen9 = [] ;
    foodsScreen10 = [] ;
    foodsScreen11 = [] ;
    foodsScreen12 = [] ;

  }


  void getGosto ()
  {
    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('وجبات عائلية')
        .collection('صنية 3 افراد')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('وجبات عائلية')
        .collection('صنية 4 افراد')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('وجبات عائلية')
        .collection('صنية 6 افراد')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('وجبات عائلية')
        .collection('صنية 8 افراد')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('وجبات عائلية')
        .collection('صنية التوفير')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    // وجبات

    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('وجبات')
        .collection('وجبة جوستوم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('وجبات')
        .collection('وجبة داود باشا')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('وجبات')
        .collection('وجبة ربع فرخة')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('وجبات')
        .collection('وجبة شيش طاووق')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('وجبات')
        .collection('وجبة صدور ع الفحم')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('وجبات')
        .collection('وجبة كبده مشوية')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('وجبات')
        .collection('وجبة كفتة')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('وجبات')
        .collection('وجبة مكس')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('وجبات')
        .collection('وجبة نص فرخة')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('وجبات')
        .collection('ورقة كبده')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('وجبات')
        .collection('ورقة لحمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // مكرونات


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('مكرونات')
        .collection('ارابيات')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('مكرونات')
        .collection('الفريدو')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('مكرونات')
        .collection('بشاميل')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('مكرونات')
        .collection('شيش طاووق')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('مكرونات')
        .collection('مكرونه بالسجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('مكرونات')
        .collection('مكرونه بالكبده')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('مكرونات')
        .collection('نجرسكو')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // مشويات


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('مشويات')
        .collection('جوز حمام محشى')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('مشويات')
        .collection('شيش طاووق')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('مشويات')
        .collection('صدور ع الفحم')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('مشويات')
        .collection('طرب ضانى')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('مشويات')
        .collection('فرخه')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('مشويات')
        .collection('فرد حمام محشى')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('مشويات')
        .collection('كباب')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('مشويات')
        .collection('كفتة ضانى')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('مشويات')
        .collection('كفته كندوز')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // كريب


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('كريب')
        .collection('بطاطس')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('كريب')
        .collection('سجق بلدى')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('كريب')
        .collection('شيش طاووق')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('كريب')
        .collection('فاهيتا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('كريب')
        .collection('فاهيتا لحم')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('كريب')
        .collection('كريب بانيه')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('كريب')
        .collection('كريب زينجر')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('كريب')
        .collection('كفته ضانى')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('كريب')
        .collection('مشكل فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('كريب')
        .collection('مشكل لحوم')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('كريب')
        .collection('هوت دوج')
        .doc('detail')
        .get().then((value) {
      foodsScreen5.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // طواجن

    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('طواجن')
        .collection('طاجن باميه باللحمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('طواجن')
        .collection('طاجن بطاطس باللحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('طواجن')
        .collection('طاجن ترولى باللحمة')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('طواجن')
        .collection('طاجن فتة شاورما')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });




    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('طواجن')
        .collection('طاجن فته ساده')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('طواجن')
        .collection('طاجن فته كوارع')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('طواجن')
        .collection('طاجن فته لحم محمر')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('طواجن')
        .collection('طاجن كباب حله')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('طواجن')
        .collection('طاجن كوارع')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('طواجن')
        .collection('طاجن لحم تركى بالموتزريلا')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('طواجن')
        .collection('طاجن ملوخية باللحمه')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('طواجن')
        .collection('طاجن ملوخية ساده')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('طواجن')
        .collection('طاجن ملوخيه بالفراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('طواجن')
        .collection('ورقة كفتة')
        .doc('detail')
        .get().then((value) {
      foodsScreen6.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // سورى


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('سورى')
        .collection('بانيه')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('سورى')
        .collection('بطاطس')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('سورى')
        .collection('زنجر')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('سورى')
        .collection('سجق')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('سورى')
        .collection('شيش')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('سورى')
        .collection('فاهيتا فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('سورى')
        .collection('فاهيتا لحم')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('سورى')
        .collection('كفته')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('سورى')
        .collection('هوت دوج')
        .doc('detail')
        .get().then((value) {
      foodsScreen7.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // سندوتشات

    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('سندوتشات')
        .collection('رغيف حواوشى')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('سندوتشات')
        .collection('رغيف حواوشى موتزريلا')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('سندوتشات')
        .collection('رغيف طرب')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('سندوتشات')
        .collection('رغيف كفته')
        .doc('detail')
        .get().then((value) {
      foodsScreen8.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // سلاطات


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('سلاطات')
        .collection('بابا غنوج')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('سلاطات')
        .collection('ثومية')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('سلاطات')
        .collection('سلطه حضراء')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('سلاطات')
        .collection('طحينه')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('سلاطات')
        .collection('كلو سلو')
        .doc('detail')
        .get().then((value) {
      foodsScreen9.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // اضافات


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('اضافات')
        .collection('أرز ابيض')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('اضافات')
        .collection('أرز بسمتى ساده')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('اضافات')
        .collection('باكيت بطاطس')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('اضافات')
        .collection('بطاطس صوص شيدر')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('اضافات')
        .collection('ريزو جوستوم')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('اضافات')
        .collection('شوربة عدس')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('اضافات')
        .collection('شوربة لسان عصفور')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('اضافات')
        .collection('شوربه كريمه بالفراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('اضافات')
        .collection('شوربه كوارع')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('اضافات')
        .collection('وجبة ممبار')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('شبين')
        .doc('مشويات')
        .collection('مطعم جوستو')
        .doc('اضافات')
        .collection('ورق عنب')
        .doc('detail')
        .get().then((value) {
      foodsScreen10.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    foodsScreen11 = [];
    foodsScreen12 = [];


  }


  void getMashweatHamza ()
  {
    FirebaseFirestore.instance.collection('طحا')
        .doc('Restaurant')
        .collection('مشويات حمزه')
        .doc('وجبات')
        .collection('وجبة ربع فرخه')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('طحا')
        .doc('Restaurant')
        .collection('مشويات حمزه')
        .doc('وجبات')
        .collection('وجبة ربع كفته')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('طحا')
        .doc('Restaurant')
        .collection('مشويات حمزه')
        .doc('وجبات')
        .collection('وجبة مكس فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('طحا')
        .doc('Restaurant')
        .collection('مشويات حمزه')
        .doc('وجبات')
        .collection('وجبة مكس فراخ دوبل')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('طحا')
        .doc('Restaurant')
        .collection('مشويات حمزه')
        .doc('وجبات')
        .collection('وجبة نص فراخ')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('طحا')
        .doc('Restaurant')
        .collection('مشويات حمزه')
        .doc('وجبات')
        .collection('وجبة نص فراخ + ربع كفته')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('طحا')
        .doc('Restaurant')
        .collection('مشويات حمزه')
        .doc('وجبات')
        .collection('وجبة نص كفته')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('طحا')
        .doc('Restaurant')
        .collection('مشويات حمزه')
        .doc('وجبات')
        .collection('وجبه مكس حمزة')
        .doc('detail')
        .get().then((value) {
      foodsScreen1.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // مشويات


    FirebaseFirestore.instance.collection('طحا')
        .doc('Restaurant')
        .collection('مشويات حمزه')
        .doc('مشويات')
        .collection('ريش ضانى')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('طحا')
        .doc('Restaurant')
        .collection('مشويات حمزه')
        .doc('مشويات')
        .collection('طرب')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('طحا')
        .doc('Restaurant')
        .collection('مشويات حمزه')
        .doc('مشويات')
        .collection('فرخه شبكه')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('طحا')
        .doc('Restaurant')
        .collection('مشويات حمزه')
        .doc('مشويات')
        .collection('فرخه شيش')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });



    FirebaseFirestore.instance.collection('طحا')
        .doc('Restaurant')
        .collection('مشويات حمزه')
        .doc('مشويات')
        .collection('كباب بتلو')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('طحا')
        .doc('Restaurant')
        .collection('مشويات حمزه')
        .doc('مشويات')
        .collection('كباب ضانى')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('طحا')
        .doc('Restaurant')
        .collection('مشويات حمزه')
        .doc('مشويات')
        .collection('كفته ضانى')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    FirebaseFirestore.instance.collection('طحا')
        .doc('Restaurant')
        .collection('مشويات حمزه')
        .doc('مشويات')
        .collection('كفته كندوز')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('طحا')
        .doc('Restaurant')
        .collection('مشويات حمزه')
        .doc('مشويات')
        .collection('مشكل')
        .doc('detail')
        .get().then((value) {
      foodsScreen2.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // سندوتشات

    FirebaseFirestore.instance.collection('طحا')
        .doc('Restaurant')
        .collection('مشويات حمزه')
        .doc('سندوتشات')
        .collection('سندوتش كفته ضانى')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('طحا')
        .doc('Restaurant')
        .collection('مشويات حمزه')
        .doc('سندوتشات')
        .collection('سندوتش كفته كندوز')
        .doc('detail')
        .get().then((value) {
      foodsScreen3.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });


    // حواوشى

    FirebaseFirestore.instance.collection('طحا')
        .doc('Restaurant')
        .collection('مشويات حمزه')
        .doc('حواوشى')
        .collection('حواوشى عادى')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    FirebaseFirestore.instance.collection('طحا')
        .doc('Restaurant')
        .collection('مشويات حمزه')
        .doc('حواوشى')
        .collection('حواوشى مخصوص')
        .doc('detail')
        .get().then((value) {
      foodsScreen4.add(ItemModel.fromFire(value.data()!));
      emit(AppGetMenusSuccessState());
    }).catchError((error){
      print('error when get gosto  : ${error.toString()}');
      emit(AppGetMenusErrorState());
    });

    foodsScreen5 = [];
    foodsScreen6 = [];
    foodsScreen7 = [];
    foodsScreen8 = [];
    foodsScreen9 = [];
    foodsScreen10 = [];
    foodsScreen11 = [];
    foodsScreen12 = [];

  }


  // void sendOrder ()
  // {
  //   // FirebaseFirestore.instance.collection('orders').
  // }
  //
  // void createInfo({
  //   required String name,
  //   required String number,
  //   required String address,
  // }){
  //
  //   AdminModel model= AdminModel(
  //     name:name,
  //     number: number,
  //     address: address,
  //   );
  //
  //   FirebaseFirestore.instance
  //       .collection('Info')
  //       .doc('uids')
  //       .set(model.toMap())
  //       .then((value) {
  //       emit(AppCreateInfoSuccessState());
  //   }).catchError((error){
  //     print('no done');
  //
  //     emit(AppCreateInfoErrorState());
  //
  //   });
  //
  // }
  //
  //
  // AdminModel? adminModel;
  //
  // void getInf(context){
  //
  //   FirebaseFirestore.instance.collection('Info')
  //       .doc('uids')
  //       .get()
  //       .then((value) {
  //         print(value);
  //         adminModel=AdminModel.fromFire(value.data()!);
  //         navigateTo(context: context, widget: adminScreen());
  //         emit(AppGetInfoSuccessState());
  //   }).catchError((error){
  //     emit(AppGetInfoErrorState());
  //
  //   });
  //
  // }


  var num=-1;

  void createOrder({
    required AdminModel userData,
    required List <Map> orderData,
  }){

    // UploadOrder model = UploadOrder(
    //   userData: userData,
    //   orderData: orderData,
    // );

    uIdDoc='${++num}';
    print('num =$num');
    print('uId'+uIdDoc);
    FirebaseFirestore.instance
        .collection('orders')
        .doc(uIdDoc)
        .set({'userData': userData.toMap(), 'orderData': orderData,'uid': uIdDoc})
        .then((value) {
      userOrders = [];
      print('Order Created Successful');
      emit(AppCreateOrderSuccessState());
    }).catchError((error){
      print('no done : ${error.toString()}');
      emit(AppCreateOrderErrorState());

    });


  }

  int num2=-1;

  void deleteOrder(
      int ?index,
      ){
    //
    // uIdDoc= '$index';

    uIdDoc='${++num2}';
    if(index! > num2)
      {
        num2=index!;
        uIdDoc='$num2';
        num2=-1;
      }

    print('num2 = $num2');
    print('uIdDoc = $uIdDoc');
    FirebaseFirestore.instance
        .collection('orders')
        .doc(uIdDoc).delete().whenComplete(() => getOrder());
    emit(AppDeleteOrderState());
  }


  UploadOrder? orderModel;

  List<UploadOrder> items=[];

  void getOrder(){
        items=[];
    FirebaseFirestore.instance.collection('orders')
          .snapshots()
        .listen((event) {
           event.docs.forEach((element) {
             print(element.data());
             items.add(UploadOrder.fromFire(element.data()));
          });
          emit(AppGetOrderSuccessState());
         });
  }

  Future<void> clearData({
       int ?index,
    }) async {

    uIdDoc='$index';

    var collection = FirebaseFirestore.instance.collection('orders');
    var snapshots = await collection.get();
    // for (var doc in snapshots.docs) {
    //   await doc.reference.delete();
    // }

    // items.clear();
    final fb= FirebaseFirestore.instance.collection('orders').doc(uIdDoc);
    fb.delete().whenComplete(() {
      print('done');

    });

    emit(AppDeleteOrderState());

  }

  void changeItemColor(index,List<Color> cardColor){

    cardColor[index]= cardColor[index]==Color.fromRGBO(58, 86, 156,1)?Colors.greenAccent:Color.fromRGBO(58, 86, 156,1);
    emit(AppChangeItemColorState());
  }

  void saveIsDone(
      List <String> isSelected,
      index,
      List<Color> cardColor

      ){

    isSelected[index]='1';
    CacheHelper.saveBool(key: 'isDone',value: isSelected );
    isSelected[index]=='1'?cardColor[index]=Colors.greenAccent:cardColor[index]=Color.fromRGBO(58, 86, 156,1);
    emit(SaveDate());

  }


  CategoryModel ?categoryModel ;
  int marketNum=-1;


  void createMarketOrder(
      {
        required String name,
        required String number,
        required String address,
        required String order,
      }
      ){

    categoryModel = CategoryModel(
      name: name,
      number: number,
      address: address,
      order: order,
    );

    uIdDoc='${++marketNum}';
    FirebaseFirestore.instance.collection('marketorders')
        .doc(uIdDoc)
        .set(categoryModel!.toMap()).
    then((value) {

      emit(AppCreateMarketSuccessState());

    }).catchError((error){
      print(error);
      emit(AppCreateMarketErrorState());

    });

  }


  List <CategoryModel> marketList=[];

  void getMarketOrder(){
    marketList=[];
    FirebaseFirestore.instance.collection('marketorders')
        .snapshots().listen((event) {
      event.docs.forEach((element) {
        print(element.data());
        marketList.add(CategoryModel.fromFire(element.data()));
        emit(AppGetMarketSuccessState());

      });
    });


  }

  int marketNum2=-1;

  void deleteMarketOrder(
      int ?index,
      ){
    //
    // uIdDoc= '$index';

    uIdDoc='${++marketNum2}';
    if(index! > marketNum2)
    {
      marketNum2=index!;
      uIdDoc='$marketNum2';
      marketNum2=-1;
    }

    print('marketNum2 = $marketNum2');
    print('uIdDoc = $uIdDoc');
    FirebaseFirestore.instance
        .collection('marketorders')
        .doc(uIdDoc).delete().whenComplete(() => getOrder());
    emit(AppDeleteOrderState());
  }




  int pharmacyNum=-1;

  void createPharmacyOrder(
      {
        required String name,
        required String number,
        required String address,
        required String order,
      }
      ){

    categoryModel =CategoryModel(
      name: name,
      number: number,
      address: address,
      order: order,
    );
    uIdDoc='${++pharmacyNum}';

    FirebaseFirestore.instance.collection('pharmacyorders')
        .doc(uIdDoc)
        .set(categoryModel!.toMap()).
    then((value) {

      emit(AppCreatePharmacySuccessState());


    }).catchError((error){

      print(error);
      emit(AppCreatePharmacyErrorState());


    });

  }


  List <CategoryModel> pharmacyList=[];

  void getPharmacyOrder(){
    pharmacyList=[];
    FirebaseFirestore.instance.collection('pharmacyorders')
        .snapshots().listen((event) {
      event.docs.forEach((element) {
        print(element.data());
        pharmacyList.add(CategoryModel.fromFire(element.data()));
        emit(AppGetPharmacySuccessState());

      });
    });


  }

  int pharmacyNum2=-1;

  void deletePharmacyOrder(
      int ?index,
      ){
    //
    // uIdDoc= '$index';

    uIdDoc='${++pharmacyNum2}';
    if(index! > pharmacyNum2)
    {
      pharmacyNum2=index!;
      uIdDoc='$pharmacyNum2';
      pharmacyNum2=-1;
    }

    print('pharmacyNum2 = $pharmacyNum2');
    print('uIdDoc = $uIdDoc');
    FirebaseFirestore.instance
        .collection('pharmacyorders')
        .doc(uIdDoc).delete().whenComplete(() => getOrder());
    emit(AppDeleteOrderState());
  }


  int shoppingNum=-1;

  void createShoppingOrder(
      {
        required String name,
        required String number,
        required String address,
        required String order,
      }
      ){

    categoryModel =CategoryModel(
      name: name,
      number: number,
      address: address,
      order: order,
    );

    uIdDoc='${++shoppingNum}';

    FirebaseFirestore.instance.collection('shoppingorders')
        .doc(uIdDoc)
        .set(categoryModel!.toMap()).
    then((value) {
      emit(AppCreateShoppingSuccessState());

    }).catchError((error){
      print(error);
      emit(AppCreateMarketErrorState());

    });

  }


  List <CategoryModel> shoppingList=[];

  void getShoppingOrder(){
    shoppingList=[];
    FirebaseFirestore.instance.collection('shoppingorders')
        .snapshots().listen((event) {
      event.docs.forEach((element) {
        print(element.data());
        shoppingList.add(CategoryModel.fromFire(element.data()));
        emit(AppGetShoppingSuccessState());

      });
    });
  }


  int shoppingNum2=-1;

  void deleteShoppingOrder(
      int ?index,
      ){
    //
    // uIdDoc= '$index';

    uIdDoc='${++shoppingNum2}';
    if(index! > shoppingNum2)
    {
      shoppingNum2=index!;
      uIdDoc='$shoppingNum2';
      shoppingNum2=-1;
    }

    print('shoppingNum2 = $shoppingNum2');
    print('uIdDoc = $uIdDoc');
    FirebaseFirestore.instance
        .collection('shoppingorders')
        .doc(uIdDoc).delete().whenComplete(() => getOrder());
    emit(AppDeleteOrderState());
  }


  int nothereNum=-1;

  void createNoThereOrder(
      {
        required String name,
        required String number,
        required String address,
        required String order,
      }
      ){

    categoryModel =CategoryModel(
      name: name,
      number: number,
      address: address,
      order: order,
    );

    uIdDoc='${++nothereNum}';

    FirebaseFirestore.instance.collection('nothereorders')
        .doc(uIdDoc)
        .set(categoryModel!.toMap()).
    then((value) {
      emit(AppCreateNoThereSuccessState());

    }).catchError((error){
      print(error);
      emit(AppCreateNoThereErrorState());

    });

  }


  List <CategoryModel> nothereList=[];

  void getNoThereOrder(){
    nothereList=[];
    FirebaseFirestore.instance.collection('nothereorders')
        .snapshots().listen((event) {
      event.docs.forEach((element) {
        print(element.data());
        nothereList.add(CategoryModel.fromFire(element.data()));
        emit(AppGetNoThereSuccessState());

      });
    });
  }


  int nothereNum2=-1;

  void deleteNoTheregOrder(
      int ?index,
      ){
    //
    // uIdDoc= '$index';

    uIdDoc='${++nothereNum2}';
    if(index! > nothereNum2)
    {
      nothereNum2=index!;
      uIdDoc='$nothereNum2';
      nothereNum2=-1;
    }

    print('nothereNum2 = $nothereNum2');
    print('uIdDoc = $uIdDoc');
    FirebaseFirestore.instance
        .collection('nothereorders')
        .doc(uIdDoc).delete().whenComplete(() => getOrder());
    emit(AppDeleteOrderState());
  }

  DriveModel ?driveModel;

  int driveNum=-1;

  void createDriveOrder(
      {
        required String name,
        required String number,
        required String address,
        required String order,
        required String from,
        required String to,

      }
      ){

    driveModel =DriveModel(
      name: name,
      number: number,
      address: address,
      order: order,
      from: from,
      to: to
    );

    uIdDoc='${++driveNum}';

    FirebaseFirestore.instance.collection('driveorders')
        .doc(uIdDoc)
        .set(driveModel!.toMap()).
    then((value) {
      emit(AppCreateDriveSuccessState());

    }).catchError((error){
      print(error);
      emit(AppCreateDriveErrorState());

    });

  }


  List <DriveModel> driveList=[];

  void getDriveOrder(){
    driveList=[];
    FirebaseFirestore.instance.collection('driveorders')
        .snapshots().listen((event) {
      event.docs.forEach((element) {
        print(element.data());
        driveList.add(DriveModel.fromFire(element.data()));
        emit(AppGetDriveSuccessState());

      });
    });
  }


  int driveNum2=-1;

  void deleteDriveOrder(
      int ?index,
      ){
    //
    // uIdDoc= '$index';

    uIdDoc='${++driveNum2}';
    if(index! > driveNum2)
    {
      driveNum2=index!;
      uIdDoc='$driveNum2';
      driveNum2=-1;
    }

    print('driveNum2 = $driveNum2');
    print('uIdDoc = $uIdDoc');
    FirebaseFirestore.instance
        .collection('driveorders')
        .doc(uIdDoc).delete().whenComplete(() => getOrder());
    emit(AppDeleteOrderState());
  }


  bool valueVisible=true;

  void switchVisible(){

    valueVisible=!valueVisible;
    emit(AppSwichValueVisibleState());
  }

}




