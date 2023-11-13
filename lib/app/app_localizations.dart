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
  // final Map<String, Map<String, String>> _about = {
  //   'About': {
  //     'en': 'About',
  //     'vi': 'Thông tin',
  //     'de': 'Uber uns',
  //   },
  // };
  // String get About => _about['About']![locale.languageCode]!;

  String get aboutUs {
    return {
      'en': 'About us',
      'vi': 'Thông tin',
      'de': 'Über uns',
    }[locale.languageCode]!;
  }

  String get About {
    return {
      'en': 'About',
      'vi': 'Thông tin',
      'de': 'Uber uns',
    }[locale.languageCode]!;
  }

  String get addANewEvent {
    return {
      'en': 'Add a new event',
      'vi': 'Thêm một sự kiện mới',
      'de': 'Fügen Sie ein neues Ereignis hinzu',
    }[locale.languageCode]!;
  }

  String get addANewMeasureableTask {
    return {
      'en': 'Add a new measureable task',
      'vi': 'Thêm một nhiệm vụ đo lường mới',
      'de': 'Fügen Sie eine neue messbare Aufgabe hinzu',
    }[locale.languageCode]!;
  }

  String get addANewTask {
    return {
      'en': 'Add a new task',
      'vi': 'Thêm một nhiệm vụ mới',
      'de': 'Fügen Sie eine neue Aufgabe hinzu',
    }[locale.languageCode]!;
  }

  String get addANewTaskWithSubTasks {
    return {
      'en': 'Add a new task with sub-tasks',
      'vi': 'Thêm một nhiệm vụ mới với các nhiệm vụ phụ',
      'de': 'Fügen Sie eine neue Aufgabe mit Unteraufgaben hinzu',
    }[locale.languageCode]!;
  }

  String get addToThisList {
    return {
      'en': 'Add to this list',
      'vi': 'Thêm vào danh sách này',
      'de': 'Zur Liste hinzufügen',
    }[locale.languageCode]!;
  }

  String get areYouSureYouWantToDeleteThisTask {
    return {
      'en': 'Are you sure you want to delete this task?',
      'vi': 'Bạn có chắc chắn muốn xóa nhiệm vụ này không?',
      'de': 'Sind Sie sicher, dass Sie diese Aufgabe löschen möchten?',
    }[locale.languageCode]!;
  }

  String get addNewMeasureableTask {
    return {
      'en': 'Add new measurable task',
      'vi': 'Thêm nhiệm vụ đo lường mới',
      'de': 'Neue messbare Aufgabe hinzufügen',
    }[locale.languageCode]!;
  }

  String get addSubtask {
    return {
      'en': 'Add Subtask',
      'vi': 'Thêm nhiệm vụ phụ',
      'de': 'Unteraufgabe hinzufügen',
    }[locale.languageCode]!;
  }

  String get addTimeInterval {
    return {
      'en': 'Add time interval',
      'vi': 'Thêm khoảng thời gian',
      'de': 'Zeitintervall hinzufügen',
    }[locale.languageCode]!;
  }

  String get areYouSureYouWantToDeleteThisSubtask {
    return {
      'en': 'Are you sure you want to delete this subtask',
      'vi': 'Bạn có chắc chắn muốn xóa nhiệm vụ phụ này',
      'de': 'Sind Sie sicher, dass Sie diese Unteraufgabe löschen möchten',
    }[locale.languageCode]!;
  }

  String get atLeast {
    return {
      'en': 'at least',
      'vi': 'ít nhất',
      'de': 'mindestens',
    }[locale.languageCode]!;
  }

  String get atMost {
    return {
      'en': 'at most',
      'vi': 'nhiều nhất',
      'de': 'höchstens',
    }[locale.languageCode]!;
  }

  String get about {
    return {
      'en': 'about',
      'vi': 'khoảng',
      'de': 'ungefähr',
    }[locale.languageCode]!;
  }

  String get calendar {
    return {
      'en': 'Calendar',
      'vi': 'Lịch',
      'de': 'Kalender',
    }[locale.languageCode]!;
  }

  String get cancel {
    return {
      'en': 'Cancel',
      'vi': 'Hủy bỏ',
      'de': 'Stornieren',
    }[locale.languageCode]!;
  }

  String get chooseThemeColor {
    return {
      'en': 'Choose theme color',
      'vi': 'Chọn màu chủ đề',
      'de': 'Wählen Sie die Themenfarbe',
    }[locale.languageCode]!;
  }

  String get chooseThemeColorFromImageColor {
    return {
      'en': 'Choose theme color from image color',
      'vi': 'Chọn màu chủ đề từ màu hình ảnh',
      'de': 'Wählen Sie die Themenfarbe aus der Bildfarbe',
    }[locale.languageCode]!;
  }

  String get chooseApplicationLanguage {
    return {
      'en': 'Choose application language',
      'vi': 'Chọn ngôn ngữ ứng dụng',
      'de': 'Wählen Sie die Anwendungssprache',
    }[locale.languageCode]!;
  }

  String get delete {
    return {
      'en': 'Delete',
      'vi': 'Xóa',
      'de': 'Löschen',
    }[locale.languageCode]!;
  }

  String get deleteTask {
    return {
      'en': 'Delete task',
      'vi': 'Xóa nhiệm vụ',
      'de': 'Aufgabe löschen',
    }[locale.languageCode]!;
  }

  String get deleteThisList {
    return {
      'en': 'Delete this list',
      'vi': 'Xóa danh sách này',
      'de': 'Diese Liste löschen',
    }[locale.languageCode]!;
  }

  String get editTask {
    return {
      'en': 'Edit task',
      'vi': 'Chỉnh sửa nhiệm vụ',
      'de': 'Aufgabe bearbeiten',
    }[locale.languageCode]!;
  }

  String get editThisList {
    return {
      'en': 'Edit this list',
      'vi': 'Chỉnh sửa danh sách này',
      'de': 'Diese Liste bearbeiten',
    }[locale.languageCode]!;
  }

  String get english {
    return {
      'en': 'English',
      'vi': 'Tiếng Anh',
      'de': 'Englisch',
    }[locale.languageCode]!;
  }

  String get focusTimer {
    return {
      'en': 'Focus timer',
      'vi': 'Hẹn giờ tập trung',
      'de': 'Fokus-Timer',
    }[locale.languageCode]!;
  }

  String get german {
    return {
      'en': 'German',
      'vi': 'Tiếng Đức',
      'de': 'Deutsch',
    }[locale.languageCode]!;
  }

  String get howToUse {
    return {
      'en': 'How to use?',
      'vi': 'Cách sử dụng?',
      'de': 'Wie benutzt man?',
    }[locale.languageCode]!;
  }

  String get list {
    return {
      'en': 'List',
      'vi': 'Danh sách',
      'de': 'Liste',
    }[locale.languageCode]!;
  }

  String get myContacts {
    return {
      'en': 'My contacts',
      'vi': 'Danh bạ của tôi',
      'de': 'Meine Kontakte',
    }[locale.languageCode]!;
  }

  String get myStatistics {
    return {
      'en': 'My statistics',
      'vi': 'Thống kê của tôi',
      'de': 'Meine Statistiken',
    }[locale.languageCode]!;
  }

  String get notes {
    return {
      'en': 'Notes',
      'vi': 'Ghi chú',
      'de': 'Notizen',
    }[locale.languageCode]!;
  }

  String get settings {
    return {
      'en': 'Settings',
      'vi': 'Cài đặt',
      'de': 'Einstellungen',
    }[locale.languageCode]!;
  }

  String get tasksAndEvents {
    return {
      'en': 'Tasks and events',
      'vi': 'Nhiệm vụ và sự kiện',
      'de': 'Aufgaben und Ereignisse',
    }[locale.languageCode]!;
  }

  String get tasks {
    return {
      'en': 'Tasks',
      'vi': 'Nhiệm vụ',
      'de': 'Aufgaben',
    }[locale.languageCode]!;
  }

  String get title {
    return {
      'en': 'Title',
      'vi': 'Tiêu đề',
      'de': 'Titel',
    }[locale.languageCode]!;
  }

  String get vietnamese {
    return {
      'en': 'Vietnamese',
      'vi': 'Tiếng Việt',
      'de': 'Vietnamesisch',
    }[locale.languageCode]!;
  }

  String get overview {
    return {
      'en': 'Overview',
      'vi': 'Tổng quan',
      'de': 'Überblick',
    }[locale.languageCode]!;
  }

  String get brightness {
  return {
    'en': 'Brightness',
    'vi': 'Độ sáng',
    'de': 'Helligkeit',
  }[locale.languageCode]!;
}

