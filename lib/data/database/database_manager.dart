import 'package:my_time_manager/data/models/models.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseManager {
  // Singleton pattern
  static final DatabaseManager _databaseManager = DatabaseManager._internal();
  factory DatabaseManager() => _databaseManager;
  DatabaseManager._internal();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    // Initialize the DB first time it is accessed
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    final path = join(databasePath, 'app_database.db');

    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    return await openDatabase(
      path,
      onCreate: _onCreate,
      version: 1,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  // When the database is first created, create a table to store breeds
  // and a table to store dogs.

  Future<void> _onCreate(Database db, int version) async {
    // Run the CREATE {task lists} TABLE statement on the database.
    await db.execute(
      '''
      CREATE TABLE tasklists(
        id TEXT PRIMARY KEY, 
        title TEXT, 
        description TEXT)
      ''',
    );
    // Run the CREATE {tasks} TABLE statement on the database.
    await db.execute(
      '''
      CREATE TABLE tasks(
        id TEXT PRIMARY KEY, 
        title TEXT, 
        description TEXT, 
        color INTEGER,
        isCompleted INTEGER NOT NULL, 
        taskListId INTEGER, 
        FOREIGN KEY (taskListId) REFERENCES tasklists(id) ON DELETE SET NULL)
      ''',
    );
  }

  // Define a function that inserts task lists into the database
  Future<void> insertTaskList(TaskList taskList) async {
    // Get a reference to the database.
    final db = await _databaseManager.database;

    // Insert the task list into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same task lists is inserted twice.
    //
    // In this case, replace any previous data.
    await db.insert(
      'tasklists',
      taskList.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertTask(Task task) async {
    final db = await _databaseManager.database;
    await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // A method that retrieves all the task lists from the tasklists table.
  Future<List<TaskList>> taskLists() async {
    // Get a reference to the database.
    final db = await _databaseManager.database;

    // Query the table for all the TaskLists.
    final List<Map<String, dynamic>> maps = await db.query('tasklists');

    // Convert the List<Map<String, dynamic> into a List<TaskList>.
    return List.generate(maps.length, (index) => TaskList.fromMap(maps[index]));
  }

  Future<TaskList> taskList(String id) async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps =
        await db.query('tasklists', where: 'id = ?', whereArgs: [id]);
    return TaskList.fromMap(maps[0]);
  }

  Future<List<Task>> tasks() async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps = await db.query('tasks');
    return List.generate(maps.length, (index) => Task.fromMap(maps[index]));
  }

  // A method that updates a task list data from the tasklists table.
  Future<void> updateTaskList(TaskList taskList) async {
    // Get a reference to the database.
    final db = await _databaseManager.database;

    // Update the given task list
    await db.update(
      'tasklists',
      taskList.toMap(),
      // Ensure that the task list has a matching id.
      where: 'id = ?',
      // Pass the tasklist's id as a whereArg to prevent SQL injection.
      whereArgs: [taskList.id],
    );
  }

  Future<void> updateTask(Task task) async {
    final db = await _databaseManager.database;
    await db
        .update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }

  // A method that deletes a task list data from the tasklists table.
  Future<void> deleteTaskList(String id) async {
    // Get a reference to the database.
    final db = await _databaseManager.database;

    // Remove the task list from the database.
    await db.delete(
      'tasklists',
      // Use a `where` clause to delete a specific task list.
      where: 'id = ?',
      // Pass the tasklist's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
  }

  Future<void> deleteTask(String id) async {
    final db = await _databaseManager.database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
