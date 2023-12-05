import 'package:conditional_builder/conditional_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talabatak/Componants/componant.dart';
import 'package:talabatak/Modules/LoginScreen/login_screen.dart';
import 'RegisterCubit/cubit.dart';
import 'RegisterCubit/state.dart';

class RegisterVistorScreen extends StatelessWidget {

  var nameController = TextEditingController();
  var phoneController = TextEditingController();
  var addressController = TextEditingController();
  var formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return  BlocProvider(
      create: (BuildContext context) => RegisterCubit(),
      child: BlocConsumer<RegisterCubit , RegisterStates>(
        listener: (context , state){
          if(state is AppRegisterSuccessState)
          {
            navigateAndRemove(context: context, widget: LoginScreen());
          }
        },
        builder: (context , state){
          var cubit = RegisterCubit.get(context);
          return Scaffold(
            appBar: AppBar(
              elevation: 0.0,
              backgroundColor: Colors.white,
              backwardsCompatibility: false,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.white,
                statusBarIconBrightness: Brightness.dark,
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

                        CircleAvatar(
                          radius: 75.0,
                          child: Image(
                            image: AssetImage('assets/images/login.jpeg'),
                          ),
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                        Text(
                          'تسجيل البيانات',
                          style: TextStyle(
                            fontSize: 22.0,
                            color: Color.fromRGBO(58, 86, 156,1),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(
                          height: 50.0,
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
                              return 'برجاء أدخال الأسم صحيح';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'الأسم بالكامل',

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
                          height: 10.0,
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
                            if(value!.isEmpty && value.length == 11)
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
                          height: 10.0,
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
                            hintText: 'العنوان الأساسى بالكامل',
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
                          height: 30.0,
                        ),
                        ConditionalBuilder(
                          condition: state is! AppRegisterLoadingState,
                          builder: (context)=>Container(
                            width: double.infinity,
                            height: 50.0,
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
                                    cubit.userRegister(
                                      name: nameController.text,
                                      phone: phoneController.text,
                                      address: addressController.text,
                                    );
                                    showToast(text: 'تم تسجيل البيانات بنجاح', state: ToastState.SUCCESS);
                                  }
                                },
                                child: Text(
                                  'تسجيل',
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
                          fallback: (context)=> Center(child: CircularProgressIndicator()),
                        ),
                        SizedBox(
                          height: 10.0,
                        ),

                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
