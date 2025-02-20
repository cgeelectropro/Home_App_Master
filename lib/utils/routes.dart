import 'package:flutter/material.dart';
import 'package:home_app/main.dart';
import 'package:home_app/screens/about_page.dart';
import 'package:home_app/screens/add_device.dart';
import 'package:home_app/screens/add_room.dart';
import 'package:home_app/screens/devices_page.dart';
import 'package:home_app/screens/home_page.dart';
import 'package:home_app/screens/login_screen.dart';
import 'package:home_app/screens/register_page.dart';
import 'package:home_app/screens/room_edit.dart';
import 'package:home_app/screens/room_page.dart';
import 'package:home_app/screens/rooms_page.dart';
import 'package:home_app/screens/my_devices_page.dart';
import 'package:home_app/screens/profile_edit_page.dart';
import 'package:home_app/screens/settings.dart';
import 'package:home_app/models/collections.dart';

final routes = {
  '/': (context) => const MyApp(),
  LoginPage.route: (context) => const LoginPage(),
  RegisterPage.route: (BuildContext context) => const RegisterPage(),
  HomePage.route: (BuildContext context) => const HomePage(),
  RoomPage.route: (context) {
    final collection = ModalRoute.of(context)!.settings.arguments as Collection;
    return RoomPage(collection: collection);
  },
  '/room-edit': (context) {
    final room = ModalRoute.of(context)!.settings.arguments as Collection;
    return RoomEditPage(room: room);
  },
  SettingsPage.route: (BuildContext context) => const SettingsPage(),
  AddRoomPage.route: (BuildContext context) => const AddRoomPage(),
  AboutPage.route: (BuildContext context) => const AboutPage(),
  DevicesPage.route: (BuildContext context) => const DevicesPage(),
  RoomsPage.route: (BuildContext context) => const RoomsPage(),
  ProfileEditPage.route: (BuildContext context) => const ProfileEditPage(),
  MyDevicesPage.route: (BuildContext context) => const MyDevicesPage(),
  AddDevicePage.route: (BuildContext context) => const AddDevicePage(),
};
