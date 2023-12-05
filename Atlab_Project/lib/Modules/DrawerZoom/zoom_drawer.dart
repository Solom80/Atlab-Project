import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:talabatak/Modules/DrawerScreen/drawer_screen.dart';
import 'package:talabatak/Modules/home_page/HomePageScreen.dart';



class ContainerScreen extends StatelessWidget {
  const ContainerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ZoomDrawer(
        style: DrawerStyle.Style1,
        mainScreen: HomePageScreen(),
        menuScreen: DrawerScreen(),
      )
    );
  }
}
