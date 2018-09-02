import 'package:flutter/material.dart';
import 'zones.dart';
import 'monitor_picker.dart';

Drawer createDrawer(BuildContext context) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        DrawerHeader(
          child: Text('Settings'),
          decoration: BoxDecoration(
            color: Colors.blue,
          ),
        ),
        ListTile(
          title: Text('Edit your zones'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ZonesScreen()),
            );
          },
        ),
        ListTile(
          title: Text('About'),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: Text('Settings'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MonitorPickerScreen()),
            );
          },
        ),
      ],
    ),
  );
}
