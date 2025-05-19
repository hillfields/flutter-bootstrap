import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart' as app_settings;
// import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings.dart';

// define the main screen of the app
// this is a stateful widget - data can change over time
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addPost(String content) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('posts').add({
        'content': content,
        'userId': user.uid,
        'userEmail': user.email,
        'timestamp': FieldValue.serverTimestamp(),
        'displayName': await app_settings.Settings.getValue<String>(SettingsPage.keyDisplayName) ?? 'User',
      });
      _controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating post: $e'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting post: $e'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Posts",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            }
          )
        ]
      ),

      body: Container(
        margin: EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              flex: 90,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('posts')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final timestamp = data['timestamp'] as Timestamp?;
                      final date = timestamp != null 
                          ? DateFormat('MM/dd/yyyy HH:mm:ss').format(timestamp.toDate())
                          : 'Loading...';

                      return Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          color: Colors.blue,
                          child: Container(
                            margin: EdgeInsets.only(left: 10),
                            alignment: Alignment.center,
                            padding: EdgeInsets.all(10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundImage: AssetImage('assets/sadge.png'),
                                  radius: 35,
                                ),
                                SizedBox(width: 20),
                    
                                Expanded(
                                  flex: 80,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              data['displayName'] ?? 'User',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            )
                                          ),
                                          SizedBox(width: 10),
                    
                                          Text(
                                            date,
                                            style: TextStyle(
                                              color: Colors.white60,
                                              fontSize: 18,
                                            ),
                                          )
                                        ]
                                      ),
                    
                                      Text(
                                        data['content'] ?? '',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                        )
                                      )
                                    ]
                                  ),
                                ),
                    
                                IconButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Confirm post deletion'),
                                        content: Text('Are you sure you want to delete this post?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: Text('Cancel')
                                          ),
                    
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              deletePost(doc.id);
                                            },
                                            child: Text('Delete')
                                          )
                                        ]
                                      )
                                    );
                                  },

                                  icon: Container(
                                    padding: EdgeInsets.all(10),
                                    child: Icon(
                                      Icons.delete,
                                      size: 30,
                                      color: Colors.white,
                                    ),
                                  )
                                ),
                              ]
                            ),
                          )
                        ),
                      );
                    }
                  );
                }
              )
            ),

            SizedBox(height: 20),

            Expanded(
              flex: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: 70,
                    child: SizedBox(
                      height: 60,
                      child: TextFormField(
                        controller: _controller,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.blue,
                            )
                          ),
                          filled: true,

                          labelText: 'Write down your thoughts...',
                          labelStyle: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                          )
                        ),
                        keyboardType: TextInputType.multiline, // allow multiline input
                        maxLines: null,                        // allow the text box to grow
                      )
                    )
                  ),
                  SizedBox(width: 10),

                  FloatingActionButton(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    onPressed: () {
                      String input = _controller.text.trim();
                      if (input.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter at least 1 non-space character.'),
                            duration: Duration(seconds: 2),
                          )
                        );
                        return;
                      }
                      addPost(input);
                    },

                    child: Icon(Icons.send),
                  )
                ]
              )
            )
          ]
        )
      )
    );
  }
}