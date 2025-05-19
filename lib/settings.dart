import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class SettingsPage extends StatefulWidget {
  static const String keyDisplayName = 'key-display-name';

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _profilePictureUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
  }

  Future<void> _loadProfilePicture() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()?['profilePicture'] != null) {
        setState(() {
          _profilePictureUrl = doc.data()?['profilePicture'];
        });
      }
    } catch (e) {
      print('Error loading profile picture: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        // Upload to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('${user.uid}.jpg');

        await storageRef.putFile(File(image.path));
        final imageUrl = await storageRef.getDownloadURL();

        // Update Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'profilePicture': imageUrl,
        }, SetOptions(merge: true));

        setState(() {
          _profilePictureUrl = imageUrl;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture updated!'),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile picture: $e'),
          ),
        );
      }
    }
  }

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
        body: ListView(children: [
          SettingsGroup(title: 'Profile', children: <Widget>[
            ListTile(
              title: Text('Profile Picture'),
              subtitle: Text('Tap to change your profile picture'),
              leading: _isLoading
                  ? CircularProgressIndicator()
                  : CircleAvatar(
                      radius: 30,
                      backgroundImage: _profilePictureUrl != null
                          ? NetworkImage(_profilePictureUrl!)
                          : AssetImage('assets/sadge.png') as ImageProvider,
                    ),
              onTap: _pickImage,
            ),
            buildDisplayName(context),
          ]),
          SettingsGroup(
            title: 'Account',
            children: <Widget>[
              ListTile(
                title: Text('Logout'),
                trailing: Icon(Icons.logout),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Confirm Logout'),
                      content: Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            FirebaseAuth.instance.signOut();
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: Text('Logout'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ]));
  }

  Widget buildDisplayName(BuildContext context) {
    return TextInputSettingsTile(
        title: 'Display name',
        settingKey: SettingsPage.keyDisplayName,
        initialValue: 'User',
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Display name must be at least 1 non-space character.';
          }
          return null;
        },
        onChange: (value) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Display name updated to $value'),
            duration: Duration(seconds: 2),
          ));
        });
  }
}
