import 'package:flutter/material.dart';
import 'package:my_time_manager/data/models/models.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../data/database/database_manager.dart';

// void main() {
//   sqfliteFfiInit();
//   databaseFactory = databaseFactoryFfi;

//   runApp(MyApp());
// }

// import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = openDatabase(
    join(await getDatabasesPath(), 'my_database.db'),
    onCreate: (db, version) {
      db.execute(
        "CREATE TABLE lists(id INTEGER PRIMARY KEY, title TEXT)",
      );
      db.execute(
        "CREATE TABLE events(id INTEGER PRIMARY KEY, title TEXT, listId INTEGER, FOREIGN KEY (listId) REFERENCES lists(id) ON DELETE CASCADE)",
      );
      db.execute(
        "CREATE TABLE times(id INTEGER PRIMARY KEY, starttime TEXT, endtime TEXT, eventId INTEGER, FOREIGN KEY (eventId) REFERENCES events(id) ON DELETE CASCADE)",
      );
    },
    version: 1,
  );

  Future<void> insertList(EventList list) async {
    final Database db = await database;
    await db.insert(
      'lists',
      list.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteList(int id) async {
    final db = await database;
    await db.delete(
      'lists',
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<List<EventList>> lists() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('lists');
    return List.generate(maps.length, (i) {
      return EventList(
        id: maps[i]['id'],
        title: maps[i]['title'],
      );
    });
  }

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(MyApp(database: database, insertList: insertList, deleteList: deleteList, lists: lists));
}

class EventList {
  final int id;
  final String title;

  EventList({required this.id, required this.title});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
    };
  }
}

class MyApp extends StatelessWidget {
  final Future<Database> database;
  final Function insertList;
  final Function deleteList;
  final Function lists;

  MyApp({Key? key, required this.database, required this.insertList, required this.deleteList, required this.lists}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page', insertList: insertList, deleteList: deleteList, lists: lists),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title, required this.insertList, required this.deleteList, required this.lists}) : super(key: key);

  final String title;
  final Function insertList;
  final Function deleteList;
  final Function lists;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<EventList>> futureLists;

  @override
  void initState() {
    super.initState();
    futureLists = widget.lists();
  }

  void _addList() async {
    int count = (await widget.lists()).length;
    widget.insertList(EventList(id: count +1 , title: 'New List $count'));
    setState(() {
      futureLists = widget.lists();
    });
  }

  void _deleteList(int id) async {
    widget.deleteList(id);
    setState(() {
      futureLists = widget.lists();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: FutureBuilder<List<EventList>>(
          future: futureLists,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(snapshot.data![index].title),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteList(snapshot.data![index].id),
                      ),
                    );
                  });
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }
            return CircularProgressIndicator();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addList,
        tooltip: 'Add List',
        child: Icon(Icons.add),
      ),
    );
  }
}
