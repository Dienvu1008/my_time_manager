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

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'String List',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(title: 'String List'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //late DatabaseManager _databaseManager = DatabaseManager();
  late Database _database;
  late SharedPreferences _prefs;
  List<String>? _strings;
  //List<TaskList>? _taskLists;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'strings.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE strings(id INTEGER PRIMARY KEY, string TEXT)",
        );
      },
      version: 1,
    );
    _prefs = await SharedPreferences.getInstance();
    final strings = await _getStrings();
    final order = _prefs.getStringList('stringOrder');
    if (order != null) {
      strings.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
    }
    setState(() => _strings = strings);
  }

  Future<List<String>> _getStrings() async {
    final List<Map<String, dynamic>> maps =
        await _database.query('strings', orderBy: 'id');
    return List.generate(maps.length, (i) => maps[i]['string']);
  }

  Future<void> _addString(String string) async {
    await _database.insert('strings', {'string': string});
    setState(() => _strings!.add(string));
  }

  Future<void> _removeString(int index) async {
    await _database
        .delete('strings', where: 'string = ?', whereArgs: [_strings![index]]);
    setState(() => _strings!.removeAt(index));
  }

  void _reorderStrings(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final string = _strings!.removeAt(oldIndex);
    setState(() => _strings!.insert(newIndex, string));
    _prefs.setStringList('stringOrder', _strings!);
  }

  @override
  Widget build(BuildContext context) {
    if (_strings == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: StringsHolder(
        strings: _strings!,
        onReorder: _reorderStrings,
        onRemove: _removeString,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final string = await showDialog<String>(
            context: context,
            builder: (context) => AddStringDialog(),
          );
          if (string != null && string.isNotEmpty) {
            await _addString(string);
          }
        },
        tooltip: 'Add String',
        child: Icon(Icons.add),
      ),
    );
  }
}

class StringsHolder extends StatefulWidget {
  final List<String> strings;
  final Function(int, int) onReorder;
  final Function(int) onRemove;

  const StringsHolder({
    Key? key,
    required this.strings,
    required this.onReorder,
    required this.onRemove,
  }) : super(key: key);

  @override
  _StringsHolderState createState() => _StringsHolderState();
}

class _StringsHolderState extends State<StringsHolder> {
  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      onReorder: widget.onReorder,
      children: [
        for (var i = 0; i < widget.strings.length; i++)
          ListTile(
            key: ValueKey(widget.strings[i]),
            title: Text(widget.strings[i]),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => widget.onRemove(i),
            ),
          ),
      ],
    );
  }
}

class AddStringDialog extends StatefulWidget {
  @override
  _AddStringDialogState createState() => _AddStringDialogState();
}

class _AddStringDialogState extends State<AddStringDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add String'),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(hintText: 'Enter string'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text('Add'),
        ),
      ],
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

//void main() => runApp(MyApp());

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//         title: 'Flutter Demo',
//         theme: ThemeData(primarySwatch: Colors.blue),
//         home: MyHomePage(title: 'Nested Draggable List'));
//   }
// }

// class MyHomePage extends StatefulWidget {
//   MyHomePage({Key? key, required this.title}) : super(key: key);

//   final String title;

//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   final List<List<String>> _lists = [
//     ['A', 'B', 'C'],
//     ['D', 'E', 'F'],
//     ['G', 'H', 'I'],
//   ];

//   void _reorderList(int oldIndex, int newIndex) {
//     if (oldIndex < newIndex) newIndex -= 1;
//     final list = _lists.removeAt(oldIndex);
//     setState(() => _lists.insert(newIndex, list));
//   }

//   void _reorderItem(int listIndex, int oldIndex, int newIndex) {
//     if (oldIndex < newIndex) newIndex -= 1;
//     final item = _lists[listIndex].removeAt(oldIndex);
//     setState(() => _lists[listIndex].insert(newIndex, item));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.title)),
//       body: ReorderableListView.builder(
//         itemCount: _lists.length,
//         itemBuilder: (context, index) {
//           return Card(
//             key: ValueKey(_lists[index]),
//             child: Column(
//               children: [
//                 ListTile(title: Text('List $index')),
//                 ReorderableListView.builder(
//                   shrinkWrap: true,
//                   physics: NeverScrollableScrollPhysics(),
//                   itemCount: _lists[index].length,
//                   itemBuilder: (context, subIndex) {
//                     return ListTile(
//                       key: ValueKey(_lists[index][subIndex]),
//                       title: Text(_lists[index][subIndex]),
//                     );
//                   },
//                   onReorder: (oldIndex, newIndex) =>
//                       _reorderItem(index, oldIndex, newIndex),
//                 ),
//               ],
//             ),
//           );
//         },
//         onReorder: _reorderList,
//       ),
//     );
//   }
// }

