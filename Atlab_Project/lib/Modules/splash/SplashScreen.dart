import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talabatak/Componants/componant.dart';
import 'package:talabatak/Componants/constants.dart';
import 'package:talabatak/Modules/LoginScreen/login_screen.dart';
import 'package:talabatak/Modules/OnBoarding/on_boarding.dart';
import 'package:talabatak/Modules/StartScreen/StartScreen.dart';
import 'package:talabatak/Modules/home_page/HomePageScreen.dart';
import 'package:talabatak/SharedPreference/CacheHelper.dart';
import 'package:lottie/lottie.dart';



class MainSplashScreen extends StatefulWidget {


  @override
  _MainSplashScreenState createState() => _MainSplashScreenState();
}

class _MainSplashScreenState extends State<MainSplashScreen> {

  var height=200;
  var width=200;
  bool isBoarding=false;

  // Set Time Of Splash Screen
    @override
    void initState(){
      Widget screen = LoginScreen();

      isBoarding=CacheHelper.getBoolen(key: 'Boarding') ?? false;
      if(isBoarding==false){
         screen=OnBoarding();
      }
      else  {
        screen=screen2;
      }
          Future.delayed(Duration(seconds: 5),(){
        navigateAndRemove(context: context, widget: screen);
      });
      super.initState();
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          elevation: 0.0,
        backgroundColor: Color.fromRGBO(58, 86, 156,1),
          backwardsCompatibility: false,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Color.fromRGBO(58, 86, 156,1),
            statusBarIconBrightness: Brightness.light,
          ),
      ),
      body:Container(
           width: double.infinity,
           color: Color.fromRGBO(58, 86, 156,1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height*.018,),

              SizedBox(height: MediaQuery.of(context).size.height*.25,),

              Lottie.asset('assets/images/bike.json',
              height: 170
              ),
              SizedBox(height: MediaQuery.of(context).size.height*.07,),
              // Text('اطلب',
              //   style: TextStyle(
              //       fontSize: 22,
              //       fontFamily: 'Lemonada',
              //       fontWeight: FontWeight.bold,
              //       color: Colors.white
              //
              //   ),),
              // Text('مع اطلب أسرع و افضل خدمه توصيل طلبات لمنازل ',
              //     style: TextStyle(
              //       fontSize: 17,
              //       fontFamily: 'Lemonada',
              //       fontWeight: FontWeight.bold,
              //       color: Colors.white
              //   ),
              //     textAlign: TextAlign.center,
              //   ),
              // SizedBox(height: MediaQuery.of(context).size.height*.13,),
              // Text('',
              //   style: TextStyle(
              //     fontSize: 13,
              //     fontFamily: 'Lemonada',
              //     fontWeight: FontWeight.bold,
              //     color: Colors.white
              //
              //
              //   ),
              //   textAlign: TextAlign.center,
              // ),
            ],
          )
        ),
    );
  }
}
