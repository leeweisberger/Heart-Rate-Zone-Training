import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers.dart';

class ZonesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: new ZonesPage(),
    );
  }
}

class ZonesPage extends StatefulWidget {
  ZonesPage({Key key}) : super(key: key);

  @override
  _ZonesState createState() => new _ZonesState();
}

class _ZonesState extends State<ZonesPage> {
  int _maxHeartRate = DEFAULT_MAX_HEART_RATE;
  List<int> _zones = [];
  NumberPicker _numberPicker;

  void initState() {
    super.initState();
    setState(() {
      _numberPicker = new NumberPicker.integer(
          initialValue: _maxHeartRate,
          minValue: 150,
          maxValue: 210,
          onChanged: (newValue) => setState(() {
            _maxHeartRate = newValue;
            _zones = calculateZones(_maxHeartRate);
            _saveMaxHeartRate();
          }));
      _loadMaxHeartRate();
      _zones = calculateZones(_maxHeartRate);
    });
  }

  Widget _makeZoneRow(
      int zone, int lowerBound, int upperBound, String description) {
    return new Container(
        padding: EdgeInsets.only(bottom: 24.0),
        child: new Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.only(bottom: 8.0, top: 24.0),
                    child: Text(
                      'Zone $zone',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24.0,
                      ),
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              child: Text('$lowerBound - $upperBound',
                  style: TextStyle(fontSize: 24.0)),
            ),
          ],
        ));
  }

  _saveMaxHeartRate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(MAX_HEART_RATE, _maxHeartRate);
  }

  _loadMaxHeartRate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _maxHeartRate = prefs.getInt(MAX_HEART_RATE) ?? _maxHeartRate;
      this._numberPicker.animateInt(_maxHeartRate);
    });
  }

  NumberPicker _getNumberPicker() {
    this._numberPicker = new NumberPicker.integer(
        initialValue: _maxHeartRate,
        minValue: 150,
        maxValue: 210,
        onChanged: (newValue) => setState(() {
          _maxHeartRate = newValue;
          _zones = calculateZones(_maxHeartRate);
          _saveMaxHeartRate();
        }));
    return this._numberPicker;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text('Edit your zones'),
      ),
      body: new ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20.0),
        children: <Widget>[
          new Center(
            child: new Text(
              'Maximum heart rate',
              style: Theme.of(context).textTheme.display1,
            ),
          ),
          _getNumberPicker(),
          _makeZoneRow(
              1, _zones[0], _zones[1], 'booop bop smear uttit awef awefawef'),
          _makeZoneRow(
              2, _zones[1], _zones[2], 'booop bop smear uttit awef awefawef'),
          _makeZoneRow(
              3, _zones[2], _zones[3], 'booop bop smear uttit awef awefawef'),
          _makeZoneRow(4, _zones[3], _maxHeartRate,
              'booop bop smear uttit awef awefawef'),
        ],
      ),
    );
  }
}
