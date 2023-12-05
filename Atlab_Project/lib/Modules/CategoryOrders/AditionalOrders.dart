import 'dart:ui';

import 'package:conditional_builder/conditional_builder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talabatak/Componants/componant.dart';
import 'package:talabatak/Componants/constants.dart';
import 'package:talabatak/Models/adminModel.dart';
import 'package:talabatak/Models/categoryModel.dart';
import 'package:talabatak/Models/itemModel.dart';
import 'package:talabatak/Models/orderModel.dart';
import 'package:talabatak/Modules/AdminScreen/itemsAdminScreen.dart';
import 'package:talabatak/Modules/LoginScreen/login_screen.dart';
import 'package:talabatak/Modules/ShowOrders/ShowOrders.dart';
import 'package:talabatak/SharedPreference/CacheHelper.dart';
import 'package:talabatak/talabatak_bloc/cubit.dart';
import 'package:talabatak/talabatak_bloc/states.dart';


int count=0;

List<String> isSelected=[];

class AditionalOrder extends StatelessWidget {



  List<Color> cardColor=[];



  @override
  Widget build(BuildContext context) {
    return Builder(
        builder: (context) {
          AppCubit.get(context).getOrder();
          return BlocConsumer<AppCubit,AppStates>(
              listener: (context,state){},
              builder: (context,state){
                var order;
                if(valueOfShowOrder=='1'){
                   order = AppCubit.get(context).marketList;
                }
                else if(valueOfShowOrder=='2'){
                  order = AppCubit.get(context).pharmacyList;
                }
                else if(valueOfShowOrder=='3'){
                  order = AppCubit.get(context).shoppingList;
                }
                else if(valueOfShowOrder=='4'){
                  order = AppCubit.get(context).nothereList;
                }
                var lenght=  order.length;
                for(int i=0;i<=lenght;i++){
                  cardColor.add(Colors.white);
                }
                for(int i=0;i<=lenght;i++){
                  isSelected.add('0');
                }

                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: Scaffold(
                    appBar: AppBar(
                      title: Text('الطلبات',style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      )),
                      leading: IconButton(
                        onPressed: (){
                          navigateAndRemove(context: context, widget: ItemsAdminScreen());
                        },
                        icon: Icon(
                          Icons.arrow_forward_outlined,
                        ),
                      ),
                    ),

                    body: ConditionalBuilder(
                      condition: order.length > 0,
                      builder:(context)=> Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0,10, 20, 0),
                            child:valueOfShowOrder=='1'? Text('طلبات سوبر ماركت',style: TextStyle(
                                color: Colors.black,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lemonada'
                            ))
                                :valueOfShowOrder=='2'?Text('طلبات صيدليات',style: TextStyle(
                                color: Colors.black,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lemonada'
                            ))
                                :valueOfShowOrder=='3'?Text('طلبات سوق',style: TextStyle(
                                color: Colors.black,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lemonada'
                            ))
                                :valueOfShowOrder=='4'?Text('طلب اخر',style: TextStyle(
                                color: Colors.black,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lemonada'
                                )):
                                Text('توصيل طلبات',style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lemonada'
                            )),

                          ),
                          Expanded(
                            child: ListView.separated(
                              itemBuilder: (context , index) => clientItem(order[index] , context,cardColor,index),
                              separatorBuilder: (context , index) => SizedBox(
                                height: 0,
                              ),
                              itemCount: order.length,
                            ),
                          ),
                          // Padding(
                          //   padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                          //   child: Text('الطلب',style: TextStyle(
                          //       color: Colors.black,
                          //       fontSize: 22,
                          //       fontWeight: FontWeight.bold,
                          //       fontFamily: 'Lemonada'
                          //   )),
                          // ),
                          // Expanded(
                          //   child: ListView.separated(
                          //       itemBuilder: (context,index)=> listItem(order[index]),
                          //       separatorBuilder: (context,index){
                          //         return SizedBox(height: 5,);
                          //       },
                          //       itemCount: AppCubit.get(context).items.length
                          //   ),
                          // ),
                        ],
                      ),
                      fallback: (context) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu,size: 150,color: Color.fromRGBO(58, 86, 156,1),),
                            Text('لا توجد طلبات',style: TextStyle(
                              color: Color.fromRGBO(58, 86, 156,1),
                              fontSize: 25,
                              fontWeight: FontWeight.bold
                            ),)
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
          );
        }
    );
  }
}