String get close {
  return {
    'en': 'Close',
    'vi': 'Đóng',
    'de': 'Schließen',
  }[locale.languageCode]!;
}

String get dark {
  return {
    'en': 'Dark',
    'vi': 'Tối',
    'de': 'Dunkel',
  }[locale.languageCode]!;
}

String get deleteSubtask {
  return {
    'en': 'Delete subtask',
    'vi': 'Xóa nhiệm vụ phụ',
    'de': 'Unteraufgabe löschen',
  }[locale.languageCode]!;
}

String get description {
  return {
    'en': 'Description',
    'vi': 'Mô tả',
    'de': 'Beschreibung',
  }[locale.languageCode]!;
}

String get editMeasurableTask {
  return {
    'en': 'Edit measurable task',
    'vi': 'Chỉnh sửa nhiệm vụ đo lường',
    'de': 'Messbare Aufgabe bearbeiten',
  }[locale.languageCode]!;
}

String get editSubtask {
  return {
    'en': 'Edit Subtask',
    'vi': 'Chỉnh sửa nhiệm vụ phụ',
    'de': 'Unteraufgabe bearbeiten',
  }[locale.languageCode]!;
}

String get endDate {
  return {
    'en': 'End date',
    'vi': 'Ngày kết thúc',
    'de': 'Enddatum',
  }[locale.languageCode]!;
}

String get endTime {
  return {
    'en': 'End time',
    'vi': 'Thời gian kết thúc',
    'de': 'Endzeit',
  }[locale.languageCode]!;
}

String get error {
  return {
    'en': 'Error',
    'vi': 'Lỗi',
    'de': 'Fehler',
  }[locale.languageCode]!;
}

String get focusRightNow {
  return {
    'en': 'Focus right now',
    'vi': 'Tập trung ngay bây giờ',
    'de': 'Jetzt fokussieren',
  }[locale.languageCode]!;
}

String get hideSubTasks {
  return {
    'en': 'Hide sub-tasks',
    'vi': 'Ẩn nhiệm vụ phụ',
    'de': 'Unteraufgaben ausblenden',
  }[locale.languageCode]!;
}

String get invalidValueForAtLeast {
  return {
    'en': 'Invalid value for "at least"',
    'vi': 'Giá trị không hợp lệ cho "ít nhất"',
    'de': 'Ungültiger Wert für "mindestens"',
  }[locale.languageCode]!;
}

String get invalidValueForAtMost {
  return {
    'en': 'Invalid value for "at most"',
    'vi': 'Giá trị không hợp lệ cho "nhiều nhất"',
    'de': 'Ungültiger Wert für "höchstens"',
  }[locale.languageCode]!;
}

String get light {
  return {
    'en': 'Light',
    'vi': 'Sáng',
    'de': 'Licht',
  }[locale.languageCode]!;
}

String get location {
  return {
    'en': 'Location',
    'vi': 'Vị trí',
    'de': 'Ort',
  }[locale.languageCode]!;
}

String get markAsCompleted {
  return {
    'en': 'Mark as completed',
    'vi': 'Đánh dấu là đã hoàn thành',
    'de': 'Als abgeschlossen markieren',
  }[locale.languageCode]!;
}

String get markAsIncompleted {
  return {
    'en': 'Mark as incompleted',
    'vi': 'Đánh dấu là chưa hoàn thành',
    'de': 'Als unvollständig markieren',
  }[locale.languageCode]!;
}

String get pleaseEnterAStartDate {
  return {
    'en': 'Please enter a start date',
    'vi': 'Vui lòng nhập ngày bắt đầu',
    'de': 'Bitte geben Sie ein Startdatum ein',
  }[locale.languageCode]!;
}

String get pleaseEnterAStartTime {
  return {
    'en': 'Please enter a start time',
    'vi': 'Vui lòng nhập thời gian bắt đầu',
    'de': 'Bitte geben Sie eine Startzeit ein',
  }[locale.languageCode]!;
}

