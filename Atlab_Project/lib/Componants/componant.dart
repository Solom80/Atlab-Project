import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void navigateAndRemove ({
  required BuildContext context,
  required Widget widget,
})
{
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context){
      return widget;
    }),
        (route){
      return false;
    },
  );
}

void navigateTo ({
  required BuildContext context,
  required Widget widget ,
})
{
  Navigator.push(context, MaterialPageRoute(builder: (context){
    return widget;
  }));

}

void showToast ({
  required String text ,
  required ToastState state ,
})
{
  Fluttertoast.showToast(
    msg: text,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 5,
    backgroundColor: chooseToastColor(state),
    textColor: Colors.white,
    fontSize: 16.0,
  );
}

enum ToastState {SUCCESS , ERROR , WARNING}

Color chooseToastColor(ToastState state)
{
  Color color;

  switch(state)
  {
    case ToastState.SUCCESS :
      color = Colors.green;
      break;

    case ToastState.ERROR :
      color = Colors.red;
      break;

    case ToastState.WARNING :
      color = Colors.amber;
      break;
  }

  return color;
}
