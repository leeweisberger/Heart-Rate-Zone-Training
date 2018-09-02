import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';
import 'monitor_picker.dart';
import 'zones.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Heart Zone',
      theme: new ThemeData(
        primarySwatch: Colors.purple,
        accentColor: Colors.deepOrangeAccent,
      ),
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _heartRate = 0;
  int _zone = 0;
  int _maxHeartRate = DEFAULT_MAX_HEART_RATE;
  List<int> _zones = [];
  StoredDevice _connectedDevice;

  void initState() {
    super.initState();
    setState(() {
      _loadMaxHeartRate();
      _zones = calculateZones(_maxHeartRate);
    });
    FlutterBleLib.instance.createClient(null);

    FlutterBleLib.instance.onDeviceConnectionChanged().listen((device) {
      setState(() {
        if (this._connectedDevice != null &&
            this._connectedDevice.id == device.id) {
          // The connected device disconnected.
          print('device ${device.id} disconnected.');
          setState(() => this._connectedDevice = null);
        } else if (device.isConnected) {
          print('device ${device.id} connected.');
          setState(() => this._connectedDevice.id = device.id);
          this._readHeartRate();
        }
      });
    });

    _loadRecentDevice().then((storedDevice) {
      if (storedDevice != null && storedDevice.id != null) {
        connectDevice(storedDevice.id).then((device) {
          setState(() {
            print('Connected to ${device.name}');
            setState(() => this._connectedDevice.id = device.id);
          });
          this._readHeartRate();
        });
      }
    });
  }

  _loadMaxHeartRate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _maxHeartRate = prefs.getInt(MAX_HEART_RATE) ?? _maxHeartRate;
    _zones = calculateZones(_maxHeartRate);
  }

  Future<StoredDevice> _loadRecentDevice() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return new StoredDevice(
        prefs.getString(RECENT_DEVICE_ID), prefs.getString(RECENT_DEVICE_NAME));
  }

  _readHeartRate() async {
    if (this._connectedDevice == null) {
      return;
    }
    final heartRateStream = await getHeartRateStream(this._connectedDevice.id);
    if (heartRateStream != null) {
      heartRateStream.listen((data) {
        if (data.characteristic.value.length > 1) {
          setState(() => this._heartRate = data.characteristic.value[1]);
          int zone =
              this._zones.indexWhere((element) => this._heartRate > element);
          if (zone == -1) {
            zone = 0;
          }
          zone = zone + 1;
          if (zone != this._zone) {
            if (this._zone != 0) {
              playZoneNotification(zone);
            }
            setState(() => this._zone = zone);
          }
        }
      });
    }
  }

  _navigateToMonitorPicker(BuildContext context) async {
    Navigator
        .push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              MonitorPickerScreen(connectedDevice: this._connectedDevice)),
    )
        .then((connectedDevice) {
      this._connectedDevice = connectedDevice;
      this._readHeartRate();
    });
  }

  int _getCurrentZone() {}

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text('Heart zone'),
        actions: <Widget>[
          new IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ZonesScreen()),
                );
              }),
          new IconButton(
            icon: this._connectedDevice == null
                ? const Icon(Icons.bluetooth_disabled)
                : const Icon(Icons.bluetooth_connected),
            onPressed: () {
              FlutterBleLib.instance
                  .createClient(null)
                  .then((data) => this._navigateToMonitorPicker(context));
            },
          )
        ],
      ),
      body: new Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Text(
              '$_heartRate',
              style: Theme.of(context).textTheme.display4,
            ),
            new Text(
              'Zone $_zone',
              style: Theme.of(context).textTheme.display2,
            ),
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: () => playZoneNotification(1),
        child: new Icon(Icons.add),
      ),
    );
  }
}