String get pleaseEnterAnEndDate {
  return {
    'en': 'Please enter an end date',
    'vi': 'Vui lòng nhập ngày kết thúc',
    'de': 'Bitte geben Sie ein Enddatum ein',
  }[locale.languageCode]!;
}

String get pleaseEnterAnEndTime {
  return {
    'en': 'Please enter an end time',
    'vi': 'Vui lòng nhập thời gian kết thúc',
    'de': 'Bitte geben Sie eine Endzeit ein',
  }[locale.languageCode]!;
}

String get saveTheList {
  return {
    'en': 'Save the list',
    'vi': 'Lưu danh sách',
    'de': 'Liste speichern',
  }[locale.languageCode]!;
}

String get showBrightnessButtonInApplicationBar {
  return {
    'en': 'Show brightness button in application bar',
    'vi': 'Hiển thị nút độ sáng trên thanh ứng dụng',
    'de': 'Helligkeitsschaltfläche in der Anwendungsleiste anzeigen',
  }[locale.languageCode]!;
}

String get showColorImageButtonInApplicationBar {
  return {
    'en': 'Show color image button in application bar',
    'vi': 'Hiển thị nút hình ảnh màu trên thanh ứng dụng',
    'de': 'Farbbildschaltfläche in der Anwendungsleiste anzeigen',
  }[locale.languageCode]!;
}

String get showColorSeedButtonInApplicationBar {
  return {
    'en': 'Show color seed button in application bar',
    'vi': 'Hiển thị nút màu hạt giống trên thanh ứng dụng',
    'de': 'Farbsamenschaltfläche in der Anwendungsleiste anzeigen',
  }[locale.languageCode]!;
}

String get showLanguagesButtonInApplicationBar {
  return {
    'en': 'Show languages button in application bar',
    'vi': 'Hiển thị nút ngôn ngữ trên thanh ứng dụng',
    'de': 'Sprachschaltfläche in der Anwendungsleiste anzeigen',
  }[locale.languageCode]!;
}

String get showMaterialDesignButtonInApplicationBar {
  return {
    'en': 'Show material design button in application bar',
    'vi': 'Hiển thị nút thiết kế vật liệu trên thanh ứng dụng',
    'de': 'Material-Design-Schaltfläche in der Anwendungsleiste anzeigen',
  }[locale.languageCode]!;
}

String get showSubTasks {
  return {
    'en': 'Show sub-tasks',
    'vi': 'Hiển thị nhiệm vụ phụ',
    'de': 'Unteraufgaben anzeigen',
  }[locale.languageCode]!;
}

String get startDate {
  return {
    'en': 'Start date',
    'vi': 'Ngày bắt đầu',
    'de': 'Startdatum',
  }[locale.languageCode]!;
}

String get startTime {
  return {
    'en': 'Start time',
    'vi': 'Thời gian bắt đầu',
    'de': 'Startzeit',
  }[locale.languageCode]!;
}

String get submit {
  return {
    'en': 'Submit',
    'vi': 'Gửi đi',
    'de': 'Einreichen',
  }[locale.languageCode]!;
}

String get targetType {
  return {
    'en': 'Target Type',
    'vi': 'Loại mục tiêu',
    'de': 'Zieltyp',
  }[locale.languageCode]!;
}

String get targetAbout {
  return {
    'en': 'Target: about',
    'vi': 'Mục tiêu: khoảng',
    'de': 'Ziel: ungefähr',
  }[locale.languageCode]!;
}

String get targetAtLeast {
  return {
    'en': 'Target: at least',
    'vi': 'Mục tiêu: ít nhất',
    'de': 'Ziel: mindestens',
  }[locale.languageCode]!;
}

String get targetAtMost {
  return {
    'en': 'Target: at most',
    'vi': 'Mục tiêu: nhiều nhất',
    'de': 'Ziel: höchstens',
  }[locale.languageCode]!;
}

String get timeInterval {
  return {
    'en': 'Time Interval',
    'vi': 'Khoảng thời gian',
    'de': 'Zeitintervall',
  }[locale.languageCode]!;
}

String get to {
  return {
    'en': 'to',
    'vi': 'đến',
    'de': 'zu',
  }[locale.languageCode]!;
}

String get undefined {
  return {
    'en': 'undefined',
    'vi': 'không xác định',
    'de': 'undefiniert',
  }[locale.languageCode]!;
}

String get unit {
  return {
    'en': 'Unit',
    'vi': 'Đơn vị',
    'de': 'Einheit',
  }[locale.languageCode]!;
}

String get userInterfaceSettings {
  return {
    'en': 'User Interface Settings',
    'vi': 'Cài đặt giao diện người dùng',
    'de': 'Benutzeroberflächeneinstellungen',
  }[locale.languageCode]!;
}

String get youAreEnteringAMinimumTargetValueThatIsGreaterThanTheMaximumTargetValue {
  return {
    'en': 'You are entering a minimum target value that is greater than the maximum target value',
    'vi': 'Bạn đang nhập một giá trị mục tiêu tối thiểu lớn hơn giá trị mục tiêu tối đa',
    'de': 'Sie geben einen minimalen Zielwert ein, der größer als der maximale Zielwert ist',
  }[locale.languageCode]!;
}

String get youHaveNotEnteredTheTitleOfTheList {
  return {
    'en': 'You have not entered the title of the list',
    'vi': 'Bạn chưa nhập tiêu đề của danh sách',
    'de': 'Sie haben den Titel der Liste nicht eingegeben',
  }[locale.languageCode]!;
}

String get youHaveNotEnteredTheTitleOfTheTask {
  return {
    'en': 'You have not entered the title of the task',
    'vi': 'Bạn chưa nhập tiêu đề của nhiệm vụ',
    'de': 'Sie haben den Titel der Aufgabe nicht eingegeben',
  }[locale.languageCode]!;
}

String get openLink {
  return {
    'en': 'Open link',
    'vi': 'Mở liên kết',
    'de': 'Link öffnen',
  }[locale.languageCode]!;
}

String get doYouWantToOpenTheLinkInYourDefaultBrowser {
  return {
    'en': 'do you want to open the link in your default browser?',
    'vi': 'bạn có muốn mở liên kết trong trình duyệt mặc định của mình không?',
    'de': 'Möchten Sie den Link in Ihrem Standardbrowser öffnen?',
  }[locale.languageCode]!;
}

