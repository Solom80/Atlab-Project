abstract class AppStates{

}

class intailstate extends AppStates{

}

class SelectedPlaceState extends AppStates{

}

class AppAddItemToUserOredersState extends AppStates {}
class AppGetUserLocation extends AppStates{}
class AppRemoveItemFromUserOredersState extends AppStates {}
class AppGetTotalPriceState extends AppStates {}
class AppGetCurrentRestaurantState extends AppStates {}
class AppCreateDatabaseState extends AppStates {}
class AppInsertDatabaseState extends AppStates {}
class AppInsertDatabaseLoadingState extends AppStates {}
class AppGetDatabaseState extends AppStates {}
class AppDeleteDatabaseState extends AppStates {}
class SmallScreenState extends AppStates {}
class NormalScreenState extends AppStates {}






class AppChangeTabsState extends AppStates{}

class SelectedAreaState extends AppStates{

}

class PlusNumberOfItemState extends AppStates{

}

class MinesNumberOfItemState extends AppStates{

}

class AppGetUserLoadingState extends AppStates {


}
class AppGetUserSuccessState extends AppStates {


}
class AppGetUserErrorState extends AppStates {
  final String error;

  AppGetUserErrorState(this.error);
}

class AppGetItemDetailLoadingState extends AppStates {


}
class AppGetItemDetailSuccessState extends AppStates {


}
class AppGetItemDetailErrorState extends AppStates {
  final String error;

  AppGetItemDetailErrorState(this.error);
}

class AppGetKosharyHamadaSuccessState extends AppStates{

}

class AppGetKosharyHamadaErrorState extends AppStates{

}

class AppGetAbuMariamFishSuccessState extends AppStates{

}


class AppGetAbuMariamFishErrorState extends AppStates{

}

class AppGetPizzaBolaSuccessState extends AppStates{

}


class AppGetPizzaBolaErrorState extends AppStates{

}

class AppGetHatyeEltakiaSuccessState extends AppStates{

}


class AppGetHatyeEltakiaErrorState extends AppStates{

}

class AppGetMenusSuccessState extends AppStates{}
class AppGetMenusErrorState extends AppStates{}

class AppCreateInfoSuccessState extends AppStates{}
class AppCreateInfoErrorState extends AppStates{}

class AppGetInfoSuccessState extends AppStates{}
class AppGetInfoErrorState extends AppStates{}


class AppCreateOrderSuccessState extends AppStates{}
class AppCreateOrderErrorState extends AppStates{}

class AppGetOrderSuccessState extends AppStates{}
class AppGetOrderErrorState extends AppStates{}

class AppInternetConnectionSuccessState extends AppStates{}
class AppInternetConnectionErrorState extends AppStates{}

class AppChangeItemColorState extends AppStates{}

class AppDeleteOrderState extends AppStates{}

class  clearOrderState extends AppStates{}

class AppGetPizzaElamiraSuccessState extends AppStates{}

class AppGetPizzaElamiraErrorState  extends AppStates{}

class AppGetCrazyPizzaSuccessState extends AppStates{}

class AppGetCrazyPizzaErrorState extends AppStates{}

class AppGetPizzaElhowtSuccessState extends AppStates{}

class AppGetPizzaElhowtErrorState extends AppStates{}

class AppGetPizzaElsaferSuccessState extends AppStates{}

class AppGetPizzaElsaferErrorState extends AppStates{}

class AppGetPizzaElmahdySuccessState extends AppStates{}

class AppGetPizzaElmahdyErrorState extends AppStates{}

class AppGetElasilSuccessState extends AppStates{}

class AppGetElasilErrorState extends AppStates{}

class AppGetHadrMotSuccessState extends AppStates{}

class AppGetHadrMotErrorState extends AppStates{}

class AppGetPizzaElomdaSuccessState extends AppStates{}

class AppGetPizzaElomdaErrorState extends AppStates{}

class AppGetHamdaElmahtaSuccessState extends AppStates{}

class SaveDate extends AppStates{}

class AppGetPizzaElprimoSuccessState extends AppStates{}


class AppGetHamdaElmahtaErrorState extends AppStates{}

class AppCreateMarketSuccessState extends AppStates{}

class AppCreateMarketErrorState extends AppStates{}

class AppGetMarketSuccessState extends AppStates{}

class AppGetMarketErrorState extends AppStates{}

class AppCreatePharmacySuccessState extends AppStates{}

class AppCreatePharmacyErrorState extends AppStates{}

class AppGetPharmacySuccessState extends AppStates{}

class AppGetPharmacyErrorState extends AppStates{}

class AppCreateShoppingSuccessState extends AppStates{}

class AppCreateShoppingErrorState extends AppStates{}

class AppGetShoppingSuccessState extends AppStates{}

class AppGetShoppingErrorState extends AppStates{}

class AppCreateNoThereSuccessState extends AppStates{}

class AppCreateNoThereErrorState extends AppStates{}

class AppGetNoThereSuccessState extends AppStates{}

class AppGetNoThereErrorState extends AppStates{}

class AppCreateDriveSuccessState extends AppStates{}

class AppCreateDriveErrorState extends AppStates{}

class AppGetDriveSuccessState extends AppStates{}

class AppSwichValueVisibleState extends AppStates{}


