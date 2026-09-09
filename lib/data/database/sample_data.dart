import 'package:flutter/material.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/models/model_list.dart';
import 'package:my_time_manager/data/models/model_task.dart';
import 'package:my_time_manager/utils/constants.dart';

// Dữ liệu mẫu — dùng model Task hợp nhất:
//   - Task đo lường: isMeasurable = true + target/unit.
//   - Task có công việc con: truyền subtasks.

final TaskList enjoyYourLife = TaskList(
    id: 'enjoyYourLife',
    title: 'Enjoy your life',
    description: 'Do something that makes you happy ',
    color: ColorSeed.baseColor.color,
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final Task eatWhatYouFindTasty = Task(
    id: 'eatWhatYouFindTasty',
    taskListId: 'enjoyYourLife',
    isCompleted: false,
    isImportant: true,
    title: 'Eat what you find tasty',
    description:
        'Vietnamese baguette, Bratwurst, Vietnamese Pho, Currywursrt, Eisbein with Sauerkraut, Vietnamese thin pancakes... ',
    location: '',
    color: ColorSeed.lightgreen.color,
    tags: [],
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final Task haveAGoodSleepAtNight = Task(
    id: 'haveAGoodSleepAtNight',
    taskListId: 'enjoyYourLife',
    isCompleted: false,
    isImportant: true,
    title: 'Have a good sleep at night',
    description: 'A deep and comfortable sleep',
    location: 'Your warm bed',
    color: ColorSeed.pink.color,
    tags: [],
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final Task takeADeepBreath = Task(
    id: 'takeADeepBreath',
    taskListId: 'enjoyYourLife',
    isCompleted: false,
    isImportant: true,
    title: 'Take a deep breath, let your mind be at peace',
    description: '',
    location: '',
    color: ColorSeed.cyan.color,
    tags: [],
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final Task chillInACafe = Task(
    id: 'chillInACafe',
    taskListId: 'enjoyYourLife',
    isCompleted: false,
    isImportant: false,
    title: 'Sit in a beautiful and quiet cafe, observing everything around you',
    description: 'Chill in a cafe',
    location: '',
    color: ColorSeed.lightblue.color,
    tags: [],
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final Task chattingWithFriends = Task(
    id: 'chattingWithFriends',
    taskListId: 'enjoyYourLife',
    isCompleted: false,
    isImportant: false,
    title: 'Talk frequently with the person you feel comfortable with',
    description: 'chatting with friends',
    location: 'Cafeteria',
    color: ColorSeed.teal.color,
    tags: [],
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final TaskList challenge = TaskList(
    id: 'challenge',
    title: 'Challenge',
    description: 'Workout',
    color: ColorSeed.baseColor.color,
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final Task walking = Task(
    id: 'walking',
    taskListId: 'challenge',
    isCompleted: false,
    isImportant: false,
    title: 'Walking',
    description: '',
    location: '',
    color: ColorSeed.amber.color,
    isMeasurable: true,
    targetAtLeast: 6000,
    targetAtMost: 10000,
    targetType: TargetType.about,
    howMuchHasBeenDone: 0.0,
    unit: 'steps',
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final Task running = Task(
    id: 'running',
    taskListId: 'challenge',
    isCompleted: false,
    isImportant: false,
    title: 'Running',
    description: '',
    location: '',
    color: ColorSeed.amber.color,
    isMeasurable: true,
    targetAtLeast: 5,
    targetAtMost: double.infinity,
    targetType: TargetType.atLeast,
    howMuchHasBeenDone: 0.0,
    unit: 'km',
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final Task swimming = Task(
    id: 'swimming',
    taskListId: 'challenge',
    isCompleted: false,
    isImportant: false,
    title: 'Swimming',
    description: '',
    location: '',
    color: ColorSeed.amber.color,
    isMeasurable: true,
    targetAtLeast: 500,
    targetAtMost: double.infinity,
    targetType: TargetType.atLeast,
    howMuchHasBeenDone: 0.0,
    unit: 'm',
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final TaskList housework = TaskList(
    id: 'housework',
    title: 'Housework',
    description: '',
    color: ColorSeed.baseColor.color,
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final Task cleaning = Task(
    id: 'cleaning',
    taskListId: 'housework',
    title: 'Clean up and organize neatly',
    description: '',
    location: '',
    color: ColorSeed.grey.color,
    isCompleted: false,
    isImportant: false,
    subtasks: [
      Subtask(title: "Living room"),
      Subtask(title: "Bedroom"),
      Subtask(title: "Restroom"),
      Subtask(title: "Kitchen"),
    ],
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final TaskList researchAndStudy = TaskList(
    id: 'researchAndStudy',
    title: 'Research and study',
    description: '',
    color: ColorSeed.red.color,
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final Task learnMachineLearningInAMonth = Task(
    id: 'learnMachineLearningInAMonth',
    taskListId: 'researchAndStudy',
    title: 'Learn machine learning in a month',
    description: '',
    location: '',
    color: ColorSeed.purple.color,
    isCompleted: false,
    isImportant: true,
    subtasks: [
      Subtask(title: "Machine learning models and algorithms"),
      Subtask(title: "Feature extraction- feature engineering"),
      Subtask(title: "Model parameters and the loss-function"),
      Subtask(title: "Linear regression"),
      Subtask(title: "Over- and underfitting"),
      Subtask(title: "Knn, k-means, naives Bayes"),
      Subtask(
          title:
              "Perceptron learning algorithm, logistic and softmax regression"),
      Subtask(title: "Dimension reduction"),
      Subtask(title: "Support vector machine"),
    ],
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final Task learnAutomationTechnology = Task(
    id: 'learnAutomationTechnology',
    taskListId: 'researchAndStudy',
    title: 'Automation technology',
    description: '',
    location: '',
    color: ColorSeed.brown.color,
    isCompleted: false,
    isImportant: true,
    subtasks: [
      Subtask(title: "How to use GX-work2,3 and GT-Designer?"),
      Subtask(title: "How to use SIMATIC Manager and TIA Portal?"),
      Subtask(title: "PLC programming"),
      Subtask(
          title:
              "Explore the Siemens S7 300, 400, 1200, 1500 and the Mitsubishi MELSEC iQ-series PLC"),
    ],
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final TaskList applicationDevelopment = TaskList(
    id: 'applicationDevelopment',
    title: 'Application development',
    description: '',
    color: ColorSeed.red.color,
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final Task completeMyApplication = Task(
    id: 'completeMyApplication',
    taskListId: 'applicationDevelopment',
    title: 'Complete My Time Manager application',
    description: '',
    location: '',
    color: ColorSeed.black.color,
    isCompleted: false,
    isImportant: true,
    subtasks: [
      Subtask(title: "Add file attachment feature for tasks and events."),
      Subtask(title: "Add alarm feature for tasks and events."),
      Subtask(
          title: "Add account creation feature and sync data with Firebase."),
      Subtask(title: "Add offline data backup feature."),
      Subtask(title: "Add focus timer and concentration music feature. "),
      Subtask(
          title:
              "Create statistical graphs of focused time periods by day, week, month, year."),
      Subtask(title: "Add day, week, month, year views for the calendar."),
      Subtask(
          title:
              "Add a function that allows adding new tasks and events or planning for pre-created tasks and events by clicking on the time slots in the calendar."),
      Subtask(
          title:
              "Create widgets to display on the home screen and lock screen."),
      Subtask(
          title:
              "Modify widgets for large screen types of tablets, windows, macos."),
      Subtask(
          isCompleted: true,
          title: "Add measurable tasks and tasks with subtasks models."),
      Subtask(
          isCompleted: true,
          title: "Add the function to switch between light and dark mode."),
      Subtask(
          isCompleted: true,
          title: "Add the function to select colors for the theme."),
      Subtask(
          isCompleted: true,
          title:
              "Add the function to switch the interface between Material Design 2 and 3."),
      Subtask(isCompleted: true, title: "Add the function to select language."),
    ],
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final TaskList test = TaskList(
    id: 'test',
    title: 'test',
    description: '',
    color: ColorSeed.red.color,
    dataFiles: [],
    updateTimeStamp: DateTime.now());

Future<void> addSampleData() async {
  final DatabaseManager databaseManager = DatabaseManager();
  databaseManager.insertTaskList(test);
  databaseManager.insertTaskList(enjoyYourLife);
  databaseManager.insertTaskList(challenge);
  databaseManager.insertTaskList(housework);
  databaseManager.insertTaskList(researchAndStudy);
  databaseManager.insertTaskList(applicationDevelopment);
  databaseManager.insertTask(eatWhatYouFindTasty);
  databaseManager.insertTask(haveAGoodSleepAtNight);
  databaseManager.insertTask(takeADeepBreath);
  databaseManager.insertTask(chillInACafe);
  databaseManager.insertTask(chattingWithFriends);
  databaseManager.insertTask(walking);
  databaseManager.insertTask(running);
  databaseManager.insertTask(swimming);
  databaseManager.insertTask(cleaning);
  databaseManager.insertTask(learnMachineLearningInAMonth);
  databaseManager.insertTask(learnAutomationTechnology);
  databaseManager.insertTask(completeMyApplication);
}
