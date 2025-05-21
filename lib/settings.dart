import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart' as app_settings;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  // Store display name locally
  static const String keyDisplayName = 'key-display-name';

  // Constructor
  const SettingsPage({super.key});

  // Create the state for the SettingsPage widget
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Initialize controllers
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Initialize display name (default is User if it is not set)
  @override
  void initState() {
    super.initState();
    _displayNameController.text = app_settings.Settings.getValue<String>(SettingsPage.keyDisplayName) ?? 'User';
  }

  // Change password
  Future<void> _changePassword() async {
    // Check if the new password and confirm password inputs match
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    try {
      // Get the current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Reauthenticate user using current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(_newPasswordController.text);

      // Clear controllers
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      // Close the dialog and show password updated message
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password updated successfully')),
      );
    } catch (e) {
      // Show error message if password could not be changed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error changing password: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // Title
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
          // Profile settings
          app_settings.SettingsGroup(title: 'Profile', children: <Widget>[
            // Change display name option
            buildDisplayName(context),
          ]),

          // Account settings
          app_settings.SettingsGroup(
            title: 'Account',
            children: <Widget>[
              ListTile(
                // Change password option
                title: Text('Change Password'),
                leading: Icon(Icons.lock),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Change Password'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Current password input
                          TextField(
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Current Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                            ),
                            controller: _currentPasswordController,
                          ),
                          SizedBox(height: 16),

                          // New password input
                          TextField(
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'New Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                            ),
                            controller: _newPasswordController,
                          ),
                          SizedBox(height: 16),

                          // Confirm new password input
                          TextField(
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Confirm New Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                            ),
                            controller: _confirmPasswordController,
                          ),
                        ],
                      ),
                      actions: [
                        // Cancel button
                        TextButton(
                          onPressed: () {
                            // Clear all controllers
                            _currentPasswordController.clear();
                            _newPasswordController.clear();
                            _confirmPasswordController.clear();

                            // Close the dialog
                            Navigator.of(context).pop();
                          },
                          child: Text('Cancel'),
                        ),

                        // Change password button
                        TextButton(
                          onPressed: _changePassword,
                          child: Text('Change'),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Logout option
              ListTile(
                title: Text('Logout'),
                leading: Icon(Icons.logout),
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

  // Implement functionality for changing display name
  Widget buildDisplayName(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.person),
      title: Text('Display Name'),
      subtitle: Text('Change your display name'),
      onTap: () {
        // Show dialog to change display name
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Change Display Name'),
            content: TextField(
              decoration: InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.blue,
                    width: 2,
                  ),
                ),
              ),
              controller: _displayNameController,
            ),
            actions: [
              // Cancel button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),

              // Save button
              TextButton(
                onPressed: () async {
                  // Check if the new display name is not empty (merge: true)
                  final newName = _displayNameController.text.trim();
                  if (newName.isNotEmpty) {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    try {
                      // Update Firestore database first
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .set({'displayName': newName}, SetOptions(merge: true));
                            
                        // Update local settings after successful Firestore update
                        app_settings.Settings.setValue<String>(SettingsPage.keyDisplayName, newName);

                        if (!mounted) return;
                        Navigator.of(context).pop();
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Display name updated to $newName')),
                        );
                      }
                    } catch (e) {
                      if (!mounted) return;
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Error updating display name: $e')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Display name cannot be empty')),
                    );
                  }
                },
                child: Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }
}
