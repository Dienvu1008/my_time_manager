import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'About': 'About',
      'add a new event': 'Add a new event',
      'add a new measureable task': 'Add a new measureable task',
      'add a new task': 'Add a new task',
      'add a new task with sub-tasks': 'Add a new task with sub-tasks',
      'add to this list': 'Add to this list',
      'Are you sure you want to delete this task?':
          'Are you sure you want to delete this task?',
      'Add new measurable task': 'Add new measurable task',
      'Add Subtask': 'Add Subtask',
      'Add time interval': 'Add time interval',
      'Are you sure you want to delete this subtask?':
          'Are you sure you want to delete this subtask',
      'at least': 'at least',
      'at most': 'at most',
      'about': 'about',
      'calendar': 'Calendar',
      'cancel': 'Cancel',
      'Choose theme color': 'Choose theme color',
      'Choose theme color from image color':
          'Choose theme color from image color',
      'Choose application language': 'Choose application language',
      'delete': 'Delete',
      'delete task': 'Delete task',
      'delete this list': 'Delete this list',
      'edit task': 'Edit task',
      'edit this list': 'Edit this list',
      'english': 'English',
      'focus timer': 'Focus timer',
      'german': 'German',
      'how to use': 'How to use?',
      'list': 'List',
      'my contacts': 'My contacts',
      'my statistics': 'My statistics',
      'notes': 'Notes',
      'settings': 'Settings',
      'tasks and events': 'Tasks and events',
      'tasks': 'Tasks',
      'title': 'Title',
      'vietnamese': 'Vietnamese',

      'Brightness': 'Brightness',
      'Close': 'Close',
      'Dark': 'Dark',
      'Delete Subtask': 'Delete subtask',
      'Description': 'Description',
      'Edit measurable task': 'Edit measurable task',
      'Edit Subtask': 'Edit Subtask',
      'End date': 'End date',
      'End time': 'End time',
      'Error': 'Error',
      'focus right now?': 'Focus right now',
      'Hide sub-tasks': 'Hide sub-tasks',
      'Invalid value for "at least"': 'Invalid value for "at least"',
      'Invalid value for "at most"': 'Invalid value for "at most"',
      'Light': 'Light',
      'Location': 'Location',
      'mark as completed': 'Mark as completed',
      'mark as incompleted': 'Mark as incompleted',
      'Please enter a start date': 'Please enter a start date',
      'Please enter a start time': 'Please enter a start time',
      'Please enter an end date': 'Please enter an end date',
      'Please enter an end time': 'Please enter an end time',
      'Save the list': 'Save the list',
      'show brightness button in application bar':
          'Show brightness button in application bar',
      'show color image button in application bar':
          'Show color image button in application bar',
      'show color seed button in application bar':
          'Show color seed button in application bar',
      'show languages button in application bar':
          'Show languages button in application bar',
      'show material design button in application bar':
          'Show material design button in application bar',
      'Show sub-tasks': 'Show sub-tasks',
      'Start date': 'Start date',
      'Start time': 'Start time',
      'Submit': 'Submit',
      'Target Type': 'Target Type',
      'target: about': 'Target: about',
      'target: at least': 'Target: at least',
      'target: at most': 'Target: at most',
      'Time Interval': 'Time Interval',
      'to': 'to',
      'undefined': 'undefined',
      'Unit': 'Unit',
      'User Interface Settings': 'User Interface Settings',
      "You are entering a minimum target value that is greater than the maximum target value":
          "You are entering a minimum target value that is greater than the maximum target value",
      "You have not entered the title of the list":
          "You have not entered the title of the list",
      "You have not entered the title of the task":
          "You have not entered the title of the task",

      'Open link': 'Open link',
      'do you want to open the link in your default browser?':
          'do you want to open the link in your default browser?',
      'Open': 'Open',
      'Application Information': 'Application Information',
      'Report an Issue': 'Report an Issue',
      'Having an issue ? Report it here': 'Having an issue ? Report it here',
      'Privacy Policy': 'Privacy Policy',
      'Open Source': 'Open Source',
      'Author': 'Author',
      'Send an Email': 'Send an Email',

      'Open Source Announcement': 'Open Source Announcement',
      'This app will become open source. We will make the source code public after cleaning up the code.':
          'This app will become open source. We will make the source code public after cleaning up the code.',
      'OK': 'OK',

      // ...
    },
    'vi': {
      'title': 'Tựa đề',
      'english': 'Tiếng Anh',
      'vietnamese': 'Tiếng Việt',
      'german': 'Tiếng Đức',
      'settings': 'Cài đặt',
      'About': 'Thông tin',
      'how to use': 'Hướng dẫn sử dụng',
      'tasks': 'Nhiệm vụ',
      'list': 'Danh sách',
      'delete task': 'Xóa nhiệm vụ',
      'Are you sure you want to delete this task?':
          'Bạn chắc chắn muốn xóa nhiệm vụ này?',
      'cancel': 'Hủy',
      'delete': 'Xóa',
      'add a new task': 'Thêm nhiệm vụ mới',
      'add a new measureable task': 'Thêm nhiệm vụ định lượng mới',
      'add a new task with sub-tasks': 'Thêm nhiệm vụ và nhiệm vụ con mới',
      'add to this list': 'Thêm vào danh sách này',
      'add a new event': 'Thêm sự kiện mới',
      'edit this list': 'Sửa danh sách này',
      'delete this list': 'Xóa danh sách này',
      'edit task': 'Sửa nhiệm vụ',
      'tasks and events': 'Nhiệm vụ và sự kiện',
      'calendar': 'Lịch',
      'my statistics': 'Thống kê của tôi',
      'focus timer': 'Chế độ tập trung',
      'my contacts': 'Danh bạ',
      'notes': 'Các ghi chú',

      'show brightness button in application bar':
          'Hiện nút chỉnh độ sáng trên thanh ứng dụng',
      'show material design button in application bar':
          'Hiện nút chọn thiết kế trên thanh ứng dụng',
      'show color seed button in application bar':
          'Hiện nút chọn màu trên thanh ứng dụng',
      'show color image button in application bar':
          'Hiện nút chọn màu từ ảnh trên thanh ứng dụng',
      'show languages button in application bar':
          'Hiện nút chọn ngôn ngữ trên thanh ứng dụng',
      'mark as incompleted': 'Đánh dấu chưa hoàn thành',
      'mark as completed': 'Đánh dấu đã hoàn thành',
      'add time interval': 'Thêm khoảng thời gian',
      'focus right now?': 'Bật đồng hồ tập trung',
      'target: about': 'Mục tiêu: trong khoảng',
      'target: at least': 'Mục tiêu: ít nhất',
      'target: at most': 'Mục tiêu: nhiều nhất',
      'has been done:': 'Đã hoàn thành được: ',
      'to': 'tới',
      'Hide sub-tasks': 'Ẩn nhiệm vụ con',
      'Show sub-tasks': 'Hiện nhiệm vụ con',
      'Delete Subtask': 'Xóa nhiệm vụ con',
      'Are you sure you want to delete this subtask?':
          'Bạn chắc chắn muốn xóa nhiệm vụ con này?',

      'You have not entered the title of the list':
          'Bạn chưa nhập tiêu đề của danh sách',
      'Close': 'Đóng',
      'Description': 'Mô tả',
      'Save the list': 'Lưu danh sách',
      'You have not entered the title of the task':
          'Bạn chưa nhập tiêu đề của nhiệm vụ',
      'Location': 'Địa điểm',
      'Error': 'Lỗi',
      'Invalid value for "at least"': 'Giá trị không hợp lệ cho "ít nhất"',
      'Invalid value for "at most"': 'Giá trị không hợp lệ cho "nhiều nhất"',
      'You are entering a minimum target value that is greater than the maximum target value':
          'Bạn đang nhập giá trị mục tiêu tối thiểu lớn hơn giá trị mục tiêu tối đa',
      'Add new measurable task': 'Thêm nhiệm vụ đo lường mới',
      'Edit measurable task': 'Chỉnh sửa nhiệm vụ đo lường',
      'at least': 'ít nhất',
      'at most': 'nhiều nhất',
      'about': 'khoảng',
      'Target Type': 'Loại mục tiêu',
      'Unit': 'Đơn vị',
      'Edit Subtask': 'Chỉnh sửa công việc phụ',
      'Add Subtask': 'Thêm công việc phụ',
      'Time Interval': 'Khoảng thời gian',
      'undefined': 'không xác định',
      'Please enter a start date': 'Vui lòng nhập ngày bắt đầu',
      'Start date': 'Ngày bắt đầu',
      'Please enter a start time': 'Vui lòng nhập thời gian bắt đầu',
      'Start time': 'Thời gian bắt đầu',
      'Please enter an end date': 'Vui lòng nhập ngày kết thúc',
      'End date': 'Ngày kết thúc',
      'Please enter an end time': 'Vui lòng nhập thời gian kết thúc',
      'End time': 'Thời gian kết thúc',
      'Please enter at least one date': 'Vui lòng nhập ít nhất một ngày',
      'The start time must not occur after the end time':
          'Thời gian bắt đầu không được phép xảy ra sau thời gian kết thúc',
      'Submit': 'Gửi đi',
      'User Interface Settings': 'Cài đặt giao diện người dùng',
      'Brightness': 'Độ sáng',
      'Light': 'Sáng',
      'Dark': 'Tối',
      'Choose theme color': 'Chọn màu chủ đề',
      'Choose theme color from image color': 'Chọn màu chủ đề từ màu ảnh',
      'Choose application language': 'Chọn ngôn ngữ ứng dụng',
      'Open link': 'Mở liên kết',
      'do you want to open the link in your default browser?':
          'bạn có muốn mở liên kết trong trình duyệt mặc định của bạn không?',
      'Open': 'Mở',

      'Application Information': 'Thông tin ứng dụng',
      'Report an Issue': 'Báo cáo một vấn đề',
      'Having an issue ? Report it here': 'Gặp vấn đề? Báo cáo tại đây',
      'Privacy Policy': 'Chính sách bảo mật',
      'Open Source': 'Mã nguồn mở',
      'Author': 'Tác giả',
      'Send an Email': 'Gửi một Email',
      'Open Source Announcement': 'Thông báo mã nguồn mở',
      'This app will become open source. We will make the source code public after cleaning up the code.':
          'Ứng dụng này sẽ trở thành mã nguồn mở. Chúng tôi sẽ công khai mã nguồn sau khi dọn dẹp mã.',
      'OK': 'Đồng ý'

      // ...
    },
    'de': {
      'title': 'Titel',
      'english': 'Englisch',
      'vietnamese': 'Vietnamesisch',
      'german': 'Deutsch',
      'settings': 'Einstellungen',
      'About': 'Über uns',
      'how to use': 'Anleitung',
      'tasks': 'Aufgaben',
      'list': 'Liste',
      'delete task': 'Aufgabe löschen',
      'Are you sure you want to delete this task?':
          'Sind Sie sicher, dass Sie diese Aufgabe löschen möchten?',
      'cancel': 'Abbrechen',
      'delete': 'Löschen',
      'add a new task': 'Eine neue Aufgabe hinzufügen',
      'add a new measureable task': 'Eine neue messbare Aufgabe hinzufügen',
      'add a new task with sub-tasks':
          'Eine neue Aufgabe mit Unteraufgaben hinzufügen',
      'add to this list': 'Zu dieser Liste hinzufügen',
      'add a new event': 'Ein neues Ereignis hinzufügen',
      'edit this list': 'Diese Liste bearbeiten',
      'delete this list': 'Diese Liste löschen',
      'edit task': 'Aufgabe bearbeiten',
      'tasks and events': 'Aufgaben und Ereignisse',
      'calendar': 'Kalendar',
      'my statistics': 'Meine Statistiken',
      'focus timer': 'Fokus-Timer',
      'my contacts': 'Meine Kontakte',
      'notes': 'Notizen',

      'show brightness button in application bar':
          'Helligkeitsschaltfläche in der Anwendungsleiste anzeigen',
      'show material design button in application bar':
          'Material Design-Schaltfläche in der Anwendungsleiste anzeigen',
      'show color seed button in application bar':
          'Farbsamen-Schaltfläche in der Anwendungsleiste anzeigen',
      'show color image button in application bar':
          'Farbbild-Schaltfläche in der Anwendungsleiste anzeigen',
      'show languages button in application bar':
          'Sprachschaltfläche in der Anwendungsleiste anzeigen',
      'mark as incompleted': 'Als unvollständig markieren',
      'mark as completed': 'Als abgeschlossen markieren',
      'add time interval': 'Zeitintervall hinzufügen',
      'focus right now?': 'Jetzt fokussieren?',
      'target: about': 'Ziel: ungefähr',
      'target: at least': 'Ziel: mindestens',
      'target: at most': 'Ziel: höchstens',
      'has been done:': 'Wurde erledigt:',
      'to': 'bis',
      'Hide sub-tasks': 'Unteraufgaben ausblenden',
      'Show sub-tasks': 'Unteraufgaben anzeigen',
      'Delete Subtask': 'Unteraufgabe löschen',
      'Are you sure you want to delete this subtask?':
          'Sind Sie sicher, dass Sie diese Unteraufgabe löschen möchten?',

      'You have not entered the title of the list':
          'Sie haben den Titel der Liste nicht eingegeben',
      'Close': 'Schließen',
      'Description': 'Beschreibung',
      'Save the list': 'Liste speichern',
      'You have not entered the title of the task':
          'Sie haben den Titel der Aufgabe nicht eingegeben',
      'Location': 'Ort',
      'Error': 'Fehler',
      'Invalid value for "at least"': 'Ungültiger Wert für "mindestens"',
      'Invalid value for "at most"': 'Ungültiger Wert für "höchstens"',
      'You are entering a minimum target value that is greater than the maximum target value':
          'Sie geben einen Mindestzielwert ein, der größer ist als der Maximalzielwert',
      'Add new measurable task': 'Neue messbare Aufgabe hinzufügen',
      'Edit measurable task': 'Messbare Aufgabe bearbeiten',
      'at least': 'mindestens',
      'at most': 'höchstens',
      'about': 'ungefähr',
      'Target Type': 'Zieltyp',
      'Unit': 'Einheit',
      'Edit Subtask': 'Teilaufgabe bearbeiten',
      'Add Subtask': 'Teilaufgabe hinzufügen',
      'Time Interval': 'Zeitintervall',
      'undefined': 'undefiniert',
      'Please enter a start date': 'Bitte geben Sie ein Startdatum ein',
      'Start date': 'Startdatum',
      'Please enter a start time': 'Bitte geben Sie eine Startzeit ein',
      'Start time': 'Startzeit',
      'Please enter an end date': 'Bitte geben Sie ein Enddatum ein',
      'End date': 'Enddatum',
      'Please enter an end time': 'Bitte geben Sie eine Endzeit ein',
      'End time': 'Endzeit',
      'Please enter at least one date':
          'Bitte geben Sie mindestens ein Datum ein',
      'The start time must not occur after the end time':
          'Die Startzeit darf nicht nach der Endzeit liegen',
      'Submit': 'Absenden',
      'User Interface Settings': 'Benutzeroberflächeneinstellungen',
      'Brightness': 'Helligkeit',
      'Light': 'Hell',
      'Dark': 'Dunkel',
      'Choose theme color': 'Themenfarbe wählen',
      'Choose theme color from image color': 'Themenfarbe aus Bildfarbe wählen',
      'Choose application language': 'Anwendungssprache wählen',
      'Open link': 'Link öffnen',
      'do you want to open the link in your default browser?':
          'Möchten Sie den Link in Ihrem Standardbrowser öffnen?',
      'Open': 'Öffnen',

      'Application Information': 'Anwendungsinformationen',
      'Report an Issue': 'Ein Problem melden',
      'Having an issue ? Report it here':
          'Haben Sie ein Problem? Melden Sie es hier',
      'Privacy Policy': 'Datenschutzrichtlinie',
      'Open Source': 'Open Source',
      'Author': 'Autor',
      'Send an Email': 'Eine E-Mail senden',
      'Open Source Announcement': 'Open Source Ankündigung',
      'This app will become open source. We will make the source code public after cleaning up the code.':
          'Diese App wird Open Source werden. Wir werden den Quellcode veröffentlichen, nachdem wir den Code bereinigt haben.',
      'OK': 'Zustimmen'

      // ...
    },
  };

  String get title => _localizedValues[locale.languageCode]!['title']!;
  String get english => _localizedValues[locale.languageCode]!['english']!;
  String get vietnamese =>
      _localizedValues[locale.languageCode]!['vietnamese']!;
  String get german => _localizedValues[locale.languageCode]!['german']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get About => _localizedValues[locale.languageCode]!['About']!;
  String get howToUse => _localizedValues[locale.languageCode]!['how to use']!;
  String get tasks => _localizedValues[locale.languageCode]!['tasks']!;
  String get list => _localizedValues[locale.languageCode]!['list']!;
  String get deleteTask =>
      _localizedValues[locale.languageCode]!['delete task']!;
  String get areYouSureYouWantToDeleteThisTask => _localizedValues[
      locale.languageCode]!['Are you sure you want to delete this task?']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get delete => _localizedValues[locale.languageCode]!['delete']!;
  String get addANewTask =>
      _localizedValues[locale.languageCode]!['add a new task']!;
  String get addANewMeasureableTask =>
      _localizedValues[locale.languageCode]!['add a new measureable task']!;
  String get addANewTaskWithSubtasks =>
      _localizedValues[locale.languageCode]!['add a new task with sub-tasks']!;
  String get addToThisList =>
      _localizedValues[locale.languageCode]!['add to this list']!;
  String get addANewEvent =>
      _localizedValues[locale.languageCode]!['add a new event']!;
  String get editThisList =>
      _localizedValues[locale.languageCode]!['edit this list']!;
  String get deleteThisList =>
      _localizedValues[locale.languageCode]!['delete this list']!;
  String get editTask => _localizedValues[locale.languageCode]!['edit task']!;
  String get tasksAndEvents =>
      _localizedValues[locale.languageCode]!['tasks and events']!;
  String get calendar => _localizedValues[locale.languageCode]!['calendar']!;
  String get myStatistics =>
      _localizedValues[locale.languageCode]!['my statistics']!;
  String get focusTimer =>
      _localizedValues[locale.languageCode]!['focus timer']!;
  String get myContacts =>
      _localizedValues[locale.languageCode]!['my contacts']!;
  String get notes => _localizedValues[locale.languageCode]!['notes']!;
  String get showBrightnessButtonInApplicationBar => _localizedValues[
      locale.languageCode]!['show brightness button in application bar']!;
  String get showMaterialDesignButtonInApplicationBar => _localizedValues[
      locale.languageCode]!['show material design button in application bar']!;
  String get showColorSeedButtonInApplicationBar => _localizedValues[
      locale.languageCode]!['show color seed button in application bar']!;
  String get showColorImageButtonInApplicationBar => _localizedValues[
      locale.languageCode]!['show color image button in application bar']!;
  String get showLanguagesButtonInApplicationBar => _localizedValues[
      locale.languageCode]!['show languages button in application bar']!;
  String get markAsIncompleted =>
      _localizedValues[locale.languageCode]!['mark as incompleted']!;
  String get markAsCompleted =>
      _localizedValues[locale.languageCode]!['mark as completed']!;
  String get addTimeInterval =>
      _localizedValues[locale.languageCode]!['add time interval']!;
  String get focusRightNow =>
      _localizedValues[locale.languageCode]!['focus right now?']!;
  String get targetAbout =>
      _localizedValues[locale.languageCode]!['target: about']!;
  String get targetAtLeast =>
      _localizedValues[locale.languageCode]!['target: at least']!;
  String get targetAtMost =>
      _localizedValues[locale.languageCode]!['target: at most']!;
  String get hasBeenDone =>
      _localizedValues[locale.languageCode]!['has been done:']!;
  String get to => _localizedValues[locale.languageCode]!['to']!;
  String get hideSubTasks =>
      _localizedValues[locale.languageCode]!['Hide sub-tasks']!;
  String get showSubTasks =>
      _localizedValues[locale.languageCode]!['Show sub-tasks']!;
  String get deleteSubtask =>
      _localizedValues[locale.languageCode]!['Delete Subtask']!;
  String get areYouSureYouWantToDeleteThisSubtask => _localizedValues[
      locale.languageCode]!['Are you sure you want to delete this subtask?']!;
  String get youHaveNotEnteredTheTitleOfTheList => _localizedValues[
      locale.languageCode]!['You have not entered the title of the list']!;
  String get close => _localizedValues[locale.languageCode]!['Close']!;
  String get description =>
      _localizedValues[locale.languageCode]!['Description']!;
  String get saveTheList =>
      _localizedValues[locale.languageCode]!['Save the list']!;
  String get youHaveNotEnteredTheTitleOfTheTask => _localizedValues[
      locale.languageCode]!['You have not entered the title of the task']!;
  String get location => _localizedValues[locale.languageCode]!['Location']!;
  String get error => _localizedValues[locale.languageCode]!['Error']!;
  String get invalidValueForAtLeast =>
      _localizedValues[locale.languageCode]!['Invalid value for "at least"']!;
  String get invalidValueForAtMost =>
      _localizedValues[locale.languageCode]!['Invalid value for "at most"']!;
  String get youAreEnteringAMinimumTargetValueThatIsGreaterThanTheMaximumTargetValue =>
      _localizedValues[locale.languageCode]![
          'You are entering a minimum target value that is greater than the maximum target value']!;
  String get addNewMeasurableTask =>
      _localizedValues[locale.languageCode]!['Add new measurable task']!;
  String get editMeasurableTask =>
      _localizedValues[locale.languageCode]!['Edit measurable task']!;
  String get atLeast => _localizedValues[locale.languageCode]!['at least']!;
  String get atMost => _localizedValues[locale.languageCode]!['at most']!;
  String get about => _localizedValues[locale.languageCode]!['about']!;
  String get targetType =>
      _localizedValues[locale.languageCode]!['Target Type']!;
  String get unit => _localizedValues[locale.languageCode]!['Unit']!;
  String get editSubtask =>
      _localizedValues[locale.languageCode]!['Edit Subtask']!;
  String get addSubtask =>
      _localizedValues[locale.languageCode]!['Add Subtask']!;
  String get timeInterval =>
      _localizedValues[locale.languageCode]!['Time Interval']!;
  String get undefined => _localizedValues[locale.languageCode]!['undefined']!;
  String get pleaseEnterAStartDate =>
      _localizedValues[locale.languageCode]!['Please enter a start date']!;
  String get startDate => _localizedValues[locale.languageCode]!['Start date']!;
  String get pleaseEnterAStartTime =>
      _localizedValues[locale.languageCode]!['Please enter a start time']!;
  String get startTime => _localizedValues[locale.languageCode]!['Start time']!;
  String get pleaseEnterAnEndDate =>
      _localizedValues[locale.languageCode]!['Please enter an end date']!;
  String get endDate => _localizedValues[locale.languageCode]!['End date']!;
  String get pleaseEnterAnEndTime =>
      _localizedValues[locale.languageCode]!['Please enter an end time']!;
  String get endTime => _localizedValues[locale.languageCode]!['End time']!;
  String get pleaseEnterAtLeastOneDate =>
      _localizedValues[locale.languageCode]!['Please enter at least one date']!;
  String get theStartTimeMustNotOccurAfterTheEndTime =>
      _localizedValues[locale.languageCode]![
          'The start time must not occur after the end time']!;
  String get submit => _localizedValues[locale.languageCode]!['Submit']!;
  String get userInterfaceSettings =>
      _localizedValues[locale.languageCode]!['User Interface Settings']!;
  String get brightness =>
      _localizedValues[locale.languageCode]!['Brightness']!;
  String get light => _localizedValues[locale.languageCode]!['Light']!;
  String get dark => _localizedValues[locale.languageCode]!['Dark']!;
  String get chooseThemeColor =>
      _localizedValues[locale.languageCode]!['Choose theme color']!;
  String get chooseThemeColorFromImageColor => _localizedValues[
      locale.languageCode]!['Choose theme color from image color']!;
  String get chooseApplicationLanguage =>
      _localizedValues[locale.languageCode]!['Choose application language']!;
  String get openLink => _localizedValues[locale.languageCode]!['Open link']!;
  String get doYouWantToOpenTheLinkInYourDefaultBrowser =>
      _localizedValues[locale.languageCode]![
          'do you want to open the link in your default browser?']!;
  String get applicationInformation =>
      _localizedValues[locale.languageCode]!['Application Information']!;
  String get reportAnIssue =>
      _localizedValues[locale.languageCode]!['Report an Issue']!;
  String get havingAnIssueReportItHere => _localizedValues[
      locale.languageCode]!['Having an issue ? Report it here']!;
  String get privacyPolicy =>
      _localizedValues[locale.languageCode]!['Privacy Policy']!;
  String get openSource =>
      _localizedValues[locale.languageCode]!['Open Source']!;
  String get author => _localizedValues[locale.languageCode]!['Author']!;
  String get sendAnEmail =>
      _localizedValues[locale.languageCode]!['Send an Email']!;
  String get Open => _localizedValues[locale.languageCode]!['Open']!;
  String get openSourceAnnouncement {
    return _localizedValues[locale.languageCode]!['Open Source Announcement']!;
  }

  String get appBecomingOpenSource {
    return _localizedValues[locale.languageCode]![
        'This app will become open source. We will make the source code public after cleaning up the code.']!;
  }

  String get ok {
    return _localizedValues[locale.languageCode]!['OK']!;
  }

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'vi', 'de'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return SynchronousFuture(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