// class _MyHomePageState extends State<MyHomePage> {
//   List<List<String>> _lists = [
//     ['A', 'B', 'C'],
//     ['D', 'E', 'F'],
//     ['G', 'H', 'I'],
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   // Load data from SharedPreferences
//   void _loadData() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       // Load parent list data
//       if (prefs.containsKey('parentList')) {
//         _lists = List<String>.from(prefs.getStringList('parentList')!)
//             .map((e) => e.split(',').toList())
//             .toList();
//       }
//     });
//   }

//   // Save data to SharedPreferences
//   void _saveData() async {
//     final prefs = await SharedPreferences.getInstance();
//     // Save parent list data
//     prefs.setStringList('parentList', _lists.map((e) => e.join(',')).toList());
//   }

//   void _reorderList(int oldIndex, int newIndex) {
//     if (oldIndex < newIndex) newIndex -= 1;
//     final list = _lists.removeAt(oldIndex);
//     setState(() {
//       _lists.insert(newIndex, list);
//       _saveData();
//     });
//   }

//   void _reorderItem(int listIndex, int oldIndex, int newIndex) {
//     if (oldIndex < newIndex) newIndex -= 1;
//     final item = _lists[listIndex].removeAt(oldIndex);
//     setState(() {
//       _lists[listIndex].insert(newIndex, item);
//       _saveData();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.title)),
//       body: ListView.builder(
//         itemCount: _lists.length,
//         itemBuilder: (context, index) {
//           return LongPressDraggable<int>(
//             data: index,
//             axis: Axis.vertical,
//             childWhenDragging: Container(),
//             feedback: ConstrainedBox(
//                 constraints: BoxConstraints(maxWidth: 200),
//                 child: Material(
//                   child: Card(
//                     child: Column(
//                       children: [
//                         ListTile(title: Text('List $index')),
//                         ReorderableListView.builder(
//                           shrinkWrap: true,
//                           physics: NeverScrollableScrollPhysics(),
//                           itemCount: _lists[index].length,
//                           itemBuilder: (context, subIndex) {
//                             return ListTile(
//                               key: ValueKey(_lists[index][subIndex]),
//                               title: Text(_lists[index][subIndex]),
//                             );
//                           },
//                           onReorder: (oldIndex, newIndex) =>
//                               _reorderItem(index, oldIndex, newIndex),
//                         ),
//                       ],
//                     ),
//                   ),
//                 )),
//             child: DragTarget<int>(
//               onAccept: (data) {
//                 setState(() {
//                   // Update the state of the list here
//                   _reorderList(data, index);
//                 });
//               },
//               // DragTarget<int>(
//               //   onAccept: (data) => _reorderList(data, index),
//               builder: (context, candidateData, rejectedData) {
//                 return Card(
//                   key: ValueKey(_lists[index]),
//                   child: Column(
//                     children: [
//                       ListTile(title: Text('List $index')),
//                       ReorderableListView.builder(
//                         shrinkWrap: true,
//                         physics: NeverScrollableScrollPhysics(),
//                         itemCount: _lists[index].length,
//                         itemBuilder: (context, subIndex) {
//                           return ListTile(
//                             key: ValueKey(_lists[index][subIndex]),
//                             title: Text(_lists[index][subIndex]),
//                           );
//                         },
//                         onReorder: (oldIndex, newIndex) =>
//                             _reorderItem(index, oldIndex, newIndex),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }


// class _MyHomePageState extends State<MyHomePage> {
//   final List<List<String>> _lists = [
//     ['A', 'B', 'C'],
//     ['D', 'E', 'F'],
//     ['G', 'H', 'I'],
//   ];

//   void _reorderList(int oldIndex, int newIndex) {
//     if (oldIndex < newIndex) newIndex -= 1;
//     final list = _lists.removeAt(oldIndex);
//     setState(() => _lists.insert(newIndex, list));
//   }

