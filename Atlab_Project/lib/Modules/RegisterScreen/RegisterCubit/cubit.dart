import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talabatak/Componants/componant.dart';
import 'package:talabatak/Componants/constants.dart';
import 'package:talabatak/Models/UserModel.dart';
import 'package:talabatak/Modules/ProfileScreen/profileScreen.dart';
import 'package:talabatak/Modules/RegisterScreen/RegisterCubit/state.dart';
import 'package:talabatak/SharedPreference/CacheHelper.dart';

class RegisterCubit extends Cubit<RegisterStates> {
  RegisterCubit() : super(AppRegisterInitialState());

  static RegisterCubit get(context) => BlocProvider.of(context);



  void userRegister({
    required String name,
    required String phone,
    required String address,
  }) {
    emit(AppRegisterLoadingState());
    FirebaseAuth.instance
        .createUserWithEmailAndPassword(
      email: '$phone@talabat.com',
      password: phone,
    )
        .then((value) {
      createUser(
        email: '$phone@talabat.com',
        name: name,
        phone: phone,
        uId: value.user!.uid,
        address: address,
      );
      emit(AppRegisterSuccessState());
    }).catchError((error) {
      print('Error when Register : ${error.toString()}');
      emit(AppRegisterErrorState(error));
    });
  }

  void createUser({
    required String email,
    required String name,
    required String phone,
    required String uId,
    required String address,
  }) {
    emit(AppRegisterLoadingState());

    UserModel model = UserModel(
      name: name,
      email: '$phone@talabat.com',
      phone: phone,
      address: address,
      uId: uId,
    );

    FirebaseFirestore.instance
        .collection('users')
        .doc(uId)
        .set(model.toMap())
        .then((value) {
      emit(AppCreateUserSuccessState());
    }).catchError((error) {
      print('Error when Register : ${error.toString()}');
      emit(AppCreateUserErrorState(error.toString()));
    });
  }

  // UserModel ?userModel;
  //
  // void getVistor(context) {
  //   emit(RegisterGetUserLoadingState());
  //
  //   FirebaseFirestore.instance
  //       .collection('users')
  //       .doc(CacheHelper.getData(key: 'uId'))
  //       .get()
  //       .then((value) {
  //     userModel=UserModel.fromFire(value.data()!);
  //     print('HI');
  //     navigateTo(context: context, widget: ProfileScreen());
  //     emit(RegisterGetUserSuccessState());
  //   }).catchError((error) {
  //     print('Error when Get : ${error.toString()}');
  //
  //     emit(RegisterGetUserErrorState());
  //   });
  // }



}
