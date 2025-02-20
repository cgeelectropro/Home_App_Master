import 'package:flutter/material.dart';
import 'package:home_app/components/icon_button.dart';
import 'package:home_app/models/collections.dart';
import 'package:home_app/models/weather.dart';
import 'package:home_app/screens/add_device.dart';
import 'package:home_app/screens/login_screen.dart';
import 'package:home_app/screens/room_page.dart';
import 'package:home_app/services/api/auth.dart';
import 'package:home_app/theme/theme_changer.dart';
import 'package:provider/provider.dart';
import 'package:home_app/components/add_room_card.dart';
import 'package:home_app/components/room_card.dart';
import 'package:home_app/screens/add_room.dart';
import 'package:home_app/screens/settings.dart';
import 'package:home_app/services/api/device.dart';
import 'package:home_app/services/api/weather_services.dart';
import 'package:home_app/services/provider/collection_provider.dart';
import 'package:home_app/services/provider/devices_provider.dart';
import 'package:home_app/services/provider/user_provider.dart';
import 'package:home_app/theme/color.dart';
import 'package:home_app/utils/assets.dart';
import 'package:home_app/utils/utilities.dart';
import 'dart:ui' as ui show ImageFilter;
import 'package:home_app/services/provider/bluetooth_provider.dart';
import 'package:home_app/utils/error_handler.dart';
import 'package:home_app/utils/app_logger.dart';
import 'package:home_app/components/loading_overlay.dart';

class HomePage extends StatefulWidget {
  static const String route = '/home';

