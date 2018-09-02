import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

class MonitorPickerScreen extends StatelessWidget {
  final StoredDevice connectedDevice;

  MonitorPickerScreen({Key key, this.connectedDevice}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: new MonitorPicker(connectedDevice: this.connectedDevice),
    );
  }
}

class MonitorPicker extends StatefulWidget {
  final StoredDevice connectedDevice;

  MonitorPicker({Key key, @required this.connectedDevice}) : super(key: key);

  @override
  _MonitorPickerState createState() => new _MonitorPickerState();
}

class StoredDevice {
  String id;
  String name;

  StoredDevice(this.id, this.name);
}

class _MonitorPickerState extends State<MonitorPicker> {
  BluetoothState _state = BluetoothState.UNKNOWN;
  StoredDevice _connectedDevice;
  Future<StoredDevice> _recentDevice;
  final List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  String _connectingDeviceId;

  @override
  void initState() {
    super.initState();
    FlutterBleLib.instance.state().then((state) {
      setState(() {
        this._state = state;
      });
    });
    // Subscribe to state changes
    FlutterBleLib.instance.onStateChange().listen((s) {
      setState(() {
        this._state = s;
      });
    });
    FlutterBleLib.instance.onDeviceConnectionChanged().listen((device) {
      setState(() {
        print('state changed to ${device.isConnected}');
        if (!device.isConnected &&
            this._connectedDevice != null &&
            this._connectedDevice.id == device.id) {
          // The connected device disconnected.
          print('device ${device.id} disconnected.');
          setState(() => this._connectedDevice = null);
        } else if (device.isConnected) {
          print('device ${device.id} connected.');
          setState(() => this._connectedDevice.id = device.id);
        }
      });
    });
    this._recentDevice = _loadRecentDevice();
    this._connectedDevice = widget.connectedDevice;
    _startScan();
  }

  @override
  void dispose() {
    super.dispose();
  }

  _addScanResult(ScanResult scanResultItem) {
    for (var scanResult in this._scanResults) {
      if (scanResult.hasTheSameDeviceAs(scanResultItem)) {
        scanResult.update(scanResultItem);
        return;
      }
    }
    this._scanResults.add(scanResultItem);
  }

  _saveRecentDevice(String deviceId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(RECENT_DEVICE_ID, deviceId);
  }

  Future<StoredDevice> _loadRecentDevice() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return new StoredDevice(
        prefs.getString(RECENT_DEVICE_ID), prefs.getString(RECENT_DEVICE_NAME));
  }

  _startScan() {
    scanForDevices().listen((scanResult) {
      setState(() {
        this._addScanResult(scanResult);
      });
      if (this._connectedDevice == null) {
        // Try to connect to the recent device.
        this._recentDevice.then((r) {
          if (r != null && r.id == scanResult.bleDevice.id) {
            this._connect(scanResult.bleDevice.id);
          }
        });
      }
      ;
    }, onDone: _stopScan);

    setState(() {
      this._isScanning = true;
    });
  }

  _stopScan() {
    setState(() => this._isScanning = false);
  }

  Future<BleDevice> _connect(String deviceId) async {
    setState(() => this._connectingDeviceId = deviceId);
    connectDevice(deviceId).then((device) {
      setState(() {
        print('Connected to ${device.name}');
        this._connectedDevice = new StoredDevice(device.id, device.name);
        this._connectingDeviceId = null;
      });
      this._saveRecentDevice(this._connectingDeviceId);
    }, onError: () => this._connectingDeviceId = null);
  }

  Widget _buildLeading(String deviceId) {
    if (this._connectedDevice != null && this._connectedDevice.id == deviceId) {
      return Icon(Icons.bluetooth_connected);
    } else if (this._connectingDeviceId != null &&
        this._connectingDeviceId == deviceId) {
      return CircularProgressIndicator();
    }
    return null;
  }

  Container _createTile(String name, String id) {
    return Container(
      child: ListTile(
        title: new Text(name),
        subtitle: new Text(id),
        leading: _buildLeading(id),
        onTap: () => (this._connectedDevice != null &&
                (id == this._connectedDevice.id ||
                    id == this._connectingDeviceId))
            ? null
            : this._connect(id),
      ),
      decoration:
          new BoxDecoration(border: new Border(bottom: new BorderSide())),
    );
  }

  _buildScanResultTiles() {
    final connectedDeviceAdded = false;
    final tiles = this
        ._scanResults
        .where((result) => result.bleDevice.name.isNotEmpty)
        .map((result) =>
            this._createTile(result.bleDevice.name, result.bleDevice.id))
        .toList();
    if (widget.connectedDevice != null &&
        !this._scanResults.any((scanResult) =>
            scanResult.bleDevice.id == widget.connectedDevice.id)) {
      // Add the passed in connected device.
      tiles.add(this
          ._createTile(widget.connectedDevice.name, widget.connectedDevice.id));
    }
    return tiles;
  }

  _buildAlertTile() {
    return new Container(
      color: Colors.redAccent,
      child: new ListTile(
        title: new Text(
          'Bluetooth is ${this._state.toString().substring(15)}',
          style: Theme.of(context).primaryTextTheme.subhead,
        ),
        trailing: new Icon(
          Icons.error,
          color: Theme.of(context).primaryTextTheme.subhead.color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var tiles = new List<Widget>();
    if (this._state != BluetoothState.POWERED_ON) {
      tiles.add(_buildAlertTile());
    } else {
      tiles.addAll(_buildScanResultTiles());
    }
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('Bluetooth Devices'),
          actions: <Widget>[
            new IconButton(
                icon: const Icon(Icons.refresh),
                onPressed:
                    this._state != BluetoothState.POWERED_ON || this._isScanning
                        ? null
                        : () => this._startScan()),
          ],
          leading: new IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context, this._connectedDevice)),
        ),
        body: new Stack(
          children: <Widget>[
            (this._isScanning)
                ? new LinearProgressIndicator()
                : new Container(),
            new ListView(children: tiles)
          ],
        ),
      ),
    );
  }
}