Widget clientItem (CategoryModel model , context,List<Color> colors,index)
{

  bool done=false;
  return GestureDetector(
    onTap: (){
      count=index;
    },
    child: Container(
      width: double.infinity,
      height: 370,
      padding: EdgeInsets.fromLTRB(15,20, 15, 20),
      child: Stack(
        children: [
          Material(
            borderRadius: BorderRadius.circular(20),
            elevation: 20,
            color: colors[index],
            child:  Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                  child: Row(
                    children: [
                      Text('اسم العميل : ',style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold
                      )),
                      Text(model.name!,style: TextStyle(
                        fontSize: 17,
                      )),
                    ],
                  ),
                ),
                SizedBox(height: 10,),
                Container(
                  height: 2,
                  margin: EdgeInsets.fromLTRB(15, 0, 15, 0),
                  color:  Color.fromRGBO(58, 86, 156,1),
                ),
                SizedBox(height: 10,),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                  child: Row(
                    children: [
                      Text('رقم الهاتف : ',style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold
                      )),
                      Text(model.number!,style: TextStyle(
                        fontSize: 17,
                      ))
                    ],

                  ),
                ),
                SizedBox(height: 10,),
                Container(
                  height: 2,
                  margin: EdgeInsets.fromLTRB(15, 0, 15, 0),
                  color:  Color.fromRGBO(58, 86, 156,1),
                ),
                SizedBox(height: 10,),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                  child: Row(
                    children: [
                      Text('العنوان : ',style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold
                      )),
                      Text(model.address!,style: TextStyle(
                        fontSize: 17,
                      ))
                    ],
                  ),
                ),
                SizedBox(height: 10,),
                Container(
                  height: 2,
                  margin: EdgeInsets.fromLTRB(15, 0, 15, 0),
                  color:  Color.fromRGBO(58, 86, 156,1),
                ),
                Container(
                  alignment: Alignment.topRight,
                  height: 100,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                    child: Row(
                      children: [
                        Text('الطلب : ',style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold
                        )),
                        Container(
                          width: 230,
                          margin: EdgeInsets.only(top: 10),
                          child: Text(model.order!,
                            maxLines: 4,
                            style: TextStyle(
                            fontSize: 17,
                          )),
                        )
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Spacer(),
                    RaisedButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      color:  Color.fromRGBO(58, 86, 156,1),
                      onPressed: (){



                        AppCubit.get(context).changeItemColor(index, colors);


                      },
                      child: Text('تم الطلب',style: TextStyle(
                        color: Colors.white,

                      ),),
                    ),
                    SizedBox(width: 7,),
                    IconButton(onPressed: (){
                      print('Hi');
                      if(valueOfShowOrder=='1'){
                         AppCubit.get(context).deleteMarketOrder(index);
                         AppCubit.get(context).getMarketOrder();
                      }
                      else if(valueOfShowOrder=='2'){
                        AppCubit.get(context).deletePharmacyOrder(index);
                        AppCubit.get(context).getPharmacyOrder();

                      }
                      else if(valueOfShowOrder=='3'){
                        AppCubit.get(context).deleteShoppingOrder(index);
                        AppCubit.get(context).getShoppingOrder();
                      }
                      else if(valueOfShowOrder=='4'){
                        AppCubit.get(context).deleteNoTheregOrder(index);
                        AppCubit.get(context).getNoThereOrder();
                      }
                    }, icon: Icon(
                      Icons.delete,
                    )),
                    SizedBox(width: 10,),

                  ],
                ),
                // IconButton(onPressed: (){
                // }, icon:
                // Icon(
                //     Icons.cloud_done_rounded
                // )
                // ),
              ],
            ),
          ),
          if(colors[index]==Colors.greenAccent)
            Positioned(
              top: 100,
              right: 80,
              child: Text('Done',style: TextStyle(
                  color: Colors.black54,
                  fontSize: 70
              ),),
            ),
        ],
      ),

    ),
  );
}

