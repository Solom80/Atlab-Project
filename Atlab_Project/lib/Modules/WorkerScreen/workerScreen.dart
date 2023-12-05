import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkerScreen extends StatelessWidget {
   WorkerScreen({Key? key}) : super(key: key);

  List <String> imagesWorkers=[
    'https://image.freepik.com/free-vector/colorful-electricity-elements-concept_1284-37811.jpg',
    'https://image.freepik.com/free-vector/carpenter-elements-collection_1284-38162.jpg',
    'https://image.freepik.com/free-vector/colorful-plumbing-round-composition_1284-40766.jpg',
    // 'https://image.freepik.com/free-vector/vegetables-fruits-market-eggplant-peppers-onions-potatoes-healthy-tomato-banana-apple-pear-pumpkin-vector-illustration_1284-46286.jpg',
    'https://img.freepik.com/free-vector/medieval-blacksmith-making-swords-shields-anvil-cartoon_1284-63172.jpg?size=338&ext=jpg',
    'https://image.freepik.com/free-vector/set-modern-workers-repairing-house_1262-19340.jpg',
    'https://image.freepik.com/free-photo/drawing-fabric_1098-18012.jpg',
    'https://image.freepik.com/free-photo/man-steaming-clothes-with-clothing-iron_23-2148386992.jpg'


  ];
  List <String> titleWorkers=[
    'كهربائي',
    'نجار',
    'سباك',
    'حداد',
    'نقاش',
    'ترزي',
    'مكوجي'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Container(
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height*.03,),
                Text('اضغط علي الصانعه التي تريدها',style: GoogleFonts.lato(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color:  Color.fromRGBO(58, 86, 156,1),
                )),
                SizedBox(height: MediaQuery.of(context).size.height*.03,),

                Expanded(
                  child: Container(
                    color: Colors.grey[200],
                    child: GridView.count(
                      physics: BouncingScrollPhysics(),
                      mainAxisSpacing: 0,
                      crossAxisSpacing: 0,
                      childAspectRatio: 1/1.5,
                      crossAxisCount: 3,
                      children: List.generate(imagesWorkers.length, (index) => orderBlock(imagesWorkers[index],titleWorkers[index],index)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void launchWhatsapp(
    String ?number,
    String ?message,
    )async{

  String url= "whatsapp://send?phone=$number&text=$message";

  await canLaunch(url) ? launch(url) : print('Can\'t open whatsapp');

}

Widget orderBlock( String images, String titles,index){
  return InkWell(
    onTap: (){

      if(index==0){
        launchWhatsapp("+201277556432", "شكرا لختيارك اطلب (كهربائي) ,اضغط ارسال لاتمام الطلب");
      }
      else if(index==1){
        launchWhatsapp("+201277556432", "شكرا لختيارك اطلب (نجار) ,اضغط ارسال لاتمام الطلب");
      }
      else if(index==2){
        launchWhatsapp("+201277556432", "شكرا لختيارك اطلب (سباك) ,اضغط ارسال لاتمام الطلب");
      }
      else if(index==3){
        launchWhatsapp("+201277556432", "شكرا لختيارك اطلب (حداد) ,اضغط ارسال لاتمام الطلب");
      }
      else if(index==4){
        launchWhatsapp("+201277556432", "شكرا لختيارك اطلب (نقاش) ,اضغط ارسال لاتمام الطلب");
      }
      else if(index==5){
        launchWhatsapp("+201277556432", "شكرا لختيارك اطلب (ترزي) ,اضغط ارسال لاتمام الطلب");
      }
      else if(index==6){
        launchWhatsapp("+201277556432", "شكرا لختيارك اطلب (مكوجي) ,اضغط ارسال لاتمام الطلب");
      }


    },
    child: Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        width: 150,
        height: 200,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
        ),
        margin: EdgeInsets.fromLTRB(3, 0, 5, 0),
        child: Column(
          children: [
            Container(

              child: Material(
                borderRadius: BorderRadius.circular(15),
                elevation: 10.0,
                child: Column(
                  children: [
                    Container(
                      height: 110,
                      width: double.infinity,
                      child: Image(
                          fit: BoxFit.cover,
                          image: NetworkImage(images)
                      ),
                    ),
                    SizedBox(height: 8,),
                    Text(titles,style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),),
                    SizedBox(height: 5,),

                  ],
                ),
              ),
            )
          ],
        ),


      ),
    ),
  );
}
