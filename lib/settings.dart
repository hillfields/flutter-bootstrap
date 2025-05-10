import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

class SettingsPage extends StatelessWidget {
  static const String keyDisplayName = 'key-display-name';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),

        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: ListView(
        children: [
          SettingsGroup(
            title: 'Profile',
            children: <Widget>[
              buildDisplayName(context),
            ]
          )
        ]
      )
    );
  }

  Widget buildDisplayName(BuildContext context) {
    return TextInputSettingsTile(
      title: 'Display name',
      settingKey: keyDisplayName,
      initialValue: 'User',
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Display name must be at least 1 non-space character.';
        }
        return null;
      },
      onChange: (value) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Display name updated to $value'),
            duration: Duration(seconds: 2),
          )
        );
      }
    );
  }
}