String get open {
  return {
    'en': 'Open',
    'vi': 'Mở',
    'de': 'Öffnen',
  }[locale.languageCode]!;
}

String get applicationInformation {
  return {
    'en': 'Application Information',
    'vi': 'Thông tin ứng dụng',
    'de': 'Anwendungsinformationen',
  }[locale.languageCode]!;
}

String get reportAnIssue {
  return {
    'en': 'Report an Issue',
    'vi': 'Báo cáo một vấn đề',
    'de': 'Ein Problem melden',
  }[locale.languageCode]!;
}

String get havingAnIssueReportItHere {
  return {
    'en': 'Having an issue ? Report it here',
    'vi': 'Gặp vấn đề? Báo cáo tại đây',
    'de': 'Ein Problem haben? Melden Sie es hier',
  }[locale.languageCode]!;
}

String get privacyPolicy {
  return {
    'en': 'Privacy Policy',
    'vi': 'Chính sách bảo mật',
    'de': 'Datenschutz-Bestimmungen',
  }[locale.languageCode]!;
}

String get openSource {
  return {
    'en': 'Open Source',
    'vi': 'Mã nguồn mở',
    'de': 'Open Source',
  }[locale.languageCode]!;
}

String get author {
  return {
    'en': 'Author',
    'vi': 'Tác giả',
    'de': 'Autor',
  }[locale.languageCode]!;
}

String get sendAnEmail {
  return {
    'en': 'Send an Email',
    'vi': 'Gửi một Email',
    'de': 'Eine E-Mail senden',
  }[locale.languageCode]!;
}

String get openSourceAnnouncement {
  return {
    'en': 'Open Source Announcement',
    'vi': 'Thông báo mã nguồn mở',
    'de': 'Open-Source-Ankündigung',
  }[locale.languageCode]!;
}

String get thisAppWillBecomeOpenSourceWeWillMakeTheSourceCodePublicAfterCleaningUpTheCode {
  return {
    'en': 'This app will become open source. We will make the source code public after cleaning up the code.',
    'vi': 'Ứng dụng này sẽ trở thành mã nguồn mở. Chúng tôi sẽ công khai mã nguồn sau khi dọn dẹp mã.',
    'de': 'Diese App wird Open Source. Wir werden den Quellcode veröffentlichen, nachdem wir den Code bereinigt haben.',
  }[locale.languageCode]!;
}

String get ok {
  return {
    'en': 'OK',
    'vi': 'Đồng ý',
    'de': 'OK',
  }[locale.languageCode]!;
}

String get supportUs {
  return {
    'en': 'Support us',
    'vi': 'Hỗ trợ chúng tôi',
    'de': 'Unterstützen Sie uns',
  }[locale.languageCode]!;
}

String get important {
  return {
    'en': 'Important',
    'vi': 'Quan trọng',
    'de': 'Wichtig',
  }[locale.languageCode]!;
}

String get hideTargetInfor {
  return {
    'en': 'Hide target infor',
    'vi': 'Ẩn thông tin mục tiêu',
    'de': 'Zielinformationen ausblenden',
  }[locale.languageCode]!;
}

String get showTargetInfor {
  return {
    'en': 'Show target infor',
    'vi': 'Hiển thị thông tin mục tiêu',
    'de': 'Zielinformationen anzeigen',
  }[locale.languageCode]!;
}

String get hasBeenDone {
  return {
    'en': 'has been done:',
    'vi': 'đã hoàn thành:',
    'de': 'wurde erledigt:',
  }[locale.languageCode]!;
}

String get planned {
  return {
    'en': 'Planned',
    'vi': 'Đã lên kế hoạch',
    'de': 'Geplant',
  }[locale.languageCode]!;
}

String get inProgress {
  return {
    'en': 'In progress',
    'vi': 'Đang tiến hành',
    'de': 'In Bearbeitung',
  }[locale.languageCode]!;
}

String get gone {
  return {
    'en': 'Gone',
    'vi': 'Đã qua',
    'de': 'Weg',
  }[locale.languageCode]!;
}

String get today {
  return {
    'en': 'Today',
    'vi': 'Hôm nay',
    'de': 'Heute',
  }[locale.languageCode]!;
}

String get from {
  return {
    'en': 'From',
    'vi': 'Từ',
    'de': 'Von',
  }[locale.languageCode]!;
}

String get markAsIncompletedInThisTimeInterval {
  return {
    'en': 'Mark as incompleted in this time interval',
    'vi': 'Đánh dấu là chưa hoàn thành trong khoảng thời gian này',
    'de': 'Als unvollständig markieren in diesem Zeitintervall',
  }[locale.languageCode]!;
}

String get markAsCompletedInThisTimeInterval {
  return {
    'en': 'Mark as completed in this time interval',
    'vi': 'Đánh dấu là đã hoàn thành trong khoảng thời gian này',
    'de': 'Als abgeschlossen markieren in diesem Zeitintervall',
  }[locale.languageCode]!;
}

String get syncDetailsFromTaskToThisTimeInterval {
  return {
    'en': 'Sync details from task to this time interval',
    'vi': 'Đồng bộ chi tiết từ nhiệm vụ đến khoảng thời gian này',
    'de': 'Details von Aufgabe zu diesem Zeitintervall synchronisieren',
  }[locale.languageCode]!;
}

String get goToMainTask {
  return {
    'en': 'Go to main task',
    'vi': 'Đi đến nhiệm vụ chính',
    'de': 'Zur Hauptaufgabe gehen',
  }[locale.languageCode]!;
}

String get editThisTimeInterval {
  return {
    'en': 'Edit this time interval',
    'vi': 'Chỉnh sửa khoảng thời gian này',
    'de': 'Bearbeiten Sie dieses Zeitintervall',
  }[locale.languageCode]!;
}

String get deleteThisTimeInterval {
  return {
    'en': 'Delete this time interval',
    'vi': 'Xóa khoảng thời gian này',
    'de': 'Löschen Sie dieses Zeitintervall',
  }[locale.languageCode]!;
}

String get update {
  return {
    'en': 'Update',
    'vi': 'Cập nhật',
    'de': 'Aktualisieren',
  }[locale.languageCode]!;
}

