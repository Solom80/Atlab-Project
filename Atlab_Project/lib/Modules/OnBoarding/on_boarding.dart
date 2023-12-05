
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:talabatak/Componants/componant.dart';
import 'package:talabatak/Componants/constants.dart';
import 'package:talabatak/Modules/LoginScreen/login_screen.dart';
import 'package:talabatak/Modules/StartScreen/StartScreen.dart';
import 'package:talabatak/SharedPreference/CacheHelper.dart';

 class Items{

   String ?image;
   String ?title;
   String ?content;

   Items({
      this.image,
      this.title,
      this.content,
   });

 }

class OnBoarding extends StatefulWidget {

  @override
  State<OnBoarding> createState() => _OnBoardingState();
}

class _OnBoardingState extends State<OnBoarding> {
  List<Items> onBoardingItems=[

    Items(
        image:'https://assets6.lottiefiles.com/packages/lf20_6sxyjyjj.json',
        title: 'الافضل',
         content: 'افضل و اسرع خدمه توصيل طلبات لمنازل'
    ),

    Items(
        image:'https://assets5.lottiefiles.com/packages/lf20_b1koyd9m.json',
        title: 'الامن',
        content: 'امن طريقه لتوصيل الطلبات لمنازل مع الالتزام بكافه الاجراءت الوقايه لضمان سلامه العملاء'
    ),

    Items(
        image:'https://assets9.lottiefiles.com/packages/lf20_3ls8a1y5.json',
        title: 'الخدمه',
        content: 'خدمه علي مدار 24 ساعه لتوصيل الطلبات المنازل'
    ),
  ];

  PageController boardController= PageController();

  bool isLast=false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          children: [

            SizedBox(height: 120,),
            Expanded(
              child: PageView.builder(
                onPageChanged: (index){
                  if(index==onBoardingItems.length-1){
                    isLast=true;
                  }
                  else{
                    isLast=false;
                  }
                },
                  physics: BouncingScrollPhysics(),
                  itemBuilder: (context,index){
                    return blockOnboarding(onBoardingItems[index]);
                  },
                  itemCount: 3,
                  controller: boardController,

              ),
            ),

            SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
              child: Row(
                children: [
                  TextButton(
                      onPressed: (){
                         navigateAndRemove(context: context, widget: LoginScreen());
                      },
                      child: Text(
                        'تخطي',style: TextStyle(
                        color: Colors.grey,
                          fontSize: 17,
                          fontWeight: FontWeight.bold
                      ),
                  )
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width*.23,),
                  SmoothPageIndicator(
                    controller: boardController,
                    count: onBoardingItems.length,
                    effect: JumpingDotEffect(
                      dotWidth: 10,
                      dotHeight: 10,
                      spacing: 7,
                      activeDotColor: Colors.blue,
                      dotColor: Colors.grey,
                      jumpScale: 3,
                    ),
                  ),
                  Spacer(),
                  TextButton(
                      onPressed: (){
                         setState(() {
                           if(isLast==true){
                             CacheHelper.saveBoolen(key: 'Boarding', value: isLast).
                             then((value) {
                               // navigateAndRemove(context: context, widget: LoginScreen());
                               uId = CacheHelper.getData(key: 'uId') ?? '';
                               if (uId.isNotEmpty) {
                                 screen2 = StartScreen();
                                 navigateAndRemove(context: context, widget: StartScreen());

                               } else {
                                 screen2 = LoginScreen();
                                 navigateAndRemove(context: context, widget: LoginScreen());
                               }
                             });
                           }
                           else{
                             boardController.nextPage(
                               duration: Duration(
                                   milliseconds: 700
                               ),
                               curve: Curves.fastLinearToSlowEaseIn,
                             );
                           }
                         });
                      },
                      child: Text(
                        'التالي',style: TextStyle(
                          color: Color.fromRGBO(58, 86, 156,1),
                          fontSize: 17,
                          fontWeight: FontWeight.bold
                      ),
                      )
                  ),

                ],
              ),
            ),


          ],
        ),
      ),

    );
  }
}

Widget blockOnboarding(Items model){
   return Container(
     child: Column(
       children: [
         Container(
           height: 280,
           child: Lottie.network('${model.image}')
         ),
         SizedBox(height: 60,),
         Text('${model.title}',
           style: TextStyle(
             color: Color.fromRGBO(58, 86, 156,1),
             fontSize: 19,
             fontWeight: FontWeight.bold,
             fontFamily: 'Lemonada',

           ),),
         SizedBox(height: 25,),
         Text('${model.content}',
           style: TextStyle(
             color: Colors.black,
             fontSize: 17,
           ),
           textAlign: TextAlign.center,
         ),
       ],
     ),
   );
}
