import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings.dart';

// Define the main screen of the app
// This is a stateful widget, meaning that the data can change over time
class HomeScreen extends StatefulWidget {
  // Constructor
  const HomeScreen({super.key});

  // Create the state for the HomeScreen widget
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Initialize controllers and Firebase instance
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a post
  Future<void> addPost(String content) async {
    try {
      // Make sure the user is logged in
      final user = _auth.currentUser;
      if (user == null) return;

      // Add the post to the Firestore database
      await _firestore.collection('posts').add({
        'content': content,
        'userId': user.uid,
        'userEmail': user.email,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clear the text field once the post is created
      _controller.clear();
    } catch (e) {
      // Show error if post could not be created
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('The post could not be created: $e'),
        ),
      );
    }
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    try {
      // Delete the post from the Firestore database
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      // Show error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting post: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // Title with display name (e.g., Name's Posts)
        appBar: AppBar(
            // Retrieve display name from Firestore database
            title: StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(_auth.currentUser?.uid)
                  .snapshots(),
              
              // Build the title
              builder: (context, snapshot) {
                final displayName = snapshot.data?.get('displayName') as String? ?? 'Posts';
                return Text(
                  "$displayName's Posts",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                  ),
                );
              },
            ),
            automaticallyImplyLeading: false, // Don't show the back button
            centerTitle: true,
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            actions: [
              // Settings button
              IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsPage()),
                    );
                  })
            ]),
        body: Container(
            margin: EdgeInsets.all(20),
            child: Column(children: [
              Expanded(
                  flex: 90,
                  child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('posts')
                          .where('userId', isEqualTo: _auth.currentUser?.uid)
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
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
                                padding: EdgeInsets.only(bottom: 16),
                                child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    color: Colors.blue,
                                    child: Container(
                                      padding: EdgeInsets.all(12),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    date,
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    padding: EdgeInsets.zero,
                                                    constraints: BoxConstraints(),
                                                    onPressed: () {
                                                      showDialog(
                                                          context:
                                                              context,
                                                          builder: (context) =>
                                                              AlertDialog(
                                                                  title: Text('Confirm post deletion'),
                                                                  content: Text('Are you sure you want to delete this post?'),
                                                                  actions: [
                                                                    TextButton(
                                                                        onPressed: () => Navigator.of(context).pop(),
                                                                        child: Text('Cancel')),
                                                                    TextButton(
                                                                        onPressed: () {
                                                                          Navigator.of(context).pop();
                                                                          deletePost(doc.id);
                                                                        },
                                                                        child: Text('Delete'))
                                                                  ]));
                                                    },
                                                    icon: Icon(
                                                      Icons.delete,
                                                      size: 24,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ]),
                                            SizedBox(height: 6),
                                            Text(data['content'] ?? '',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                ))
                                          ]),
                                    )),
                              );
                            });
                      })),

              // Spacing above text input field
              SizedBox(height: 20),

              Expanded(
                  flex: 10,
                  child: Row(children: [
                    // Text input field for post
                    Expanded(
                        flex: 70,
                        child: SizedBox(
                            height: 60,
                            child: TextFormField(
                              controller: _controller,
                              decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.blue,
                                        width: 2,
                                      )),
                                  labelText: 'Write down your thoughts...',
                                  labelStyle: TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  )),
                              keyboardType: TextInputType.multiline, // Allow for multiline input
                              maxLines: null, // Allow the text box to grow
                            ))),
                    SizedBox(width: 10),

                    // Create post button
                    FloatingActionButton(
                      elevation: 0,
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      onPressed: () {
                        // Check if the text input is empty
                        String input = _controller.text.trim();
                        if (input.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Please enter at least 1 non-space character.'),
                            duration: Duration(seconds: 2),
                          ));
                          return;
                        }

                        // Create the post
                        addPost(input);
                      },
                      child: Icon(Icons.send),
                    )
                  ]))
            ])));
  }
}
