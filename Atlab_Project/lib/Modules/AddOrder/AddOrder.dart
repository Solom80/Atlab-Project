import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talabatak/Componants/componant.dart';
import 'package:talabatak/Componants/constants.dart';
import 'package:talabatak/Models/itemModel.dart';
import 'package:talabatak/Models/orderModel.dart';
import 'package:talabatak/Modules/FinishOrder/FinishOrder.dart';
import 'package:talabatak/Modules/home_page/HomePageScreen.dart';
import 'package:talabatak/talabatak_bloc/cubit.dart';
import 'package:talabatak/talabatak_bloc/states.dart';

class AddOrder extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return Builder(
        builder: (BuildContext context){
          AppCubit.get(context).getTotalPrice();
          return BlocConsumer<AppCubit,AppStates>(
            listener: (context,state){},
            builder: (context,state){
              return Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  appBar: AppBar(
                    title: Text('اتمام الطلب',style: TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                    ),),
                  ),
                  body: Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: ListView.separated(
                              itemBuilder: (context , index) => listItem(userOrders[index] , context , index),
                              separatorBuilder: (context , index) => SizedBox(
                                height: 1,
                              ),
                              itemCount: userOrders.length,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Row(
                            children: [
                              MaterialButton(
                                elevation: 7,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                color: Color.fromRGBO(58, 86, 156,1),
                                onPressed: (){
                                  AppCubit.get(context).getCurrentLocation();
                                  String userLocation = AppCubit.get(context).currentLocation;
                                  navigateTo(context: context, widget: FinishOrder(finishOrders , userLocation));
                                },
                                child: Text('تأكيد الطلب',style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16
                                ),),
                              ),
                              SizedBox(
                                width: 5.0,
                              ),
                              MaterialButton(
                                elevation: 7,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                color: Color.fromRGBO(58, 86, 156,1),
                                onPressed: (){
                                  navigateTo(context: context, widget: HomePageScreen());
                                },
                                child: Text('اضافة اخر',style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                ),),
                              ),
                              SizedBox(width: 5,),
                              Row(
                                children: [
                                  Text(
                                    'السعر :',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    'L.E ',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  Text('${AppCubit.get(context).totalPrice}',style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold
                                  ),),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 20.0,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        });
  }

  Widget listItem (OrderModel model  , context , index)
  {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
      child: Material(
        color:Color.fromRGBO(58, 86, 156,1),
        borderRadius: BorderRadius.circular(20),
        elevation: 5,
        child: Container(
          height: 240,
          width: 330,
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: IconButton(
                  onPressed: (){
                    AppCubit.get(context).removeItemFromUserOrders(index);
                  },
                  icon: Icon(
                    Icons.cancel_outlined,
                    size: 30,
                    color: Color.fromRGBO(58, 86, 156,1),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0,0, 30, 0),
                child: Row(
                  children: [
                   CircleAvatar(
                     radius: 40,
                     backgroundImage: NetworkImage('https://firebasestorage.googleapis.com/v0/b/talabat-d4b5a.appspot.com/o/burger.jpeg?alt=media&token=c3071bd2-692b-4e08-a286-6b11eed46d38',),
                   ),
                    SizedBox(width: 5,),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Container(
                          child: Text(
                            '${model.name}',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                          ),
                        ),
                        Text(
                          '${model.category}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[200],
                          ),),
                        // Container(
                        //   width: 150,
                        //   child: Text(
                        //     '${model.details}',
                        //     style: TextStyle(
                        //         fontSize: 14,
                        //         fontWeight: FontWeight.bold
                        //     ),
                        //     maxLines: 3,
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 12,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0 ,0, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text('العدد :',style: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold
                        ),),
                        SizedBox(width: 20,),
                        Text('${model.number}',style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold
                        ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 20.0,
                    ),
                    Row(
                      children: [
                        Text('الحجم :',style: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold
                        ),),
                        SizedBox(width: 20,),
                        Text(
                          'صغير',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold
                          ),)
                      ],
                    ),
                  ],
                ),

              ),
            ],
          ),
        ),
      ),
    );
  }

}