//   void _reorderItem(int listIndex, int oldIndex, int newIndex) {
//     if (oldIndex < newIndex) newIndex -= 1;
//     final item = _lists[listIndex].removeAt(oldIndex);
//     setState(() => _lists[listIndex].insert(newIndex, item));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.title)),
//       body: ListView.builder(
//         itemCount: _lists.length,
//         itemBuilder: (context, index) {
//           return LongPressDraggable<int>(
//             data: index,
//             axis: Axis.vertical,
//             childWhenDragging: Container(),
//             feedback: ConstrainedBox(
//                 constraints: BoxConstraints(maxWidth: 200),
//                 child: Material(
//                   child: Card(
//                     child: Column(
//                       children: [
//                         ListTile(title: Text('List $index')),
//                         ReorderableListView.builder(
//                           shrinkWrap: true,
//                           physics: NeverScrollableScrollPhysics(),
//                           itemCount: _lists[index].length,
//                           itemBuilder: (context, subIndex) {
//                             return ListTile(
//                               key: ValueKey(_lists[index][subIndex]),
//                               title: Text(_lists[index][subIndex]),
//                             );
//                           },
//                           onReorder: (oldIndex, newIndex) =>
//                               _reorderItem(index, oldIndex, newIndex),
//                         ),
//                       ],
//                     ),
//                   ),
//                 )),
//             child: DragTarget<int>(
//               onAccept: (data) => _reorderList(data, index),
//               builder: (context, candidateData, rejectedData) {
//                 return Card(
//                   key: ValueKey(_lists[index]),
//                   child: Column(
//                     children: [
//                       ListTile(title: Text('List $index')),
//                       ReorderableListView.builder(
//                         shrinkWrap: true,
//                         physics: NeverScrollableScrollPhysics(),
//                         itemCount: _lists[index].length,
//                         itemBuilder: (context, subIndex) {
//                           return ListTile(
//                             key: ValueKey(_lists[index][subIndex]),
//                             title: Text(_lists[index][subIndex]),
//                           );
//                         },
//                         onReorder: (oldIndex, newIndex) =>
//                             _reorderItem(index, oldIndex, newIndex),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }


// import 'package:flutter/material.dart';

// void main() => runApp(MyApp());

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//         title: 'Flutter Demo',
//         theme: ThemeData(primarySwatch: Colors.blue),
//         home: MyHomePage(title: 'Nested Draggable List'));
//   }
// }

// class MyHomePage extends StatefulWidget {
//   MyHomePage({Key? key, required this.title}) : super(key: key);

//   final String title;

//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   final List<List<String>> _lists = [
//     ['A', 'B', 'C'],
//     ['D', 'E', 'F'],
//     ['G', 'H', 'I'],
//   ];

//   void _reorderList(int oldIndex, int newIndex) {
//     if (oldIndex < newIndex) newIndex -= 1;
//     final list = _lists.removeAt(oldIndex);
//     setState(() => _lists.insert(newIndex, list));
//   }

//   void _reorderItem(int listIndex, int oldIndex, int newIndex) {
//     if (oldIndex < newIndex) newIndex -= 1;
//     final item = _lists[listIndex].removeAt(oldIndex);
//     setState(() => _lists[listIndex].insert(newIndex, item));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.title)),
//       body: ListView.builder(
//         itemCount: _lists.length,
//         itemBuilder: (context, index) {
//           return Card(
//             child: Column(
//               children: [
//                 ListTile(title: Text('List $index')),
//                 SizedBox(
//                   height: 200,
//                   child: ListView.builder(
//                     itemCount: _lists[index].length,
//                     itemBuilder: (context, subIndex) {
//                       return LongPressDraggable<String>(
//                         data: _lists[index][subIndex],
//                         childWhenDragging: Container(),
//                         feedback: ConstrainedBox(
//                           constraints: BoxConstraints(maxWidth: 200),
//                           child: Material(
//                             child: ListTile(
//                               title: Text(_lists[index][subIndex]),
//                             ),
//                           ),
//                         ),
//                         child: DragTarget<String>(
//                           onAccept: (data) {
//                             setState(() {
//                               final list =
//                                   _lists.firstWhere((l) => l.contains(data));
//                               list.remove(data);
//                               _lists[index].insert(subIndex, data);
//                             });
//                           },
//                           builder: (context, candidateData, rejectedData) {
//                             return ListTile(
//                               title: Text(_lists[index][subIndex]),
//                             );
//                           },
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

