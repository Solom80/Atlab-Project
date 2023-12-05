import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:talabatak/Componants/componant.dart';
import 'package:talabatak/Componants/constants.dart';
import 'package:talabatak/Modules/DrawerZoom/zoom_drawer.dart';
import 'package:url_launcher/url_launcher.dart';

class DoneOrder extends StatefulWidget {
  const DoneOrder({Key? key}) : super(key: key);

  @override
  _DoneOrderState createState() => _DoneOrderState();
}

class _DoneOrderState extends State<DoneOrder> {


  // Set Time Of Splash Screen
  @override
  void initState(){

    Future.delayed(Duration(seconds: 1),(){
      void launchWhatsapp(
          String ?number,
          String ?message,
          )async{

        String url= "whatsapp://send?phone=$number&text=$message";

        await canLaunch(url) ? launch(url) : print('Can\'t open whatsapp');


      }
      if(valueOfOrder=='1')
      {
        launchWhatsapp("+201277556432", "شكرا لختيارك اطلب (سوبر ماركت) ,اضغط ارسال لاتمام الطلب");

      }
      else if(valueOfOrder=='2')
      {
        launchWhatsapp("+201277556432", "شكرا لختيارك اطلب (صيدليات) ,اضغط ارسال لاتمام الطلب");

      }
      else if(valueOfOrder=='3')
      {
        launchWhatsapp("+201277556432", "شكرا لختيارك اطلب (طلبات سوق) ,اضغط ارسال لاتمام الطلب");

      }
      else if(valueOfOrder=='4')
      {
        launchWhatsapp("+201277556432", "شكرا لختيارك اطلب (طلب اخر) ,اضغط ارسال لاتمام الطلب");

      }
      else if(valueOfOrder=='5')
      {
        launchWhatsapp("+201277556432", "شكرا لختيارك اطلب (مطاعم) ,اضغط ارسال لاتمام الطلب");

      }
      else if(valueOfOrder=='6')
      {
        launchWhatsapp("+201277556432", "شكرا لختيارك اطلب (توصيل طلبات) ,اضغط ارسال لاتمام الطلب");

      }
      // navigateAndRemove(context: context, widget: screen);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:Color.fromRGBO(58, 86, 156,1),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: (){
            navigateTo(context: context, widget: ContainerScreen());
          },
        ),
        backgroundColor:Color.fromRGBO(58, 86, 156,1),
        backwardsCompatibility: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor:Color.fromRGBO(58, 86, 156,1),
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: Container(
        width: double.infinity,
        alignment: Alignment.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            SizedBox(height: 80,),
             Lottie.asset('assets/images/done.json',
             height: 310
             ),

          ],
        )
      ),
    );
  }
}
