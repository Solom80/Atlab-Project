import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talabatak/Componants/componant.dart';
import 'package:talabatak/Componants/constants.dart';
import 'package:talabatak/Modules/AdminScreen/adminScreen.dart';
import 'package:talabatak/Modules/CategoryOrders/AditionalOrders.dart';
import 'package:talabatak/Modules/CategoryOrders/ShowDriveOrders.dart';
import 'package:talabatak/Modules/LoginScreen/login_screen.dart';
import 'package:talabatak/Modules/ShowOrders/ShowOrders.dart';
import 'package:talabatak/Modules/antherOrder/AntherOrder.dart';
import 'package:talabatak/Modules/home_page/HomePageScreen.dart';
import 'package:talabatak/talabatak_bloc/cubit.dart';
import 'package:talabatak/talabatak_bloc/states.dart';

class ItemsAdminScreen extends StatelessWidget {

  List <String> imagesCategory=[
    'https://media-cdn.tripadvisor.com/media/photo-s/18/20/62/8d/papy-s-fast-food.jpg',
    'https://image.freepik.com/free-vector/shop-cart-shop-building-cartoon_138676-2085.jpg',
    'https://image.freepik.com/free-psd/medical-capsules-mock-up-top-view_23-2148478002.jpg',
    'https://image.freepik.com/free-vector/vegetables-fruits-market-eggplant-peppers-onions-potatoes-healthy-tomato-banana-apple-pear-pumpkin-vector-illustration_1284-46286.jpg',
    'https://matrixclouds.com/uploads/blog/1604394498.png',
    'https://image.freepik.com/free-vector/design-inspiration-concept-illustration_114360-3992.jpg'


  ];
  List <String> titleCategory=[
    'مطاعم',
    'سوبر ماركت',
    'صيدليات',
    'طلبات سوق',
    'توصيل طلبات',
    'طلب اخر'

  ];
  @override
  Widget build(BuildContext context) {
    List <Function> functionCategory=[
          (){
        navigateAndRemove(context: context, widget: adminScreen());
      },
          (){
        valueOfShowOrder='1';
        AppCubit.get(context).getMarketOrder();
        navigateAndRemove(context: context, widget:AditionalOrder());
      },
          (){
            valueOfShowOrder='2';
            AppCubit.get(context).getPharmacyOrder();
            navigateAndRemove(context: context, widget: AditionalOrder());
      },
          (){
            valueOfShowOrder='3';
            AppCubit.get(context).getShoppingOrder();
            navigateAndRemove(context: context, widget: AditionalOrder());      },
          (){
            AppCubit.get(context).getDriveOrder();
            navigateAndRemove(context: context, widget: ShowDriveOrder());      },
          (){
            valueOfShowOrder='4';
            AppCubit.get(context).getNoThereOrder();
            navigateAndRemove(context: context, widget: AditionalOrder());
      },
    ];
    return BlocConsumer<AppCubit,AppStates>(
      listener: (context,state){

      },
      builder: (context,state){
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: Colors.grey[100],
            appBar: AppBar(
              titleSpacing: 0.0,
              toolbarHeight: 130,
              title:  Container(
                alignment: Alignment.center,
                color: Color.fromRGBO(58, 86, 156,1),
                child: Column(
                  children: [
                    SizedBox(height: 10,),
                    Container(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        color: Colors.white,
                        onPressed: (){
                          navigateAndRemove(context: context, widget: LoginScreen());
                        },

                        icon: Icon(
                          Icons.logout
                        ),

                      ),
                    ),
                    SizedBox(height: 0,),
                    Text('أسرع و أفضل دليفري مع',textAlign: TextAlign.center
                      ,style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),),
                    Text('اطلب ',textAlign: TextAlign.center
                      ,style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color:  Colors.white,
                      ),),
                  ],
                ),
              ),
              backgroundColor: Colors.white,
              backwardsCompatibility: false,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Color.fromRGBO(58, 86, 156,1),
                statusBarIconBrightness: Brightness.light,
              ),
            ),
            body: Container(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Container(
                    color:  Color.fromRGBO(58, 86, 156,1),
                    height: MediaQuery.of(context).size.height*.05,
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height*.05,
                  ),
                  Expanded(
                    child: GridView.count(

                      physics: BouncingScrollPhysics(),
                      mainAxisSpacing: 0,
                      crossAxisSpacing: 0,
                      childAspectRatio: 1/1.3,
                      crossAxisCount: 2,
                      children: List.generate(6, (index) => orderBlock(imagesCategory[index],titleCategory[index],functionCategory[index])),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


Widget orderBlock( String images, String titles,Function function){
  return InkWell(
    onTap: (){
      function();
    },
    child: Container(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: EdgeInsets.fromLTRB(7, 0, 7, 0),
      child: Column(
        children: [
          Container(
            width: 200,
            height: 200,
            child: Material(
              borderRadius: BorderRadius.circular(15),
              elevation: 10.0,
              child: Column(
                children: [
                  Container(
                    height: 130,
                    width: double.infinity,
                    child: Image(
                        fit: BoxFit.cover,
                        image: NetworkImage(images)
                    ),
                  ),
                  SizedBox(height: 17,),
                  Text(titles,style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),),

                ],
              ),
            ),
          )
        ],
      ),


    ),
  );
}
