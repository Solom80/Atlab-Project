import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
 static SharedPreferences? sharedPreferences;

 static void init () async {
   sharedPreferences = await SharedPreferences.getInstance();
 }


 static Future<bool> saveData ({
  required String key ,
  dynamic value ,
 }) async
 {
  return sharedPreferences!.setString(key, value);
 }

 static dynamic getData ({
  required String key,
 })
 {
  return sharedPreferences!.get(key);
 }

 static Future<bool> saveBoolen(
     {
      required String key,
      required bool value,
     }) async
 {

  return await sharedPreferences!.setBool(key, value);

 }

 static bool? getBoolen(
     {
      required String key,
     }){

     return sharedPreferences!.getBool(key);

 }



 static Future<bool> removeData({
  required String key,
 }) async
 {
  return await sharedPreferences!.remove(key);
 }


 static Future<bool> saveBool ({
  required String key ,
  required List <String> value ,
 }) async
 {
  return sharedPreferences!.setStringList(key, value);
 }

 static dynamic getBool ({
  required String key,
 })
 {
  return sharedPreferences!.get(key);
 }




}