import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talabatak/Componants/componant.dart';
import 'package:talabatak/Componants/constants.dart';
import 'package:talabatak/Models/categoryModel.dart';
import 'package:talabatak/Modules/LoginScreen/LoginCubit/state.dart';

class LoginCubit extends Cubit<LoginStates> {
  LoginCubit() : super(AppLoginInitialState());

  static LoginCubit get(context) => BlocProvider.of(context);
  var loginModel;

  void userLogin({
    required String phone,
  }) {
    emit(AppLoginLoadingState());

    FirebaseAuth.instance.signInWithEmailAndPassword(
      email: '$phone@talabat.com',
      password: phone,
    ).then((value){
      emit(AppLoginSuccessState(value.user!.uid));
      showToast(text: 'تم التسجيل بنجاح', state: ToastState.SUCCESS);
    }).catchError((error){
      print('Error when login : ${error.toString()}');
      emit(AppLoginErrorState(error.toString()));
    });

  }


  void vistorState(){
    vistorLogin= true;
    emit(VistorState());
  }

  Future<void> clearData() async {

    var collection = FirebaseFirestore.instance.collection('orders');
    var snapshots = await collection.get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }

    // items.clear();
    // final fb= FirebaseFirestore.instance.collection('orders').doc();
    // fb.delete().whenComplete(() {
    //   print('done');
    // });

    emit(ClearDataState());

  }

}
