import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talabatak/Componants/componant.dart';
import 'package:talabatak/Componants/constants.dart';
import 'package:talabatak/Models/itemModel.dart';
import 'package:talabatak/Models/orderModel.dart';
import 'package:talabatak/Modules/AddOrder/AddOrder.dart';
import 'package:talabatak/Modules/UserBasket/UserBasket.dart';
import 'package:talabatak/talabatak_bloc/cubit.dart';
import 'package:talabatak/talabatak_bloc/states.dart';

class ItemScreen extends StatelessWidget {

  ItemModel itemModel;
  ItemScreen(this.itemModel);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit,AppStates>(
      listener: (context,state){},
      builder: (context,state){

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              title: Text('تفاصيل المنتج',style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold
              ),),
            ),
            body: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [

                  Padding(
                    padding: const EdgeInsets.fromLTRB(30, 30, 20, 20),
                    child: Material(
                      color:  Color.fromRGBO(58, 86, 156,1),
                      borderRadius: BorderRadius.circular(20),
                      elevation: 5,
                      child: Container(
                        height: 420,
                        width: 330,
                        child: Column(
                          children: [
                            SizedBox(height: 30,),
                            Row(
                              children: [
                                SizedBox(width: 10,),
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage: NetworkImage('https://firebasestorage.googleapis.com/v0/b/talabat-d4b5a.appspot.com/o/burger.jpeg?alt=media&token=c3071bd2-692b-4e08-a286-6b11eed46d38',),
                                ),
                                SizedBox(width: 20,),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${itemModel.name}',
                                      style: TextStyle(
                                        fontSize: 19,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                    ),),
                                    Text(
                                      '${itemModel.category}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[200],
                                    ),),
                                    Container(
                                      width: 180,
                                      child: Text(
                                        '${itemModel.details}',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold
                                        ),
                                      maxLines: 3,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 12,
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 110, 0),
                              child: Row(
                                children: [
                                  Text('الحجم :',style: TextStyle(
                                      fontSize: 22,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold
                                  ),),
                                  SizedBox(width: 35,),
                                  Text(
                                    'صغير',
                                    style: TextStyle(
                                      fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold
                                  ),)
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0,50,3),
                              child: Text(
                                'يختلف السعر علي حسب الحجم',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[200]

                                )),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 110, 5),
                              child: Row(
                                children: [
                                  Text('السعر :',style: TextStyle(
                                      fontSize: 22,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold
                                  ),),
                                  SizedBox(width: 35,),
                                  Text(
                                    'L.E ',
                                    style: TextStyle(
                                      fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold
                                     ),
                                  ),
                                  Text('${int.parse(itemModel.price!) * AppCubit.get(context).numberOfItem}',style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
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
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold
                                  ),),
                                  SizedBox(width: 10,),
                                  FloatingActionButton(
                                    backgroundColor: Color.fromRGBO(58, 86, 156,1),
                                    elevation: 0,

                                    onPressed: (){
                                      AppCubit.get(context).plusNumberOfItem();
                                    },
                                    mini:true ,
                                    child:Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.white,
                                      size: 30,
                                    ) ,
                                  ),
                                  Text('${AppCubit.get(context).numberOfItem}',style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold
                                  ),),
                                  FloatingActionButton(
                                    backgroundColor: Color.fromRGBO(58, 86, 156,1),
                                    elevation: 0,
                                    onPressed: (){
                                      AppCubit.get(context).minesNumberOfItem();
                                    },
                                    mini:true ,
                                    child:Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.white,
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
                              color: Colors.white,
                              onPressed: (){
                                //
                                // AlertDialog alert=AlertDialog(
                                //   title:Container(
                                //     child: Column(
                                //       children: [
                                //         Text('هل متاكد انك تريد اضافه المنتج الي طلباتك',textDirection: TextDirection.rtl,),
                                //         SizedBox(height: 5,),
                                //         Container(
                                //           color: Colors.black,
                                //           height: 2,
                                //         )
                                //       ],
                                //     ),
                                //   ),
                                //   content: Container(
                                //     height: 50,
                                //     child: Row(
                                //       children: [
                                //         Expanded(
                                //           child: TextButton(onPressed: (){
                                //            Navigator.pop(context);
                                //           }, child: Text('لاا',style: TextStyle(
                                //               fontSize: 19,
                                //               color:  Color.fromRGBO(58, 86, 156,1),
                                //               fontWeight: FontWeight.bold
                                //           ),)),
                                //         ),
                                //         Expanded(
                                //           child: TextButton(onPressed: (){
                                //
                                //             }, child: Text('نعم',style: TextStyle(
                                //               fontSize: 19,
                                //             color:  Color.fromRGBO(58, 86, 156,1),
                                //             fontWeight: FontWeight.bold
                                //           ),)),
                                //         ),
                                //
                                //       ],
                                //     )
                                //   ),
                                // );
                                // showDialog(builder: (context) => alert, context: context);

                                AppCubit.get(context).addItemToUserOrders(OrderModel(restaurantName : currentRestaurant , name: itemModel.name , price: (int.parse(itemModel.price!) * AppCubit.get(context).numberOfItem).toString(), category: itemModel.category , number: AppCubit.get(context).numberOfItem));
                                //AppCubit.get(context).createOrder(number: itemNumber, name: itemModel.name! ,price: itemModel.price!);
                                navigateTo(context: context, widget: AddOrder());

                              },
                              child: Text('اضف الي طلباتك',style: TextStyle(
                                  color: Color.fromRGBO(58, 86, 156,1),
                                  fontSize: 20,
                                fontWeight: FontWeight.bold
                              ),),
                            ),
                            SizedBox(
                              height: 20.0,
                            ),
                          ],
                        ),
                      ),

                    ),
                  ),

                  // Padding(
                  //   padding: const EdgeInsets.fromLTRB(28, 0, 0, 0),
                  //   child: InkWell(
                  //     onTap: (){
                  //       //
                  //       // navigateTo(context: context, widget: UserBasket());
                  //       // AppCubit.get(context).insertDatabase(name: itemModel.name!, price: itemModel.price!, category: itemModel.category!, details: itemModel.details!);
                  //       AppCubit.get(context).addItemToUserOrders(OrderModel(restaurantName : currentRestaurant , name: itemModel.name , price: (int.parse(itemModel.price!) * AppCubit.get(context).numberOfItem).toString(), category: itemModel.category , number: AppCubit.get(context).numberOfItem));
                  //       //AppCubit.get(context).createOrder(number: itemNumber, name: itemModel.name! ,price: itemModel.price!);
                  //       navigateTo(context: context, widget: AddOrder());
                  //     },
                  //     child: Column(
                  //       children: [
                  //         Image(image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/talabat-d4b5a.appspot.com/o/shopping.jpeg?alt=media&token=d7d9e1fe-5445-429e-b4ab-1b6bc1833f65',),
                  //           height: 100,
                  //           width: 100,
                  //         ),
                  //         Text(
                  //           'أضف الى السله',
                  //           style: TextStyle(
                  //             color: Color.fromRGBO(58, 86, 156,1),
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                ],

              ),

            ),
          ),
        );
      },
    );
  }
}