String get selectMultipleDays {
  return {
    'en': 'Select multiple days',
    'vi': 'Chọn nhiều ngày',
    'de': 'Wählen Sie mehrere Tage',
  }[locale.languageCode]!;
}

String get selectDateRange {
  return {
    'en': 'Select date range',
    'vi': 'Chọn phạm vi ngày',
    'de': 'Datumsbereich auswählen',
  }[locale.languageCode]!;
}

String get notImportant {
  return {
    'en': 'Not Important',
    'vi': 'Không quan trọng',
    'de': 'Nicht wichtig',
  }[locale.languageCode]!;
}

String get map {
  return {
    'en': 'Map',
    'vi': 'Bản đồ',
    'de': 'Karte',
  }[locale.languageCode]!;
}

String get schedule {
  return {
    'en': 'Schedule',
    'vi': 'Lịch trình',
    'de': 'Zeitplan',
  }[locale.languageCode]!;
}

String get minimum {
  return {
    'en': 'minimum',
    'vi': 'tối thiểu',
    'de': 'Minimum',
  }[locale.languageCode]!;
}

String get maximum {
  return {
    'en': 'maximum',
    'vi': 'tối đa',
    'de': 'Maximum',
  }[locale.languageCode]!;
}



// String get focusRightNow {
//   return {
//     'en': 'Focus right now?',
//     'vi': 'Tập trung ngay bây giờ?',
//     'de': 'Jetzt fokussieren?',
//   }[locale.languageCode]!;
// }

