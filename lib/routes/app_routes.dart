import 'package:car_navigation/features/home/view/screen/home_screen.dart';
import 'package:get/get.dart';

class AppRoute {
  static String homeScreen = "/homeScreen";

  static String getHomeScreen() => homeScreen;

  static List<GetPage> routes = [
    GetPage(name: homeScreen, page: () => const HomeScreen()),
  ];
}
