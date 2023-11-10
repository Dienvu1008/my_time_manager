import 'package:flutter/material.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/models/model_list.dart';
import 'package:my_time_manager/data/models/model_measurable_task.dart';
import 'package:my_time_manager/data/models/model_task.dart';
import 'package:my_time_manager/data/models/model_task_with_subtasks.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:my_time_manager/utils/constants.dart';

final TimeInterval t1 = TimeInterval(
    id: 'ff336480-88fa-4a62-aac5-fd8f80c23d8b',
    isCompleted: false,
    isImportant: true,
    taskId: null,
    measurableTaskId: null,
    taskWithSubtasksId: '5435460b-847b-48b6-b01e-098b8b273af0',
    location: '',
    color: const Color(4284960932 | 0xFF000000),
    title: 'task with S',
    description: '',
    startDate: DateTime.parse('2023-09-25T00:00:00.000'),
    endDate: DateTime.parse('2023-09-25T00:00:00.000'),
    startTime: const TimeOfDay(hour: 12, minute: 30),
    endTime: const TimeOfDay(hour: 13, minute: 30),
    isStartDateUndefined: false,
    isEndDateUndefined: false,
    isStartTimeUndefined: false,
    isEndTimeUndefined: false,
    targetAtLeast: double.parse('-Infinity'),
    targetAtMost: double.parse('Infinity'),
    targetType: TargetType.about,
    unit: '',
    howMuchHasBeenDone: double.parse('0.0'),
    subtasks: [],
    dataFiles: [],
    updateTimeStamp: DateTime.now(),
    timeZone: '');

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

