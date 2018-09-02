import 'dart:async';

import 'package:audioplayers/audio_cache.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:uuid/uuid.dart';

List<int> calculateZones(int maxHeartRate) {
  return [
    (maxHeartRate * .6).ceil(),
    (maxHeartRate * .7).ceil(),
    (maxHeartRate * .8).ceil(),
    (maxHeartRate * .9).ceil()
  ];
}

playZoneNotification(int zone) async {
  AudioCache audioCache = new AudioCache();
  audioCache.play('zone$zone.mp3');
}

Future<BleDevice> connectDevice(String deviceId) async {
//  if (await isDeviceConnected(deviceId)) {
//    return null;
//  }
  return FlutterBleLib.instance.connectToDevice(deviceId, isAutoConnect: true);
}

Stream<ScanResult> scanForDevices() {
  return FlutterBleLib.instance.startDeviceScan(1, 1, null);
}

Future<bool> isDeviceConnected(String deviceId) async {
  return FlutterBleLib.instance.isDeviceConnected(deviceId);
}

Future<Stream<MonitorCharacteristic>> getHeartRateStream(
    String deviceId) async {
  final device = await FlutterBleLib.instance
      .discoverAllServicesAndCharacteristicsForDevice(deviceId);
  final services = await FlutterBleLib.instance.servicesForDevice(device.id);
  final heartRateService =
      services.firstWhere((element) => element.uuid.contains('180d'));
  if (heartRateService == null) {
    return null;
  }
  final characteristics = await FlutterBleLib.instance
      .characteristicsForService(heartRateService.id);
  final heartRateCharacteristic = characteristics.firstWhere(
      (characteristic) => characteristic.uuid.contains('2a37'),
      orElse: null);
  if (heartRateCharacteristic == null) {
    return null;
  }
  return FlutterBleLib.instance
      .monitorCharacteristic(heartRateCharacteristic.id, Uuid().v1());
}
//  FlutterBleLib.instance.
//  return FlutterBleLib.instance
//      .discoverAllServicesAndCharacteristicsForDevice(deviceId)
//      .then((device) =>
//          FlutterBleLib.instance.servicesForDevice(device.id).then((services) {
//            final heartRateService =
//                services.firstWhere((element) => element.uuid.contains('180d'));
//            FlutterBleLib.instance
//                .characteristicsForService(heartRateService.id)
//                .then((characteristics) {
//              final heartRateCharacteristic = characteristics.firstWhere(
//                  (characteristic) => characteristic.uuid.contains('2A37'));
//              return FlutterBleLib.instance.monitorCharacteristicForService(
//                  heartRateService.id, heartRateCharacteristic.uuid, 'foo');
//            });
//          }));

//Stream<MonitorCharacteristic> readHeartRate(Characteristic characteristic) {
//  FlutterBleLib.instance.monitorCharacteristicForService(
//      _bleService.device.id,
//      _bleService.uuid,
//      characteristic.uuid,
//      new Uuid().v1())
//      .listen((value) => _action(value.characteristic.value))
//  ;
//}

//Future<BluetoothCharacteristic> getHeartRateCharacteristic(BluetoothDevice d) {
//  return d.discoverServices().then((services) {
//    print(services);
//    final heartService = services.firstWhere((service) =>
//    service.uuid.toMac() == '00:00:18:0D:00:00');
//    if (heartService != null) {
//      return heartService.characteristics.firstWhere((characteristic) =>
//      characteristic.uuid.toMac() == '00:00:2A:37:00:00');
//    }
//    return null;
//  });
//}

String MAX_HEART_RATE = 'MAX_HEART_RATE';
int DEFAULT_MAX_HEART_RATE = 190;
String RECENT_DEVICE_ID = 'RECENT_DEVICE_ID';
String RECENT_DEVICE_NAME = 'RECENT_DEVICE_NAME';
String RESTORE_ID = 'RESTORE_ID';
