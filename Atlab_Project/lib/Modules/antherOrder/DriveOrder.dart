import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talabatak/Componants/componant.dart';
import 'package:talabatak/Componants/constants.dart';
import 'package:talabatak/Modules/FinishOrder/FinishDriveOrder.dart';
import 'package:talabatak/Modules/FinishOrder/FinshAntherOrder.dart';
import 'package:talabatak/Modules/StartScreen/StartScreen.dart';
import 'package:talabatak/talabatak_bloc/cubit.dart';
import 'package:talabatak/talabatak_bloc/states.dart';

class DriveOrder extends StatelessWidget {

  String ?imageCategory;
  String ?titleCategory;

  DriveOrder({
    this.imageCategory,
    this.titleCategory
  });

  var orderController = TextEditingController();
  var FromorderController = TextEditingController();
  var ToorderController = TextEditingController();

  var formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit,AppStates>(listener: (context,state){

    },
      builder: (context,state){
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(

              toolbarHeight: 220,
              title: Container(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(300, 0, 1, 0),
                      child: IconButton(onPressed: (){

                        navigateAndRemove(context: context, widget: StartScreen());

                      }, icon: Icon(Icons.arrow_back)),
                    ),

                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(imageCategory!),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height*.016,),
                    Text(titleCategory!,style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),),
                    SizedBox(height: MediaQuery.of(context).size.height*.03,),

                  ],
                ),
              ),
            ),
            body: SingleChildScrollView(
              child: Container(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Center(
                        child: Form(
                          key: formKey,
                          child: Column(
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height*.02,),
                              TextFormField(
                                maxLines: 6,
                                controller: orderController,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(58, 86, 156,1),
                                ),
                                keyboardType: TextInputType.text,
                                validator: (value){
                                  if(value!.isEmpty)
                                  {
                                    return 'برجاء أكتب طلباك هنا';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(

                                  hintText: 'اكتب طلبك هنا...',

                                  hintTextDirection: TextDirection.rtl,

                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 15,
                                    horizontal: 20,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromRGBO(58, 86, 156,1),
                                      width: 2.0,
                                    ),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10.0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.blueAccent,
                                      width: 2.0,
                                    ),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10.0),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height*.02,),
                              Container(
                                  padding: EdgeInsets.only(right: 10),
                                  alignment: Alignment.topRight,
                                  child: Text('توصيل الطلب من ',style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold
                                  ),)
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height*.01,),
                              TextFormField(
                                maxLines: 2,
                                controller: FromorderController,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(58, 86, 156,1),
                                ),
                                keyboardType: TextInputType.text,
                                validator: (value){
                                  if(value!.isEmpty)
                                  {
                                    return 'برجاء أكتب المكان هنا';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(

                                  hintText: 'اكتب المكان هنا...',

                                  hintTextDirection: TextDirection.rtl,

                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 15,
                                    horizontal: 20,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromRGBO(58, 86, 156,1),
                                      width: 2.0,
                                    ),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10.0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.blueAccent,
                                      width: 2.0,
                                    ),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10.0),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height*.02,),
                              Container(
                                  padding: EdgeInsets.only(right: 10),
                                  alignment: Alignment.topRight,
                                  child: Text('توصيل الطلب الي ',style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold
                                  ),)
                              ),
                              TextFormField(
                                maxLines: 2,
                                controller: ToorderController,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(58, 86, 156,1),
                                ),
                                keyboardType: TextInputType.text,
                                validator: (value){
                                  if(value!.isEmpty)
                                  {
                                    return 'برجاء أكتب المكان هنا';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(

                                  hintText: 'اكتب المكان هنا...',

                                  hintTextDirection: TextDirection.rtl,

                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 15,
                                    horizontal: 20,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromRGBO(58, 86, 156,1),
                                      width: 2.0,
                                    ),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10.0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.blueAccent,
                                      width: 2.0,
                                    ),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10.0),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height*.03,),
                              Container(
                                width: double.infinity,
                                height: 40,
                                child: Material(
                                  elevation: 5.0,
                                  borderRadius: BorderRadius.circular(15.0),
                                  color: Color.fromRGBO(58, 86, 156,1),
                                  child: MaterialButton(
                                    minWidth: double.infinity,
                                    height: 50.0,
                                    onPressed: (){
                                      if(formKey.currentState!.validate())
                                      {

                                        // LoginCubit.get(context).clearData();
                                        navigateTo(context: context, widget: FinishDriveOrder(orderController.text, FromorderController.text, ToorderController.text));
                                      }
                                    },
                                    child: Text(
                                      'اتمام الطلب',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18.0,
                                      ),
                                    ),
                                  ),

                                ),
                              ),


                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
