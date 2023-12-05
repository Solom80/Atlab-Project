import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talabatak/Componants/componant.dart';
import 'package:talabatak/Componants/constants.dart';
import 'package:talabatak/Modules/DrawerZoom/zoom_drawer.dart';
import 'package:talabatak/Modules/LoginScreen/login_screen.dart';
import 'package:talabatak/Modules/WorkerScreen/workerScreen.dart';
import 'package:talabatak/Modules/antherOrder/AntherOrder.dart';
import 'package:talabatak/Modules/antherOrder/DriveOrder.dart';
import 'package:talabatak/Modules/home_page/HomePageScreen.dart';
import 'package:talabatak/talabatak_bloc/cubit.dart';
import 'package:talabatak/talabatak_bloc/states.dart';

class StartScreen extends StatelessWidget {

  List <String> imagesCategory=[
    'https://media-cdn.tripadvisor.com/media/photo-s/18/20/62/8d/papy-s-fast-food.jpg',
    'https://image.freepik.com/free-vector/shop-cart-shop-building-cartoon_138676-2085.jpg',
    'https://image.freepik.com/free-psd/medical-capsules-mock-up-top-view_23-2148478002.jpg',
    'https://image.freepik.com/free-vector/vegetables-fruits-market-eggplant-peppers-onions-potatoes-healthy-tomato-banana-apple-pear-pumpkin-vector-illustration_1284-46286.jpg',
    'https://matrixclouds.com/uploads/blog/1604394498.png',
    'https://image.freepik.com/free-vector/set-modern-workers-repairing-house_1262-19340.jpg',
    'https://image.freepik.com/free-vector/design-inspiration-concept-illustration_114360-3992.jpg',


  ];
  List <String> titleCategory=[
    'مطاعم',
    'سوبر ماركت',
    'صيدليات',
    'طلبات سوق',
    'توصيل طلبات',
    'صنايعيه',
    'طلب اخر'
  ];
  @override
  Widget build(BuildContext context) {
    List <Function> functionCategory=[
          (){
        valueOfOrder='5';
        navigateAndRemove(context: context, widget: ContainerScreen());
      },
          (){
        navigateAndRemove(context: context, widget: AntherOrder(imageCategory: 'https://image.freepik.com/free-vector/shop-cart-shop-building-cartoon_138676-2085.jpg',titleCategory: 'سوبر ماركت',));
      },
          (){
        navigateAndRemove(context: context, widget:AntherOrder(imageCategory: 'https://image.freepik.com/free-psd/medical-capsules-mock-up-top-view_23-2148478002.jpg',titleCategory: 'صيدليات',));
      },
          (){
        navigateAndRemove(context: context, widget: AntherOrder(imageCategory: 'https://image.freepik.com/free-vector/vegetables-fruits-market-eggplant-peppers-onions-potatoes-healthy-tomato-banana-apple-pear-pumpkin-vector-illustration_1284-46286.jpg',titleCategory: 'طلبات سوق',));
      },
          (){
            valueOfOrder='6';
            navigateAndRemove(context: context, widget: DriveOrder(imageCategory: 'https://matrixclouds.com/uploads/blog/1604394498.png',titleCategory: 'توصيل طلبات',));
      },
          (){
            navigateTo(context: context, widget: WorkerScreen());
          },
          (){
        navigateAndRemove(context: context, widget: AntherOrder(imageCategory: 'https://img.freepik.com/free-vector/thinking-face-emoji_1319-430.jpg',titleCategory: 'طلب اخر',));
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
              toolbarHeight: 150,
              title:Container(
                alignment: Alignment.center,
                color: Color.fromRGBO(58, 86, 156,1),
                child: Stack(
                  children: [
                    Column(
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
                        SizedBox(height: MediaQuery.of(context).size.height*.007,),
                        Text('اسرع و افضل دليفري مع',textAlign: TextAlign.center
                          ,style: GoogleFonts.cookie(
                                fontSize: 27,
                                fontWeight: FontWeight.bold,
                                color:  Colors.white,
                            )),
                        Text('اطلب',textAlign: TextAlign.center
                          ,style: GoogleFonts.lato(
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                              color:  Colors.white,
                            )),

                      ],
                    ),
                  ],
                ),
              ),
              backgroundColor:  Color.fromRGBO(58, 86, 156,1),
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
                      children: List.generate(imagesCategory.length, (index) => orderBlock(imagesCategory[index],titleCategory[index],functionCategory[index])),
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