  const HomePage({super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool switchValue = false;
  late GlobalKey _globalKey;
  bool animate = false;
  late DeviceServices _deviceServices;
  WeatherServices weatherServices = WeatherServices();
  Weather weather = Weather(
    lat: 0.0,
    lon: 0.0,
    temp: Temp(value: 0.0),
    humidity: Humidity(value: 0.0),
    observationTime: ObservationTime(value: DateTime.now().toIso8601String()),
  );
  AuthServices authServices = AuthServices();
  bool _isLoading = false;

  getWeather() async {
    var data = await weatherServices.fetchData();
    setState(() {
      weather = data;
    });
  }

  @override
  void initState() {
    super.initState();
    _globalKey = GlobalKey();
    _deviceServices = DeviceServices(context.read<BluetoothProvider>());
    getWeather();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      final bluetoothProvider = context.read<BluetoothProvider>();
      final devicesProvider = context.read<DeviceProvider>();
      final collectionProvider = context.read<CollectionProvider>();

      // Initialize Bluetooth
      if (!bluetoothProvider.isInitialized) {
        await bluetoothProvider.initialize();
      }

      // Load devices and collections
      await Future.wait([
        devicesProvider.fetchDevices(),
        collectionProvider.loadCollections(),
      ]);
    } catch (e) {
      await AppLogger.logError(
          'Failed to initialize home page', e, StackTrace.current);
      ErrorHandler.showErrorSnackBar(
          context, 'Failed to initialize: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final devicesProvider = context.read<DeviceProvider>();
      final collectionProvider = context.read<CollectionProvider>();

      await Future.wait([
        devicesProvider.refreshDevices(),
        collectionProvider.refreshCollections(),
      ]);
    } catch (e) {
      await AppLogger.logError('Failed to refresh data', e, StackTrace.current);
      ErrorHandler.showErrorSnackBar(
          context, 'Failed to refresh: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: LayoutBuilder(
        builder: (context, constraints) => Scaffold(
          key: _globalKey,
          appBar: buildAppBar(context),
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: <Widget>[
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(22.0),
                      bottomLeft: Radius.circular(22.0),
                    ),
                  ),
                  child: Wrap(
                    direction: Axis.vertical,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    alignment: WrapAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 20.0, bottom: 0, left: 10),
                        child: Consumer<UserProvider>(
                          builder: (context, value, child) => Text(
                            'Hello, ${value.currentUser?.name ?? ''} ',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Text('Good to see you again',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: buildWeather(context),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  width: MediaQuery.of(context).size.width,
                  child: Wrap(
                    direction: Axis.horizontal,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(top: 10, left: 10),
                        child: Text(
                          'Scenes',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      buildScenes(context),
                      Container(
                        padding: const EdgeInsets.only(top: 0, left: 10),
                        child: Text(
                          'Rooms',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      buildRooms(context),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      actions: [
        Padding(
          padding: const EdgeInsets.only(top: 12.0, bottom: 12),
          child: RectIconButton(
              height: 32,
              width: 32,
              onPressed: () {
                showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (context) {
                    var width = MediaQuery.of(context).size.width;
                    var height = MediaQuery.of(context).size.height;
                    double buttonSize = 63;
                    return addDialogWidget(context, width, height, buttonSize);
                  },
                );
              },
              color: Colors.white,
              child: Image.asset(
                Assets.menuIcon,
                scale: 1.5,
              )),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _refreshData,
        ),
      ],
      leading: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          child: CircularIconButton(
            height: 32,
            width: 32,
            color: Colors.white,
            onPressed: _setting,
            child: Hero(
              tag: 'profile',
              child: Consumer<UserProvider>(
                builder: (context, value, child) => Container(
                  width: 32.0,
                  height: 32.0,
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.all(Radius.elliptical(16.0, 16.0)),
                    image: DecorationImage(
                      image: value.currentUser != null
                          ? NetworkImage('${value.currentUser?.picture}')
                          : const NetworkImage(
                              'https://celebmafia.com/wp-content/uploads/2017/04/scarlett-johansson-glamour-magazine-mexico-april-2017-issue-6.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget addDialogWidget(
      BuildContext context, double width, double height, double buttonSize) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
        child: GestureDetector(
          onTap: () {
            animate = false;
            Navigator.pop(context);
          },
          child: Container(
            width: width,
            height: height,
            decoration: const BoxDecoration(
              color: Color(0x57ffffff),
            ),
            child: Center(
              child: Stack(
                children: [
                  Center(
                      child: CircularIconButton(
                    onPressed: () {
                      animate = false;
                      Navigator.pop(context);
                    },
                    color: Colors.white,
                    height: buttonSize,
                    width: buttonSize,
                    child: const Icon(Icons.close),
                  )),
                  Positioned(
                      top: height * 0.5 - (buttonSize * 2),
                      left: width * 0.5 - (buttonSize / 2),
                      child: Center(
                          child: CircularIconButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(AddDevicePage.route);
                        },
                        color: Colors.white,
                        height: buttonSize,
                        width: buttonSize,
                        child: Center(
                            child: Text(
                          'Device',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppColors.textColor_light),
                        )),
                      ))),
                  Positioned(
                      top: height * 0.5 - (buttonSize / 2),
                      left: width * 0.5 - (buttonSize * 2),
                      child: Center(
                          child: CircularIconButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(AddRoomPage.route);
                        },
                        color: Colors.white,
                        height: buttonSize,
                        width: buttonSize,
                        child: Center(
                            child: Text(
                          'Room',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppColors.textColor_light),
                        )),
                      ))),
                  Positioned(
                      top: height * 0.5 - (buttonSize / 2),
                      right: width * 0.5 - (buttonSize * 2),
                      child: Center(
                          child: CircularIconButton(
                        onPressed: () async {
                          authServices.logout().then((value) {
                            Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (BuildContext context) =>
                                        const LoginPage()),
                                (Route<dynamic> route) => false);
                          }).catchError((onError) {
                            print(onError);
                          });
                        },
                        color: Colors.white,
                        height: buttonSize,
                        width: buttonSize,
                        child: Center(
                            child: Text(
                          'logout',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppColors.textColor_light),
                        )),
                      ))),
                  Positioned(
                      bottom: height * 0.5 - (buttonSize * 2),
                      left: width * 0.5 - (buttonSize / 2),
                      child: Center(
                          child: CircularIconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => SimpleDialog(
                              title: const Center(child: Text('Sorry🥺')),
                              children: [
                                Center(
                                    child: Text(
                                  ' This feature not work at this time',
                                  style: Theme.of(context).textTheme.titleSmall,
                                )),
                              ],
                            ),
                          );
                        },
                        color: Colors.white,
                        height: buttonSize,
                        width: buttonSize,
                        child: Center(
                            child: Text(
                          'Scene',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppColors.textColor_light),
                        )),
                      ))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildWeather(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
      child: Wrap(
        direction: Axis.horizontal,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          Wrap(
            direction: Axis.horizontal,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Consumer<ThemeChanger>(
                builder: (context, value, child) => CircularIconButton(
                  height: 32,
                  width: 32,
                  color: value.darkTheme
                      ? AppColors.iconsColorBackground2_dark
                      : AppColors.iconsColorBackground3_light,
                  child: Image.asset(
                    Assets.temperatureIcon,
                    color: value.darkTheme
                        ? AppColors.iconsColor_dark
                        : AppColors.iconsColorBackground2_dark,
                    scale: 1.5,
                  ),
                  onPressed: () {},
                ),
              ),
              Text(
                  // ignore: unnecessary_null_comparison
                  'Temperature ${weather.temp == null ? '' : weather.temp.value.floor()} C')
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Wrap(
              direction: Axis.horizontal,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Consumer<ThemeChanger>(
                  builder: (context, value, child) => CircularIconButton(
                    height: 32,
                    width: 32,
                    color: value.darkTheme
                        ? AppColors.iconsColorBackground3_dark
                        : AppColors.iconsColorBackground3_light,
                    child: Image.asset(
                      Assets.humidityIcon,
                      color: value.darkTheme
                          ? AppColors.iconsColor_dark
                          : AppColors.iconsColorBackground3_dark,
                      scale: 1.5,
                    ),
                    onPressed: () {},
                  ),
                ),
                Text('Humidity ${weather.humidity.value.floor()} %')
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRooms(BuildContext context) {
    return Consumer<CollectionProvider>(
      builder: (context, value, child) {
        return FutureBuilder(
          future: value.getCollections(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<Collection> rooms = snapshot.data as List<Collection>;
              return Container(
                height: MediaQuery.of(context).size.height * 0.42,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                width: MediaQuery.of(context).size.width,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: rooms.length + 1,
                  itemBuilder: (context, index) {
                    if (index == (snapshot.data as List<Collection>).length) {
                      return AddRoomCard(
                        onTap: _addRoom,
                      );
                    } else {
                      return RoomCard(
                        onPressed: () async {
                          Provider.of<DeviceProvider>(context, listen: false)
                              .setDevices(await _deviceServices.getDevicesByIds(
                                  (snapshot.data as List<Collection>)[index]
                                      .devices));
                          Provider.of<CollectionProvider>(context,
                                  listen: false)
                              .setCollection(
                                  (snapshot.data as List<Collection>)[index]);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RoomPage(
                                collection:
                                    (snapshot.data as List<Collection>)[index],
                              ),
                            ),
                          );
                        },
                        room: rooms[index],
                      );
                    }
                  },
                ),
              );
            } else {
              return Container(
                height: MediaQuery.of(context).size.height * 0.4,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                width: MediaQuery.of(context).size.width,
                child: Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Theme.of(context).primaryColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.surface),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget buildScenes(BuildContext context) {
    return Container(
      height: isLarge(context) ? 150 : 100,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      width: MediaQuery.of(context).size.width,
      child: ListView.builder(
        itemCount: scenes.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: MaterialButton(
            padding: const EdgeInsets.all(0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Center(child: Text('Sorry🥺')),
                  children: [
                    Center(
                        child: Text(
                      ' This feature not work at this time',
                      style: Theme.of(context).textTheme.titleSmall,
                    )),
                  ],
                ),
              );
            },
            child: Container(
              width: isLarge(context) ? 300 : 150,
              height: isLarge(context) ? 150 : 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                image: DecorationImage(
                  image: AssetImage(scenes[index].imagePath),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: scenes[index].shadowColor,
                    offset: const Offset(0, 0),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Center(
                  child: Text(
                'Night mode',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: Colors.white),
              )),
            ),
          ),
        ),
      ),
    );
  }

  void _setting() {
    Navigator.pushNamed(context, SettingsPage.route);
  }

  void _addRoom() {
    Navigator.pushNamed(context, AddRoomPage.route);
  }
}

class Scene {
  String imagePath;
  Color shadowColor;
  Scene({
    required this.imagePath,
    required this.shadowColor,
  });
}

List<Scene> scenes = [
  Scene(imagePath: Assets.nightImage, shadowColor: const Color(0xFF1C4276)),
  Scene(imagePath: Assets.morningImage, shadowColor: const Color(0xFFD2C6BD)),
  Scene(imagePath: Assets.eveningImage, shadowColor: const Color(0xFF7A4547)),
];
