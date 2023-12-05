abstract class LoginStates{}

class AppLoginInitialState extends LoginStates{}

class AppLoginLoadingState extends LoginStates {}
class AppLoginSuccessState extends LoginStates {
  final String uId;
  AppLoginSuccessState(this.uId);

}
class AppLoginErrorState extends LoginStates {
  final String error;

  AppLoginErrorState(this.error);
}


class AppLoginChangePasswordState extends LoginStates{}

class ClearDataState extends LoginStates{}

class VistorState extends LoginStates{}







