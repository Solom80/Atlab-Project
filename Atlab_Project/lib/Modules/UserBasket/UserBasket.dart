import 'package:conditional_builder/conditional_builder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talabatak/Componants/componant.dart';
import 'package:talabatak/Componants/constants.dart';
import 'package:talabatak/Models/orderModel.dart';
import 'package:talabatak/Modules/AddOrder/AddOrder.dart';
import 'package:talabatak/Modules/home_page/HomePageScreen.dart';
import 'package:talabatak/talabatak_bloc/cubit.dart';
import 'package:talabatak/talabatak_bloc/states.dart';

class UserBasket extends StatelessWidget {
  const UserBasket({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit,AppStates>(
      listener: (context,state){},
      builder: (context,state){
        List tasks = AppCubit.get(context).orders;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              title: Text('السلة',style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            body: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ConditionalBuilder(
                      condition: AppCubit.get(context).orders.length > 0,
                      builder: (context) => Expanded(
                        child: ListView.separated(
                          itemBuilder: (context , index) => listItem(AppCubit.get(context).orders[index] , context , index),
                          separatorBuilder: (context , index) => SizedBox(
                            height: 5.0,
                          ),
                          itemCount: AppCubit.get(context).orders.length,
                        ),
                      ),
                      fallback: (context) => Expanded(
                        child: Center(
                          child: Text(
                            'السلة فارغة',
                            style: TextStyle(
                              fontSize: 40.0,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    alignment: Alignment.center,
                    child: Expanded(
                      child: MaterialButton(
                        elevation: 7,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: EdgeInsets.fromLTRB(15, 5, 15, 5),
                        color: Color.fromRGBO(58, 86, 156,1),
                        onPressed: (){
                          navigateTo(context: context, widget: HomePageScreen());
                        },
                        child: Text('اضافة عنصر جديد',style: TextStyle(
                            color: Colors.white,
                            fontSize: 20
                        ),),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                ],

              ),

            ),
          ),
        );
      },
    );
  }


  Widget listItem (Map model , context , id)
  {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 10 , 20, 10),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        elevation: 5,
        child: Container(
          height: 400,
          width: 350,
          child: Column(
            children: [
              SizedBox(height: 30,),
              Row(
                children: [
                  Image(
                    image: AssetImage('assets/images/burger.png',),
                    height: 90,
                    width: 90,
                  ),
                  Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${model['name']}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        maxLines: 2,
                        ),
                        Text(
                          '${model['category']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),),
                        Container(
                          width: 120,
                          child: Text(
                            '${model['details']}',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold
                            ),
                            maxLines: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  IconButton(
                      onPressed: (){
                        AppCubit.get(context).deleteDatabase(id: model['id']);
                      },
                      icon: Icon(
                          Icons.delete,
                          color: Color.fromRGBO(58, 86, 156,1),
                      ),
                  ),
                ],
              ),
              SizedBox(
                height: 12,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 110, 5),
                child: Row(
                  children: [
                    Text('الحجم :',style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold
                    ),),
                    SizedBox(width: 35,),
                    Text(
                      'نص',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold
                      ),)
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 110, 5),
                child: Row(
                  children: [
                    Text('السعر :',style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold
                    ),),
                    SizedBox(width: 35,),
                    Text(
                      'L.E',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    Text('${model['price']}',style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold
                    ),),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 110, 10),
                child: Row(
                  children: [
                    Text('العدد :',style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold
                    ),),
                    SizedBox(width: 10,),
                    FloatingActionButton(
                      backgroundColor: Colors.grey[50],
                      elevation: 0,
                      onPressed: (){
                        AppCubit.get(context).plusNumberOfItem();
                      },
                      mini:true ,
                      child:Icon(
                        Icons.add_circle_outline,
                        color: Color.fromRGBO(58, 86, 156,1),
                        size: 30,
                      ) ,
                    ),
                    Text('${AppCubit.get(context).numberOfItem}',style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold
                    ),),
                    FloatingActionButton(
                      backgroundColor: Colors.grey[50],
                      elevation: 0,
                      onPressed: (){
                        AppCubit.get(context).minesNumberOfItem();
                      },
                      mini:true ,
                      child:Icon(
                        Icons.remove_circle_outline,
                        color: Color.fromRGBO(58, 86, 156,1),
                        size: 30,
                      ) ,
                    ),


                  ],
                ),
              ),
              SizedBox(height: 5,),
              MaterialButton(
                elevation: 7,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.fromLTRB(15, 5, 15, 5),
                color: Color.fromRGBO(58, 86, 156,1),
                onPressed: (){
                   AppCubit.get(context).addItemToUserOrders(OrderModel(restaurantName : currentRestaurant, name: model['name'] , price: model['price'] , number: AppCubit.get(context).numberOfItem , category: model['category']) , );
                   navigateTo(context: context, widget: AddOrder());
                   AppCubit.get(context).deleteDatabase(id: model['id']);
                },
                child: Text('اضف الي طلباتك',style: TextStyle(
                    color: Colors.white,
                    fontSize: 20
                ),),
              ),
              SizedBox(
                height: 20.0,
              ),
            ],
          ),
        ),

      ),
    );
  }


}