// String get editTask {
//   return {
//     'en': 'Edit Task',
//     'vi': 'Chỉnh sửa nhiệm vụ',
//     'de': 'Aufgabe bearbeiten',
//   }[locale.languageCode]!;
// }





  // String get title => _localizedValues[locale.languageCode]!['title']!;
  // String get english => _localizedValues[locale.languageCode]!['english']!;
  // String get vietnamese =>
  //     _localizedValues[locale.languageCode]!['vietnamese']!;
  // String get german => _localizedValues[locale.languageCode]!['german']!;
  // String get settings => _localizedValues[locale.languageCode]!['settings']!;
  // String get About => _localizedValues1['About']![locale.languageCode]!;
  // String get howToUse => _localizedValues[locale.languageCode]!['how to use']!;
  // String get tasks => _localizedValues[locale.languageCode]!['tasks']!;
  // String get list => _localizedValues[locale.languageCode]!['list']!;
  // String get deleteTask =>
  //     _localizedValues[locale.languageCode]!['delete task']!;
  // String get areYouSureYouWantToDeleteThisTask => _localizedValues[
  //     locale.languageCode]!['Are you sure you want to delete this task?']!;
  // String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  // String get delete => _localizedValues[locale.languageCode]!['delete']!;
  // String get addANewTask =>
  //     _localizedValues[locale.languageCode]!['add a new task']!;
  // String get addANewMeasureableTask =>
  //     _localizedValues[locale.languageCode]!['add a new measureable task']!;
  // String get addANewTaskWithSubtasks =>
  //     _localizedValues[locale.languageCode]!['add a new task with sub-tasks']!;
  // String get addToThisList =>
  //     _localizedValues[locale.languageCode]!['add to this list']!;
  // String get addANewEvent =>
  //     _localizedValues[locale.languageCode]!['add a new event']!;
  // String get editThisList =>
  //     _localizedValues[locale.languageCode]!['edit this list']!;
  // String get deleteThisList =>
  //     _localizedValues[locale.languageCode]!['delete this list']!;
  // String get editTask => _localizedValues[locale.languageCode]!['edit task']!;
  // String get tasksAndEvents =>
  //     _localizedValues[locale.languageCode]!['tasks and events']!;
  // String get calendar => _localizedValues[locale.languageCode]!['calendar']!;
  // String get myStatistics =>
  //     _localizedValues[locale.languageCode]!['my statistics']!;
  // String get focusTimer =>
  //     _localizedValues[locale.languageCode]!['focus timer']!;
  // String get myContacts =>
  //     _localizedValues[locale.languageCode]!['my contacts']!;
  // String get notes => _localizedValues[locale.languageCode]!['notes']!;
  // String get showBrightnessButtonInApplicationBar => _localizedValues[
  //     locale.languageCode]!['show brightness button in application bar']!;
  // String get showMaterialDesignButtonInApplicationBar => _localizedValues[
  //     locale.languageCode]!['show material design button in application bar']!;
  // String get showColorSeedButtonInApplicationBar => _localizedValues[
  //     locale.languageCode]!['show color seed button in application bar']!;
  // String get showColorImageButtonInApplicationBar => _localizedValues[
  //     locale.languageCode]!['show color image button in application bar']!;
  // String get showLanguagesButtonInApplicationBar => _localizedValues[
  //     locale.languageCode]!['show languages button in application bar']!;
  // String get markAsIncompleted =>
  //     _localizedValues[locale.languageCode]!['mark as incompleted']!;
  // String get markAsCompleted =>
  //     _localizedValues[locale.languageCode]!['mark as completed']!;
  // String get addTimeInterval =>
  //     _localizedValues[locale.languageCode]!['add time interval']!;
  // String get focusRightNow =>
  //     _localizedValues[locale.languageCode]!['focus right now?']!;
  // String get targetAbout =>
  //     _localizedValues[locale.languageCode]!['target: about']!;
  // String get targetAtLeast =>
  //     _localizedValues[locale.languageCode]!['target: at least']!;
  // String get targetAtMost =>
  //     _localizedValues[locale.languageCode]!['target: at most']!;
  // String get hasBeenDone =>
  //     _localizedValues[locale.languageCode]!['has been done:']!;
  // String get to => _localizedValues[locale.languageCode]!['to']!;
  // String get hideSubTasks =>
  //     _localizedValues[locale.languageCode]!['Hide sub-tasks']!;
  // String get showSubTasks =>
  //     _localizedValues[locale.languageCode]!['Show sub-tasks']!;
  // String get deleteSubtask =>
  //     _localizedValues[locale.languageCode]!['Delete Subtask']!;
  // String get areYouSureYouWantToDeleteThisSubtask => _localizedValues[
  //     locale.languageCode]!['Are you sure you want to delete this subtask?']!;
  // String get youHaveNotEnteredTheTitleOfTheList => _localizedValues[
  //     locale.languageCode]!['You have not entered the title of the list']!;
  // String get close => _localizedValues[locale.languageCode]!['Close']!;
  // String get description =>
  //     _localizedValues[locale.languageCode]!['Description']!;
  // String get saveTheList =>
  //     _localizedValues[locale.languageCode]!['Save the list']!;
  // String get youHaveNotEnteredTheTitleOfTheTask => _localizedValues[
  //     locale.languageCode]!['You have not entered the title of the task']!;
  // String get location => _localizedValues[locale.languageCode]!['Location']!;
  // String get error => _localizedValues[locale.languageCode]!['Error']!;
  // String get invalidValueForAtLeast =>
  //     _localizedValues[locale.languageCode]!['Invalid value for "at least"']!;
  // String get invalidValueForAtMost =>
  //     _localizedValues[locale.languageCode]!['Invalid value for "at most"']!;
  // String get youAreEnteringAMinimumTargetValueThatIsGreaterThanTheMaximumTargetValue =>
  //     _localizedValues[locale.languageCode]![
  //         'You are entering a minimum target value that is greater than the maximum target value']!;
  // String get addNewMeasurableTask =>
  //     _localizedValues[locale.languageCode]!['Add new measurable task']!;
  // String get editMeasurableTask =>
  //     _localizedValues[locale.languageCode]!['Edit measurable task']!;
  // String get atLeast => _localizedValues[locale.languageCode]!['at least']!;
  // String get atMost => _localizedValues[locale.languageCode]!['at most']!;
  // String get about => _localizedValues[locale.languageCode]!['about']!;
  // String get targetType =>
  //     _localizedValues[locale.languageCode]!['Target Type']!;
  // String get unit => _localizedValues[locale.languageCode]!['Unit']!;
  // String get editSubtask =>
  //     _localizedValues[locale.languageCode]!['Edit Subtask']!;
  // String get addSubtask =>
  //     _localizedValues[locale.languageCode]!['Add Subtask']!;
  // String get timeInterval =>
  //     _localizedValues[locale.languageCode]!['Time Interval']!;
  // String get undefined => _localizedValues[locale.languageCode]!['undefined']!;
  // String get pleaseEnterAStartDate =>
  //     _localizedValues[locale.languageCode]!['Please enter a start date']!;
  // String get startDate => _localizedValues[locale.languageCode]!['Start date']!;
  // String get pleaseEnterAStartTime =>
  //     _localizedValues[locale.languageCode]!['Please enter a start time']!;
  // String get startTime => _localizedValues[locale.languageCode]!['Start time']!;
  // String get pleaseEnterAnEndDate =>
  //     _localizedValues[locale.languageCode]!['Please enter an end date']!;
  // String get endDate => _localizedValues[locale.languageCode]!['End date']!;
  // String get pleaseEnterAnEndTime =>
  //     _localizedValues[locale.languageCode]!['Please enter an end time']!;
  // String get endTime => _localizedValues[locale.languageCode]!['End time']!;
  String get pleaseEnterAtLeastOneDate =>
      _localizedValues[locale.languageCode]!['Please enter at least one date']!;
  String get theStartTimeMustNotOccurAfterTheEndTime =>
      _localizedValues[locale.languageCode]![
          'The start time must not occur after the end time']!;
  // String get submit => _localizedValues[locale.languageCode]!['Submit']!;
  // String get userInterfaceSettings =>
  //     _localizedValues[locale.languageCode]!['User Interface Settings']!;
  // String get brightness =>
  //     _localizedValues[locale.languageCode]!['Brightness']!;
  // String get light => _localizedValues[locale.languageCode]!['Light']!;
  // String get dark => _localizedValues[locale.languageCode]!['Dark']!;
  // String get chooseThemeColor =>
  //     _localizedValues[locale.languageCode]!['Choose theme color']!;
  // String get chooseThemeColorFromImageColor => _localizedValues[
  //     locale.languageCode]!['Choose theme color from image color']!;
  // String get chooseApplicationLanguage =>
  //     _localizedValues[locale.languageCode]!['Choose application language']!;
  // String get openLink => _localizedValues[locale.languageCode]!['Open link']!;
  // String get doYouWantToOpenTheLinkInYourDefaultBrowser =>
  //     _localizedValues[locale.languageCode]![
  //         'do you want to open the link in your default browser?']!;
  // String get applicationInformation =>
  //     _localizedValues[locale.languageCode]!['Application Information']!;
  // String get reportAnIssue =>
  //     _localizedValues[locale.languageCode]!['Report an Issue']!;
  // String get havingAnIssueReportItHere => _localizedValues[
  //     locale.languageCode]!['Having an issue ? Report it here']!;
  // String get privacyPolicy =>
  //     _localizedValues[locale.languageCode]!['Privacy Policy']!;
  // String get openSource =>
  //     _localizedValues[locale.languageCode]!['Open Source']!;
  // String get author => _localizedValues[locale.languageCode]!['Author']!;
  // String get sendAnEmail =>
  //     _localizedValues[locale.languageCode]!['Send an Email']!;
  //String get Open => _localizedValues[locale.languageCode]!['Open']!;
  // String get openSourceAnnouncement {
  //   return _localizedValues[locale.languageCode]!['Open Source Announcement']!;
  // }

  String get appBecomingOpenSource {
    return _localizedValues[locale.languageCode]![
        'This app will become open source. We will make the source code public after cleaning up the code.']!;
  }

  // String get ok {
  //   return _localizedValues[locale.languageCode]!['OK']!;
  // }

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  static const _localizedValues1 = {
    'About': {
      'en': 'About',
      'vi': 'Thông tin',
      'de': 'Uber uns',
    },
    'add a new event': {
      'en': 'Add a new event',
      'vi': 'Thêm sự kiện mới',
      'de': 'Fugen Sie ein neues Ereignis hinzu',
    },
    'add a new measureable task': {
      'en': 'Add a new measureable task',
      'vi': 'Thêm nhiệm vụ đo lường mới',
      'de': 'Fugen Sie eine neue messbare Aufgabe hinzu',
    },
    'add a new task': {
      'en': 'Add a new task',
      'vi': 'Thêm nhiệm vụ mới',
      'de': 'Fugen Sie eine neue Aufgabe hinzu',
    },
    'add a new task with sub-tasks': {
      'en': 'Add a new task with sub-tasks',
      'vi': 'Thêm nhiệm vụ mới với các nhiệm vụ phụ',
      'de': 'Fugen Sie eine neue Aufgabe mit Unteraufgaben hinzu',
    },
    'add to this list': {
      'en': 'Add to this list',
      'vi': 'Thêm vào danh sách này',
      'de': 'Fugen Sie dieser Liste hinzu',
    },
    'Are you sure you want to delete this task?': {
      'en': 'Are you sure you want to delete this task?',
      'vi': 'Bạn có chắc chắn muốn xóa nhiệm vụ này không?',
      'de': 'Sind Sie sicher, dass Sie diese Aufgabe loschen mochten?',
    },
    'Add new measurable task': {
      'en': 'Add new measurable task',
      'vi': 'Thêm nhiệm vụ đo lường mới',
      'de': 'Fugen Sie eine neue messbare Aufgabe hinzu',
    },
    'Add Subtask': {
      'en': 'Add Subtask',
      'vi': 'Thêm nhiệm vụ phụ',
      'de': 'Unteraufgabe hinzufugen',
    },
    'Add time interval': {
      'en': 'Add time interval',
      'vi': 'Thêm khoảng thời gian',
      'de': 'Zeitintervall hinzufugen',
    },
    'Are you sure you want to delete this subtask?': {
      'en': 'Are you sure you want to delete this subtask?',
      'vi': 'Bạn có chắc chắn muốn xóa nhiệm vụ phụ này không?',
      'de': 'Sind Sie sicher, dass Sie diese Unteraufgabe loschen mochten?',
    },
    'at least': {
      'en': 'at least',
      'vi': 'ít nhất',
      'de': 'mindestens',
    },
    'at most': {
      'en': 'at most',
      'vi': 'nhiều nhất',
      'de': 'hochstens',
    },
    'about': {
      'en': 'about',
      'vi': 'về',
      'de': 'uber',
    },
    'calendar': {
      'en': 'Calendar',
      'vi': 'Lịch',
      'de': 'Kalender',
    },
    'cancel': {
      'en': 'Cancel',
      'vi': 'Hủy',
      'de': 'Stornieren',
    },
    'Choose theme color': {
      'en': 'Choose theme color',
      'vi': 'Chọn màu chủ đề',
      'de': 'Wahlen Sie die Themenfarbe',
    },
    'Choose theme color from image color': {
      'en': 'Choose theme color from image color',
      'vi': 'Chọn màu chủ đề từ màu hình ảnh',
      'de': 'Wahlen Sie die Themenfarbe aus der Bildfarbe',
    },
    'Choose application language': {
      'en': 'Choose application language',
      'vi': 'Chọn ngôn ngữ ứng dụng',
      'de': 'Wahlen Sie die Anwendungssprache',
    },
    'delete': {
      'en': 'Delete',
      'vi': 'Xóa',
      'de': 'Loschen',
    },
    'delete task': {
      'en': 'Delete task',
      'vi': 'Xóa nhiệm vụ',
      'de': 'Aufgabe loschen',
    },
    'delete this list': {
      'en': 'Delete this list',
      'vi': 'Xóa danh sách này',
      'de': 'Diese Liste loschen',
    },
    'edit task': {
      'en': 'Edit task',
      'vi': 'Chỉnh sửa nhiệm vụ',
      'de': 'Aufgabe bearbeiten',
    },
    'edit this list': {
      'en': 'Edit this list',
      'vi': 'Chỉnh sửa danh sách này',
      'de': 'Diese Liste bearbeiten',
    },
    'english': {
      'en': 'English',
      'vi': 'Tiếng Anh',
      'de': 'Englisch',
    },
    'focus timer': {
      'en': 'Focus timer',
      'vi': 'Hẹn giờ tập trung',
      'de': 'Fokus-Timer',
    },
    'german': {
      'en': 'German',
      'vi': 'Tiếng Đức',
      'de': 'Deutsch',
    },
    'how to use': {
      'en': 'How to use?',
      'vi': 'Làm thế nào để sử dụng?',
      'de': 'Wie benutzt man das?',
    },
    'list': {
      'en': 'List',
      'vi': 'Danh sách',
      'de': 'Liste',
    },
    'my contacts': {
      'en': 'My contacts',
      'vi': 'Danh bạ của tôi',
      'de': 'Meine Kontakte',
    },
    'my statistics': {
      'en': 'My statistics',
      'vi': 'Thống kê của tôi',
      'de': 'Meine Statistiken',
    },
    'notes': {
      'en': 'Notes',
      'vi': 'Ghi chú',
      'de': 'Notizen',
    },
    'settings': {
      'en': 'Settings',
      'vi': 'Cài đặt',
      'de': 'Einstellungen',
    },
    'tasks and events': {
      'en': 'Tasks and events',
      'vi': 'Nhiệm vụ và sự kiện',
      'de': 'Aufgaben und Ereignisse',
    },
    'tasks': {
      'en': 'Tasks',
      'vi': 'Nhiệm vụ',
      'de': 'Aufgaben',
    },
    'title': {
      'en': 'Title',
      'vi': 'Tiêu đề',
      'de': 'Titel',
    },
    'vietnamese': {
      'en': 'Vietnamese',
      'vi': 'Tiếng Việt',
      'de': 'Vietnamesisch',
    },
    'Brightness': {
      'en': 'Brightness',
      'vi': 'Độ sáng',
      'de': 'Helligkeit',
    },
    'Close': {
      'en': 'Close',
      'vi': 'Đóng',
      'de': 'Schließen',
    },
    'Dark': {
      'en': 'Dark',
      'vi': 'Tối',
      'de': 'Dunkel',
    },
    'Delete Subtask': {
      'en': 'Delete subtask',
      'vi': 'Xóa nhiệm vụ phụ',
      'de': 'Unteraufgabe löschen',
    },
    'Description': {
      'en': 'Description',
      'vi': 'Mô tả',
      'de': 'Beschreibung',
    },
    'Edit measurable task': {
      'en': 'Edit measurable task',
      'vi': 'Chỉnh sửa nhiệm vụ đo lường',
      'de': 'Messbare Aufgabe bearbeiten',
    },
    'Edit Subtask': {
      'en': 'Edit Subtask',
      'vi': 'Chỉnh sửa nhiệm vụ phụ',
      'de': 'Unteraufgabe bearbeiten',
    },
    'End date': {
      'en': 'End date',
      'vi': 'Ngày kết thúc',
      'de': 'Enddatum',
    },
    'End time': {
      'en': 'End time',
      'vi': 'Thời gian kết thúc',
      'de': 'Endzeit',
    },
    'Error': {
      'en': 'Error',
      'vi': 'Lỗi',
      'de': 'Fehler',
    },
    'focus right now?': {
      'en': 'Focus right now',
      'vi': 'Tập trung ngay bây giờ',
      'de': 'Jetzt fokussieren',
    },
    'Hide sub-tasks': {
      'en': 'Hide sub-tasks',
      'vi': 'Ẩn nhiệm vụ phụ',
      'de': 'Unteraufgaben ausblenden',
    },
    'Invalid value for "at least"': {
      'en': 'Invalid value for "at least"',
      'vi': 'Giá trị không hợp lệ cho "ít nhất"',
      'de': 'Ungültiger Wert für "mindestens"',
    },
    'Invalid value for "at most"': {
      'en': 'Invalid value for "at most"',
      'vi': 'Giá trị không hợp lệ cho "nhiều nhất"',
      'de': 'Ungültiger Wert für "höchstens"',
    },
    'Light': {
      'en': 'Light',
      'vi': 'Sáng',
      'de': 'Licht',
    },
    'Location': {
      'en': 'Location',
      'vi': 'Vị trí',
      'de': 'Ort',
    },
    'mark as completed': {
      'en': 'Mark as completed',
      'vi': 'Đánh dấu là đã hoàn thành',
      'de': 'Als abgeschlossen markieren',
    },
    'mark as incompleted': {
      'en': 'Mark as incompleted',
      'vi': 'Đánh dấu là chưa hoàn thành',
      'de': 'Als unvollständig markieren',
    },
    'Please enter a start date': {
      'en': 'Please enter a start date',
      'vi': 'Vui lòng nhập ngày bắt đầu',
      'de': 'Bitte geben Sie ein Startdatum ein',
    },
    'Please enter a start time': {
      'en': 'Please enter a start time',
      'vi': 'Vui lòng nhập thời gian bắt đầu',
      'de': 'Bitte geben Sie eine Startzeit ein',
    },
    'Please enter an end date': {
      'en': 'Please enter an end date',
      'vi': 'Vui lòng nhập ngày kết thúc',
      'de': 'Bitte geben Sie ein Enddatum ein',
    },
    'Please enter an end time': {
      'en': 'Please enter an end time',
      'vi': 'Vui lòng nhập thời gian kết thúc',
      'de': 'Bitte geben Sie eine Endzeit ein',
    },
    'Save the list': {
      'en': 'Save the list',
      'vi': 'Lưu danh sách',
      'de': 'Liste speichern',
    },
    'show brightness button in application bar': {
      'en': 'Show brightness button in application bar',
      'vi': 'Hiển thị nút độ sáng trên thanh ứng dụng',
      'de': 'Helligkeitsschaltfläche in der Anwendungsleiste anzeigen',
    },
    'show color image button in application bar': {
      'en': 'Show color image button in application bar',
      'vi': 'Hiển thị nút hình ảnh màu trên thanh ứng dụng',
      'de': 'Farbbildschaltfläche in der Anwendungsleiste anzeigen',
    },
    'show color seed button in application bar': {
      'en': 'Show color seed button in application bar',
      'vi': 'Hiển thị nút màu hạt giống trên thanh ứng dụng',
      'de': 'Farbsamenschaltfläche in der Anwendungsleiste anzeigen',
    },
    'show languages button in application bar': {
      'en': 'Show languages button in application bar',
      'vi': 'Hiển thị nút ngôn ngữ trên thanh ứng dụng',
      'de': 'Sprachschaltfläche in der Anwendungsleiste anzeigen',
    },
    'show material design button in application bar': {
      'en': 'Show material design button in application bar',
      'vi': 'Hiển thị nút thiết kế vật liệu trên thanh ứng dụng',
      'de': 'Material-Design-Schaltfläche in der Anwendungsleiste anzeigen',
    },
    'Show sub-tasks': {
      'en': 'Show sub-tasks',
      'vi': 'Hiển thị nhiệm vụ phụ',
      'de': 'Unteraufgaben anzeigen',
    },
    'Start date': {
      'en': 'Start date',
      'vi': 'Ngày bắt đầu',
      'de': 'Startdatum',
    },
    'Start time': {
      'en': 'Start time',
      'vi': 'Thời gian bắt đầu',
      'de': 'Startzeit',
    },
    'Submit': {
      'en': 'Submit',
      'vi': 'Gửi đi',
      'de': 'Einreichen',
    },
    'Target Type': {
      'en': 'Target Type',
      'vi': 'Loại mục tiêu',
      'de': 'Zieltyp',
    },
    'target: about': {
      'en': 'Target: about',
      'vi': 'Mục tiêu: khoảng',
      'de': 'Ziel: ungefähr',
    },
    'target: at least': {
      'en': 'Target: at least',
      'vi': 'Mục tiêu: ít nhất',
      'de': 'Ziel: mindestens',
    },
    'target: at most': {
      'en': 'Target: at most',
      'vi': 'Mục tiêu: nhiều nhất',
      'de': 'Ziel: höchstens',
    },
    'Time Interval': {
      'en': 'Time Interval',
      'vi': 'Khoảng thời gian',
      'de': 'Zeitintervall',
    },
    'to': {
      'en': 'to',
      'vi': 'đến',
      'de': 'zu',
    },
    'undefined': {
      'en': 'undefined',
      'vi': 'không xác định',
      'de': 'undefiniert',
    },
    'Unit': {
      'en': 'Unit',
      'vi': 'Đơn vị',
      'de': 'Einheit',
    },
    'User Interface Settings': {
      'en': 'User Interface Settings',
      'vi': 'Cài đặt giao diện người dùng',
      'de': 'Benutzeroberflächeneinstellungen',
    },
  };

  String translate1(String key, String languageCode) {
    return _localizedValues1[key]![languageCode]!;
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
