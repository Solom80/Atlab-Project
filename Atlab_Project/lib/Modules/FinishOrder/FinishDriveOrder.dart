import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talabatak/Componants/componant.dart';
import 'package:talabatak/Componants/constants.dart';
import 'package:talabatak/Models/adminModel.dart';
import 'package:talabatak/Models/orderModel.dart';
import 'package:talabatak/Modules/AdminScreen/adminScreen.dart';
import 'package:talabatak/Modules/DoneOrder/DoneOrder.dart';
import 'package:talabatak/Modules/LoginScreen/login_screen.dart';
import 'package:talabatak/Modules/RegisterScreen/RegisterCubit/cubit.dart';
import 'package:talabatak/Modules/RegisterScreen/RegisterCubit/state.dart';
import 'package:talabatak/Modules/StartScreen/StartScreen.dart';
import 'package:talabatak/Modules/home_page/HomePageScreen.dart';
import 'package:talabatak/talabatak_bloc/cubit.dart';
import 'package:talabatak/talabatak_bloc/states.dart';
import 'package:url_launcher/url_launcher.dart';

class FinishDriveOrder extends StatelessWidget {

  var nameController = TextEditingController();
  var phoneController = TextEditingController();
  var addressController = TextEditingController();

  var formKey = GlobalKey<FormState>();



  String ?order;
  String ?fromOrder;
  String ?toOrder;



  FinishDriveOrder(this.order,this.fromOrder,this.toOrder);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer <AppCubit , AppStates>(
      listener: (context , state){},
      builder: (context , state){
        AppCubit.get(context).getCurrentLocation();
        String userLocation = AppCubit.get(context).currentLocation;

        addressController.text = userLocation;
        return Scaffold(
          appBar: AppBar(
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Center(
                  child: Text(
                    'تأكيد الطلب',
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            leading: IconButton(
              onPressed: (){
                navigateAndRemove(context: context, widget: StartScreen());
              },
              icon: Icon(
                Icons.arrow_back,
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Center(
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 70,
                      ),
                      TextFormField(
                        controller: nameController,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(58, 86, 156,1),
                        ),
                        keyboardType: TextInputType.text,
                        validator: (value){
                          if(value!.isEmpty)
                          {
                            return 'برجاء أدخال الاسم';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'الاسم ثلاثي',
                          hintTextDirection: TextDirection.rtl,
                          suffixIcon: Icon(
                            Icons.person,
                          ),
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
                      SizedBox(
                        height: 20.0,
                      ),
                      TextFormField(
                        controller: phoneController,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:Color.fromRGBO(58, 86, 156,1)
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value){
                          if(value!.isEmpty && value.length <= 11)
                          {
                            return 'برجاء أدخال رقم موبيل صحيح';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'رقم الموبيل (يفضل رقم الواتس)',

                          hintTextDirection: TextDirection.rtl,
                          suffixIcon: Icon(
                            Icons.phone,
                          ),
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
                      SizedBox(
                        height: 20.0,
                      ),
                      TextFormField(
                        controller: addressController,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(58, 86, 156,1),
                        ),
                        keyboardType: TextInputType.text,
                        validator: (value){
                          if(value!.isEmpty)
                          {
                            return 'برجاء أدخال عنوان صحيح';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'العنوان بالكامل',
                          hintTextDirection: TextDirection.rtl,
                          suffixIcon: Icon(
                            Icons.location_on,
                          ),
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
                      SizedBox(
                        height: 50.0,
                      ),
                      MaterialButton(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: Color.fromRGBO(58, 86, 156,1),
                        minWidth: double.infinity,
                        height: 50.0,
                        onPressed: (){
                          if(formKey.currentState!.validate())
                          {
                            // AdminModel userData = AdminModel(
                            //   name: nameController.text,
                            //   number: phoneController.text,
                            //   address: addressController.text,
                            // );
                            AppCubit.get(context).createDriveOrder(name: nameController.text, number: phoneController.text, address: addressController.text, order: order!, from: fromOrder!, to: toOrder!);
                            // AppCubit.get(context).createOrder(userData: userData, orderData: order);
                            //AppCubit.get(context)..getOrder();
                            navigateTo(context: context, widget: DoneOrder());
                            // launchWhatsapp("+201016257980", "شكرا لختيارك طلباتك(توصيل طلبات) ,اضغط ارسال لاتمام الطلب");
                            // navigateAndRemove(context: context, widget: DoneOrder());

                          }
                        },
                        child: Text(
                          'اتمام العملية',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height*.06,),
                      Text('لدفع عن طريق فودفوان كاش : 01030018001',style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold
                      ),)

                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
