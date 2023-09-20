import 'package:my_time_manager/data/models/model_list.dart';
import 'package:my_time_manager/data/models/model_measurable_task.dart';
import 'package:my_time_manager/data/models/model_task.dart';
import 'package:my_time_manager/data/models/model_task_with_subtasks.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
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

//ON DELETE CASCADE doesn't work right. Why????
  Future<void> _onCreate(Database db, int version) async {
    // Run the CREATE {task lists} TABLE statement on the database.
    // await db.execute(
    //   '''
    //   CREATE TABLE tasklists (
    //     id TEXT PRIMARY KEY,
    //     title TEXT,
    //     description TEXT,
    //     color INTEGER,
    //     dataFiles TEXT,
    //     updateTimeStamp TEXT
    //     )
    //   ''',
    // );
    await onCreateTableTaskLists(db);
    await onCreateTableTasks(db);
    await onCreateTableMeasurableTasks(db);
    await onCreateTableTasksWithSubtasks(db);
    await onCreateTableEvents(db);
    await onCreateTableTimeIntervals(db);

    // Run the CREATE {tasks} TABLE statement on the database.
    // await db.execute(
    //   '''
    //   CREATE TABLE tasks (
    //     id TEXT PRIMARY KEY,
    //     taskListId TEXT,
    //     isCompleted INTEGER NOT NULL,
    //     isImportant INTEGER NOT NULL,  
    //     title TEXT, 
    //     description TEXT,
    //     location TEXT, 
    //     color INTEGER,
    //     tags TEXT,
    //     dataFiles TEXT,
    //     updateTimeStamp TEXT, 
    //     FOREIGN KEY (taskListId) REFERENCES tasklists(id) ON DELETE CASCADE)
    //   ''',
    // );

    // await db.execute(
    //   '''
    //   CREATE TABLE measurabletasks (
    //     id TEXT PRIMARY KEY,
    //     taskListId TEXT,
    //     isCompleted INTEGER NOT NULL,
    //     isImportant INTEGER NOT NULL,  
    //     title TEXT, 
    //     description TEXT,
    //     location TEXT, 
    //     color INTEGER,
    //     targetAtLeast REAL,
    //     targetAtMost REAL,
    //     targetType INTEGER NOT NULL,
    //     howMuchHasBeenDone REAL,
    //     unit TEXT,
    //     tags TEXT,
    //     dataFiles TEXT,
    //     updateTimeStamp TEXT, 
    //     FOREIGN KEY (taskListId) REFERENCES tasklists(id) ON DELETE CASCADE)
    //   ''',
    // );

    // await db.execute(
    //   '''
    //   CREATE TABLE taskswithsubtasks (
    //     id TEXT PRIMARY KEY,
    //     taskListId TEXT,
    //     title TEXT,
    //     description TEXT,
    //     location TEXT,
    //     color INTEGER,
    //     isCompleted INTEGER NOT NULL,
    //     isImportant INTEGER NOT NULL,
    //     subtasks TEXT,
    //     dataFiles TEXT,
    //     updateTimeStamp TEXT,
    //     FOREIGN KEY (taskListId) REFERENCES tasklists(id) ON DELETE CASCADE)
    //   ''',
    // );

    // await db.execute(
    //   '''
    //   CREATE TABLE events (
    //     id TEXT PRIMARY KEY,
    //     taskListId TEXT,
    //     title TEXT, 
    //     description TEXT,
    //     location TEXT, 
    //     color INTEGER,
    //     startTimeStamp INTEGER,
    //     endTimeStamp INTEGER,
    //     tags TEXT,
    //     dataFiles TEXT,
    //     updateTimeStamp TEXT, 
    //     FOREIGN KEY (taskListId) REFERENCES tasklists(id) ON DELETE CASCADE)
    //   ''',
    // );

    // await db.execute(
    //   '''
    // CREATE TABLE timeintervals (
    //   id TEXT PRIMARY KEY,
    //   isCompleted INTEGER NOT NULL,
    //   taskId TEXT,
    //   measurableTaskId TEXT,
    //   taskWithSubtasksId TEXT,
    //   location TEXT,
    //   color INTEGER,
    //   title TEXT, 
    //   notes TEXT,
    //   startDate TEXT,
    //   endDate TEXT,
    //   startTime INTEGER,
    //   endTime INTEGER,
    //   isStartDateUndefined INTEGER NOT NULL,
    //   isEndDateUndefined INTEGER NOT NULL,
    //   isStartTimeUndefined INTEGER NOT NULL,
    //   isEndTimeUndefined INTEGER NOT NULL,
    //   targetAtLeast REAL,
    //   targetAtMost REAL,
    //   targetType INTEGER,
    //   unit TEXT,
    //   howMuchHasBeenDone REAL,
    //   subtasks TEXT,
    //   dataFiles TEXT,
    //   updateTimeStamp TEXT,
    //   timeZone TEXT,
    //   FOREIGN KEY (taskId) REFERENCES tasks(id) ON DELETE CASCADE,
    //   FOREIGN KEY (measurableTaskId) REFERENCES measurabletasks(id) ON DELETE CASCADE,
    //   FOREIGN KEY (taskWithSubtasksId) REFERENCES taskswithsubtasks(id) ON DELETE CASCADE)
    // ''',
    // );

    await db.execute('''
  CREATE TRIGGER update_timeintervals_of_task_title_color
  AFTER UPDATE OF title, color ON tasks
  BEGIN
    UPDATE timeintervals
    SET title = NEW.title, color = NEW.color
    WHERE taskId = OLD.id;
  END;
''');

    await db.execute('''
  CREATE TRIGGER update_timeintervals_of_measurableTask_title_color
  AFTER UPDATE OF title, color ON measurabletasks
  BEGIN
    UPDATE timeintervals
    SET title = NEW.title, color = NEW.color
    WHERE measurableTaskId = OLD.id;
  END;
''');

    await db.execute('''
  CREATE TRIGGER update_timeintervals_of_taskWithSubtasks_title_color
  AFTER UPDATE OF title, color ON taskswithsubtasks
  BEGIN
    UPDATE timeintervals
    SET title = NEW.title, color = NEW.color
    WHERE taskWithSubtasksId = OLD.id;
  END;
''');

    await db.execute('''
  CREATE TRIGGER delete_timeintervals_of_task
  AFTER DELETE ON tasks
  BEGIN
    DELETE FROM timeintervals
    WHERE taskId = OLD.id;
  END;
''');

    await db.execute('''
  CREATE TRIGGER delete_timeintervals_of_measurableTask
  AFTER DELETE ON measurabletasks
  BEGIN
    DELETE FROM timeintervals
    WHERE measurableTaskId = OLD.id;
  END;
''');

    await db.execute('''
  CREATE TRIGGER delete_timeintervals_of_taskWithSubtasks
  AFTER DELETE ON taskswithsubtasks
  BEGIN
    DELETE FROM timeintervals
    WHERE taskWithSubtasksId = OLD.id;
  END;
''');

    //_addSampleData();
  }

  Future<void> _addSampleData() async {
    final db = await _initDatabase();

    await db.insert(
      'tasklists',
      {'id': 'a', 'title': 'work', 'description': ''},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert(
      'tasklists',
      {'id': 'b', 'title': 'habit tracking', 'description': ''},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    for (int i = 1; i <= 100; i++) {
      await db.insert(
        'tasks',
        {
          'id': 'a$i',
          'title': 'Task $i',
          'description': 'Description for task $i',
          'color': 0xFF0000FF,
          'isCompleted': 0,
          'taskListId': 'a',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> deleteDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'app_database.db');
    await databaseFactory.deleteDatabase(path);
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
    printTasks();
  }

  Future<void> insertMeasurableTask(MeasurableTask measurableTask) async {
    final db = await _databaseManager.database;
    await db.insert(
      'measurabletasks',
      measurableTask.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertTaskWithSubtasks(TaskWithSubtasks taskWithSubtasks) async {
    final db = await _databaseManager.database;
    await db.insert(
      'taskswithsubtasks',
      taskWithSubtasks.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertTimeInterval(TimeInterval timeInterval) async {
    final db = await _databaseManager.database;
    await db.insert(
      'timeintervals',
      timeInterval.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    printTimeIntervals();
  }

  Future<void> insertEvent(Event event) async {
    final db = await _databaseManager.database;
    await db.insert(
      'events',
      event.toMap(),
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

  Future<List<Task>> tasks() async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps = await db.query('tasks');
    return List.generate(maps.length, (index) => Task.fromMap(maps[index]));
  }

  Future<List<MeasurableTask>> measurableTasks() async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps = await db.query('measurabletasks');
    return List.generate(
        maps.length, (index) => MeasurableTask.fromMap(maps[index]));
  }

  Future<List<TaskWithSubtasks>> tasksWithSubtasks() async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps = await db.query('taskswithsubtasks');
    return List.generate(
        maps.length, (index) => TaskWithSubtasks.fromMap(maps[index]));
  }

  Future<List<TimeInterval>> timeIntervals() async {
    // Get a reference to the database.
    final db = await _databaseManager.database;

    // Query the table for all the time intervals.
    final List<Map<String, dynamic>> maps = await db.query('timeintervals');

    // Convert the List<Map<String, dynamic> into a List<TaskList>.
    return List.generate(
        maps.length, (index) => TimeInterval.fromMap(maps[index]));
  }

  Future<List<Event>> events() async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps = await db.query('events');
    return List.generate(maps.length, (index) => Event.fromMap(maps[index]));
  }

  Future<TaskList> taskList(String id) async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps =
        await db.query('tasklists', where: 'id = ?', whereArgs: [id]);
    return TaskList.fromMap(maps[0]);
  }

  Future<Task> task(String id) async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps =
        await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    return Task.fromMap(maps[0]);
  }

  Future<MeasurableTask> measurableTask(String id) async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps =
        await db.query('measurabletasks', where: 'id = ?', whereArgs: [id]);
    return MeasurableTask.fromMap(maps[0]);
  }

  Future<TaskWithSubtasks> taskWithSubtasks(String id) async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps =
        await db.query('taskswithsubtasks', where: 'id = ?', whereArgs: [id]);
    return TaskWithSubtasks.fromMap(maps[0]);
  }

  Future<Event> event(String id) async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps =
        await db.query('events', where: 'id = ?', whereArgs: [id]);
    return Event.fromMap(maps[0]);
  }

    Future<TimeInterval> timeInterval(String id) async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps =
        await db.query('timeintervals', where: 'id = ?', whereArgs: [id]);
    return TimeInterval.fromMap(maps[0]);
  }

  Future<List<Task>> tasksOfTaskList(String taskListId) async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'taskListId = ?',
      whereArgs: [taskListId],
    );
    return List.generate(maps.length, (index) => Task.fromMap(maps[index]));
  }

  Future<List<MeasurableTask>> measurableTasksOfTaskList(
      String taskListId) async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'measurabletasks',
      where: 'taskListId = ?',
      whereArgs: [taskListId],
    );
    return List.generate(
        maps.length, (index) => MeasurableTask.fromMap(maps[index]));
  }

  Future<List<TaskWithSubtasks>> tasksWithSubtasksOfTaskList(
      String taskListId) async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'taskswithsubtasks',
      where: 'taskListId = ?',
      whereArgs: [taskListId],
    );
    return List.generate(
        maps.length, (index) => TaskWithSubtasks.fromMap(maps[index]));
  }

  Future<List<Event>> eventsOfTaskList(String taskListId) async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'taskListId = ?',
      whereArgs: [taskListId],
    );
    return List.generate(maps.length, (index) => Event.fromMap(maps[index]));
  }

  Future<List<TimeInterval>> timeIntervalsOfTask(String taskId) async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'timeintervals',
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
    return List.generate(
        maps.length, (index) => TimeInterval.fromMap(maps[index]));
  }

  Future<List<TimeInterval>> timeIntervalsOfMeasureableTask(
      String measurableTaskId) async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'timeintervals',
      where: 'measurableTaskId = ?',
      whereArgs: [measurableTaskId],
    );
    return List.generate(
        maps.length, (index) => TimeInterval.fromMap(maps[index]));
  }

  Future<List<TimeInterval>> timeIntervalsOfTaskWithSubtasks(
      String taskWithSubtasksId) async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'timeintervals',
      where: 'taskWithSubtasksId = ?',
      whereArgs: [taskWithSubtasksId],
    );
    return List.generate(
        maps.length, (index) => TimeInterval.fromMap(maps[index]));
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
    print('Updating task with id: ${task.id}');
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    print('Task updated');
    printTasks();
    printTimeIntervals();
  }

  Future<void> updateMeasurableTask(MeasurableTask measurableTask) async {
    final db = await _databaseManager.database;
    await db.update(
      'measurabletasks',
      measurableTask.toMap(),
      where: 'id = ?',
      whereArgs: [measurableTask.id],
    );
  }

  Future<void> updateTaskWithSubtasks(TaskWithSubtasks taskWithSubtasks) async {
    final db = await _databaseManager.database;
    await db.update(
      'taskswithsubtasks',
      taskWithSubtasks.toMap(),
      where: 'id = ?',
      whereArgs: [taskWithSubtasks.id],
    );
  }

  Future<void> updateEvent(Event event) async {
    final db = await _databaseManager.database;
    await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<void> updateTimeInterval(TimeInterval timeInterval) async {
    final db = await _databaseManager.database;
    await db.update(
      'timeintervals',
      timeInterval.toMap(),
      where: 'id = ?',
      whereArgs: [timeInterval.id],
    );
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
    printTasks();
  }

  Future<void> deleteTask(String id) async {
    final db = await _databaseManager.database;

    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    printTimeIntervals();
  }

  Future<void> deleteMeasurableTask(String id) async {
    final db = await _databaseManager.database;

    await db.delete('measurabletasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteTaskWithSubtasks(String id) async {
    final db = await _databaseManager.database;

    await db.delete('taskswithsubtasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteEvent(String id) async {
    final db = await _databaseManager.database;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteTimeInterval(String id) async {
    final db = await _databaseManager.database;
    await db.delete('timeintervals', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> printTimeIntervals() async {
    final db = await _databaseManager.database;
    List<Map> result = await db.query('timeintervals');
    for (var row in result) {
      print(row);
    }
  }

  Future<void> printTasks() async {
    final db = await _databaseManager.database;
    List<Map> result = await db.query('tasks');
    for (var row in result) {
      print(row);
    }
  }

  Future<void> onCreateTableTaskLists(Database db) async {
    // Run the CREATE {task lists} TABLE statement on the database.
    await db.execute(
      '''
    CREATE TABLE tasklists (
      id TEXT PRIMARY KEY, 
      title TEXT,
      description TEXT,
      color INTEGER,
      dataFiles TEXT,
      updateTimeStamp TEXT
      )
    ''',
    );
  }

  Future<void> onCreateTableTasks(Database db) async {
    // Run the CREATE {tasks} TABLE statement on the database.
    await db.execute(
      '''
    CREATE TABLE tasks (
      id TEXT PRIMARY KEY,
      taskListId TEXT,
      isCompleted INTEGER NOT NULL,
      isImportant INTEGER NOT NULL,  
      title TEXT, 
      description TEXT,
      location TEXT, 
      color INTEGER,
      tags TEXT,
      dataFiles TEXT,
      updateTimeStamp TEXT, 
      FOREIGN KEY (taskListId) REFERENCES tasklists(id) ON DELETE CASCADE)
    ''',
    );
  }

  Future<void> onCreateTableMeasurableTasks(Database db) async {
    // Run the CREATE {task lists} TABLE statement on the database.
    await db.execute(
      '''
      CREATE TABLE measurabletasks (
        id TEXT PRIMARY KEY,
        taskListId TEXT,
        isCompleted INTEGER NOT NULL,
        isImportant INTEGER NOT NULL,  
        title TEXT, 
        description TEXT,
        location TEXT, 
        color INTEGER,
        targetAtLeast REAL,
        targetAtMost REAL,
        targetType INTEGER NOT NULL,
        howMuchHasBeenDone REAL,
        unit TEXT,
        tags TEXT,
        dataFiles TEXT,
        updateTimeStamp TEXT, 
        FOREIGN KEY (taskListId) REFERENCES tasklists(id) ON DELETE CASCADE)
      ''',
    );
  }

  Future<void> onCreateTableTasksWithSubtasks(Database db) async {
    // Run the CREATE {task lists} TABLE statement on the database.
    await db.execute(
      '''
      CREATE TABLE taskswithsubtasks (
        id TEXT PRIMARY KEY,
        taskListId TEXT,
        title TEXT,
        description TEXT,
        location TEXT,
        color INTEGER,
        isCompleted INTEGER NOT NULL,
        isImportant INTEGER NOT NULL,
        subtasks TEXT,
        dataFiles TEXT,
        updateTimeStamp TEXT,
        FOREIGN KEY (taskListId) REFERENCES tasklists(id) ON DELETE CASCADE)
      ''',
    );
  }

  Future<void> onCreateTableEvents(Database db) async {
    // Run the CREATE {task lists} TABLE statement on the database.
    await db.execute(
      '''
      CREATE TABLE events (
        id TEXT PRIMARY KEY,
        taskListId TEXT,
        title TEXT, 
        description TEXT,
        location TEXT, 
        color INTEGER,
        startTimeStamp INTEGER,
        endTimeStamp INTEGER,
        tags TEXT,
        dataFiles TEXT,
        updateTimeStamp TEXT, 
        FOREIGN KEY (taskListId) REFERENCES tasklists(id) ON DELETE CASCADE)
      ''',
    );
  }

  Future<void> onCreateTableTimeIntervals(Database db) async {
    // Run the CREATE {task lists} TABLE statement on the database.
    await db.execute(
      '''
    CREATE TABLE timeintervals (
      id TEXT PRIMARY KEY,
      isCompleted INTEGER NOT NULL,
      taskId TEXT,
      measurableTaskId TEXT,
      taskWithSubtasksId TEXT,
      location TEXT,
      color INTEGER,
      title TEXT, 
      description TEXT,
      startDate TEXT,
      endDate TEXT,
      startTime INTEGER,
      endTime INTEGER,
      isStartDateUndefined INTEGER NOT NULL,
      isEndDateUndefined INTEGER NOT NULL,
      isStartTimeUndefined INTEGER NOT NULL,
      isEndTimeUndefined INTEGER NOT NULL,
      targetAtLeast REAL,
      targetAtMost REAL,
      targetType INTEGER,
      unit TEXT,
      howMuchHasBeenDone REAL,
      subtasks TEXT,
      dataFiles TEXT,
      updateTimeStamp TEXT,
      timeZone TEXT,
      FOREIGN KEY (taskId) REFERENCES tasks(id) ON DELETE CASCADE,
      FOREIGN KEY (measurableTaskId) REFERENCES measurabletasks(id) ON DELETE CASCADE,
      FOREIGN KEY (taskWithSubtasksId) REFERENCES taskswithsubtasks(id) ON DELETE CASCADE)
    ''',
    );
  }
}
