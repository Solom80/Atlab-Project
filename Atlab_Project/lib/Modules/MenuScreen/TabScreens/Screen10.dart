import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talabatak/Componants/componant.dart';
import 'package:talabatak/Models/itemModel.dart';
import 'package:talabatak/Modules/ItemScreen/itemScreen.dart';
import 'package:talabatak/talabatak_bloc/cubit.dart';
import 'package:talabatak/talabatak_bloc/states.dart';

class Screen10 extends StatelessWidget {
  const Screen10({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit,AppStates>(
      listener: (context,state){},
      builder: (context,state){
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: ListView.separated(
              physics: BouncingScrollPhysics(),
              itemBuilder: (context , index) => menuListItem(context,AppCubit.get(context).foodsScreen10[index]),
              separatorBuilder: (context , index) => SizedBox(
                height: 1.0,
              ),
              itemCount: AppCubit.get(context).foodsScreen10.length,
            ),
          ),
        );
      },
    );
  }
}
Widget menuListItem (context,ItemModel foods)
{
  return GestureDetector(
    onTap: (){
      navigateTo(context: context, widget: ItemScreen(foods));
    },
    child: Padding(
      padding: const EdgeInsets.all(10.0),
      child: Material(
        elevation: 1.0,
        color: Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(15.0),
        shadowColor: Colors.grey,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 10.0,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 45.0,
                backgroundImage: NetworkImage('https://firebasestorage.googleapis.com/v0/b/talabat-d4b5a.appspot.com/o/burger.jpeg?alt=media&token=c3071bd2-692b-4e08-a286-6b11eed46d38'),
              ),
              SizedBox(
                width: 20.0,
              ),
              Expanded(
                child: Text(foods.name!,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                width: 10.0,
              ),
              Text(
                'LE',
                style: TextStyle(
                  fontSize: 18.0,
                ),
              ),
              SizedBox(
                width: 5.0,
              ),
              Text(foods.price!,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}