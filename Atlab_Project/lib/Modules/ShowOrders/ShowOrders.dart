import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:talabatak/Models/orderModel.dart';

class ShowOrders extends StatelessWidget {
  List <dynamic> orders ;
  ShowOrders(this.orders);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title:  Text('الطلبات',style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          )),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemBuilder: (context , index) => listItem(orders[index]),
                separatorBuilder: (context , index) => SizedBox(
                  height: 10.0,
                ),
                itemCount: orders.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget listItem (Map model)
  {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 30, 20, 10),
      child: Material(
        color: Color.fromRGBO(58, 86, 156,1),
        borderRadius: BorderRadius.circular(20),
        elevation: 5,
        child: Container(
          height: 240,
          width: 330,
          child: Column(
            children: [
              SizedBox(
                height: 10.0,
              ),
              Container(
                alignment: AlignmentDirectional.topCenter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'المطعم : ',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${model['restaurantName']}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,

                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 10.0,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0,0, 30, 0),
                child: Row(
                  children: [
                     CircleAvatar(
                       radius: 40,
                       backgroundImage: NetworkImage('https://firebasestorage.googleapis.com/v0/b/talabat-d4b5a.appspot.com/o/burger.jpeg?alt=media&token=c3071bd2-692b-4e08-a286-6b11eed46d38'),
                     ),
                    SizedBox(width: 15,),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Container(
                          child: Text(
                            '${model['name']}',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                          ),
                        ),
                        Text(
                          '${model['category']}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[300],

                            fontWeight: FontWeight.bold,
                          ),),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 20,
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
                        SizedBox(width: 7,),
                        Text('${model['number']}',style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold
                        ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 10.0,
                    ),
                    Row(
                      children: [
                        Text('الحجم :',style: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold
                        ),),

                        SizedBox(width: 12,),
                        Text(
                          'صغير',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold
                          ),)
                      ],
                    ),
                    SizedBox(
                      width: 20.0,
                    ),
                    Row(
                      children: [
                        Text(
                          'السعر : ',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold
                          ),
                          maxLines: 3,
                        ),
                        Text(
                          '${model['price']}',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold
                          ),
                          maxLines: 3,
                        ),
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