final MeasurableTask walking = MeasurableTask(
    id: 'walking',
    taskListId: 'challenge',
    isCompleted: false,
    isImportant: false,
    title: 'Walking',
    description: '',
    location: '',
    color: ColorSeed.amber.color,
    targetAtLeast: 6000, //double.parse('6000.0'),
    targetAtMost: 10000, //double.parse('10000.0'),
    targetType: TargetType.about,
    howMuchHasBeenDone: 0.0,
    unit: 'steps',
    //tags: null,
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final MeasurableTask running = MeasurableTask(
    id: 'running',
    taskListId: 'challenge',
    isCompleted: false,
    isImportant: false,
    title: 'Running',
    description: '',
    location: '',
    color: ColorSeed.amber.color,
    targetAtLeast: 5, //double.parse('6000.0'),
    targetAtMost: double.parse('Infinity'),
    targetType: TargetType.atLeast,
    howMuchHasBeenDone: 0.0,
    unit: 'km',
    //tags: null,
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final MeasurableTask swimming = MeasurableTask(
    id: 'swimming',
    taskListId: 'challenge',
    isCompleted: false,
    isImportant: false,
    title: 'Swimming',
    description: '',
    location: '',
    color: ColorSeed.amber.color,
    targetAtLeast: 500, //double.parse('6000.0'),
    targetAtMost: double.parse('Infinity'),
    targetType: TargetType.atLeast,
    howMuchHasBeenDone: 0.0,
    unit: 'm',
    //tags: null,
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final TaskList housework = TaskList(
    id: 'housework',
    title: 'Housework',
    description: '',
    color: ColorSeed.baseColor.color,
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final TaskWithSubtasks cleaning = TaskWithSubtasks(
    id: 'cleaning',
    taskListId: 'housework',
    title: 'Clean up and organize neatly',
    description: '',
    location: '',
    color: ColorSeed.grey.color,
    isCompleted: false,
    isImportant: false,
    subtasks: [
      Subtask(isSubtaskCompleted: false, title: "Living room"),
      Subtask(isSubtaskCompleted: false, title: "Bedroom"),
      Subtask(isSubtaskCompleted: false, title: "Restroom"),
      Subtask(isSubtaskCompleted: false, title: "Kitchen"),
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

final TaskWithSubtasks learnMachineLearningInAMonth = TaskWithSubtasks(
    id: 'learnMachineLearningInAMonth',
    taskListId: 'researchAndStudy',
    title: 'Learn machine learning in a month',
    description: '',
    location: '',
    color: ColorSeed.purple.color,
    isCompleted: false,
    isImportant: true,
    subtasks: [
      Subtask(
          isSubtaskCompleted: false,
          title: "Machine learning models and algorithms"),
      Subtask(
          isSubtaskCompleted: false,
          title: "Feature extraction- feature engineering"),
      Subtask(
          isSubtaskCompleted: false,
          title: "Model parameters and the loss-function"),
      Subtask(isSubtaskCompleted: false, title: "Linear regression"),
      Subtask(isSubtaskCompleted: false, title: "Over- and underfitting"),
      Subtask(isSubtaskCompleted: false, title: "Knn, k-means, naives Bayes"),
      Subtask(
          isSubtaskCompleted: false,
          title:
              "Perceptron learning algorithm, logistic and softmax regression"),
      Subtask(isSubtaskCompleted: false, title: "Dimension reduction"),
      Subtask(isSubtaskCompleted: false, title: "Support vector machine"),
    ],
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final TaskWithSubtasks learnAutomationTechnology = TaskWithSubtasks(
    id: 'learnAutomationTechnology',
    taskListId: 'researchAndStudy',
    title: 'Automation technology',
    description: '',
    location: '',
    color: ColorSeed.brown.color,
    isCompleted: false,
    isImportant: true,
    subtasks: [
      Subtask(
          isSubtaskCompleted: false,
          title: "How to use GX-work2,3 and GT-Designer?"),
      Subtask(
          isSubtaskCompleted: false,
          title: "How to use SIMATIC Manager and TIA Portal?"),
      Subtask(isSubtaskCompleted: false, title: "PLC programming"),
      Subtask(
          isSubtaskCompleted: false,
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

final TaskWithSubtasks completeMyApplication = TaskWithSubtasks(
    id: 'completeMyApplication',
    taskListId: 'applicationDevelopment',
    title: 'Complete My Time Manager application',
    description: '',
    location: '',
    color: ColorSeed.black.color,
    isCompleted: false,
    isImportant: true,
    subtasks: [
      Subtask(
          isSubtaskCompleted: false,
          title: "Add file attachment feature for tasks and events."),
      Subtask(
          isSubtaskCompleted: false,
          title: "Add alarm feature for tasks and events."),
      Subtask(
          isSubtaskCompleted: false,
          title: "Add account creation feature and sync data with Firebase."),
      Subtask(
          isSubtaskCompleted: false, title: "Add offline data backup feature."),
      Subtask(
          isSubtaskCompleted: false,
          title: "Add focus timer and concentration music feature. "),
      Subtask(
          isSubtaskCompleted: false,
          title:
              "Create statistical graphs of focused time periods by day, week, month, year."),
      Subtask(
          isSubtaskCompleted: false,
          title: "Add day, week, month, year views for the calendar."),
      Subtask(
          isSubtaskCompleted: false,
          title:
              "Add a function that allows adding new tasks and events or planning for pre-created tasks and events by clicking on the time slots in the calendar."),
      Subtask(
          isSubtaskCompleted: false,
          title:
              "Create widgets to display on the home screen and lock screen."),
      Subtask(
          isSubtaskCompleted: false,
          title:
              "Modify widgets for large screen types of tablets, windows, macos."),
      Subtask(
          isSubtaskCompleted: true,
          title: "Add measurable tasks and tasks with subtasks models."),
      Subtask(
          isSubtaskCompleted: true,
          title: "Add the function to switch between light and dark mode."),
      Subtask(
          isSubtaskCompleted: true,
          title: "Add the function to select colors for the theme."),
      Subtask(
          isSubtaskCompleted: true,
          title:
              "Add the function to switch the interface between Material Design 2 and 3."),
      Subtask(
          isSubtaskCompleted: true,
          title: "Add the function to select language."),
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

final TaskList selfImprovement = TaskList(
    id: 'selfImprovement',
    title: 'Self-improvement',
    description: '',
    color: ColorSeed.red.color,
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final TaskList changeMyAuraChangeTheWayIPresentMyself = TaskList(
    id: 'changeMyAuraChangeTheWayIPresentMyself',
    title: 'Change my aura- Change the way i present myself',
    description: '',
    color: ColorSeed.red.color,
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final TaskWithSubtasks changeMyAura = TaskWithSubtasks(
    id: 'changeMyAura',
    taskListId: 'changeMyAuraChangeTheWayIPresentMyself',
    title: 'Change my aura',
    description: '',
    location: '',
    color: ColorSeed.brown.color,
    isCompleted: false,
    isImportant: true,
    subtasks: [
      Subtask(
          isSubtaskCompleted: false, title: "Always be neat when going out."),
      Subtask(
          isSubtaskCompleted: false,
          title: "Walk with my head held high, and step briskly."),
      Subtask(
          isSubtaskCompleted: false,
          title:
              "Maintain a fresh appearance, a friendly, sociable, and likable style, always smiling, and full of energy."),
      Subtask(
          isSubtaskCompleted: false,
          title:
              "Always bear in mind the need to absorb new knowledge to maintain the confident demeanor of an intelligent, knowledgeable, and experienced individual."),
      Subtask(
          isSubtaskCompleted: false,
          title:
              "Maintain daily exercise, keep a strong, masculine, and calm appearance."),
      Subtask(
          isSubtaskCompleted: false,
          title:
              "Maintain daily practice of foreign languages. Train to think faster in a foreign language, pronounce more accurately, and understand more precisely.”"),
      Subtask(
          isSubtaskCompleted: false,
          title:
              "Do everything faster, more focused, think and critique deeper, keep reflexes quicker. When not having to work, focus on deep breathing, listen to all the sounds around, observe everything around."),
      Subtask(
          isSubtaskCompleted: false,
          title: "Do not use the phone, computer unconsciously."),
      Subtask(
          isSubtaskCompleted: false,
          title:
              "When working, do not sit in front of the computer for too long. When feeling that your thoughts are not flowing smoothly, you can stand up and walk around the room. Record tasks and ideas in the My Time Manager app. Turn on the focus clock in the My Time Manager app when working."),
    ],
    dataFiles: [],
    updateTimeStamp: DateTime.now());

final TaskWithSubtasks stayAwakeAndActive = TaskWithSubtasks(
    id: 'stayAwakeAndActive',
    taskListId: 'changeMyAuraChangeTheWayIPresentMyself',
    title: 'Stay awake and active',
    description: '',
    location: '',
    color: ColorSeed.brown.color,
    isCompleted: false,
    isImportant: true,
    subtasks: [
      Subtask(isSubtaskCompleted: false, title: "Get enough sleep."),
      Subtask(isSubtaskCompleted: false, title: "Trink tea, coffee"),
      Subtask(
          isSubtaskCompleted: false,
          title: "Eat foods that are easy to disgest. Eat slow and chew well."),
      Subtask(isSubtaskCompleted: false, title: "Meditation. Deep breath."),
      Subtask(
          isSubtaskCompleted: false,
          title: "Perform a few gentle exercises, stretch muscles…"),
      Subtask(
          isSubtaskCompleted: false,
          title: "Listening to EDM, acoustic or epic music."),
    ],
    dataFiles: [],
    updateTimeStamp: DateTime.now());

Future<void> addSampleData() async {
  final DatabaseManager databaseManager = DatabaseManager();
  //final db = await databaseManager.database;
  databaseManager.insertTaskList(test);
  databaseManager.insertTaskList(enjoyYourLife);
  databaseManager.insertTaskList(challenge);
  databaseManager.insertTaskList(housework);
  databaseManager.insertTaskList(researchAndStudy);
  databaseManager.insertTaskList(applicationDevelopment);
  //databaseManager.insertTaskList(changeMyAuraChangeTheWayIPresentMyself);
  databaseManager.insertTask(eatWhatYouFindTasty);
  databaseManager.insertTask(haveAGoodSleepAtNight);
  databaseManager.insertTask(takeADeepBreath);
  databaseManager.insertTask(chillInACafe);
  databaseManager.insertTask(chattingWithFriends);
  databaseManager.insertMeasurableTask(walking);
  databaseManager.insertMeasurableTask(running);
  databaseManager.insertMeasurableTask(swimming);
  databaseManager.insertTaskWithSubtasks(cleaning);
  databaseManager.insertTaskWithSubtasks(learnMachineLearningInAMonth);
  databaseManager.insertTaskWithSubtasks(learnAutomationTechnology);
  databaseManager.insertTaskWithSubtasks(completeMyApplication);
  //databaseManager.insertTaskWithSubtasks(changeMyAura);
  //databaseManager.insertTaskWithSubtasks(stayAwakeAndActive);
}