import 'package:flutter/material.dart';
import 'package:home_app/components/show_loading.dart';
import 'package:home_app/screens/home_page.dart';
import 'package:home_app/services/ap_mode/add_device_services.dart';
import 'package:home_app/theme/theme_changer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue/flutter_blue.dart';

///Add new device with AP mode
class AddDevicePage2 extends StatefulWidget {
  const AddDevicePage2({super.key});

  @override
  _AddDevicePage2State createState() => _AddDevicePage2State();
}

class _AddDevicePage2State extends State<AddDevicePage2> {
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _devicePasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final APModeServices _apModeServices = APModeServices();
  FlutterBlue flutterBlue = FlutterBlue.instance;

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    // Initialize Bluetooth if necessary
    // For example, start scanning for devices
    flutterBlue.startScan(timeout: const Duration(seconds: 4));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        iconTheme: Theme.of(context).iconTheme,
        elevation: 0,
        title: Text(
          'Add device',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: Colors.white),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(12.0),
          child: MaterialButton(
            onPressed: () => Navigator.pop(context),
            padding: const EdgeInsets.all(0),
            minWidth: 32,
            height: 32,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.elliptical(16.0, 16.0)),
            ),
            child: const Center(
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
      body: Consumer<ThemeChanger>(
        builder: (context, theme, child) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                  ),
                  child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Theme.of(context).cardColor,
                      ),
                      child: tut()),
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 250,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Theme.of(context).cardColor,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: form(),
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: MaterialButton(
        height: 45,
        minWidth: 120,
        elevation: 0,
        color: Theme.of(context).colorScheme.secondary,
        onPressed: sendData,
        child: Text(
          'Next',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }

  Widget form() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _deviceNameController,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              hintText: 'Device Name',
              hintStyle: Theme.of(context).textTheme.titleMedium,
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Please enter device name';
              }
              return null;
            },
          ),
          const SizedBox(
            height: 20,
          ),
          TextFormField(
            keyboardType: TextInputType.visiblePassword,
            controller: _devicePasswordController,
            obscureText: true,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              hintText: 'Device Password',
              hintStyle: Theme.of(context).textTheme.titleMedium,
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Please enter device password';
              } else if (val.length < 6) {
                return 'Password needs to be at least 6 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget tut() {
    var textTheme = Theme.of(context).textTheme.titleLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '1. Enter your device name',
            style: textTheme,
          ),
          Text(
            '2. Enter your device password',
            style: textTheme,
          ),
          Text(
            '3. Click Next',
            style: textTheme,
          ),
        ],
      ),
    );
  }

  sendData() async {
    final formState = _formKey.currentState;
    if (formState!.validate()) {
      formState.save();
      try {
        showLoading(context);
        var res = await _apModeServices.sendData(
          _deviceNameController.text,
          _devicePasswordController.text,
        );
        Navigator.pop(context); // Close the loading dialog
        if (res) {
          Navigator.pushReplacementNamed(context, HomePage.route);
        } else {
          showError();
        }
      } catch (e) {
        Navigator.pop(context); // Close the loading dialog
        showError();
      }
    }
  }

  showError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Ok'),
          )
        ],
        title: const Center(
          child: Text(
            'Error',
          ),
        ),
        content: const Text(
            'Oh no!🤦‍♂️ can\'t add device, please make sure you connect to the device'),
        contentTextStyle: const TextStyle(color: Colors.black),
      ),
    );
  }
}
