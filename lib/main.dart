// everything is a widget

// access Flutter's prebuilt widgets following Google's Material Design
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'settings.dart';

// run the app
Future main() async {
  await Settings.init();
  // load the widget called MyApp
  runApp(MyApp());
}

// create the root widget (first widget that gets shown)
// it is a stateless widget - data does not change
class MyApp extends StatelessWidget {
  // constructor (takes properties of StatelessWidget)
  const MyApp({super.key});

  // rewrite method from the parent class (StatelessWidget)
  // every widget that extends Stateless Widget must override the build() method
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),                // tell Flutter which screen to show first
      debugShowCheckedModeBanner: false, // remove debug banner
    );
  }
}

// define the main screen of the app
// this is a stateful widget - data can change over time
class HomeScreen extends StatefulWidget {
  // constructor (takes properties of StatefulWidget)
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, String>> postsList = [];
  final TextEditingController _controller = TextEditingController();
  int updateIndex = -1;

  addList(String task) {
    setState(() {
      postsList.add({
        'task': task,
        'date': DateFormat('MM/dd/yyyy HH:mm:ss').format(DateTime.now()),
      });
      _controller.clear();
    });
  }

  updateListItem(String task, int index) {
    setState(() {
      postsList[index]['task'] = task;
      updateIndex = -1;
      _controller.clear();
    });
  }

  deleteItem(index) {
    setState(() {
      postsList.removeAt(index);
    });
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
              child: ListView.builder(
                itemCount: postsList.length,
                itemBuilder: (context, index) {
                  final reversedIndex = postsList.length - 1 - index;
                  final item = postsList[reversedIndex];

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
                                        // display name
                                        child: ValueChangeObserver<String> (
                                          cacheKey: SettingsPage.keyDisplayName,
                                          defaultValue: 'User',
                                          builder: (context, value, _) => Text(
                                            value,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        )
                     
                                      ),
                                      SizedBox(width: 10),
                    
                                      // date
                                      Text(
                                        item['date'] ?? '',
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 18,
                                        ),
                                      )
                                    ]
                                  ),
                    
                                  // text
                                  Text(
                                    item['task'] ?? '',
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
                                          deleteItem(reversedIndex);
                                        },
                                        child: Text('Delete')
                                      )
                                    ]
                                  )
                                );
                              },
                              // icon: Icon(
                              //   Icons.delete,
                              //   size: 30,
                              //   color: Colors.white,
                              // ),
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
              )
            ),


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

                      updateIndex != -1
                        ? updateListItem(_controller.text, updateIndex)
                        : addList(_controller.text);
                    },

                    child: Icon(
                      updateIndex != -1
                      ? Icons.edit
                      : Icons.add
                    ),
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

