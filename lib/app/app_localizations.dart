import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  String get aboutUs {
    return {
      'en': 'About us',
      'vi': 'Thông tin',
      'de': 'Über uns',
      'cs': 'O nás',
      'es': 'Sobre nosotros',
      'fr': 'À propos de nous',
      'it': 'Riguardo a noi',
      'ja': '私たちについて',
      'ko': '우리에 대해',
      'no': 'Om oss',
      'ru': 'О нас',
      'sv': 'Om oss',
      'zh': '关于我们',
    }[locale.languageCode]!;
  }

  String get addANewEvent {
    return {
      'en': 'Add a new event',
      'vi': 'Thêm một sự kiện mới',
      'de': 'Ein neues Ereignis hinzufügen',
      'cs': 'Přidat novou událost',
      'es': 'Agregar un nuevo evento',
      'fr': 'Ajouter un nouvel événement',
      'it': 'Aggiungi un nuovo evento',
      'ja': '新しいイベントを追加',
      'ko': '새 이벤트 추가',
      'no': 'Legg til en ny hendelse',
      'ru': 'Добавить новое событие',
      'sv': 'Lägg till en ny händelse',
      'zh': '添加新事件',
    }[locale.languageCode]!;
  }

  String get addANewMeasureableTask {
    return {
      'en': 'Add a new measureable task',
      'vi': 'Thêm một nhiệm vụ định lượng mới',
      'de': 'Eine neue messbare Aufgabe hinzufügen',
      'cs': 'Přidat nový měřitelný úkol',
      'es': 'Agregar una nueva tarea medible',
      'fr': 'Ajouter une nouvelle tâche mesurable',
      'it': 'Aggiungi un nuovo compito misurabile',
      'ja': '新しい測定可能なタスクを追加',
      'ko': '새로운 측정 가능한 작업 추가',
      'no': 'Legg til en ny målbar oppgave',
      'ru': 'Добавить новую измеримую задачу',
      'sv': 'Lägg till en ny mätbar uppgift',
      'zh': '添加新的可衡量任务',
    }[locale.languageCode]!;
  }

  String get addANewTask {
    return {
      'en': 'Add a new task',
      'vi': 'Thêm một nhiệm vụ mới',
      'de': 'Eine neue Aufgabe hinzufügen',
      'cs': 'Přidat nový úkol',
      'es': 'Agregar una nueva tarea',
      'fr': 'Ajouter une nouvelle tâche',
      'it': 'Aggiungi un nuovo compito',
      'ja': '新しいタスクを追加',
      'ko': '새 작업 추가',
      'no': 'Legg til en ny oppgave',
      'ru': 'Добавить новую задачу',
      'sv': 'Lägg till en ny uppgift',
      'zh': '添加新任务',
    }[locale.languageCode]!;
  }

  String get addANewTaskWithSubTasks {
    return {
      'en': 'Add a new task with sub-tasks',
      'vi': 'Thêm một nhiệm vụ mới với các nhiệm vụ phụ',
      'de': 'Eine neue Aufgabe mit Unteraufgaben hinzufügen',
      'cs': 'Přidat nový úkol s dílčími úkoly',
      'es': 'Agregar una nueva tarea con subtareas',
      'fr': 'Ajouter une nouvelle tâche avec des sous-tâches',
      'it': 'Aggiungi un nuovo compito con sottocompiti',
      'ja': 'サブタスクを持つ新しいタスクを追加',
      'ko': '하위 작업이 있는 새 작업 추가',
      'no': 'Legg til en ny oppgave med underoppgaver',
      'ru': 'Добавить новую задачу с подзадачами',
      'sv': 'Lägg till en ny uppgift med deluppgifter',
      'zh': '添加带有子任务的新任务',
    }[locale.languageCode]!;
  }

  String get addToThisList {
    return {
      'en': 'Add to this list',
      'vi': 'Thêm vào danh sách này',
      'de': 'Zu dieser Liste hinzufügen',
      'cs': 'Přidat do tohoto seznamu',
      'es': 'Agregar a esta lista',
      'fr': 'Ajouter à cette liste',
      'it': 'Aggiungi a questa lista',
      'ja': 'このリストに追加',
      'ko': '이 목록에 추가',
      'no': 'Legg til i denne listen',
      'ru': 'Добавить в этот список',
      'sv': 'Lägg till i den här listan',
      'zh': '添加到此列表',
    }[locale.languageCode]!;
  }

  String get areYouSureYouWantToDeleteThisTask {
    return {
      'en': 'Are you sure you want to delete this task?',
      'vi': 'Bạn có chắc chắn muốn xóa nhiệm vụ này không?',
      'de': 'Sind Sie sicher, dass Sie diese Aufgabe löschen möchten?',
      'cs': 'Opravdu chcete tuto úlohu smazat?',
      'es': '¿Estás seguro de que quieres eliminar esta tarea?',
      'fr': 'Êtes-vous sûr de vouloir supprimer cette tâche?',
      'it': 'Sei sicuro di voler eliminare questo compito?',
      'ja': 'このタスクを削除してもよろしいですか？',
      'ko': '이 작업을 삭제하시겠습니까?',
      'no': 'Er du sikker på at du vil slette denne oppgaven?',
      'ru': 'Вы уверены, что хотите удалить эту задачу?',
      'sv': 'Är du säker på att du vill ta bort denna uppgift?',
      'zh': '您确定要删除此任务吗？',
    }[locale.languageCode]!;
  }

  String get addSubtask {
    return {
      'en': 'Add Subtask',
      'vi': 'Thêm nhiệm vụ phụ',
      'de': 'Unteraufgabe hinzufügen',
      'cs': 'Přidat dílčí úkol',
      'es': 'Agregar subtarea',
      'fr': 'Ajouter une sous-tâche',
      'it': 'Aggiungi sottocompito',
      'ja': 'サブタスクを追加',
      'ko': '하위 작업 추가',
      'no': 'Legg til underoppgave',
      'ru': 'Добавить подзадачу',
      'sv': 'Lägg till underuppgift',
      'zh': '添加子任务',
    }[locale.languageCode]!;
  }

  String get addTimeInterval {
    return {
      'en': 'Add time interval',
      'vi': 'Thêm khoảng thời gian',
      'de': 'Zeitintervall hinzufügen',
      'cs': 'Přidat časový interval',
      'es': 'Agregar intervalo de tiempo',
      'fr': 'Ajouter un intervalle de temps',
      'it': 'Aggiungi intervallo di tempo',
      'ja': '時間間隔を追加',
      'ko': '시간 간격 추가',
      'no': 'Legg til tidsintervall',
      'ru': 'Добавить временной интервал',
      'sv': 'Lägg till tidsintervall',
      'zh': '添加时间间隔',
    }[locale.languageCode]!;
  }

  String get areYouSureYouWantToDeleteThisSubtask {
    return {
      'en': 'Are you sure you want to delete this subtask',
      'vi': 'Bạn có chắc chắn muốn xóa nhiệm vụ phụ này',
      'de': 'Sind Sie sicher, dass Sie diese Unteraufgabe löschen möchten',
      'cs': 'Opravdu chcete smazat tuto dílčí úlohu',
      'es': '¿Estás seguro de que quieres eliminar esta subtarea?',
      'fr': 'Êtes-vous sûr de vouloir supprimer cette sous-tâche',
      'it': 'Sei sicuro di voler eliminare questo sottocompito',
      'ja': 'このサブタスクを削除してもよろしいですか',
      'ko': '이 하위 작업을 삭제하시겠습니까',
      'no': 'Er du sikker på at du vil slette denne underoppgaven',
      'ru': 'Вы уверены, что хотите удалить эту подзадачу',
      'sv': 'Är du säker på att du vill ta bort denna underuppgift',
      'zh': '您确定要删除此子任务吗',
    }[locale.languageCode]!;
  }

  String get atLeast {
    return {
      'en': 'at least',
      'vi': 'ít nhất',
      'de': 'mindestens',
      'cs': 'alespoň',
      'es': 'al menos',
      'fr': 'au moins',
      'it': 'almeno',
      'ja': '少なくとも',
      'ko': '적어도',
      'no': 'minst',
      'ru': 'по крайней мере',
      'sv': 'minst',
      'zh': '至少',
    }[locale.languageCode]!;
  }

  String get atMost {
    return {
      'en': 'at most',
      'vi': 'nhiều nhất',
      'de': 'höchstens',
      'cs': 'nejvýše',
      'es': 'como máximo',
      'fr': 'au plus',
      'it': 'al massimo',
      'ja': '最大',
      'ko': '최대',
      'no': 'høyst',
      'ru': 'максимум',
      'sv': 'högst',
      'zh': '最多',
    }[locale.languageCode]!;
  }

  String get about {
    return {
      'en': 'about',
      'vi': 'khoảng',
      'de': 'ungefähr',
      'cs': 'o',
      'es': 'acerca de',
      'fr': 'à propos',
      'it': 'circa',
      'ja': '約',
      'ko': '약',
      'no': 'om',
      'ru': 'около',
      'sv': 'om',
      'zh': '关于',
    }[locale.languageCode]!;
  }

  String get calendar {
    return {
      'en': 'Calendar',
      'vi': 'Lịch',
      'de': 'Kalender',
      'cs': 'Kalendář',
      'es': 'Calendario',
      'fr': 'Calendrier',
      'it': 'Calendario',
      'ja': 'カレンダー',
      'ko': '달력',
      'no': 'Kalender',
      'ru': 'Календарь',
      'sv': 'Kalender',
      'zh': '日历',
    }[locale.languageCode]!;
  }

  String get cancel {
    return {
      'en': 'Cancel',
      'vi': 'Hủy bỏ',
      'de': 'Stornieren',
      'cs': 'Zrušit',
      'es': 'Cancelar',
      'fr': 'Annuler',
      'it': 'Annulla',
      'ja': 'キャンセル',
      'ko': '취소',
      'no': 'Avbryt',
      'ru': 'Отмена',
      'sv': 'Avbryt',
      'zh': '取消',
    }[locale.languageCode]!;
  }

  String get chooseThemeColor {
    return {
      'en': 'Choose theme color',
      'vi': 'Chọn màu chủ đề',
      'de': 'Wählen Sie die Themenfarbe',
      'cs': 'Vyberte barvu tématu',
      'es': 'Elige el color del tema',
      'fr': 'Choisissez la couleur du thème',
      'it': 'Scegli il colore del tema',
      'ja': 'テーマの色を選択',
      'ko': '테마 색상 선택',
      'no': 'Velg tema farge',
      'ru': 'Выберите цвет темы',
      'sv': 'Välj temafärg',
      'zh': '选择主题颜色',
    }[locale.languageCode]!;
  }

  String get chooseThemeColorFromImageColor {
    return {
      'en': 'Choose theme color from image color',
      'vi': 'Chọn màu chủ đề từ màu hình ảnh',
      'de': 'Wählen Sie die Themenfarbe aus der Bildfarbe',
      'cs': 'Vyberte barvu tématu z barvy obrázku',
      'es': 'Elige el color del tema del color de la imagen',
      'fr': 'Choisissez la couleur du thème à partir de la couleur de l\'image',
      'it': 'Scegli il colore del tema dal colore dell\'immagine',
      'ja': '画像の色からテーマの色を選択',
      'ko': '이미지 색상에서 테마 색상 선택',
      'no': 'Velg tema farge fra bildefarge',
      'ru': 'Выберите цвет темы из цвета изображения',
      'sv': 'Välj temafärg från bildfärg',
      'zh': '从图像颜色中选择主题颜色',
    }[locale.languageCode]!;
  }

  String get chooseApplicationLanguage {
    return {
      'en': 'Choose application language',
      'vi': 'Chọn ngôn ngữ ứng dụng',
      'de': 'Wählen Sie die Anwendungssprache',
      'cs': 'Vyberte jazyk aplikace',
      'es': 'Elige el idioma de la aplicación',
      'fr': 'Choisissez la langue de l\'application',
      'it': 'Scegli la lingua dell\'applicazione',
      'ja': 'アプリケーションの言語を選択',
      'ko': '응용 프로그램 언어 선택',
      'no': 'Velg applikasjonsspråk',
      'ru': 'Выберите язык приложения',
      'sv': 'Välj applikationsspråk',
      'zh': '选择应用语言',
    }[locale.languageCode]!;
  }

  String get taskCardStyle {
    return {
      'en': 'Task card style',
      'vi': 'Kiểu thẻ công việc',
      'de': 'Stil der Aufgabenkarte',
      'cs': 'Styl karty úkolu',
      'es': 'Estilo de la tarjeta de tarea',
      'fr': 'Style de la carte de tâche',
      'it': 'Stile della scheda attività',
      'ja': 'タスクカードのスタイル',
      'ko': '작업 카드 스타일',
      'no': 'Stil for oppgavekort',
      'ru': 'Стиль карточки задачи',
      'sv': 'Stil på uppgiftskort',
      'zh': '任务卡片样式',
    }[locale.languageCode]!;
  }

  String get taskCardStyleFilled {
    return {
      'en': 'Filled background',
      'vi': 'Nền đầy màu',
      'de': 'Gefüllter Hintergrund',
      'cs': 'Vyplněné pozadí',
      'es': 'Fondo relleno',
      'fr': 'Fond rempli',
      'it': 'Sfondo pieno',
      'ja': '塗りつぶし背景',
      'ko': '채운 배경',
      'no': 'Fylt bakgrunn',
      'ru': 'Заливка фона',
      'sv': 'Fylld bakgrund',
      'zh': '填充背景',
    }[locale.languageCode]!;
  }

  String get taskCardStyleLeadingBar {
    return {
      'en': 'Colored side bar',
      'vi': 'Dải màu bên trái',
      'de': 'Farbiger Seitenbalken',
      'cs': 'Barevný boční pruh',
      'es': 'Barra lateral de color',
      'fr': 'Barre latérale colorée',
      'it': 'Barra laterale colorata',
      'ja': '色付きサイドバー',
      'ko': '색상 사이드 바',
      'no': 'Farget sidestolpe',
      'ru': 'Цветная боковая полоса',
      'sv': 'Färgad sidorad',
      'zh': '彩色侧边条',
    }[locale.languageCode]!;
  }

  String get delete {
    return {
      'en': 'Delete',
      'vi': 'Xóa',
      'de': 'Löschen',
      'cs': 'Smazat',
      'es': 'Eliminar',
      'fr': 'Supprimer',
      'it': 'Elimina',
      'ja': '削除',
      'ko': '삭제',
      'no': 'Slett',
      'ru': 'Удалить',
      'sv': 'Radera',
      'zh': '删除',
    }[locale.languageCode]!;
  }

  String get deleteTask {
    return {
      'en': 'Delete task',
      'vi': 'Xóa nhiệm vụ',
      'de': 'Aufgabe löschen',
      'cs': 'Smazat úkol',
      'es': 'Eliminar tarea',
      'fr': 'Supprimer la tâche',
      'it': 'Elimina compito',
      'ja': 'タスクを削除',
      'ko': '작업 삭제',
      'no': 'Slett oppgave',
      'ru': 'Удалить задачу',
      'sv': 'Radera uppgift',
      'zh': '删除任务',
    }[locale.languageCode]!;
  }

  String get deleteThisList {
    return {
      'en': 'Delete this list',
      'vi': 'Xóa danh sách này',
      'de': 'Diese Liste löschen',
      'cs': 'Smazat tento seznam',
      'es': 'Eliminar esta lista',
      'fr': 'Supprimer cette liste',
      'it': 'Elimina questa lista',
      'ja': 'このリストを削除',
      'ko': '이 목록 삭제',
      'no': 'Slett denne listen',
      'ru': 'Удалить этот список',
      'sv': 'Radera denna lista',
      'zh': '删除此列表',
    }[locale.languageCode]!;
  }

  String get editTask {
    return {
      'en': 'Edit task',
      'vi': 'Chỉnh sửa nhiệm vụ',
      'de': 'Aufgabe bearbeiten',
      'cs': 'Upravit úkol',
      'es': 'Editar tarea',
      'fr': 'Modifier la tâche',
      'it': 'Modifica compito',
      'ja': 'タスクを編集',
      'ko': '작업 편집',
      'no': 'Rediger oppgave',
      'ru': 'Редактировать задачу',
      'sv': 'Redigera uppgift',
      'zh': '编辑任务',
    }[locale.languageCode]!;
  }

  String get editThisList {
    return {
      'en': 'Edit this list',
      'vi': 'Chỉnh sửa danh sách này',
      'de': 'Diese Liste bearbeiten',
      'cs': 'Upravit tento seznam',
      'es': 'Editar esta lista',
      'fr': 'Modifier cette liste',
      'it': 'Modifica questa lista',
      'ja': 'このリストを編集',
      'ko': '이 목록 편집',
      'no': 'Rediger denne listen',
      'ru': 'Редактировать этот список',
      'sv': 'Redigera denna lista',
      'zh': '编辑此列表',
    }[locale.languageCode]!;
  }

  String get english {
    return {
      'en': 'English',
      'vi': 'Tiếng Anh',
      'de': 'Englisch',
      'cs': 'Angličtina',
      'es': 'Inglés',
      'fr': 'Anglais',
      'it': 'Inglese',
      'ja': '英語',
      'ko': '영어',
      'no': 'Engelsk',
      'ru': 'Английский',
      'sv': 'Engelska',
      'zh': '英语',
    }[locale.languageCode]!;
  }

  String get focusTimer {
    return {
      'en': 'Focus timer',
      'vi': 'Đồng hồ tập trung',
      'de': 'Fokus-Timer',
      'cs': 'Časovač zaměření',
      'es': 'Temporizador de enfoque',
      'fr': 'Minuteur de concentration',
      'it': 'Timer di messa a fuoco',
      'ja': 'フォーカスタイマー',
      'ko': '집중 타이머',
      'no': 'Fokustimer',
      'ru': 'Таймер фокусировки',
      'sv': 'Fokustimer',
      'zh': '专注计时器',
    }[locale.languageCode]!;
  }

  String get german {
    return {
      'en': 'German',
      'vi': 'Tiếng Đức',
      'de': 'Deutsch',
      'cs': 'Němčina',
      'es': 'Alemán',
      'fr': 'Allemand',
      'it': 'Tedesco',
      'ja': 'ドイツ語',
      'ko': '독일어',
      'no': 'Tysk',
      'ru': 'Немецкий',
      'sv': 'Tyska',
      'zh': '德语',
    }[locale.languageCode]!;
  }

  String get howToUse {
    return {
      'en': 'How to use?',
      'vi': 'Cách sử dụng?',
      'de': 'Wie benutzt man?',
      'cs': 'Jak používat?',
      'es': '¿Cómo usar?',
      'fr': 'Comment utiliser?',
      'it': 'Come si usa?',
      'ja': '使い方は？',
      'ko': '어떻게 사용하나요?',
      'no': 'Hvordan bruke?',
      'ru': 'Как использовать?',
      'sv': 'Hur använder man?',
      'zh': '如何使用？',
    }[locale.languageCode]!;
  }

  String get list {
    return {
      'en': 'List',
      'vi': 'Danh sách',
      'de': 'Liste',
      'cs': 'Seznam',
      'es': 'Lista',
      'fr': 'Liste',
      'it': 'Elenco',
      'ja': 'リスト',
      'ko': '리스트',
      'no': 'Liste',
      'ru': 'Список',
      'sv': 'Lista',
      'zh': '列表',
    }[locale.languageCode]!;
  }

  String get myContacts {
    return {
      'en': 'My contacts',
      'vi': 'Danh bạ của tôi',
      'de': 'Meine Kontakte',
      'cs': 'Moje kontakty',
      'es': 'Mis contactos',
      'fr': 'Mes contacts',
      'it': 'I miei contatti',
      'ja': '私の連絡先',
      'ko': '내 연락처',
      'no': 'Mine kontakter',
      'ru': 'Мои контакты',
      'sv': 'Mina kontakter',
      'zh': '我的联系人',
    }[locale.languageCode]!;
  }

  String get myStatistics {
    return {
      'en': 'My statistics',
      'vi': 'Thống kê của tôi',
      'de': 'Meine Statistiken',
      'cs': 'Moje statistiky',
      'es': 'Mis estadísticas',
      'fr': 'Mes statistiques',
      'it': 'Le mie statistiche',
      'ja': '私の統計',
      'ko': '내 통계',
      'no': 'Min statistikk',
      'ru': 'Моя статистика',
      'sv': 'Min statistik',
      'zh': '我的统计',
    }[locale.languageCode]!;
  }

  String get notes {
    return {
      'en': 'Notes',
      'vi': 'Ghi chú',
      'de': 'Notizen',
      'cs': 'Poznámky',
      'es': 'Notas',
      'fr': 'Notes',
      'it': 'Appunti',
      'ja': 'ノート',
      'ko': '노트',
      'no': 'Notater',
      'ru': 'Заметки',
      'sv': 'Anteckningar',
      'zh': '笔记',
    }[locale.languageCode]!;
  }

  String get settings {
    return {
      'en': 'Settings',
      'vi': 'Cài đặt',
      'de': 'Einstellungen',
      'cs': 'Nastavení',
      'es': 'Configuraciones',
      'fr': 'Paramètres',
      'it': 'Impostazioni',
      'ja': '設定',
      'ko': '설정',
      'no': 'Innstillinger',
      'ru': 'Настройки',
      'sv': 'Inställningar',
      'zh': '设置',
    }[locale.languageCode]!;
  }

  String get tasksAndEvents {
    return {
      'en': 'Tasks and events',
      'vi': 'Nhiệm vụ và sự kiện',
      'de': 'Aufgaben und Ereignisse',
      'cs': 'Úkoly a události',
      'es': 'Tareas y eventos',
      'fr': 'Tâches et événements',
      'it': 'Attività ed eventi',
      'ja': 'タスクとイベント',
      'ko': '작업 및 이벤트',
      'no': 'Oppgaver og hendelser',
      'ru': 'Задачи и события',
      'sv': 'Uppgifter och händelser',
      'zh': '任务和事件',
    }[locale.languageCode]!;
  }

  String get tasks {
    return {
      'en': 'Tasks',
      'vi': 'Nhiệm vụ',
      'de': 'Aufgaben',
      'cs': 'Úkoly',
      'es': 'Tareas',
      'fr': 'Tâches',
      'it': 'Attività',
      'ja': 'タスク',
      'ko': '작업',
      'no': 'Oppgaver',
      'ru': 'Задачи',
      'sv': 'Uppgifter',
      'zh': '任务',
    }[locale.languageCode]!;
  }

  String get title {
    return {
      'en': 'Title',
      'vi': 'Tiêu đề',
      'de': 'Titel',
      'cs': 'Název',
      'es': 'Título',
      'fr': 'Titre',
      'it': 'Titolo',
      'ja': 'タイトル',
      'ko': '제목',
      'no': 'Tittel',
      'ru': 'Заголовок',
      'sv': 'Titel',
      'zh': '标题',
    }[locale.languageCode]!;
  }

  String get vietnamese {
    return {
      'en': 'Vietnamese',
      'vi': 'Tiếng Việt',
      'de': 'Vietnamesisch',
      'cs': 'Vietnamština',
      'es': 'Vietnamita',
      'fr': 'Vietnamien',
      'it': 'Vietnamita',
      'ja': 'ベトナム語',
      'ko': '베트남어',
      'no': 'Vietnamesisk',
      'ru': 'Вьетнамский',
      'sv': 'Vietnamesiska',
      'zh': '越南语',
    }[locale.languageCode]!;
  }

  String get czech {
    return {
      'en': 'Czech',
      'vi': 'Tiếng Séc',
      'de': 'Tschechisch',
      'cs': 'Čeština',
      'es': 'Checo',
      'fr': 'Tchèque',
      'it': 'Ceco',
      'ja': 'チェコ語',
      'ko': '체코어',
      'no': 'Tsjekkisk',
      'ru': 'Чешский',
      'sv': 'Tjeckiska',
      'zh': '捷克语',
    }[locale.languageCode]!;
  }

  String get spanish {
    return {
      'en': 'Spanish',
      'vi': 'Tiếng Tây Ban Nha',
      'de': 'Spanisch',
      'cs': 'Španělština',
      'es': 'Español',
      'fr': 'Espagnol',
      'it': 'Spagnolo',
      'ja': 'スペイン語',
      'ko': '스페인어',
      'no': 'Spansk',
      'ru': 'Испанский',
      'sv': 'Spanska',
      'zh': '西班牙语',
    }[locale.languageCode]!;
  }

  String get french {
    return {
      'en': 'French',
      'vi': 'Tiếng Pháp',
      'de': 'Französisch',
      'cs': 'Francouzština',
      'es': 'Francés',
      'fr': 'Français',
      'it': 'Francese',
      'ja': 'フランス語',
      'ko': '프랑스어',
      'no': 'Fransk',
      'ru': 'Французский',
      'sv': 'Franska',
      'zh': '法语',
    }[locale.languageCode]!;
  }

  String get italian {
    return {
      'en': 'Italian',
      'vi': 'Tiếng Ý',
      'de': 'Italienisch',
      'cs': 'Italština',
      'es': 'Italiano',
      'fr': 'Italien',
      'it': 'Italiano',
      'ja': 'イタリア語',
      'ko': '이탈리아어',
      'no': 'Italiensk',
      'ru': 'Итальянский',
      'sv': 'Italienska',
      'zh': '意大利语',
    }[locale.languageCode]!;
  }

  String get japanese {
    return {
      'en': 'Japanese',
      'vi': 'Tiếng Nhật',
      'de': 'Japanisch',
      'cs': 'Japonština',
      'es': 'Japonés',
      'fr': 'Japonais',
      'it': 'Giapponese',
      'ja': '日本語',
      'ko': '일본어',
      'no': 'Japansk',
      'ru': 'Японский',
      'sv': 'Japanska',
      'zh': '日语',
    }[locale.languageCode]!;
  }

  String get korean {
    return {
      'en': 'Korean',
      'vi': 'Tiếng Hàn',
      'de': 'Koreanisch',
      'cs': 'Korejština',
      'es': 'Coreano',
      'fr': 'Coréen',
      'it': 'Coreano',
      'ja': '韓国語',
      'ko': '한국어',
      'no': 'Koreansk',
      'ru': 'Корейский',
      'sv': 'Koreanska',
      'zh': '韩语',
    }[locale.languageCode]!;
  }

  String get norwegian {
    return {
      'en': 'Norwegian',
      'vi': 'Tiếng Na Uy',
      'de': 'Norwegisch',
      'cs': 'Norština',
      'es': 'Noruego',
      'fr': 'Norvégien',
      'it': 'Norvegese',
      'ja': 'ノルウェー語',
      'ko': '노르웨이어',
      'no': 'Norsk',
      'ru': 'Норвежский',
      'sv': 'Norska',
      'zh': '挪威语',
    }[locale.languageCode]!;
  }

  String get russian {
    return {
      'en': 'Russian',
      'vi': 'Tiếng Nga',
      'de': 'Russisch',
      'cs': 'Ruština',
      'es': 'Ruso',
      'fr': 'Russe',
      'it': 'Russo',
      'ja': 'ロシア語',
      'ko': '러시아어',
      'no': 'Russisk',
      'ru': 'Русский',
      'sv': 'Ryska',
      'zh': '俄语',
    }[locale.languageCode]!;
  }

  String get swedish {
    return {
      'en': 'Swedish',
      'vi': 'Tiếng Thụy Điển',
      'de': 'Schwedisch',
      'cs': 'Švédština',
      'es': 'Sueco',
      'fr': 'Suédois',
      'it': 'Svedese',
      'ja': 'スウェーデン語',
      'ko': '스웨덴어',
      'no': 'Svensk',
      'ru': 'Шведский',
      'sv': 'Svenska',
      'zh': '瑞典语',
    }[locale.languageCode]!;
  }

  String get chinese {
    return {
      'en': 'Chinese',
      'vi': 'Tiếng Trung',
      'de': 'Chinesisch',
      'cs': 'Čínština',
      'es': 'Chino',
      'fr': 'Chinois',
      'it': 'Cinese',
      'ja': '中国語',
      'ko': '중국어',
      'no': 'Kinesisk',
      'ru': 'Китайский',
      'sv': 'Kinesiska',
      'zh': '中文',
    }[locale.languageCode]!;
  }

  String get overview {
    return {
      'en': 'Overview',
      'vi': 'Tổng quan',
      'de': 'Überblick',
      'cs': 'Přehled',
      'es': 'Resumen',
      'fr': 'Aperçu',
      'it': 'Panoramica',
      'ja': '概要',
      'ko': '개요',
      'no': 'Oversikt',
      'ru': 'Обзор',
      'sv': 'Översikt',
      'zh': '概述',
    }[locale.languageCode]!;
  }

  String get timeline {
    return {
      'en': 'Timeline',
      'vi': 'Dòng thời gian',
      'de': 'Zeitleiste',
      'cs': 'Časová osa',
      'es': 'Cronología',
      'fr': 'Chronologie',
      'it': 'Cronologia',
      'ja': 'タイムライン',
      'ko': '타임라인',
      'no': 'Tidslinje',
      'ru': 'Хронология',
      'sv': 'Tidslinje',
      'zh': '时间线',
    }[locale.languageCode]!;
  }

  String get archive {
    return {
      'en': 'Archive',
      'vi': 'Lưu trữ',
      'de': 'Archiv',
      'cs': 'Archiv',
      'es': 'Archivo',
      'fr': 'Archives',
      'it': 'Archivio',
      'ja': 'アーカイブ',
      'ko': '보관함',
      'no': 'Arkiv',
      'ru': 'Архив',
      'sv': 'Arkiv',
      'zh': '归档',
    }[locale.languageCode]!;
  }

  // --- Projects / workspace (Core Track C6) ---

  String get projects {
    return {
      'en': 'Projects',
      'vi': 'Dự án',
      'de': 'Projekte',
      'cs': 'Projekty',
      'es': 'Proyectos',
      'fr': 'Projets',
      'it': 'Progetti',
      'ja': 'プロジェクト',
      'ko': '프로젝트',
      'no': 'Prosjekter',
      'ru': 'Проекты',
      'sv': 'Projekt',
      'zh': '项目',
    }[locale.languageCode]!;
  }

  String get projectWorkspace {
    return {
      'en': 'Project workspace',
      'vi': 'Không gian dự án',
      'de': 'Projektarbeitsbereich',
      'cs': 'Pracovní prostor projektu',
      'es': 'Espacio de trabajo del proyecto',
      'fr': 'Espace de travail du projet',
      'it': 'Area di lavoro del progetto',
      'ja': 'プロジェクトワークスペース',
      'ko': '프로젝트 작업 공간',
      'no': 'Prosjektarbeidsområde',
      'ru': 'Рабочее пространство проекта',
      'sv': 'Projektarbetsyta',
      'zh': '项目工作区',
    }[locale.languageCode]!;
  }

  String get noProjectsYet {
    return {
      'en': 'No projects yet',
      'vi': 'Chưa có dự án nào',
      'de': 'Noch keine Projekte',
      'cs': 'Zatím žádné projekty',
      'es': 'Aún no hay proyectos',
      'fr': 'Aucun projet pour le moment',
      'it': 'Ancora nessun progetto',
      'ja': 'まだプロジェクトがありません',
      'ko': '아직 프로젝트가 없습니다',
      'no': 'Ingen prosjekter ennå',
      'ru': 'Проектов пока нет',
      'sv': 'Inga projekt ännu',
      'zh': '暂无项目',
    }[locale.languageCode]!;
  }

  String get noProjectsHint {
    return {
      'en': 'Tap + to create your first project.',
      'vi': 'Nhấn + để tạo dự án đầu tiên.',
      'de': 'Tippe auf +, um dein erstes Projekt zu erstellen.',
      'cs': 'Klepnutím na + vytvoříte svůj první projekt.',
      'es': 'Toca + para crear tu primer proyecto.',
      'fr': 'Appuyez sur + pour créer votre premier projet.',
      'it': 'Tocca + per creare il tuo primo progetto.',
      'ja': '+ をタップして最初のプロジェクトを作成しましょう。',
      'ko': '+를 눌러 첫 프로젝트를 만드세요.',
      'no': 'Trykk på + for å opprette ditt første prosjekt.',
      'ru': 'Нажмите +, чтобы создать первый проект.',
      'sv': 'Tryck på + för att skapa ditt första projekt.',
      'zh': '点按 + 创建你的第一个项目。',
    }[locale.languageCode]!;
  }

  String get projectNotFound {
    return {
      'en': 'Project not found',
      'vi': 'Không tìm thấy dự án',
      'de': 'Projekt nicht gefunden',
      'cs': 'Projekt nenalezen',
      'es': 'Proyecto no encontrado',
      'fr': 'Projet introuvable',
      'it': 'Progetto non trovato',
      'ja': 'プロジェクトが見つかりません',
      'ko': '프로젝트를 찾을 수 없습니다',
      'no': 'Prosjektet ble ikke funnet',
      'ru': 'Проект не найден',
      'sv': 'Projektet hittades inte',
      'zh': '未找到项目',
    }[locale.languageCode]!;
  }

  String get projectUntitled {
    return {
      'en': '(Untitled)',
      'vi': '(Không có tiêu đề)',
      'de': '(Ohne Titel)',
      'cs': '(Bez názvu)',
      'es': '(Sin título)',
      'fr': '(Sans titre)',
      'it': '(Senza titolo)',
      'ja': '(無題)',
      'ko': '(제목 없음)',
      'no': '(Uten tittel)',
      'ru': '(Без названия)',
      'sv': '(Namnlös)',
      'zh': '(无标题)',
    }[locale.languageCode]!;
  }

  String get projectSectionTaskLists {
    return {
      'en': 'Task lists',
      'vi': 'Danh sách công việc',
      'de': 'Aufgabenlisten',
      'cs': 'Seznamy úkolů',
      'es': 'Listas de tareas',
      'fr': 'Listes de tâches',
      'it': 'Elenchi di attività',
      'ja': 'タスクリスト',
      'ko': '작업 목록',
      'no': 'Oppgavelister',
      'ru': 'Списки задач',
      'sv': 'Uppgiftslistor',
      'zh': '任务列表',
    }[locale.languageCode]!;
  }

  String get projectSectionTasks {
    return {
      'en': 'Tasks',
      'vi': 'Công việc',
      'de': 'Aufgaben',
      'cs': 'Úkoly',
      'es': 'Tareas',
      'fr': 'Tâches',
      'it': 'Attività',
      'ja': 'タスク',
      'ko': '작업',
      'no': 'Oppgaver',
      'ru': 'Задачи',
      'sv': 'Uppgifter',
      'zh': '任务',
    }[locale.languageCode]!;
  }

  String get projectSectionNotes {
    return {
      'en': 'Notes',
      'vi': 'Ghi chú',
      'de': 'Notizen',
      'cs': 'Poznámky',
      'es': 'Notas',
      'fr': 'Notes',
      'it': 'Note',
      'ja': 'メモ',
      'ko': '메모',
      'no': 'Notater',
      'ru': 'Заметки',
      'sv': 'Anteckningar',
      'zh': '笔记',
    }[locale.languageCode]!;
  }

  String get projectSectionGoals {
    return {
      'en': 'Goals',
      'vi': 'Mục tiêu',
      'de': 'Ziele',
      'cs': 'Cíle',
      'es': 'Objetivos',
      'fr': 'Objectifs',
      'it': 'Obiettivi',
      'ja': '目標',
      'ko': '목표',
      'no': 'Mål',
      'ru': 'Цели',
      'sv': 'Mål',
      'zh': '目标',
    }[locale.languageCode]!;
  }

  String get projectSectionEvents {
    return {
      'en': 'Calendar events',
      'vi': 'Sự kiện lịch',
      'de': 'Kalenderereignisse',
      'cs': 'Události kalendáře',
      'es': 'Eventos del calendario',
      'fr': 'Événements du calendrier',
      'it': 'Eventi del calendario',
      'ja': 'カレンダーの予定',
      'ko': '캘린더 일정',
      'no': 'Kalenderhendelser',
      'ru': 'События календаря',
      'sv': 'Kalenderhändelser',
      'zh': '日历事件',
    }[locale.languageCode]!;
  }

  String get projectSectionEmpty {
    return {
      'en': 'Nothing linked yet',
      'vi': 'Chưa có mục nào được liên kết',
      'de': 'Noch nichts verknüpft',
      'cs': 'Zatím nic propojeno',
      'es': 'Aún no hay nada vinculado',
      'fr': 'Rien de lié pour le moment',
      'it': 'Ancora nulla di collegato',
      'ja': 'まだリンクされた項目はありません',
      'ko': '아직 연결된 항목이 없습니다',
      'no': 'Ingenting koblet ennå',
      'ru': 'Пока ничего не связано',
      'sv': 'Inget länkat ännu',
      'zh': '尚未关联任何内容',
    }[locale.languageCode]!;
  }

  String get projectViaList {
    return {
      'en': 'Via list',
      'vi': 'Qua danh sách',
      'de': 'Über Liste',
      'cs': 'Přes seznam',
      'es': 'Mediante lista',
      'fr': 'Via la liste',
      'it': 'Tramite elenco',
      'ja': 'リスト経由',
      'ko': '목록을 통해',
      'no': 'Via liste',
      'ru': 'Через список',
      'sv': 'Via lista',
      'zh': '通过列表',
    }[locale.languageCode]!;
  }

  String get projectLinkedDirectly {
    return {
      'en': 'Linked directly',
      'vi': 'Liên kết trực tiếp',
      'de': 'Direkt verknüpft',
      'cs': 'Propojeno přímo',
      'es': 'Vinculado directamente',
      'fr': 'Lié directement',
      'it': 'Collegato direttamente',
      'ja': '直接リンク',
      'ko': '직접 연결됨',
      'no': 'Koblet direkte',
      'ru': 'Связано напрямую',
      'sv': 'Direktlänkad',
      'zh': '直接关联',
    }[locale.languageCode]!;
  }

  String get projectTasksCompleted {
    return {
      'en': 'Tasks completed',
      'vi': 'Công việc đã hoàn thành',
      'de': 'Erledigte Aufgaben',
      'cs': 'Dokončené úkoly',
      'es': 'Tareas completadas',
      'fr': 'Tâches terminées',
      'it': 'Attività completate',
      'ja': '完了したタスク',
      'ko': '완료된 작업',
      'no': 'Fullførte oppgaver',
      'ru': 'Выполнено задач',
      'sv': 'Slutförda uppgifter',
      'zh': '已完成任务',
    }[locale.languageCode]!;
  }

  String get projectTaskCompleted {
    return {
      'en': 'Completed',
      'vi': 'Đã hoàn thành',
      'de': 'Erledigt',
      'cs': 'Dokončeno',
      'es': 'Completada',
      'fr': 'Terminée',
      'it': 'Completata',
      'ja': '完了',
      'ko': '완료됨',
      'no': 'Fullført',
      'ru': 'Выполнено',
      'sv': 'Slutförd',
      'zh': '已完成',
    }[locale.languageCode]!;
  }

  String get projectTaskNotCompleted {
    return {
      'en': 'Not completed',
      'vi': 'Chưa hoàn thành',
      'de': 'Nicht erledigt',
      'cs': 'Nedokončeno',
      'es': 'No completada',
      'fr': 'Non terminée',
      'it': 'Non completata',
      'ja': '未完了',
      'ko': '미완료',
      'no': 'Ikke fullført',
      'ru': 'Не выполнено',
      'sv': 'Inte slutförd',
      'zh': '未完成',
    }[locale.languageCode]!;
  }

  String get projectStartDate {
    return {
      'en': 'Start',
      'vi': 'Bắt đầu',
      'de': 'Beginn',
      'cs': 'Začátek',
      'es': 'Inicio',
      'fr': 'Début',
      'it': 'Inizio',
      'ja': '開始',
      'ko': '시작',
      'no': 'Start',
      'ru': 'Начало',
      'sv': 'Start',
      'zh': '开始',
    }[locale.languageCode]!;
  }

  String get projectTargetDate {
    return {
      'en': 'Target',
      'vi': 'Mục tiêu đến',
      'de': 'Ziel',
      'cs': 'Cílové datum',
      'es': 'Fecha objetivo',
      'fr': 'Échéance',
      'it': 'Scadenza',
      'ja': '目標日',
      'ko': '목표일',
      'no': 'Mål',
      'ru': 'Срок',
      'sv': 'Måldatum',
      'zh': '目标日期',
    }[locale.languageCode]!;
  }

  String get projectStatusActive {
    return {
      'en': 'Active',
      'vi': 'Đang thực hiện',
      'de': 'Aktiv',
      'cs': 'Aktivní',
      'es': 'Activo',
      'fr': 'Actif',
      'it': 'Attivo',
      'ja': '進行中',
      'ko': '진행 중',
      'no': 'Aktiv',
      'ru': 'Активный',
      'sv': 'Aktiv',
      'zh': '进行中',
    }[locale.languageCode]!;
  }

  String get projectStatusOnHold {
    return {
      'en': 'On hold',
      'vi': 'Tạm dừng',
      'de': 'Pausiert',
      'cs': 'Pozastaveno',
      'es': 'En pausa',
      'fr': 'En pause',
      'it': 'In pausa',
      'ja': '保留中',
      'ko': '보류 중',
      'no': 'På vent',
      'ru': 'Приостановлен',
      'sv': 'Pausad',
      'zh': '暂停',
    }[locale.languageCode]!;
  }

  String get projectStatusCompleted {
    return {
      'en': 'Completed',
      'vi': 'Đã hoàn thành',
      'de': 'Abgeschlossen',
      'cs': 'Dokončeno',
      'es': 'Completado',
      'fr': 'Terminé',
      'it': 'Completato',
      'ja': '完了',
      'ko': '완료됨',
      'no': 'Fullført',
      'ru': 'Завершён',
      'sv': 'Slutfört',
      'zh': '已完成',
    }[locale.languageCode]!;
  }

  String get projectStatusCancelled {
    return {
      'en': 'Cancelled',
      'vi': 'Đã hủy',
      'de': 'Abgebrochen',
      'cs': 'Zrušeno',
      'es': 'Cancelado',
      'fr': 'Annulé',
      'it': 'Annullato',
      'ja': 'キャンセル',
      'ko': '취소됨',
      'no': 'Avbrutt',
      'ru': 'Отменён',
      'sv': 'Avbrutet',
      'zh': '已取消',
    }[locale.languageCode]!;
  }

  String get projectGoalProgress {
    return {
      'en': 'Progress',
      'vi': 'Tiến độ',
      'de': 'Fortschritt',
      'cs': 'Pokrok',
      'es': 'Progreso',
      'fr': 'Progression',
      'it': 'Avanzamento',
      'ja': '進捗',
      'ko': '진행률',
      'no': 'Fremdrift',
      'ru': 'Прогресс',
      'sv': 'Framsteg',
      'zh': '进度',
    }[locale.languageCode]!;
  }

  // --- Habits (Phase H1) ---

  /// Archive item type label for a habit.
  String get archivedItemTypeHabit {
    return {
      'en': 'Habit',
      'vi': 'Thói quen',
      'de': 'Gewohnheit',
      'cs': 'Návyk',
      'es': 'Hábito',
      'fr': 'Habitude',
      'it': 'Abitudine',
      'ja': '習慣',
      'ko': '습관',
      'no': 'Vane',
      'ru': 'Привычка',
      'sv': 'Vana',
      'zh': '习惯',
    }[locale.languageCode]!;
  }

  // --- Learning / courses (Core Track C7) ---

  String get courses {
    return {
      'en': 'Courses',
      'vi': 'Khóa học',
      'de': 'Kurse',
      'cs': 'Kurzy',
      'es': 'Cursos',
      'fr': 'Cours',
      'it': 'Corsi',
      'ja': 'コース',
      'ko': '강좌',
      'no': 'Kurs',
      'ru': 'Курсы',
      'sv': 'Kurser',
      'zh': '课程',
    }[locale.languageCode]!;
  }

  String get noCoursesYet {
    return {
      'en': 'No courses yet',
      'vi': 'Chưa có khóa học nào',
      'de': 'Noch keine Kurse',
      'cs': 'Zatím žádné kurzy',
      'es': 'Aún no hay cursos',
      'fr': 'Aucun cours pour l\'instant',
      'it': 'Nessun corso ancora',
      'ja': 'まだコースがありません',
      'ko': '아직 강좌가 없습니다',
      'no': 'Ingen kurs ennå',
      'ru': 'Пока нет курсов',
      'sv': 'Inga kurser än',
      'zh': '还没有课程',
    }[locale.languageCode]!;
  }

  String get noCoursesHint {
    return {
      'en': 'Tap + to create your first course.',
      'vi': 'Nhấn + để tạo khóa học đầu tiên.',
      'de': 'Tippe auf +, um deinen ersten Kurs zu erstellen.',
      'cs': 'Klepnutím na + vytvoříte svůj první kurz.',
      'es': 'Toca + para crear tu primer curso.',
      'fr': 'Appuyez sur + pour créer votre premier cours.',
      'it': 'Tocca + per creare il tuo primo corso.',
      'ja': '+ をタップして最初のコースを作成します。',
      'ko': '+를 눌러 첫 강좌를 만드세요.',
      'no': 'Trykk + for å lage ditt første kurs.',
      'ru': 'Нажмите +, чтобы создать первый курс.',
      'sv': 'Tryck på + för att skapa din första kurs.',
      'zh': '点击 + 创建第一个课程。',
    }[locale.languageCode]!;
  }

  String get newCourse {
    return {
      'en': 'New course',
      'vi': 'Khóa học mới',
      'de': 'Neuer Kurs',
      'cs': 'Nový kurz',
      'es': 'Nuevo curso',
      'fr': 'Nouveau cours',
      'it': 'Nuovo corso',
      'ja': '新しいコース',
      'ko': '새 강좌',
      'no': 'Nytt kurs',
      'ru': 'Новый курс',
      'sv': 'Ny kurs',
      'zh': '新建课程',
    }[locale.languageCode]!;
  }

  String get editCourse {
    return {
      'en': 'Edit course',
      'vi': 'Sửa khóa học',
      'de': 'Kurs bearbeiten',
      'cs': 'Upravit kurz',
      'es': 'Editar curso',
      'fr': 'Modifier le cours',
      'it': 'Modifica corso',
      'ja': 'コースを編集',
      'ko': '강좌 편집',
      'no': 'Rediger kurs',
      'ru': 'Изменить курс',
      'sv': 'Redigera kurs',
      'zh': '编辑课程',
    }[locale.languageCode]!;
  }

  String get courseNotFound {
    return {
      'en': 'Course not found',
      'vi': 'Không tìm thấy khóa học',
      'de': 'Kurs nicht gefunden',
      'cs': 'Kurz nenalezen',
      'es': 'Curso no encontrado',
      'fr': 'Cours introuvable',
      'it': 'Corso non trovato',
      'ja': 'コースが見つかりません',
      'ko': '강좌를 찾을 수 없습니다',
      'no': 'Fant ikke kurset',
      'ru': 'Курс не найден',
      'sv': 'Kursen hittades inte',
      'zh': '未找到课程',
    }[locale.languageCode]!;
  }

  String get learningUntitled {
    return {
      'en': '(Untitled)',
      'vi': '(Không tiêu đề)',
      'de': '(Ohne Titel)',
      'cs': '(Bez názvu)',
      'es': '(Sin título)',
      'fr': '(Sans titre)',
      'it': '(Senza titolo)',
      'ja': '(無題)',
      'ko': '(제목 없음)',
      'no': '(Uten tittel)',
      'ru': '(Без названия)',
      'sv': '(Namnlös)',
      'zh': '(无标题)',
    }[locale.languageCode]!;
  }

  String get titleRequired {
    return {
      'en': 'Title is required',
      'vi': 'Vui lòng nhập tiêu đề',
      'de': 'Titel ist erforderlich',
      'cs': 'Název je povinný',
      'es': 'El título es obligatorio',
      'fr': 'Le titre est obligatoire',
      'it': 'Il titolo è obbligatorio',
      'ja': 'タイトルは必須です',
      'ko': '제목을 입력하세요',
      'no': 'Tittel er påkrevd',
      'ru': 'Введите название',
      'sv': 'Titel krävs',
      'zh': '标题为必填项',
    }[locale.languageCode]!;
  }

  String get courseStatus {
    return {
      'en': 'Status',
      'vi': 'Trạng thái',
      'de': 'Status',
      'cs': 'Stav',
      'es': 'Estado',
      'fr': 'Statut',
      'it': 'Stato',
      'ja': 'ステータス',
      'ko': '상태',
      'no': 'Status',
      'ru': 'Статус',
      'sv': 'Status',
      'zh': '状态',
    }[locale.languageCode]!;
  }

  String get courseStatusActive {
    return {
      'en': 'Active',
      'vi': 'Đang học',
      'de': 'Aktiv',
      'cs': 'Aktivní',
      'es': 'Activo',
      'fr': 'Actif',
      'it': 'Attivo',
      'ja': '受講中',
      'ko': '진행 중',
      'no': 'Aktiv',
      'ru': 'Активен',
      'sv': 'Aktiv',
      'zh': '进行中',
    }[locale.languageCode]!;
  }

  String get courseStatusPaused {
    return {
      'en': 'Paused',
      'vi': 'Tạm dừng',
      'de': 'Pausiert',
      'cs': 'Pozastaveno',
      'es': 'En pausa',
      'fr': 'En pause',
      'it': 'In pausa',
      'ja': '一時停止',
      'ko': '일시 중지',
      'no': 'Satt på pause',
      'ru': 'Приостановлен',
      'sv': 'Pausad',
      'zh': '已暂停',
    }[locale.languageCode]!;
  }

  String get courseCompleted {
    return {
      'en': 'Completed',
      'vi': 'Đã hoàn thành',
      'de': 'Abgeschlossen',
      'cs': 'Dokončeno',
      'es': 'Completado',
      'fr': 'Terminé',
      'it': 'Completato',
      'ja': '完了',
      'ko': '완료됨',
      'no': 'Fullført',
      'ru': 'Завершён',
      'sv': 'Slutförd',
      'zh': '已完成',
    }[locale.languageCode]!;
  }

  String get lessonsCompleted {
    return {
      'en': 'Lessons completed',
      'vi': 'Bài học đã hoàn thành',
      'de': 'Abgeschlossene Lektionen',
      'cs': 'Dokončené lekce',
      'es': 'Lecciones completadas',
      'fr': 'Leçons terminées',
      'it': 'Lezioni completate',
      'ja': '完了したレッスン',
      'ko': '완료한 강의',
      'no': 'Fullførte leksjoner',
      'ru': 'Пройдено уроков',
      'sv': 'Avklarade lektioner',
      'zh': '已完成课时',
    }[locale.languageCode]!;
  }

  String get learningProgress {
    return {
      'en': 'Progress',
      'vi': 'Tiến độ',
      'de': 'Fortschritt',
      'cs': 'Pokrok',
      'es': 'Progreso',
      'fr': 'Progression',
      'it': 'Avanzamento',
      'ja': '進捗',
      'ko': '진행률',
      'no': 'Fremdrift',
      'ru': 'Прогресс',
      'sv': 'Framsteg',
      'zh': '进度',
    }[locale.languageCode]!;
  }

  String get noModulesYet {
    return {
      'en': 'No modules yet',
      'vi': 'Chưa có chương nào',
      'de': 'Noch keine Module',
      'cs': 'Zatím žádné moduly',
      'es': 'Aún no hay módulos',
      'fr': 'Aucun module pour l\'instant',
      'it': 'Nessun modulo ancora',
      'ja': 'まだモジュールがありません',
      'ko': '아직 모듈이 없습니다',
      'no': 'Ingen moduler ennå',
      'ru': 'Пока нет модулей',
      'sv': 'Inga moduler än',
      'zh': '还没有章节',
    }[locale.languageCode]!;
  }

  String get addModule {
    return {
      'en': 'Add module',
      'vi': 'Thêm chương',
      'de': 'Modul hinzufügen',
      'cs': 'Přidat modul',
      'es': 'Añadir módulo',
      'fr': 'Ajouter un module',
      'it': 'Aggiungi modulo',
      'ja': 'モジュールを追加',
      'ko': '모듈 추가',
      'no': 'Legg til modul',
      'ru': 'Добавить модуль',
      'sv': 'Lägg till modul',
      'zh': '添加章节',
    }[locale.languageCode]!;
  }

  String get newModule {
    return {
      'en': 'New module',
      'vi': 'Chương mới',
      'de': 'Neues Modul',
      'cs': 'Nový modul',
      'es': 'Nuevo módulo',
      'fr': 'Nouveau module',
      'it': 'Nuovo modulo',
      'ja': '新しいモジュール',
      'ko': '새 모듈',
      'no': 'Ny modul',
      'ru': 'Новый модуль',
      'sv': 'Ny modul',
      'zh': '新建章节',
    }[locale.languageCode]!;
  }

  String get editModule {
    return {
      'en': 'Edit module',
      'vi': 'Sửa chương',
      'de': 'Modul bearbeiten',
      'cs': 'Upravit modul',
      'es': 'Editar módulo',
      'fr': 'Modifier le module',
      'it': 'Modifica modulo',
      'ja': 'モジュールを編集',
      'ko': '모듈 편집',
      'no': 'Rediger modul',
      'ru': 'Изменить модуль',
      'sv': 'Redigera modul',
      'zh': '编辑章节',
    }[locale.languageCode]!;
  }

  String get noLessonsYet {
    return {
      'en': 'No lessons yet',
      'vi': 'Chưa có bài học',
      'de': 'Noch keine Lektionen',
      'cs': 'Zatím žádné lekce',
      'es': 'Aún no hay lecciones',
      'fr': 'Aucune leçon pour l\'instant',
      'it': 'Nessuna lezione ancora',
      'ja': 'まだレッスンがありません',
      'ko': '아직 강의가 없습니다',
      'no': 'Ingen leksjoner ennå',
      'ru': 'Пока нет уроков',
      'sv': 'Inga lektioner än',
      'zh': '还没有课时',
    }[locale.languageCode]!;
  }

  String get addLesson {
    return {
      'en': 'Add lesson',
      'vi': 'Thêm bài học',
      'de': 'Lektion hinzufügen',
      'cs': 'Přidat lekci',
      'es': 'Añadir lección',
      'fr': 'Ajouter une leçon',
      'it': 'Aggiungi lezione',
      'ja': 'レッスンを追加',
      'ko': '강의 추가',
      'no': 'Legg til leksjon',
      'ru': 'Добавить урок',
      'sv': 'Lägg till lektion',
      'zh': '添加课时',
    }[locale.languageCode]!;
  }

  String get newLesson {
    return {
      'en': 'New lesson',
      'vi': 'Bài học mới',
      'de': 'Neue Lektion',
      'cs': 'Nová lekce',
      'es': 'Nueva lección',
      'fr': 'Nouvelle leçon',
      'it': 'Nuova lezione',
      'ja': '新しいレッスン',
      'ko': '새 강의',
      'no': 'Ny leksjon',
      'ru': 'Новый урок',
      'sv': 'Ny lektion',
      'zh': '新建课时',
    }[locale.languageCode]!;
  }

  String get editLesson {
    return {
      'en': 'Edit lesson',
      'vi': 'Sửa bài học',
      'de': 'Lektion bearbeiten',
      'cs': 'Upravit lekci',
      'es': 'Editar lección',
      'fr': 'Modifier la leçon',
      'it': 'Modifica lezione',
      'ja': 'レッスンを編集',
      'ko': '강의 편집',
      'no': 'Rediger leksjon',
      'ru': 'Изменить урок',
      'sv': 'Redigera lektion',
      'zh': '编辑课时',
    }[locale.languageCode]!;
  }

  String get lessonNotFound {
    return {
      'en': 'Lesson not found',
      'vi': 'Không tìm thấy bài học',
      'de': 'Lektion nicht gefunden',
      'cs': 'Lekce nenalezena',
      'es': 'Lección no encontrada',
      'fr': 'Leçon introuvable',
      'it': 'Lezione non trovata',
      'ja': 'レッスンが見つかりません',
      'ko': '강의를 찾을 수 없습니다',
      'no': 'Fant ikke leksjonen',
      'ru': 'Урок не найден',
      'sv': 'Lektionen hittades inte',
      'zh': '未找到课时',
    }[locale.languageCode]!;
  }

  String get markComplete {
    return {
      'en': 'Mark complete',
      'vi': 'Đánh dấu hoàn thành',
      'de': 'Als erledigt markieren',
      'cs': 'Označit jako dokončené',
      'es': 'Marcar como completada',
      'fr': 'Marquer comme terminée',
      'it': 'Segna come completata',
      'ja': '完了にする',
      'ko': '완료로 표시',
      'no': 'Merk som fullført',
      'ru': 'Отметить как пройденный',
      'sv': 'Markera som klar',
      'zh': '标记为完成',
    }[locale.languageCode]!;
  }

  String get markIncomplete {
    return {
      'en': 'Mark as not completed',
      'vi': 'Đánh dấu chưa hoàn thành',
      'de': 'Als nicht erledigt markieren',
      'cs': 'Označit jako nedokončené',
      'es': 'Marcar como no completada',
      'fr': 'Marquer comme non terminée',
      'it': 'Segna come non completata',
      'ja': '未完了に戻す',
      'ko': '미완료로 표시',
      'no': 'Merk som ikke fullført',
      'ru': 'Отметить как непройденный',
      'sv': 'Markera som inte klar',
      'zh': '标记为未完成',
    }[locale.languageCode]!;
  }

  String get lessonStatusNotStarted {
    return {
      'en': 'Not started',
      'vi': 'Chưa bắt đầu',
      'de': 'Nicht begonnen',
      'cs': 'Nezahájeno',
      'es': 'Sin empezar',
      'fr': 'Non commencée',
      'it': 'Non iniziata',
      'ja': '未開始',
      'ko': '시작 전',
      'no': 'Ikke startet',
      'ru': 'Не начат',
      'sv': 'Inte påbörjad',
      'zh': '未开始',
    }[locale.languageCode]!;
  }

  String get lessonStatusInProgress {
    return {
      'en': 'In progress',
      'vi': 'Đang học',
      'de': 'In Bearbeitung',
      'cs': 'Probíhá',
      'es': 'En curso',
      'fr': 'En cours',
      'it': 'In corso',
      'ja': '学習中',
      'ko': '학습 중',
      'no': 'Pågår',
      'ru': 'В процессе',
      'sv': 'Pågår',
      'zh': '学习中',
    }[locale.languageCode]!;
  }

  String get lessonStatusCompleted {
    return {
      'en': 'Completed',
      'vi': 'Đã hoàn thành',
      'de': 'Abgeschlossen',
      'cs': 'Dokončeno',
      'es': 'Completada',
      'fr': 'Terminée',
      'it': 'Completata',
      'ja': '完了',
      'ko': '완료됨',
      'no': 'Fullført',
      'ru': 'Пройден',
      'sv': 'Klar',
      'zh': '已完成',
    }[locale.languageCode]!;
  }

  String get lessonLinks {
    return {
      'en': 'Links',
      'vi': 'Liên kết',
      'de': 'Links',
      'cs': 'Odkazy',
      'es': 'Enlaces',
      'fr': 'Liens',
      'it': 'Link',
      'ja': 'リンク',
      'ko': '링크',
      'no': 'Lenker',
      'ru': 'Ссылки',
      'sv': 'Länkar',
      'zh': '链接',
    }[locale.languageCode]!;
  }

  String get addLink {
    return {
      'en': 'Add link',
      'vi': 'Thêm liên kết',
      'de': 'Link hinzufügen',
      'cs': 'Přidat odkaz',
      'es': 'Añadir enlace',
      'fr': 'Ajouter un lien',
      'it': 'Aggiungi link',
      'ja': 'リンクを追加',
      'ko': '링크 추가',
      'no': 'Legg til lenke',
      'ru': 'Добавить ссылку',
      'sv': 'Lägg till länk',
      'zh': '添加链接',
    }[locale.languageCode]!;
  }

  String get linkUrl {
    return {
      'en': 'URL',
      'vi': 'Địa chỉ URL',
      'de': 'URL',
      'cs': 'URL',
      'es': 'URL',
      'fr': 'URL',
      'it': 'URL',
      'ja': 'URL',
      'ko': 'URL',
      'no': 'URL',
      'ru': 'URL',
      'sv': 'URL',
      'zh': '网址',
    }[locale.languageCode]!;
  }

  String get invalidUrl {
    return {
      'en': 'Enter a valid http(s) URL',
      'vi': 'Nhập URL http(s) hợp lệ',
      'de': 'Gib eine gültige http(s)-URL ein',
      'cs': 'Zadejte platnou adresu http(s)',
      'es': 'Introduce una URL http(s) válida',
      'fr': 'Saisissez une URL http(s) valide',
      'it': 'Inserisci un URL http(s) valido',
      'ja': '有効な http(s) URL を入力してください',
      'ko': '올바른 http(s) URL을 입력하세요',
      'no': 'Skriv inn en gyldig http(s)-URL',
      'ru': 'Введите корректный http(s) URL',
      'sv': 'Ange en giltig http(s)-URL',
      'zh': '请输入有效的 http(s) 网址',
    }[locale.languageCode]!;
  }

  String get cannotOpenLink {
    return {
      'en': 'Could not open the link',
      'vi': 'Không mở được liên kết',
      'de': 'Link konnte nicht geöffnet werden',
      'cs': 'Odkaz nelze otevřít',
      'es': 'No se pudo abrir el enlace',
      'fr': 'Impossible d\'ouvrir le lien',
      'it': 'Impossibile aprire il link',
      'ja': 'リンクを開けませんでした',
      'ko': '링크를 열 수 없습니다',
      'no': 'Kunne ikke åpne lenken',
      'ru': 'Не удалось открыть ссылку',
      'sv': 'Det gick inte att öppna länken',
      'zh': '无法打开链接',
    }[locale.languageCode]!;
  }

  String get linkedNotes {
    return {
      'en': 'Linked notes',
      'vi': 'Ghi chú liên kết',
      'de': 'Verknüpfte Notizen',
      'cs': 'Propojené poznámky',
      'es': 'Notas vinculadas',
      'fr': 'Notes liées',
      'it': 'Note collegate',
      'ja': 'リンクされたメモ',
      'ko': '연결된 메모',
      'no': 'Koblede notater',
      'ru': 'Связанные заметки',
      'sv': 'Länkade anteckningar',
      'zh': '关联笔记',
    }[locale.languageCode]!;
  }

  String get attachNote {
    return {
      'en': 'Attach note',
      'vi': 'Đính kèm ghi chú',
      'de': 'Notiz anhängen',
      'cs': 'Připojit poznámku',
      'es': 'Adjuntar nota',
      'fr': 'Joindre une note',
      'it': 'Allega nota',
      'ja': 'メモを添付',
      'ko': '메모 첨부',
      'no': 'Legg ved notat',
      'ru': 'Прикрепить заметку',
      'sv': 'Bifoga anteckning',
      'zh': '附加笔记',
    }[locale.languageCode]!;
  }

  String get removeItem {
    return {
      'en': 'Remove',
      'vi': 'Gỡ bỏ',
      'de': 'Entfernen',
      'cs': 'Odebrat',
      'es': 'Quitar',
      'fr': 'Retirer',
      'it': 'Rimuovi',
      'ja': '削除',
      'ko': '제거',
      'no': 'Fjern',
      'ru': 'Убрать',
      'sv': 'Ta bort',
      'zh': '移除',
    }[locale.languageCode]!;
  }

  String get edit {
    return {
      'en': 'Edit',
      'vi': 'Sửa',
      'de': 'Bearbeiten',
      'cs': 'Upravit',
      'es': 'Editar',
      'fr': 'Modifier',
      'it': 'Modifica',
      'ja': '編集',
      'ko': '편집',
      'no': 'Rediger',
      'ru': 'Изменить',
      'sv': 'Redigera',
      'zh': '编辑',
    }[locale.languageCode]!;
  }

  String get moveUp {
    return {
      'en': 'Move up',
      'vi': 'Di chuyển lên',
      'de': 'Nach oben',
      'cs': 'Posunout nahoru',
      'es': 'Subir',
      'fr': 'Monter',
      'it': 'Sposta su',
      'ja': '上へ移動',
      'ko': '위로 이동',
      'no': 'Flytt opp',
      'ru': 'Переместить вверх',
      'sv': 'Flytta upp',
      'zh': '上移',
    }[locale.languageCode]!;
  }

  String get moveDown {
    return {
      'en': 'Move down',
      'vi': 'Di chuyển xuống',
      'de': 'Nach unten',
      'cs': 'Posunout dolů',
      'es': 'Bajar',
      'fr': 'Descendre',
      'it': 'Sposta giù',
      'ja': '下へ移動',
      'ko': '아래로 이동',
      'no': 'Flytt ned',
      'ru': 'Переместить вниз',
      'sv': 'Flytta ned',
      'zh': '下移',
    }[locale.languageCode]!;
  }

  String get moveToTrash {
    return {
      'en': 'Move to trash',
      'vi': 'Chuyển vào thùng rác',
      'de': 'In den Papierkorb',
      'cs': 'Přesunout do koše',
      'es': 'Mover a la papelera',
      'fr': 'Mettre à la corbeille',
      'it': 'Sposta nel cestino',
      'ja': 'ゴミ箱に移動',
      'ko': '휴지통으로 이동',
      'no': 'Flytt til papirkurven',
      'ru': 'В корзину',
      'sv': 'Flytta till papperskorgen',
      'zh': '移至回收站',
    }[locale.languageCode]!;
  }

  String get confirmDeleteModule {
    return {
      'en': 'Delete this module and all its lessons?',
      'vi': 'Xóa chương này và toàn bộ bài học?',
      'de': 'Dieses Modul und alle seine Lektionen löschen?',
      'cs': 'Smazat tento modul a všechny jeho lekce?',
      'es': '¿Eliminar este módulo y todas sus lecciones?',
      'fr': 'Supprimer ce module et toutes ses leçons ?',
      'it': 'Eliminare questo modulo e tutte le sue lezioni?',
      'ja': 'このモジュールとすべてのレッスンを削除しますか？',
      'ko': '이 모듈과 모든 강의를 삭제할까요?',
      'no': 'Slette denne modulen og alle leksjonene?',
      'ru': 'Удалить этот модуль и все его уроки?',
      'sv': 'Ta bort den här modulen och alla dess lektioner?',
      'zh': '删除此章节及其所有课时？',
    }[locale.languageCode]!;
  }

  String get confirmDeleteLesson {
    return {
      'en': 'Delete this lesson?',
      'vi': 'Xóa bài học này?',
      'de': 'Diese Lektion löschen?',
      'cs': 'Smazat tuto lekci?',
      'es': '¿Eliminar esta lección?',
      'fr': 'Supprimer cette leçon ?',
      'it': 'Eliminare questa lezione?',
      'ja': 'このレッスンを削除しますか？',
      'ko': '이 강의를 삭제할까요?',
      'no': 'Slette denne leksjonen?',
      'ru': 'Удалить этот урок?',
      'sv': 'Ta bort den här lektionen?',
      'zh': '删除此课时？',
    }[locale.languageCode]!;
  }

  // --- Shared pickers / form fields ---

  String get search {
    return {
      'en': 'Search',
      'vi': 'Tìm kiếm',
      'de': 'Suchen',
      'cs': 'Hledat',
      'es': 'Buscar',
      'fr': 'Rechercher',
      'it': 'Cerca',
      'ja': '検索',
      'ko': '검색',
      'no': 'Søk',
      'ru': 'Поиск',
      'sv': 'Sök',
      'zh': '搜索',
    }[locale.languageCode]!;
  }

  String get pickerNoItems {
    return {
      'en': 'Nothing to choose',
      'vi': 'Không có mục nào để chọn',
      'de': 'Nichts zur Auswahl',
      'cs': 'Není z čeho vybírat',
      'es': 'No hay nada que elegir',
      'fr': 'Rien à choisir',
      'it': 'Niente da scegliere',
      'ja': '選択できる項目がありません',
      'ko': '선택할 항목이 없습니다',
      'no': 'Ingenting å velge',
      'ru': 'Нечего выбрать',
      'sv': 'Inget att välja',
      'zh': '没有可选择的项目',
    }[locale.languageCode]!;
  }

  String get color {
    return {
      'en': 'Color',
      'vi': 'Màu',
      'de': 'Farbe',
      'cs': 'Barva',
      'es': 'Color',
      'fr': 'Couleur',
      'it': 'Colore',
      'ja': '色',
      'ko': '색상',
      'no': 'Farge',
      'ru': 'Цвет',
      'sv': 'Färg',
      'zh': '颜色',
    }[locale.languageCode]!;
  }

  String get dateNotSet {
    return {
      'en': 'Not set',
      'vi': 'Chưa đặt',
      'de': 'Nicht festgelegt',
      'cs': 'Nenastaveno',
      'es': 'Sin definir',
      'fr': 'Non défini',
      'it': 'Non impostata',
      'ja': '未設定',
      'ko': '설정 안 됨',
      'no': 'Ikke angitt',
      'ru': 'Не задано',
      'sv': 'Inte angivet',
      'zh': '未设置',
    }[locale.languageCode]!;
  }

  String get clearDate {
    return {
      'en': 'Clear date',
      'vi': 'Xóa ngày',
      'de': 'Datum löschen',
      'cs': 'Vymazat datum',
      'es': 'Borrar fecha',
      'fr': 'Effacer la date',
      'it': 'Cancella data',
      'ja': '日付をクリア',
      'ko': '날짜 지우기',
      'no': 'Fjern dato',
      'ru': 'Очистить дату',
      'sv': 'Rensa datum',
      'zh': '清除日期',
    }[locale.languageCode]!;
  }

  // --- Goals (UI) ---

  String get goals {
    return {
      'en': 'Goals',
      'vi': 'Mục tiêu',
      'de': 'Ziele',
      'cs': 'Cíle',
      'es': 'Objetivos',
      'fr': 'Objectifs',
      'it': 'Obiettivi',
      'ja': '目標',
      'ko': '목표',
      'no': 'Mål',
      'ru': 'Цели',
      'sv': 'Mål',
      'zh': '目标',
    }[locale.languageCode]!;
  }

  String get noGoalsYet {
    return {
      'en': 'No goals yet',
      'vi': 'Chưa có mục tiêu nào',
      'de': 'Noch keine Ziele',
      'cs': 'Zatím žádné cíle',
      'es': 'Aún no hay objetivos',
      'fr': 'Aucun objectif pour l\'instant',
      'it': 'Ancora nessun obiettivo',
      'ja': '目標はまだありません',
      'ko': '아직 목표가 없습니다',
      'no': 'Ingen mål ennå',
      'ru': 'Целей пока нет',
      'sv': 'Inga mål ännu',
      'zh': '暂无目标',
    }[locale.languageCode]!;
  }

  String get noGoalsHint {
    return {
      'en': 'Tap + to create your first goal.',
      'vi': 'Nhấn + để tạo mục tiêu đầu tiên.',
      'de': 'Tippe auf +, um dein erstes Ziel zu erstellen.',
      'cs': 'Klepnutím na + vytvoříte svůj první cíl.',
      'es': 'Toca + para crear tu primer objetivo.',
      'fr': 'Appuyez sur + pour créer votre premier objectif.',
      'it': 'Tocca + per creare il tuo primo obiettivo.',
      'ja': '+ をタップして最初の目標を作成します。',
      'ko': '+를 눌러 첫 목표를 만드세요.',
      'no': 'Trykk på + for å opprette ditt første mål.',
      'ru': 'Нажмите +, чтобы создать первую цель.',
      'sv': 'Tryck på + för att skapa ditt första mål.',
      'zh': '点击 + 创建第一个目标。',
    }[locale.languageCode]!;
  }

  String get noGoalsForFilter {
    return {
      'en': 'No goals with this status',
      'vi': 'Không có mục tiêu nào ở trạng thái này',
      'de': 'Keine Ziele mit diesem Status',
      'cs': 'Žádné cíle s tímto stavem',
      'es': 'No hay objetivos con este estado',
      'fr': 'Aucun objectif avec ce statut',
      'it': 'Nessun obiettivo con questo stato',
      'ja': 'このステータスの目標はありません',
      'ko': '이 상태의 목표가 없습니다',
      'no': 'Ingen mål med denne statusen',
      'ru': 'Нет целей с этим статусом',
      'sv': 'Inga mål med denna status',
      'zh': '没有此状态的目标',
    }[locale.languageCode]!;
  }

  String get newGoal {
    return {
      'en': 'New goal',
      'vi': 'Mục tiêu mới',
      'de': 'Neues Ziel',
      'cs': 'Nový cíl',
      'es': 'Nuevo objetivo',
      'fr': 'Nouvel objectif',
      'it': 'Nuovo obiettivo',
      'ja': '新しい目標',
      'ko': '새 목표',
      'no': 'Nytt mål',
      'ru': 'Новая цель',
      'sv': 'Nytt mål',
      'zh': '新建目标',
    }[locale.languageCode]!;
  }

  String get editGoal {
    return {
      'en': 'Edit goal',
      'vi': 'Sửa mục tiêu',
      'de': 'Ziel bearbeiten',
      'cs': 'Upravit cíl',
      'es': 'Editar objetivo',
      'fr': 'Modifier l\'objectif',
      'it': 'Modifica obiettivo',
      'ja': '目標を編集',
      'ko': '목표 편집',
      'no': 'Rediger mål',
      'ru': 'Изменить цель',
      'sv': 'Redigera mål',
      'zh': '编辑目标',
    }[locale.languageCode]!;
  }

  String get goalNotFound {
    return {
      'en': 'Goal not found',
      'vi': 'Không tìm thấy mục tiêu',
      'de': 'Ziel nicht gefunden',
      'cs': 'Cíl nenalezen',
      'es': 'Objetivo no encontrado',
      'fr': 'Objectif introuvable',
      'it': 'Obiettivo non trovato',
      'ja': '目標が見つかりません',
      'ko': '목표를 찾을 수 없습니다',
      'no': 'Fant ikke målet',
      'ru': 'Цель не найдена',
      'sv': 'Målet hittades inte',
      'zh': '未找到目标',
    }[locale.languageCode]!;
  }

  String get goalStatus {
    return {
      'en': 'Status',
      'vi': 'Trạng thái',
      'de': 'Status',
      'cs': 'Stav',
      'es': 'Estado',
      'fr': 'Statut',
      'it': 'Stato',
      'ja': 'ステータス',
      'ko': '상태',
      'no': 'Status',
      'ru': 'Статус',
      'sv': 'Status',
      'zh': '状态',
    }[locale.languageCode]!;
  }

  String get goalStatusActive {
    return {
      'en': 'Active',
      'vi': 'Đang thực hiện',
      'de': 'Aktiv',
      'cs': 'Aktivní',
      'es': 'Activo',
      'fr': 'Actif',
      'it': 'Attivo',
      'ja': '進行中',
      'ko': '진행 중',
      'no': 'Aktiv',
      'ru': 'Активна',
      'sv': 'Aktiv',
      'zh': '进行中',
    }[locale.languageCode]!;
  }

  String get goalStatusPaused {
    return {
      'en': 'Paused',
      'vi': 'Tạm dừng',
      'de': 'Pausiert',
      'cs': 'Pozastaveno',
      'es': 'En pausa',
      'fr': 'En pause',
      'it': 'In pausa',
      'ja': '一時停止',
      'ko': '일시 중지',
      'no': 'Satt på pause',
      'ru': 'Приостановлена',
      'sv': 'Pausad',
      'zh': '已暂停',
    }[locale.languageCode]!;
  }

  String get goalStatusCompleted {
    return {
      'en': 'Completed',
      'vi': 'Đã hoàn thành',
      'de': 'Abgeschlossen',
      'cs': 'Dokončeno',
      'es': 'Completado',
      'fr': 'Terminé',
      'it': 'Completato',
      'ja': '完了',
      'ko': '완료',
      'no': 'Fullført',
      'ru': 'Выполнена',
      'sv': 'Slutförd',
      'zh': '已完成',
    }[locale.languageCode]!;
  }

  String get goalStatusAbandoned {
    return {
      'en': 'Abandoned',
      'vi': 'Đã bỏ',
      'de': 'Aufgegeben',
      'cs': 'Opuštěno',
      'es': 'Abandonado',
      'fr': 'Abandonné',
      'it': 'Abbandonato',
      'ja': '断念',
      'ko': '포기함',
      'no': 'Forlatt',
      'ru': 'Заброшена',
      'sv': 'Övergiven',
      'zh': '已放弃',
    }[locale.languageCode]!;
  }

  String get goalTargetDate {
    return {
      'en': 'Target date',
      'vi': 'Ngày mục tiêu',
      'de': 'Zieldatum',
      'cs': 'Cílové datum',
      'es': 'Fecha objetivo',
      'fr': 'Date cible',
      'it': 'Data obiettivo',
      'ja': '目標日',
      'ko': '목표 날짜',
      'no': 'Måldato',
      'ru': 'Целевая дата',
      'sv': 'Måldatum',
      'zh': '目标日期',
    }[locale.languageCode]!;
  }

  String get goalFilterAll {
    return {
      'en': 'All',
      'vi': 'Tất cả',
      'de': 'Alle',
      'cs': 'Vše',
      'es': 'Todos',
      'fr': 'Tous',
      'it': 'Tutti',
      'ja': 'すべて',
      'ko': '전체',
      'no': 'Alle',
      'ru': 'Все',
      'sv': 'Alla',
      'zh': '全部',
    }[locale.languageCode]!;
  }

  String get goalMilestones {
    return {
      'en': 'Milestones',
      'vi': 'Cột mốc',
      'de': 'Meilensteine',
      'cs': 'Milníky',
      'es': 'Hitos',
      'fr': 'Jalons',
      'it': 'Traguardi',
      'ja': 'マイルストーン',
      'ko': '마일스톤',
      'no': 'Milepæler',
      'ru': 'Этапы',
      'sv': 'Milstolpar',
      'zh': '里程碑',
    }[locale.languageCode]!;
  }

  String get noMilestonesYet {
    return {
      'en': 'No milestones yet',
      'vi': 'Chưa có cột mốc nào',
      'de': 'Noch keine Meilensteine',
      'cs': 'Zatím žádné milníky',
      'es': 'Aún no hay hitos',
      'fr': 'Aucun jalon pour l\'instant',
      'it': 'Ancora nessun traguardo',
      'ja': 'マイルストーンはまだありません',
      'ko': '아직 마일스톤이 없습니다',
      'no': 'Ingen milepæler ennå',
      'ru': 'Этапов пока нет',
      'sv': 'Inga milstolpar ännu',
      'zh': '暂无里程碑',
    }[locale.languageCode]!;
  }

  String get addMilestone {
    return {
      'en': 'Add milestone',
      'vi': 'Thêm cột mốc',
      'de': 'Meilenstein hinzufügen',
      'cs': 'Přidat milník',
      'es': 'Añadir hito',
      'fr': 'Ajouter un jalon',
      'it': 'Aggiungi traguardo',
      'ja': 'マイルストーンを追加',
      'ko': '마일스톤 추가',
      'no': 'Legg til milepæl',
      'ru': 'Добавить этап',
      'sv': 'Lägg till milstolpe',
      'zh': '添加里程碑',
    }[locale.languageCode]!;
  }

  String get newMilestone {
    return {
      'en': 'New milestone',
      'vi': 'Cột mốc mới',
      'de': 'Neuer Meilenstein',
      'cs': 'Nový milník',
      'es': 'Nuevo hito',
      'fr': 'Nouveau jalon',
      'it': 'Nuovo traguardo',
      'ja': '新しいマイルストーン',
      'ko': '새 마일스톤',
      'no': 'Ny milepæl',
      'ru': 'Новый этап',
      'sv': 'Ny milstolpe',
      'zh': '新建里程碑',
    }[locale.languageCode]!;
  }

  String get editMilestone {
    return {
      'en': 'Edit milestone',
      'vi': 'Sửa cột mốc',
      'de': 'Meilenstein bearbeiten',
      'cs': 'Upravit milník',
      'es': 'Editar hito',
      'fr': 'Modifier le jalon',
      'it': 'Modifica traguardo',
      'ja': 'マイルストーンを編集',
      'ko': '마일스톤 편집',
      'no': 'Rediger milepæl',
      'ru': 'Изменить этап',
      'sv': 'Redigera milstolpe',
      'zh': '编辑里程碑',
    }[locale.languageCode]!;
  }

  String get milestoneDueDate {
    return {
      'en': 'Due',
      'vi': 'Hạn',
      'de': 'Fällig',
      'cs': 'Termín',
      'es': 'Vence',
      'fr': 'Échéance',
      'it': 'Scadenza',
      'ja': '期限',
      'ko': '마감',
      'no': 'Frist',
      'ru': 'Срок',
      'sv': 'Förfaller',
      'zh': '截止',
    }[locale.languageCode]!;
  }

  String get confirmDeleteMilestone {
    return {
      'en':
          'Delete this milestone? Its linked items stay linked directly to the goal.',
      'vi':
          'Xóa cột mốc này? Các mục đã gắn vẫn được gắn trực tiếp với mục tiêu.',
      'de':
          'Diesen Meilenstein löschen? Verknüpfte Elemente bleiben direkt mit dem Ziel verknüpft.',
      'cs':
          'Smazat tento milník? Propojené položky zůstanou propojené přímo s cílem.',
      'es':
          '¿Eliminar este hito? Sus elementos vinculados seguirán vinculados directamente al objetivo.',
      'fr':
          'Supprimer ce jalon ? Ses éléments liés resteront liés directement à l\'objectif.',
      'it':
          'Eliminare questo traguardo? Gli elementi collegati resteranno collegati direttamente all\'obiettivo.',
      'ja': 'このマイルストーンを削除しますか？リンクされた項目は目標に直接リンクされたままになります。',
      'ko': '이 마일스톤을 삭제할까요? 연결된 항목은 목표에 직접 연결된 상태로 유지됩니다.',
      'no':
          'Slette denne milepælen? Koblede elementer forblir koblet direkte til målet.',
      'ru':
          'Удалить этот этап? Связанные элементы останутся связанными напрямую с целью.',
      'sv':
          'Ta bort denna milstolpe? Länkade objekt förblir länkade direkt till målet.',
      'zh': '删除此里程碑？其关联项将保持直接关联到目标。',
    }[locale.languageCode]!;
  }

  String get goalMilestonesDone {
    return {
      'en': 'Milestones done',
      'vi': 'Cột mốc đã xong',
      'de': 'Erledigte Meilensteine',
      'cs': 'Dokončené milníky',
      'es': 'Hitos completados',
      'fr': 'Jalons terminés',
      'it': 'Traguardi completati',
      'ja': '完了したマイルストーン',
      'ko': '완료된 마일스톤',
      'no': 'Fullførte milepæler',
      'ru': 'Выполнено этапов',
      'sv': 'Klara milstolpar',
      'zh': '已完成里程碑',
    }[locale.languageCode]!;
  }

  String get goalLinkTask {
    return {
      'en': 'Link task',
      'vi': 'Gắn công việc',
      'de': 'Aufgabe verknüpfen',
      'cs': 'Propojit úkol',
      'es': 'Vincular tarea',
      'fr': 'Lier une tâche',
      'it': 'Collega attività',
      'ja': 'タスクをリンク',
      'ko': '작업 연결',
      'no': 'Koble oppgave',
      'ru': 'Связать задачу',
      'sv': 'Länka uppgift',
      'zh': '关联任务',
    }[locale.languageCode]!;
  }

  String get goalLinkCourse {
    return {
      'en': 'Link course',
      'vi': 'Gắn khóa học',
      'de': 'Kurs verknüpfen',
      'cs': 'Propojit kurz',
      'es': 'Vincular curso',
      'fr': 'Lier un cours',
      'it': 'Collega corso',
      'ja': 'コースをリンク',
      'ko': '강좌 연결',
      'no': 'Koble kurs',
      'ru': 'Связать курс',
      'sv': 'Länka kurs',
      'zh': '关联课程',
    }[locale.languageCode]!;
  }

  String get goalLinkTarget {
    return {
      'en': 'Link to',
      'vi': 'Gắn vào',
      'de': 'Verknüpfen mit',
      'cs': 'Propojit s',
      'es': 'Vincular a',
      'fr': 'Lier à',
      'it': 'Collega a',
      'ja': 'リンク先',
      'ko': '연결 대상',
      'no': 'Koble til',
      'ru': 'Связать с',
      'sv': 'Länka till',
      'zh': '关联到',
    }[locale.languageCode]!;
  }

  String get goalLinkDirect {
    return {
      'en': 'Directly to the goal',
      'vi': 'Trực tiếp với mục tiêu',
      'de': 'Direkt mit dem Ziel',
      'cs': 'Přímo s cílem',
      'es': 'Directamente al objetivo',
      'fr': 'Directement à l\'objectif',
      'it': 'Direttamente all\'obiettivo',
      'ja': '目標に直接',
      'ko': '목표에 직접',
      'no': 'Direkte til målet',
      'ru': 'Напрямую к цели',
      'sv': 'Direkt till målet',
      'zh': '直接关联到目标',
    }[locale.languageCode]!;
  }

  String get goalUnlink {
    return {
      'en': 'Unlink',
      'vi': 'Bỏ gắn',
      'de': 'Verknüpfung lösen',
      'cs': 'Zrušit propojení',
      'es': 'Desvincular',
      'fr': 'Délier',
      'it': 'Scollega',
      'ja': 'リンク解除',
      'ko': '연결 해제',
      'no': 'Fjern kobling',
      'ru': 'Отвязать',
      'sv': 'Ta bort länk',
      'zh': '取消关联',
    }[locale.languageCode]!;
  }

  String get confirmUnlink {
    return {
      'en': 'Remove this link? The item itself is not deleted.',
      'vi': 'Bỏ liên kết này? Bản thân mục đó không bị xóa.',
      'de':
          'Diese Verknüpfung entfernen? Das Element selbst wird nicht gelöscht.',
      'cs': 'Odebrat toto propojení? Samotná položka nebude smazána.',
      'es': '¿Quitar este vínculo? El elemento en sí no se elimina.',
      'fr': 'Supprimer ce lien ? L\'élément lui-même n\'est pas supprimé.',
      'it':
          'Rimuovere questo collegamento? L\'elemento stesso non viene eliminato.',
      'ja': 'このリンクを解除しますか？項目自体は削除されません。',
      'ko': '이 연결을 제거할까요? 항목 자체는 삭제되지 않습니다.',
      'no': 'Fjerne denne koblingen? Selve elementet slettes ikke.',
      'ru': 'Удалить эту связь? Сам элемент не удаляется.',
      'sv': 'Ta bort denna länk? Själva objektet tas inte bort.',
      'zh': '移除此关联？项目本身不会被删除。',
    }[locale.languageCode]!;
  }

  String get confirmArchiveGoal {
    return {
      'en': 'Archive this goal?',
      'vi': 'Lưu trữ mục tiêu này?',
      'de': 'Dieses Ziel archivieren?',
      'cs': 'Archivovat tento cíl?',
      'es': '¿Archivar este objetivo?',
      'fr': 'Archiver cet objectif ?',
      'it': 'Archiviare questo obiettivo?',
      'ja': 'この目標をアーカイブしますか？',
      'ko': '이 목표를 보관할까요?',
      'no': 'Arkivere dette målet?',
      'ru': 'Архивировать эту цель?',
      'sv': 'Arkivera detta mål?',
      'zh': '归档此目标？',
    }[locale.languageCode]!;
  }

  String get confirmTrashGoal {
    return {
      'en': 'Move this goal to trash?',
      'vi': 'Chuyển mục tiêu này vào thùng rác?',
      'de': 'Dieses Ziel in den Papierkorb verschieben?',
      'cs': 'Přesunout tento cíl do koše?',
      'es': '¿Mover este objetivo a la papelera?',
      'fr': 'Mettre cet objectif à la corbeille ?',
      'it': 'Spostare questo obiettivo nel cestino?',
      'ja': 'この目標をゴミ箱に移動しますか？',
      'ko': '이 목표를 휴지통으로 이동할까요?',
      'no': 'Flytte dette målet til papirkurven?',
      'ru': 'Переместить эту цель в корзину?',
      'sv': 'Flytta detta mål till papperskorgen?',
      'zh': '将此目标移到回收站？',
    }[locale.languageCode]!;
  }

  // --- Projects (UI) ---

  String get newProject {
    return {
      'en': 'New project',
      'vi': 'Dự án mới',
      'de': 'Neues Projekt',
      'cs': 'Nový projekt',
      'es': 'Nuevo proyecto',
      'fr': 'Nouveau projet',
      'it': 'Nuovo progetto',
      'ja': '新しいプロジェクト',
      'ko': '새 프로젝트',
      'no': 'Nytt prosjekt',
      'ru': 'Новый проект',
      'sv': 'Nytt projekt',
      'zh': '新建项目',
    }[locale.languageCode]!;
  }

  String get editProject {
    return {
      'en': 'Edit project',
      'vi': 'Sửa dự án',
      'de': 'Projekt bearbeiten',
      'cs': 'Upravit projekt',
      'es': 'Editar proyecto',
      'fr': 'Modifier le projet',
      'it': 'Modifica progetto',
      'ja': 'プロジェクトを編集',
      'ko': '프로젝트 편집',
      'no': 'Rediger prosjekt',
      'ru': 'Изменить проект',
      'sv': 'Redigera projekt',
      'zh': '编辑项目',
    }[locale.languageCode]!;
  }

  String get projectStatus {
    return {
      'en': 'Status',
      'vi': 'Trạng thái',
      'de': 'Status',
      'cs': 'Stav',
      'es': 'Estado',
      'fr': 'Statut',
      'it': 'Stato',
      'ja': 'ステータス',
      'ko': '상태',
      'no': 'Status',
      'ru': 'Статус',
      'sv': 'Status',
      'zh': '状态',
    }[locale.languageCode]!;
  }

  String get projectTargetBeforeStart {
    return {
      'en': 'Target date cannot be before start date',
      'vi': 'Ngày mục tiêu không được trước ngày bắt đầu',
      'de': 'Das Zieldatum darf nicht vor dem Startdatum liegen',
      'cs': 'Cílové datum nemůže být před datem zahájení',
      'es': 'La fecha objetivo no puede ser anterior a la fecha de inicio',
      'fr': 'La date cible ne peut pas précéder la date de début',
      'it': 'La data obiettivo non può essere precedente alla data di inizio',
      'ja': '目標日を開始日より前にすることはできません',
      'ko': '목표일은 시작일보다 앞설 수 없습니다',
      'no': 'Måldato kan ikke være før startdato',
      'ru': 'Целевая дата не может быть раньше даты начала',
      'sv': 'Måldatum kan inte vara före startdatum',
      'zh': '目标日期不能早于开始日期',
    }[locale.languageCode]!;
  }

  String get projectAddItem {
    return {
      'en': 'Add item',
      'vi': 'Thêm mục',
      'de': 'Element hinzufügen',
      'cs': 'Přidat položku',
      'es': 'Añadir elemento',
      'fr': 'Ajouter un élément',
      'it': 'Aggiungi elemento',
      'ja': '項目を追加',
      'ko': '항목 추가',
      'no': 'Legg til element',
      'ru': 'Добавить элемент',
      'sv': 'Lägg till objekt',
      'zh': '添加项目内容',
    }[locale.languageCode]!;
  }

  String get projectChooseItemType {
    return {
      'en': 'Choose item type',
      'vi': 'Chọn loại mục',
      'de': 'Elementtyp wählen',
      'cs': 'Vyberte typ položky',
      'es': 'Elige el tipo de elemento',
      'fr': 'Choisir le type d\'élément',
      'it': 'Scegli il tipo di elemento',
      'ja': '項目の種類を選択',
      'ko': '항목 유형 선택',
      'no': 'Velg elementtype',
      'ru': 'Выберите тип элемента',
      'sv': 'Välj objekttyp',
      'zh': '选择内容类型',
    }[locale.languageCode]!;
  }

  String get confirmRemoveProjectItem {
    return {
      'en': 'Remove this item from the project? The item itself is not deleted.',
      'vi': 'Gỡ mục này khỏi dự án? Bản thân mục đó không bị xóa.',
      'de':
          'Dieses Element aus dem Projekt entfernen? Das Element selbst wird nicht gelöscht.',
      'cs': 'Odebrat tuto položku z projektu? Samotná položka nebude smazána.',
      'es':
          '¿Quitar este elemento del proyecto? El elemento en sí no se elimina.',
      'fr':
          'Retirer cet élément du projet ? L\'élément lui-même n\'est pas supprimé.',
      'it':
          'Rimuovere questo elemento dal progetto? L\'elemento stesso non viene eliminato.',
      'ja': 'この項目をプロジェクトから外しますか？項目自体は削除されません。',
      'ko': '이 항목을 프로젝트에서 제거할까요? 항목 자체는 삭제되지 않습니다.',
      'no': 'Fjerne dette elementet fra prosjektet? Selve elementet slettes ikke.',
      'ru': 'Убрать этот элемент из проекта? Сам элемент не удаляется.',
      'sv': 'Ta bort detta objekt från projektet? Själva objektet tas inte bort.',
      'zh': '从项目中移除此内容？内容本身不会被删除。',
    }[locale.languageCode]!;
  }

  String get confirmArchiveProject {
    return {
      'en': 'Archive this project?',
      'vi': 'Lưu trữ dự án này?',
      'de': 'Dieses Projekt archivieren?',
      'cs': 'Archivovat tento projekt?',
      'es': '¿Archivar este proyecto?',
      'fr': 'Archiver ce projet ?',
      'it': 'Archiviare questo progetto?',
      'ja': 'このプロジェクトをアーカイブしますか？',
      'ko': '이 프로젝트를 보관할까요?',
      'no': 'Arkivere dette prosjektet?',
      'ru': 'Архивировать этот проект?',
      'sv': 'Arkivera detta projekt?',
      'zh': '归档此项目？',
    }[locale.languageCode]!;
  }

  String get confirmTrashProject {
    return {
      'en': 'Move this project to trash?',
      'vi': 'Chuyển dự án này vào thùng rác?',
      'de': 'Dieses Projekt in den Papierkorb verschieben?',
      'cs': 'Přesunout tento projekt do koše?',
      'es': '¿Mover este proyecto a la papelera?',
      'fr': 'Mettre ce projet à la corbeille ?',
      'it': 'Spostare questo progetto nel cestino?',
      'ja': 'このプロジェクトをゴミ箱に移動しますか？',
      'ko': '이 프로젝트를 휴지통으로 이동할까요?',
      'no': 'Flytte dette prosjektet til papirkurven?',
      'ru': 'Переместить этот проект в корзину?',
      'sv': 'Flytta detta projekt till papperskorgen?',
      'zh': '将此项目移到回收站？',
    }[locale.languageCode]!;
  }

  // --- Reminders (Phase R) ---
  // Các chuỗi chứa '{n}' / '{time}' là template: nơi gọi dùng replaceAll.

  String get reminders {
    return {
      'en': 'Reminders',
      'vi': 'Nhắc',
      'de': 'Erinnerungen',
      'cs': 'Připomínky',
      'es': 'Recordatorios',
      'fr': 'Rappels',
      'it': 'Promemoria',
      'ja': 'リマインダー',
      'ko': '알림',
      'no': 'Påminnelser',
      'ru': 'Напоминания',
      'sv': 'Påminnelser',
      'zh': '提醒',
    }[locale.languageCode]!;
  }

  String get upcomingReminders {
    return {
      'en': 'Upcoming reminders',
      'vi': 'Nhắc sắp tới',
      'de': 'Anstehende Erinnerungen',
      'cs': 'Nadcházející připomínky',
      'es': 'Próximos recordatorios',
      'fr': 'Rappels à venir',
      'it': 'Promemoria imminenti',
      'ja': '今後のリマインダー',
      'ko': '예정된 알림',
      'no': 'Kommende påminnelser',
      'ru': 'Предстоящие напоминания',
      'sv': 'Kommande påminnelser',
      'zh': '即将到来的提醒',
    }[locale.languageCode]!;
  }

  String get noUpcomingReminders {
    return {
      'en': 'No upcoming reminders',
      'vi': 'Không có nhắc sắp tới',
      'de': 'Keine anstehenden Erinnerungen',
      'cs': 'Žádné nadcházející připomínky',
      'es': 'No hay próximos recordatorios',
      'fr': 'Aucun rappel à venir',
      'it': 'Nessun promemoria imminente',
      'ja': '今後のリマインダーはありません',
      'ko': '예정된 알림이 없습니다',
      'no': 'Ingen kommende påminnelser',
      'ru': 'Нет предстоящих напоминаний',
      'sv': 'Inga kommande påminnelser',
      'zh': '没有即将到来的提醒',
    }[locale.languageCode]!;
  }

  String get noUpcomingRemindersHint {
    return {
      'en': 'Add reminders to time intervals or calendar events.',
      'vi': 'Thêm mốc nhắc cho khoảng thời gian hoặc sự kiện lịch.',
      'de': 'Füge Zeitintervallen oder Kalenderereignissen Erinnerungen hinzu.',
      'cs': 'Přidejte připomínky k časovým intervalům nebo událostem v kalendáři.',
      'es': 'Añade recordatorios a intervalos de tiempo o eventos del calendario.',
      'fr': 'Ajoutez des rappels aux plages horaires ou aux événements du calendrier.',
      'it': 'Aggiungi promemoria a intervalli di tempo o eventi del calendario.',
      'ja': '時間枠またはカレンダーの予定にリマインダーを追加してください。',
      'ko': '시간 구간이나 캘린더 일정에 알림을 추가하세요.',
      'no': 'Legg til påminnelser på tidsintervaller eller kalenderhendelser.',
      'ru': 'Добавьте напоминания к интервалам времени или событиям календаря.',
      'sv': 'Lägg till påminnelser på tidsintervall eller kalenderhändelser.',
      'zh': '为时间段或日历事件添加提醒。',
    }[locale.languageCode]!;
  }

  String get reminderDeferred {
    return {
      'en': 'Deferred',
      'vi': 'Đang hoãn',
      'de': 'Zurückgestellt',
      'cs': 'Odloženo',
      'es': 'Aplazado',
      'fr': 'Différé',
      'it': 'Rinviato',
      'ja': '保留中',
      'ko': '보류됨',
      'no': 'Utsatt',
      'ru': 'Отложено',
      'sv': 'Uppskjuten',
      'zh': '已推迟',
    }[locale.languageCode]!;
  }

  String get reminderShiftedQuietHours {
    return {
      'en': 'Moved by quiet hours',
      'vi': 'Dời do giờ yên lặng',
      'de': 'Durch Ruhezeit verschoben',
      'cs': 'Posunuto tichými hodinami',
      'es': 'Movido por horas de silencio',
      'fr': 'Décalé par les heures calmes',
      'it': 'Spostato per le ore di silenzio',
      'ja': 'おやすみ時間により移動',
      'ko': '방해 금지 시간으로 이동됨',
      'no': 'Flyttet av stilletid',
      'ru': 'Перенесено из-за тихих часов',
      'sv': 'Flyttad av tysta timmar',
      'zh': '因免打扰时段而推迟',
    }[locale.languageCode]!;
  }

  String get reminderHighPriority {
    return {
      'en': 'High priority',
      'vi': 'Ưu tiên cao',
      'de': 'Hohe Priorität',
      'cs': 'Vysoká priorita',
      'es': 'Prioridad alta',
      'fr': 'Priorité élevée',
      'it': 'Priorità alta',
      'ja': '高優先度',
      'ko': '높은 우선순위',
      'no': 'Høy prioritet',
      'ru': 'Высокий приоритет',
      'sv': 'Hög prioritet',
      'zh': '高优先级',
    }[locale.languageCode]!;
  }

  String get notificationsDenied {
    return {
      'en':
          'Notifications are turned off for this app, so reminders will not appear.',
      'vi': 'Thông báo đang bị tắt cho ứng dụng nên nhắc sẽ không hiển thị.',
      'de':
          'Benachrichtigungen sind für diese App deaktiviert, daher werden keine Erinnerungen angezeigt.',
      'cs':
          'Oznámení jsou pro tuto aplikaci vypnutá, takže se připomínky nezobrazí.',
      'es':
          'Las notificaciones están desactivadas para esta app, así que los recordatorios no aparecerán.',
      'fr':
          'Les notifications sont désactivées pour cette app, les rappels ne s\'afficheront donc pas.',
      'it':
          'Le notifiche sono disattivate per questa app, quindi i promemoria non verranno mostrati.',
      'ja': 'このアプリの通知がオフのため、リマインダーは表示されません。',
      'ko': '이 앱의 알림이 꺼져 있어 알림이 표시되지 않습니다.',
      'no': 'Varsler er slått av for denne appen, så påminnelser vises ikke.',
      'ru':
          'Уведомления для этого приложения отключены, поэтому напоминания не появятся.',
      'sv':
          'Aviseringar är avstängda för den här appen, så påminnelser visas inte.',
      'zh': '此应用的通知已关闭，提醒将不会显示。',
    }[locale.languageCode]!;
  }

  String get exactAlarmsDenied {
    return {
      'en':
          'Exact alarms are not allowed for this app, so reminders may arrive late.',
      'vi':
          'Ứng dụng chưa được phép đặt báo thức chính xác nên nhắc có thể đến muộn.',
      'de':
          'Exakte Alarme sind für diese App nicht erlaubt, daher können Erinnerungen verspätet kommen.',
      'cs':
          'Přesné budíky nejsou pro tuto aplikaci povoleny, připomínky proto mohou přijít později.',
      'es':
          'Las alarmas exactas no están permitidas para esta app, así que los recordatorios pueden llegar tarde.',
      'fr':
          'Les alarmes exactes ne sont pas autorisées pour cette app, les rappels peuvent donc arriver en retard.',
      'it':
          'Le sveglie esatte non sono consentite per questa app, quindi i promemoria potrebbero arrivare in ritardo.',
      'ja': 'このアプリは正確なアラームが許可されていないため、リマインダーが遅れる場合があります。',
      'ko': '이 앱에 정확한 알람이 허용되지 않아 알림이 늦게 올 수 있습니다.',
      'no':
          'Nøyaktige alarmer er ikke tillatt for denne appen, så påminnelser kan komme for sent.',
      'ru':
          'Точные будильники для этого приложения не разрешены, поэтому напоминания могут приходить с опозданием.',
      'sv':
          'Exakta alarm är inte tillåtna för den här appen, så påminnelser kan komma sent.',
      'zh': '此应用未获准使用精确闹钟，提醒可能会延迟。',
    }[locale.languageCode]!;
  }

  String get remindersOffInfo {
    return {
      'en': 'Reminders are turned off in Settings.',
      'vi': 'Nhắc đang tắt trong Cài đặt.',
      'de': 'Erinnerungen sind in den Einstellungen deaktiviert.',
      'cs': 'Připomínky jsou v Nastavení vypnuté.',
      'es': 'Los recordatorios están desactivados en Ajustes.',
      'fr': 'Les rappels sont désactivés dans les Paramètres.',
      'it': 'I promemoria sono disattivati nelle Impostazioni.',
      'ja': 'リマインダーは設定でオフになっています。',
      'ko': '설정에서 알림이 꺼져 있습니다.',
      'no': 'Påminnelser er slått av i Innstillinger.',
      'ru': 'Напоминания отключены в настройках.',
      'sv': 'Påminnelser är avstängda i Inställningar.',
      'zh': '提醒已在设置中关闭。',
    }[locale.languageCode]!;
  }

  String get reminderRulesSaveFailed {
    return {
      'en': 'The event was saved, but its specific-time reminders could not be saved.',
      'vi': 'Đã lưu sự kiện nhưng không lưu được các nhắc theo thời điểm cụ thể.',
      'de':
          'Der Termin wurde gespeichert, aber seine Erinnerungen zu festen Zeiten konnten nicht gespeichert werden.',
      'cs':
          'Událost byla uložena, ale její připomínky v konkrétní čas se nepodařilo uložit.',
      'es':
          'El evento se guardó, pero no se pudieron guardar sus recordatorios a una hora concreta.',
      'fr':
          'L\'événement a été enregistré, mais ses rappels à heure précise n\'ont pas pu l\'être.',
      'it':
          'L\'evento è stato salvato, ma non è stato possibile salvare i promemoria a orario specifico.',
      'ja': '予定は保存されましたが、指定時刻のリマインダーを保存できませんでした。',
      'ko': '일정은 저장되었지만 특정 시간 알림을 저장하지 못했습니다.',
      'no':
          'Hendelsen ble lagret, men påminnelsene på bestemte tidspunkt kunne ikke lagres.',
      'ru':
          'Событие сохранено, но напоминания на определённое время сохранить не удалось.',
      'sv':
          'Händelsen sparades, men dess påminnelser vid en viss tid kunde inte sparas.',
      'zh': '事件已保存，但无法保存其指定时间的提醒。',
    }[locale.languageCode]!;
  }

  String get allowNotifications {
    return {
      'en': 'Allow',
      'vi': 'Cho phép',
      'de': 'Erlauben',
      'cs': 'Povolit',
      'es': 'Permitir',
      'fr': 'Autoriser',
      'it': 'Consenti',
      'ja': '許可',
      'ko': '허용',
      'no': 'Tillat',
      'ru': 'Разрешить',
      'sv': 'Tillåt',
      'zh': '允许',
    }[locale.languageCode]!;
  }

  String get quietHours {
    return {
      'en': 'Quiet hours',
      'vi': 'Giờ yên lặng',
      'de': 'Ruhezeit',
      'cs': 'Tiché hodiny',
      'es': 'Horas de silencio',
      'fr': 'Heures calmes',
      'it': 'Ore di silenzio',
      'ja': 'おやすみ時間',
      'ko': '방해 금지 시간',
      'no': 'Stilletid',
      'ru': 'Тихие часы',
      'sv': 'Tysta timmar',
      'zh': '免打扰时段',
    }[locale.languageCode]!;
  }

  String get quietHoursSubtitle {
    return {
      'en': 'Reminders in this window are moved to its end',
      'vi': 'Nhắc rơi vào khoảng này được dời tới lúc kết thúc',
      'de': 'Erinnerungen in diesem Zeitraum werden an dessen Ende verschoben',
      'cs': 'Připomínky v tomto období se posunou na jeho konec',
      'es': 'Los recordatorios en este periodo se mueven a su final',
      'fr': 'Les rappels dans cette plage sont décalés à sa fin',
      'it': 'I promemoria in questa fascia vengono spostati alla sua fine',
      'ja': 'この時間帯のリマインダーは終了時刻に移動します',
      'ko': '이 시간대의 알림은 종료 시각으로 이동됩니다',
      'no': 'Påminnelser i dette tidsrommet flyttes til slutten',
      'ru': 'Напоминания в этот период переносятся на его окончание',
      'sv': 'Påminnelser under denna period flyttas till dess slut',
      'zh': '此时段内的提醒将推迟到结束时间',
    }[locale.languageCode]!;
  }

  String get quietHoursStart {
    return {
      'en': 'Starts',
      'vi': 'Bắt đầu',
      'de': 'Beginn',
      'cs': 'Začátek',
      'es': 'Inicio',
      'fr': 'Début',
      'it': 'Inizio',
      'ja': '開始',
      'ko': '시작',
      'no': 'Start',
      'ru': 'Начало',
      'sv': 'Start',
      'zh': '开始',
    }[locale.languageCode]!;
  }

  String get quietHoursEnd {
    return {
      'en': 'Ends',
      'vi': 'Kết thúc',
      'de': 'Ende',
      'cs': 'Konec',
      'es': 'Fin',
      'fr': 'Fin',
      'it': 'Fine',
      'ja': '終了',
      'ko': '종료',
      'no': 'Slutt',
      'ru': 'Конец',
      'sv': 'Slut',
      'zh': '结束',
    }[locale.languageCode]!;
  }

  String get reminderEngine {
    return {
      'en': 'Smart reminder scheduling',
      'vi': 'Lên lịch nhắc thông minh',
      'de': 'Intelligente Erinnerungsplanung',
      'cs': 'Chytré plánování připomínek',
      'es': 'Programación inteligente de recordatorios',
      'fr': 'Planification intelligente des rappels',
      'it': 'Pianificazione intelligente dei promemoria',
      'ja': 'スマートなリマインダー予約',
      'ko': '스마트 알림 예약',
      'no': 'Smart planlegging av påminnelser',
      'ru': 'Умное планирование напоминаний',
      'sv': 'Smart schemaläggning av påminnelser',
      'zh': '智能提醒调度',
    }[locale.languageCode]!;
  }

  String get reminderEngineSubtitle {
    return {
      'en':
          'Also schedules calendar event and specific-time reminders, nearest first within the system limit',
      'vi':
          'Lên lịch cả nhắc của sự kiện lịch và nhắc theo thời điểm, ưu tiên mốc gần nhất trong giới hạn của hệ thống',
      'de':
          'Plant auch Erinnerungen für Kalenderereignisse und feste Zeitpunkte, die nächsten zuerst innerhalb des Systemlimits',
      'cs':
          'Plánuje i připomínky událostí kalendáře a pevných časů, nejbližší nejdříve v rámci limitu systému',
      'es':
          'También programa recordatorios de eventos y de hora concreta, los más próximos primero dentro del límite del sistema',
      'fr':
          'Planifie aussi les rappels d\'événements et à heure précise, les plus proches d\'abord dans la limite du système',
      'it':
          'Pianifica anche i promemoria degli eventi e a orario specifico, i più vicini prima entro il limite di sistema',
      'ja': 'カレンダーの予定や指定時刻のリマインダーも、システム上限内で近い順に予約します',
      'ko': '캘린더 일정과 지정 시각 알림도 시스템 한도 내에서 가까운 순으로 예약합니다',
      'no':
          'Planlegger også påminnelser for kalenderhendelser og faste tidspunkt, nærmeste først innenfor systemgrensen',
      'ru':
          'Планирует также напоминания о событиях календаря и на точное время, ближайшие первыми в пределах лимита системы',
      'sv':
          'Schemalägger även påminnelser för kalenderhändelser och fasta tider, närmaste först inom systemets gräns',
      'zh': '同时调度日历事件和指定时间的提醒，在系统限制内优先最近的',
    }[locale.languageCode]!;
  }

  String get reminderLegacyModeInfo {
    return {
      'en': 'Classic mode: only time-interval reminders are scheduled.',
      'vi': 'Chế độ cổ điển: chỉ lên lịch nhắc cho các khoảng thời gian.',
      'de': 'Klassischer Modus: Nur Erinnerungen für Zeitintervalle werden geplant.',
      'cs': 'Klasický režim: plánují se jen připomínky časových intervalů.',
      'es': 'Modo clásico: solo se programan recordatorios de intervalos de tiempo.',
      'fr': 'Mode classique : seuls les rappels des plages horaires sont planifiés.',
      'it':
          'Modalità classica: vengono pianificati solo i promemoria degli intervalli di tempo.',
      'ja': 'クラシックモード：時間枠のリマインダーのみ予約されます。',
      'ko': '클래식 모드: 시간 구간 알림만 예약됩니다.',
      'no': 'Klassisk modus: bare påminnelser for tidsintervaller planlegges.',
      'ru': 'Классический режим: планируются только напоминания интервалов времени.',
      'sv': 'Klassiskt läge: endast påminnelser för tidsintervall schemaläggs.',
      'zh': '经典模式：仅调度时间段的提醒。',
    }[locale.languageCode]!;
  }

  String get reminderAdd {
    return {
      'en': 'Add reminder',
      'vi': 'Thêm nhắc',
      'de': 'Erinnerung hinzufügen',
      'cs': 'Přidat připomínku',
      'es': 'Añadir recordatorio',
      'fr': 'Ajouter un rappel',
      'it': 'Aggiungi promemoria',
      'ja': 'リマインダーを追加',
      'ko': '알림 추가',
      'no': 'Legg til påminnelse',
      'ru': 'Добавить напоминание',
      'sv': 'Lägg till påminnelse',
      'zh': '添加提醒',
    }[locale.languageCode]!;
  }

  String get reminderEdit {
    return {
      'en': 'Edit reminder',
      'vi': 'Sửa nhắc',
      'de': 'Erinnerung bearbeiten',
      'cs': 'Upravit připomínku',
      'es': 'Editar recordatorio',
      'fr': 'Modifier le rappel',
      'it': 'Modifica promemoria',
      'ja': 'リマインダーを編集',
      'ko': '알림 편집',
      'no': 'Rediger påminnelse',
      'ru': 'Изменить напоминание',
      'sv': 'Redigera påminnelse',
      'zh': '编辑提醒',
    }[locale.languageCode]!;
  }

  String get reminderDelete {
    return {
      'en': 'Delete reminder',
      'vi': 'Xóa nhắc',
      'de': 'Erinnerung löschen',
      'cs': 'Smazat připomínku',
      'es': 'Eliminar recordatorio',
      'fr': 'Supprimer le rappel',
      'it': 'Elimina promemoria',
      'ja': 'リマインダーを削除',
      'ko': '알림 삭제',
      'no': 'Slett påminnelse',
      'ru': 'Удалить напоминание',
      'sv': 'Ta bort påminnelse',
      'zh': '删除提醒',
    }[locale.languageCode]!;
  }

  String get reminderNone {
    return {
      'en': 'No reminders set',
      'vi': 'Chưa đặt nhắc',
      'de': 'Keine Erinnerungen festgelegt',
      'cs': 'Nejsou nastaveny žádné připomínky',
      'es': 'Sin recordatorios',
      'fr': 'Aucun rappel défini',
      'it': 'Nessun promemoria impostato',
      'ja': 'リマインダー未設定',
      'ko': '설정된 알림 없음',
      'no': 'Ingen påminnelser satt',
      'ru': 'Напоминания не заданы',
      'sv': 'Inga påminnelser angivna',
      'zh': '未设置提醒',
    }[locale.languageCode]!;
  }

  String get reminderPickTitle {
    return {
      'en': 'Choose when to remind',
      'vi': 'Chọn thời điểm nhắc',
      'de': 'Erinnerungszeitpunkt wählen',
      'cs': 'Vyberte čas připomínky',
      'es': 'Elige cuándo recordar',
      'fr': 'Choisir quand rappeler',
      'it': 'Scegli quando ricordare',
      'ja': '通知タイミングを選択',
      'ko': '알림 시점 선택',
      'no': 'Velg når du vil bli påminnet',
      'ru': 'Выберите время напоминания',
      'sv': 'Välj när du vill påminnas',
      'zh': '选择提醒时间',
    }[locale.languageCode]!;
  }

  String get reminderCustomMinutes {
    return {
      'en': 'Custom (minutes before)...',
      'vi': 'Tùy chỉnh (phút trước)...',
      'de': 'Benutzerdefiniert (Minuten vorher)...',
      'cs': 'Vlastní (minut předem)...',
      'es': 'Personalizado (minutos antes)...',
      'fr': 'Personnalisé (minutes avant)...',
      'it': 'Personalizzato (minuti prima)...',
      'ja': 'カスタム（何分前）...',
      'ko': '사용자 지정(분 전)...',
      'no': 'Egendefinert (minutter før)...',
      'ru': 'Своё значение (минут до)...',
      'sv': 'Anpassad (minuter före)...',
      'zh': '自定义（提前分钟数）...',
    }[locale.languageCode]!;
  }

  String get reminderCustomMinutesTitle {
    return {
      'en': 'Minutes before',
      'vi': 'Số phút trước',
      'de': 'Minuten vorher',
      'cs': 'Minut předem',
      'es': 'Minutos antes',
      'fr': 'Minutes avant',
      'it': 'Minuti prima',
      'ja': '何分前',
      'ko': '몇 분 전',
      'no': 'Minutter før',
      'ru': 'Минут до',
      'sv': 'Minuter före',
      'zh': '提前分钟数',
    }[locale.languageCode]!;
  }

  String get reminderCustomMinutesHint {
    return {
      'en': 'e.g. 45',
      'vi': 'Ví dụ: 45',
      'de': 'z. B. 45',
      'cs': 'např. 45',
      'es': 'p. ej. 45',
      'fr': 'ex. : 45',
      'it': 'es. 45',
      'ja': '例: 45',
      'ko': '예: 45',
      'no': 'f.eks. 45',
      'ru': 'например, 45',
      'sv': 't.ex. 45',
      'zh': '例如：45',
    }[locale.languageCode]!;
  }

  /// "Thêm" (nút xác nhận trong hộp thoại nhắc).
  String get reminderConfirmAdd {
    return {
      'en': 'Add',
      'vi': 'Thêm',
      'de': 'Hinzufügen',
      'cs': 'Přidat',
      'es': 'Añadir',
      'fr': 'Ajouter',
      'it': 'Aggiungi',
      'ja': '追加',
      'ko': '추가',
      'no': 'Legg til',
      'ru': 'Добавить',
      'sv': 'Lägg till',
      'zh': '添加',
    }[locale.languageCode]!;
  }

  /// "Hủy" (khác [cancel] = 'Hủy bỏ'; giữ nguyên chữ của hộp thoại nhắc cũ).
  String get reminderCancel {
    return {
      'en': 'Cancel',
      'vi': 'Hủy',
      'de': 'Abbrechen',
      'cs': 'Zrušit',
      'es': 'Cancelar',
      'fr': 'Annuler',
      'it': 'Annulla',
      'ja': 'キャンセル',
      'ko': '취소',
      'no': 'Avbryt',
      'ru': 'Отмена',
      'sv': 'Avbryt',
      'zh': '取消',
    }[locale.languageCode]!;
  }

  String get reminderAtStart {
    return {
      'en': 'At start time',
      'vi': 'Đúng giờ',
      'de': 'Zur Startzeit',
      'cs': 'V čase začátku',
      'es': 'A la hora de inicio',
      'fr': 'À l\'heure de début',
      'it': 'All\'ora di inizio',
      'ja': '開始時刻',
      'ko': '시작 시각',
      'no': 'Ved starttid',
      'ru': 'Во время начала',
      'sv': 'Vid starttid',
      'zh': '开始时',
    }[locale.languageCode]!;
  }

  String get reminderOneMinuteBefore {
    return {
      'en': '1 minute before',
      'vi': '1 phút trước',
      'de': '1 Minute vorher',
      'cs': '1 minutu předem',
      'es': '1 minuto antes',
      'fr': '1 minute avant',
      'it': '1 minuto prima',
      'ja': '1分前',
      'ko': '1분 전',
      'no': '1 minutt før',
      'ru': 'За 1 минуту',
      'sv': '1 minut före',
      'zh': '提前1分钟',
    }[locale.languageCode]!;
  }

  /// Template: '{n}' = số phút.
  String get reminderMinutesBefore {
    return {
      'en': '{n} minutes before',
      'vi': '{n} phút trước',
      'de': '{n} Minuten vorher',
      'cs': '{n} min předem',
      'es': '{n} minutos antes',
      'fr': '{n} minutes avant',
      'it': '{n} minuti prima',
      'ja': '{n}分前',
      'ko': '{n}분 전',
      'no': '{n} minutter før',
      'ru': 'За {n} мин',
      'sv': '{n} minuter före',
      'zh': '提前{n}分钟',
    }[locale.languageCode]!;
  }

  String get reminderOneHourBefore {
    return {
      'en': '1 hour before',
      'vi': '1 giờ trước',
      'de': '1 Stunde vorher',
      'cs': '1 hodinu předem',
      'es': '1 hora antes',
      'fr': '1 heure avant',
      'it': '1 ora prima',
      'ja': '1時間前',
      'ko': '1시간 전',
      'no': '1 time før',
      'ru': 'За 1 час',
      'sv': '1 timme före',
      'zh': '提前1小时',
    }[locale.languageCode]!;
  }

  /// Template: '{n}' = số giờ.
  String get reminderHoursBefore {
    return {
      'en': '{n} hours before',
      'vi': '{n} giờ trước',
      'de': '{n} Stunden vorher',
      'cs': '{n} h předem',
      'es': '{n} horas antes',
      'fr': '{n} heures avant',
      'it': '{n} ore prima',
      'ja': '{n}時間前',
      'ko': '{n}시간 전',
      'no': '{n} timer før',
      'ru': 'За {n} ч',
      'sv': '{n} timmar före',
      'zh': '提前{n}小时',
    }[locale.languageCode]!;
  }

  String get reminderOneDayBefore {
    return {
      'en': '1 day before',
      'vi': '1 ngày trước',
      'de': '1 Tag vorher',
      'cs': '1 den předem',
      'es': '1 día antes',
      'fr': '1 jour avant',
      'it': '1 giorno prima',
      'ja': '1日前',
      'ko': '1일 전',
      'no': '1 dag før',
      'ru': 'За 1 день',
      'sv': '1 dag före',
      'zh': '提前1天',
    }[locale.languageCode]!;
  }

  /// Template: '{n}' = số ngày.
  String get reminderDaysBefore {
    return {
      'en': '{n} days before',
      'vi': '{n} ngày trước',
      'de': '{n} Tage vorher',
      'cs': '{n} d předem',
      'es': '{n} días antes',
      'fr': '{n} jours avant',
      'it': '{n} giorni prima',
      'ja': '{n}日前',
      'ko': '{n}일 전',
      'no': '{n} dager før',
      'ru': 'За {n} дн.',
      'sv': '{n} dagar före',
      'zh': '提前{n}天',
    }[locale.languageCode]!;
  }

  String get reminderOneWeekBefore {
    return {
      'en': '1 week before',
      'vi': '1 tuần trước',
      'de': '1 Woche vorher',
      'cs': '1 týden předem',
      'es': '1 semana antes',
      'fr': '1 semaine avant',
      'it': '1 settimana prima',
      'ja': '1週間前',
      'ko': '1주 전',
      'no': '1 uke før',
      'ru': 'За 1 неделю',
      'sv': '1 vecka före',
      'zh': '提前1周',
    }[locale.languageCode]!;
  }

  /// Template: '{n}' = số tuần.
  String get reminderWeeksBefore {
    return {
      'en': '{n} weeks before',
      'vi': '{n} tuần trước',
      'de': '{n} Wochen vorher',
      'cs': '{n} týd. předem',
      'es': '{n} semanas antes',
      'fr': '{n} semaines avant',
      'it': '{n} settimane prima',
      'ja': '{n}週間前',
      'ko': '{n}주 전',
      'no': '{n} uker før',
      'ru': 'За {n} нед.',
      'sv': '{n} veckor före',
      'zh': '提前{n}周',
    }[locale.languageCode]!;
  }

  String get reminderAtSpecificTime {
    return {
      'en': 'At a specific time…',
      'vi': 'Vào thời điểm cụ thể…',
      'de': 'Zu einem bestimmten Zeitpunkt…',
      'cs': 'V určitý čas…',
      'es': 'A una hora concreta…',
      'fr': 'À une heure précise…',
      'it': 'A un orario specifico…',
      'ja': '指定した日時…',
      'ko': '특정 시각…',
      'no': 'På et bestemt tidspunkt…',
      'ru': 'В определённое время…',
      'sv': 'Vid en viss tidpunkt…',
      'zh': '在指定时间…',
    }[locale.languageCode]!;
  }

  /// Template: '{time}' = ngày giờ đã định dạng.
  String get reminderAbsoluteAt {
    return {
      'en': 'At {time}',
      'vi': 'Lúc {time}',
      'de': 'Um {time}',
      'cs': 'V {time}',
      'es': 'A las {time}',
      'fr': 'À {time}',
      'it': 'Alle {time}',
      'ja': '{time}に',
      'ko': '{time}에',
      'no': 'Kl. {time}',
      'ru': 'В {time}',
      'sv': 'Kl. {time}',
      'zh': '于 {time}',
    }[locale.languageCode]!;
  }

  String get useCalendarDefault {
    return {
      'en': 'Use calendar default',
      'vi': 'Dùng mặc định của lịch',
      'de': 'Kalenderstandard verwenden',
      'cs': 'Použít výchozí nastavení kalendáře',
      'es': 'Usar el predeterminado del calendario',
      'fr': 'Utiliser le réglage par défaut du calendrier',
      'it': 'Usa il predefinito del calendario',
      'ja': 'カレンダーの既定を使用',
      'ko': '캘린더 기본값 사용',
      'no': 'Bruk kalenderens standard',
      'ru': 'Использовать настройки календаря',
      'sv': 'Använd kalenderns standard',
      'zh': '使用日历默认设置',
    }[locale.languageCode]!;
  }

  String get useCalendarDefaultSubtitle {
    return {
      'en':
          'The calendar provider sends its default alerts; no reminder is set on this device',
      'vi':
          'Nhà cung cấp lịch tự gửi nhắc mặc định; không đặt nhắc trên thiết bị này',
      'de':
          'Der Kalenderanbieter sendet seine Standardhinweise; auf diesem Gerät wird keine Erinnerung gesetzt',
      'cs':
          'Poskytovatel kalendáře posílá svá výchozí upozornění; na tomto zařízení se připomínka nenastaví',
      'es':
          'El proveedor del calendario envía sus avisos predeterminados; no se configura ningún recordatorio en este dispositivo',
      'fr':
          'Le fournisseur du calendrier envoie ses alertes par défaut ; aucun rappel n\'est défini sur cet appareil',
      'it':
          'Il provider del calendario invia i suoi avvisi predefiniti; nessun promemoria su questo dispositivo',
      'ja': 'カレンダー提供元が既定の通知を送ります。この端末ではリマインダーを設定しません',
      'ko': '캘린더 제공자가 기본 알림을 보냅니다. 이 기기에는 알림이 설정되지 않습니다',
      'no':
          'Kalenderleverandøren sender sine standardvarsler; ingen påminnelse settes på denne enheten',
      'ru':
          'Поставщик календаря отправляет свои уведомления по умолчанию; на этом устройстве напоминание не ставится',
      'sv':
          'Kalenderleverantören skickar sina standardaviseringar; ingen påminnelse ställs in på den här enheten',
      'zh': '由日历服务商发送默认提醒；本设备不设置提醒',
    }[locale.languageCode]!;
  }

  // --- AI activity log (Core Track C8b) ---
  // aiActivityLogInfo là template chứa '{n}' / '{days}': nơi gọi dùng replaceAll.

  String get aiActivityLog {
    return {
      'en': 'AI activity log',
      'vi': 'Nhật ký hoạt động AI',
      'de': 'KI-Aktivitätsprotokoll',
      'cs': 'Protokol aktivit AI',
      'es': 'Registro de actividad de IA',
      'fr': 'Journal d\'activité de l\'IA',
      'it': 'Registro attività IA',
      'ja': 'AI アクティビティログ',
      'ko': 'AI 활동 기록',
      'no': 'AI-aktivitetslogg',
      'ru': 'Журнал действий ИИ',
      'sv': 'AI-aktivitetslogg',
      'zh': 'AI 活动日志',
    }[locale.languageCode]!;
  }

  String get aiActivityLogEmpty {
    return {
      'en': 'No AI actions recorded yet.',
      'vi': 'Chưa có hành động AI nào được ghi lại.',
      'de': 'Noch keine KI-Aktionen aufgezeichnet.',
      'cs': 'Zatím nebyly zaznamenány žádné akce AI.',
      'es': 'Aún no hay acciones de IA registradas.',
      'fr': 'Aucune action de l\'IA enregistrée pour l\'instant.',
      'it': 'Nessuna azione IA registrata finora.',
      'ja': 'まだ AI の操作は記録されていません。',
      'ko': '아직 기록된 AI 작업이 없습니다.',
      'no': 'Ingen AI-handlinger registrert ennå.',
      'ru': 'Действия ИИ пока не записаны.',
      'sv': 'Inga AI-åtgärder har registrerats ännu.',
      'zh': '尚无 AI 操作记录。',
    }[locale.languageCode]!;
  }

  String get aiActivityLogInfo {
    return {
      'en':
          'Write and destructive actions proposed by the AI assistant. Keeps the newest {n} entries from the last {days} days on this device; not included in backups.',
      'vi':
          'Các hành động ghi và xóa do trợ lý AI đề xuất. Giữ {n} mục mới nhất trong {days} ngày gần đây trên thiết bị này; không có trong bản sao lưu.',
      'de':
          'Vom KI-Assistenten vorgeschlagene Schreib- und Löschaktionen. Behält die neuesten {n} Einträge der letzten {days} Tage auf diesem Gerät; nicht in Sicherungen enthalten.',
      'cs':
          'Zápisové a mazací akce navržené asistentem AI. Uchovává nejnovějších {n} záznamů za posledních {days} dní na tomto zařízení; není součástí záloh.',
      'es':
          'Acciones de escritura y eliminación propuestas por el asistente de IA. Conserva las {n} entradas más recientes de los últimos {days} días en este dispositivo; no se incluye en las copias de seguridad.',
      'fr':
          'Actions d\'écriture et de suppression proposées par l\'assistant IA. Conserve les {n} entrées les plus récentes des {days} derniers jours sur cet appareil ; non incluses dans les sauvegardes.',
      'it':
          'Azioni di scrittura ed eliminazione proposte dall\'assistente IA. Conserva le {n} voci più recenti degli ultimi {days} giorni su questo dispositivo; non incluse nei backup.',
      'ja':
          'AI アシスタントが提案した書き込み・削除操作です。この端末に直近 {days} 日間の最新 {n} 件を保持します。バックアップには含まれません。',
      'ko':
          'AI 도우미가 제안한 쓰기 및 삭제 작업입니다. 이 기기에 최근 {days}일 동안의 최신 {n}개 항목을 보관하며 백업에는 포함되지 않습니다.',
      'no':
          'Skrive- og slettehandlinger foreslått av AI-assistenten. Beholder de nyeste {n} oppføringene fra de siste {days} dagene på denne enheten; ikke med i sikkerhetskopier.',
      'ru':
          'Действия записи и удаления, предложенные ИИ-помощником. Хранятся последние {n} записей за {days} дней на этом устройстве; не входят в резервные копии.',
      'sv':
          'Skriv- och raderingsåtgärder som AI-assistenten föreslagit. Behåller de senaste {n} posterna från de senaste {days} dagarna på den här enheten; ingår inte i säkerhetskopior.',
      'zh': 'AI 助手提议的写入和删除操作。本设备保留最近 {days} 天内最新的 {n} 条记录；不包含在备份中。',
    }[locale.languageCode]!;
  }

  String get aiActivityLogClear {
    return {
      'en': 'Clear log',
      'vi': 'Xóa nhật ký',
      'de': 'Protokoll löschen',
      'cs': 'Vymazat protokol',
      'es': 'Borrar registro',
      'fr': 'Effacer le journal',
      'it': 'Cancella registro',
      'ja': 'ログを消去',
      'ko': '기록 지우기',
      'no': 'Tøm logg',
      'ru': 'Очистить журнал',
      'sv': 'Rensa logg',
      'zh': '清除日志',
    }[locale.languageCode]!;
  }

  String get aiActivityLogClearConfirm {
    return {
      'en': 'Delete all entries from the AI activity log?',
      'vi': 'Xóa toàn bộ mục trong nhật ký hoạt động AI?',
      'de': 'Alle Einträge aus dem KI-Aktivitätsprotokoll löschen?',
      'cs': 'Smazat všechny záznamy z protokolu aktivit AI?',
      'es': '¿Eliminar todas las entradas del registro de actividad de IA?',
      'fr': 'Supprimer toutes les entrées du journal d\'activité de l\'IA ?',
      'it': 'Eliminare tutte le voci dal registro attività IA?',
      'ja': 'AI アクティビティログのすべての項目を削除しますか？',
      'ko': 'AI 활동 기록의 모든 항목을 삭제할까요?',
      'no': 'Slette alle oppføringer fra AI-aktivitetsloggen?',
      'ru': 'Удалить все записи из журнала действий ИИ?',
      'sv': 'Radera alla poster i AI-aktivitetsloggen?',
      'zh': '删除 AI 活动日志中的所有记录？',
    }[locale.languageCode]!;
  }

  String get aiOutcomeAll {
    return {
      'en': 'All',
      'vi': 'Tất cả',
      'de': 'Alle',
      'cs': 'Vše',
      'es': 'Todo',
      'fr': 'Tout',
      'it': 'Tutti',
      'ja': 'すべて',
      'ko': '전체',
      'no': 'Alle',
      'ru': 'Все',
      'sv': 'Alla',
      'zh': '全部',
    }[locale.languageCode]!;
  }

  String get aiOutcomeExecuted {
    return {
      'en': 'Executed',
      'vi': 'Đã thực hiện',
      'de': 'Ausgeführt',
      'cs': 'Provedeno',
      'es': 'Ejecutada',
      'fr': 'Exécutée',
      'it': 'Eseguita',
      'ja': '実行済み',
      'ko': '실행됨',
      'no': 'Utført',
      'ru': 'Выполнено',
      'sv': 'Utförd',
      'zh': '已执行',
    }[locale.languageCode]!;
  }

  String get aiOutcomeDeclined {
    return {
      'en': 'Declined',
      'vi': 'Đã từ chối',
      'de': 'Abgelehnt',
      'cs': 'Odmítnuto',
      'es': 'Rechazada',
      'fr': 'Refusée',
      'it': 'Rifiutata',
      'ja': '拒否',
      'ko': '거부됨',
      'no': 'Avslått',
      'ru': 'Отклонено',
      'sv': 'Avböjd',
      'zh': '已拒绝',
    }[locale.languageCode]!;
  }

  String get aiOutcomeFailed {
    return {
      'en': 'Failed',
      'vi': 'Thất bại',
      'de': 'Fehlgeschlagen',
      'cs': 'Selhalo',
      'es': 'Fallida',
      'fr': 'Échouée',
      'it': 'Non riuscita',
      'ja': '失敗',
      'ko': '실패',
      'no': 'Mislyktes',
      'ru': 'Ошибка',
      'sv': 'Misslyckad',
      'zh': '失败',
    }[locale.languageCode]!;
  }

  String get aiOutcomeDeniedByPolicy {
    return {
      'en': 'Denied by policy',
      'vi': 'Bị chặn bởi chính sách',
      'de': 'Durch Richtlinie verweigert',
      'cs': 'Zamítnuto zásadou',
      'es': 'Denegada por la política',
      'fr': 'Refusée par la politique',
      'it': 'Negata dalla policy',
      'ja': 'ポリシーにより拒否',
      'ko': '정책에 의해 거부됨',
      'no': 'Avvist av policy',
      'ru': 'Запрещено политикой',
      'sv': 'Nekad av policy',
      'zh': '被策略拒绝',
    }[locale.languageCode]!;
  }

  String get aiActionArguments {
    return {
      'en': 'Arguments',
      'vi': 'Tham số',
      'de': 'Argumente',
      'cs': 'Argumenty',
      'es': 'Argumentos',
      'fr': 'Arguments',
      'it': 'Argomenti',
      'ja': '引数',
      'ko': '인수',
      'no': 'Argumenter',
      'ru': 'Аргументы',
      'sv': 'Argument',
      'zh': '参数',
    }[locale.languageCode]!;
  }

  String get aiActionResult {
    return {
      'en': 'Result',
      'vi': 'Kết quả',
      'de': 'Ergebnis',
      'cs': 'Výsledek',
      'es': 'Resultado',
      'fr': 'Résultat',
      'it': 'Risultato',
      'ja': '結果',
      'ko': '결과',
      'no': 'Resultat',
      'ru': 'Результат',
      'sv': 'Resultat',
      'zh': '结果',
    }[locale.languageCode]!;
  }

  String get aiActionError {
    return {
      'en': 'Error',
      'vi': 'Lỗi',
      'de': 'Fehler',
      'cs': 'Chyba',
      'es': 'Error',
      'fr': 'Erreur',
      'it': 'Errore',
      'ja': 'エラー',
      'ko': '오류',
      'no': 'Feil',
      'ru': 'Ошибка',
      'sv': 'Fel',
      'zh': '错误',
    }[locale.languageCode]!;
  }

  String get aiActionRiskLevel {
    return {
      'en': 'Risk level',
      'vi': 'Mức rủi ro',
      'de': 'Risikostufe',
      'cs': 'Úroveň rizika',
      'es': 'Nivel de riesgo',
      'fr': 'Niveau de risque',
      'it': 'Livello di rischio',
      'ja': 'リスクレベル',
      'ko': '위험 수준',
      'no': 'Risikonivå',
      'ru': 'Уровень риска',
      'sv': 'Risknivå',
      'zh': '风险级别',
    }[locale.languageCode]!;
  }

  String get aiActionPolicyMode {
    return {
      'en': 'Policy mode',
      'vi': 'Chế độ chính sách',
      'de': 'Richtlinienmodus',
      'cs': 'Režim zásad',
      'es': 'Modo de política',
      'fr': 'Mode de politique',
      'it': 'Modalità policy',
      'ja': 'ポリシーモード',
      'ko': '정책 모드',
      'no': 'Policymodus',
      'ru': 'Режим политики',
      'sv': 'Policyläge',
      'zh': '策略模式',
    }[locale.languageCode]!;
  }

  String get aiActionConversation {
    return {
      'en': 'Conversation',
      'vi': 'Cuộc trò chuyện',
      'de': 'Unterhaltung',
      'cs': 'Konverzace',
      'es': 'Conversación',
      'fr': 'Conversation',
      'it': 'Conversazione',
      'ja': '会話',
      'ko': '대화',
      'no': 'Samtale',
      'ru': 'Разговор',
      'sv': 'Konversation',
      'zh': '对话',
    }[locale.languageCode]!;
  }

  String get brightness {
    return {
      'en': 'Brightness',
      'vi': 'Độ sáng',
      'de': 'Helligkeit',
      'cs': 'Jas',
      'es': 'Brillo',
      'fr': 'Luminosité',
      'it': 'Luminosità',
      'ja': '明るさ',
      'ko': '밝기',
      'no': 'Lysstyrke',
      'ru': 'Яркость',
      'sv': 'Ljusstyrka',
      'zh': '亮度',
    }[locale.languageCode]!;
  }

  String get close {
    return {
      'en': 'Close',
      'vi': 'Đóng',
      'de': 'Schließen',
      'cs': 'Zavřít',
      'es': 'Cerrar',
      'fr': 'Fermer',
      'it': 'Chiudi',
      'ja': '閉じる',
      'ko': '닫기',
      'no': 'Lukk',
      'ru': 'Закрыть',
      'sv': 'Stäng',
      'zh': '关闭',
    }[locale.languageCode]!;
  }

  String get dark {
    return {
      'en': 'Dark',
      'vi': 'Tối',
      'de': 'Dunkel',
      'cs': 'Tmavý',
      'es': 'Oscuro',
      'fr': 'Sombre',
      'it': 'Scuro',
      'ja': 'ダーク',
      'ko': '어두운',
      'no': 'Mørk',
      'ru': 'Темный',
      'sv': 'Mörk',
      'zh': '暗',
    }[locale.languageCode]!;
  }

  String get deleteSubtask {
    return {
      'en': 'Delete subtask',
      'vi': 'Xóa nhiệm vụ phụ',
      'de': 'Unteraufgabe löschen',
      'cs': 'Smazat dílčí úkol',
      'es': 'Eliminar subtarea',
      'fr': 'Supprimer la sous-tâche',
      'it': 'Elimina sottocompito',
      'ja': 'サブタスクを削除',
      'ko': '하위 작업 삭제',
      'no': 'Slett underoppgave',
      'ru': 'Удалить подзадачу',
      'sv': 'Radera underuppgift',
      'zh': '删除子任务',
    }[locale.languageCode]!;
  }

  String get description {
    return {
      'en': 'Description',
      'vi': 'Mô tả',
      'de': 'Beschreibung',
      'cs': 'Popis',
      'es': 'Descripción',
      'fr': 'Description',
      'it': 'Descrizione',
      'ja': '説明',
      'ko': '설명',
      'no': 'Beskrivelse',
      'ru': 'Описание',
      'sv': 'Beskrivning',
      'zh': '描述',
    }[locale.languageCode]!;
  }

  String get editMeasurableTask {
    return {
      'en': 'Edit measurable task',
      'vi': 'Chỉnh sửa nhiệm vụ đo lường',
      'de': 'Messbare Aufgabe bearbeiten',
      'cs': 'Upravit měřitelný úkol',
      'es': 'Editar tarea medible',
      'fr': 'Modifier la tâche mesurable',
      'it': 'Modifica compito misurabile',
      'ja': '測定可能なタスクを編集',
      'ko': '측정 가능한 작업 편집',
      'no': 'Rediger målbar oppgave',
      'ru': 'Редактировать измеримую задачу',
      'sv': 'Redigera mätbar uppgift',
      'zh': '编辑可衡量的任务',
    }[locale.languageCode]!;
  }

  String get editSubtask {
    return {
      'en': 'Edit Subtask',
      'vi': 'Chỉnh sửa nhiệm vụ phụ',
      'de': 'Unteraufgabe bearbeiten',
      'cs': 'Upravit dílčí úkol',
      'es': 'Editar subtarea',
      'fr': 'Modifier la sous-tâche',
      'it': 'Modifica sottocompito',
      'ja': 'サブタスクを編集',
      'ko': '하위 작업 편집',
      'no': 'Rediger underoppgave',
      'ru': 'Редактировать подзадачу',
      'sv': 'Redigera underuppgift',
      'zh': '编辑子任务',
    }[locale.languageCode]!;
  }

  String get endDate {
    return {
      'en': 'End date',
      'vi': 'Ngày kết thúc',
      'de': 'Enddatum',
      'cs': 'Datum ukončení',
      'es': 'Fecha de finalización',
      'fr': 'Date de fin',
      'it': 'Data di fine',
      'ja': '終了日',
      'ko': '종료 날짜',
      'no': 'Sluttdato',
      'ru': 'Дата окончания',
      'sv': 'Slutdatum',
      'zh': '结束日期',
    }[locale.languageCode]!;
  }

  String get endTime {
    return {
      'en': 'End time',
      'vi': 'Thời gian kết thúc',
      'de': 'Endzeit',
      'cs': 'Čas ukončení',
      'es': 'Hora de finalización',
      'fr': 'Heure de fin',
      'it': 'Ora di fine',
      'ja': '終了時間',
      'ko': '종료 시간',
      'no': 'Sluttid',
      'ru': 'Время окончания',
      'sv': 'Sluttid',
      'zh': '结束时间',
    }[locale.languageCode]!;
  }

  String get error {
    return {
      'en': 'Error',
      'vi': 'Lỗi',
      'de': 'Fehler',
      'cs': 'Chyba',
      'es': 'Error',
      'fr': 'Erreur',
      'it': 'Errore',
      'ja': 'エラー',
      'ko': '오류',
      'no': 'Feil',
      'ru': 'Ошибка',
      'sv': 'Fel',
      'zh': '错误',
    }[locale.languageCode]!;
  }

  String get focusRightNow {
    return {
      'en': 'Focus right now?',
      'vi': 'Tập trung ngay bây giờ?',
      'de': 'Jetzt fokussieren?',
      'cs': 'Soustředit se právě teď?',
      'es': '¿Enfocar ahora mismo?',
      'fr': 'Se concentrer maintenant?',
      'it': 'Concentrarsi adesso?',
      'ja': '今すぐ集中しますか？',
      'ko': '지금 집중하십니까?',
      'no': 'Fokusere akkurat nå?',
      'ru': 'Сосредоточиться прямо сейчас?',
      'sv': 'Fokusera just nu?',
      'zh': '现在专注？',
    }[locale.languageCode]!;
  }

  String get hideSubTasks {
    return {
      'en': 'Hide sub-tasks',
      'vi': 'Ẩn nhiệm vụ phụ',
      'de': 'Unteraufgaben ausblenden',
      'cs': 'Skrýt dílčí úkoly',
      'es': 'Ocultar subtareas',
      'fr': 'Masquer les sous-tâches',
      'it': 'Nascondi sottocompiti',
      'ja': 'サブタスクを非表示',
      'ko': '하위 작업 숨기기',
      'no': 'Skjul underoppgaver',
      'ru': 'Скрыть подзадачи',
      'sv': 'Dölj underuppgifter',
      'zh': '隐藏子任务',
    }[locale.languageCode]!;
  }

  String get invalidValueForAtLeast {
    return {
      'en': 'Invalid value for "at least"',
      'vi': 'Giá trị không hợp lệ cho "ít nhất"',
      'de': 'Ungültiger Wert für "mindestens"',
      'cs': 'Neplatná hodnota pro "alespoň"',
      'es': 'Valor no válido para "al menos"',
      'fr': 'Valeur non valide pour "au moins"',
      'it': 'Valore non valido per "almeno"',
      'ja': '"少なくとも"の無効な値',
      'ko': '"적어도"에 대한 잘못된 값',
      'no': 'Ugyldig verdi for "minst"',
      'ru': 'Недопустимое значение для "по крайней мере"',
      'sv': 'Ogiltigt värde för "minst"',
      'zh': '“至少”值无效',
    }[locale.languageCode]!;
  }

  String get invalidValueForAtMost {
    return {
      'en': 'Invalid value for "at most"',
      'vi': 'Giá trị không hợp lệ cho "nhiều nhất"',
      'de': 'Ungültiger Wert für "höchstens"',
      'cs': 'Neplatná hodnota pro "nejvýše"',
      'es': 'Valor no válido para "como máximo"',
      'fr': 'Valeur non valide pour "au plus"',
      'it': 'Valore non valido per "al massimo"',
      'ja': '"最大"の無効な値',
      'ko': '"최대"에 대한 잘못된 값',
      'no': 'Ugyldig verdi for "høyst"',
      'ru': 'Недопустимое значение для "максимум"',
      'sv': 'Ogiltigt värde för "högst"',
      'zh': '“最多”值无效',
    }[locale.languageCode]!;
  }

  String get light {
    return {
      'en': 'Light',
      'vi': 'Sáng',
      'de': 'Licht',
      'cs': 'Světlý',
      'es': 'Luz',
      'fr': 'Lumière',
      'it': 'Luce',
      'ja': 'ライト',
      'ko': '빛',
      'no': 'Lys',
      'ru': 'Свет',
      'sv': 'Ljus',
      'zh': '光',
    }[locale.languageCode]!;
  }

  String get location {
    return {
      'en': 'Location',
      'vi': 'Vị trí',
      'de': 'Ort',
      'cs': 'Umístění',
      'es': 'Ubicación',
      'fr': 'Emplacement',
      'it': 'Posizione',
      'ja': '場所',
      'ko': '위치',
      'no': 'Plassering',
      'ru': 'Место нахождения',
      'sv': 'Plats',
      'zh': '位置',
    }[locale.languageCode]!;
  }

  String get markAsCompleted {
    return {
      'en': 'Mark as completed',
      'vi': 'Đánh dấu là đã hoàn thành',
      'de': 'Als abgeschlossen markieren',
      'cs': 'Označit jako dokončené',
      'es': 'Marcar como completado',
      'fr': 'Marquer comme terminé',
      'it': 'Segna come completato',
      'ja': '完了としてマーク',
      'ko': '완료로 표시',
      'no': 'Merk som fullført',
      'ru': 'Отметить как выполненное',
      'sv': 'Markera som klar',
      'zh': '标记为已完成',
    }[locale.languageCode]!;
  }

  String get markAsIncompleted {
    return {
      'en': 'Mark as incompleted',
      'vi': 'Đánh dấu là chưa hoàn thành',
      'de': 'Als unvollständig markieren',
      'cs': 'Označit jako nedokončené',
      'es': 'Marcar como incompleto',
      'fr': 'Marquer comme incomplet',
      'it': 'Segna come non completato',
      'ja': '未完了としてマーク',
      'ko': '미완료로 표시',
      'no': 'Merk som ufullstendig',
      'ru': 'Отметить как незавершенное',
      'sv': 'Markera som ofullständig',
      'zh': '标记为未完成',
    }[locale.languageCode]!;
  }

  String get pleaseEnterAStartDate {
    return {
      'en': 'Please enter a start date',
      'vi': 'Vui lòng nhập ngày bắt đầu',
      'de': 'Bitte geben Sie ein Startdatum ein',
      'cs': 'Zadejte prosím datum začátku',
      'es': 'Por favor ingrese una fecha de inicio',
      'fr': 'Veuillez entrer une date de début',
      'it': 'Si prega di inserire una data di inizio',
      'ja': '開始日を入力してください',
      'ko': '시작 날짜를 입력해 주세요',
      'no': 'Vennligst oppgi en startdato',
      'ru': 'Пожалуйста, введите дату начала',
      'sv': 'Ange ett startdatum',
      'zh': '请输入开始日期',
    }[locale.languageCode]!;
  }

  String get pleaseEnterAStartTime {
    return {
      'en': 'Please enter a start time',
      'vi': 'Vui lòng nhập thời gian bắt đầu',
      'de': 'Bitte geben Sie eine Startzeit ein',
      'cs': 'Zadejte prosím čas začátku',
      'es': 'Por favor ingrese una hora de inicio',
      'fr': 'Veuillez entrer une heure de début',
      'it': 'Si prega di inserire un orario di inizio',
      'ja': '開始時間を入力してください',
      'ko': '시작 시간을 입력해 주세요',
      'no': 'Vennligst oppgi en starttid',
      'ru': 'Пожалуйста, введите время начала',
      'sv': 'Ange en starttid',
      'zh': '请输入开始时间',
    }[locale.languageCode]!;
  }

  String get pleaseEnterAnEndDate {
    return {
      'en': 'Please enter an end date',
      'vi': 'Vui lòng nhập ngày kết thúc',
      'de': 'Bitte geben Sie ein Enddatum ein',
      'cs': 'Zadejte prosím datum ukončení',
      'es': 'Por favor ingrese una fecha de finalización',
      'fr': 'Veuillez entrer une date de fin',
      'it': 'Si prega di inserire una data di fine',
      'ja': '終了日を入力してください',
      'ko': '종료 날짜를 입력해 주세요',
      'no': 'Vennligst oppgi en sluttdato',
      'ru': 'Пожалуйста, введите дату окончания',
      'sv': 'Ange ett slutdatum',
      'zh': '请输入结束日期',
    }[locale.languageCode]!;
  }

  String get pleaseEnterAnEndTime {
    return {
      'en': 'Please enter an end time',
      'vi': 'Vui lòng nhập thời gian kết thúc',
      'de': 'Bitte geben Sie eine Endzeit ein',
      'cs': 'Zadejte prosím čas ukončení',
      'es': 'Por favor ingrese una hora de finalización',
      'fr': 'Veuillez entrer une heure de fin',
      'it': 'Si prega di inserire un orario di fine',
      'ja': '終了時間を入力してください',
      'ko': '종료 시간을 입력해 주세요',
      'no': 'Vennligst oppgi en sluttid',
      'ru': 'Пожалуйста, введите время окончания',
      'sv': 'Ange en sluttid',
      'zh': '请输入结束时间',
    }[locale.languageCode]!;
  }

  String get saveTheList {
    return {
      'en': 'Save the list',
      'vi': 'Lưu danh sách',
      'de': 'Liste speichern',
      'cs': 'Uložit seznam',
      'es': 'Guardar la lista',
      'fr': 'Enregistrer la liste',
      'it': 'Salva la lista',
      'ja': 'リストを保存',
      'ko': '목록 저장',
      'no': 'Lagre listen',
      'ru': 'Сохранить список',
      'sv': 'Spara listan',
      'zh': '保存列表',
    }[locale.languageCode]!;
  }

  String get showBrightnessButtonInApplicationBar {
    return {
      'en': 'Show brightness button in application bar',
      'vi': 'Hiển thị nút độ sáng trên thanh ứng dụng',
      'de': 'Helligkeitsschaltfläche in der Anwendungsleiste anzeigen',
      'cs': 'Zobrazit tlačítko jasu na panelu aplikace',
      'es': 'Mostrar el botón de brillo en la barra de la aplicación',
      'fr': 'Afficher le bouton de luminosité dans la barre d\'application',
      'it': 'Mostra il pulsante di luminosità nella barra dell\'applicazione',
      'ja': 'アプリケーションバーに明るさボタンを表示',
      'ko': '응용 프로그램 바에 밝기 버튼 표시',
      'no': 'Vis lysstyrkeknappen i programlinjen',
      'ru': 'Показать кнопку яркости на панели приложения',
      'sv': 'Visa ljusstyrkeknappen i applikationsfältet',
      'zh': '在应用栏中显示亮度按钮',
    }[locale.languageCode]!;
  }

  String get showColorImageButtonInApplicationBar {
    return {
      'en': 'Show color image button in application bar',
      'vi': 'Hiển thị nút hình ảnh màu trên thanh ứng dụng',
      'de': 'Farbbildschaltfläche in der Anwendungsleiste anzeigen',
      'cs': 'Zobrazit tlačítko barevného obrázku na panelu aplikace',
      'es': 'Mostrar el botón de imagen en color en la barra de la aplicación',
      'fr':
          'Afficher le bouton d\'image en couleur dans la barre d\'application',
      'it':
          'Mostra il pulsante dell\'immagine a colori nella barra dell\'applicazione',
      'ja': 'アプリケーションバーにカラー画像ボタンを表示',
      'ko': '응용 프로그램 바에 색상 이미지 버튼 표시',
      'no': 'Vis fargebildeknappen i programlinjen',
      'ru': 'Показать кнопку цветного изображения на панели приложения',
      'sv': 'Visa färgbildknappen i applikationsfältet',
      'zh': '在应用栏中显示彩色图像按钮',
    }[locale.languageCode]!;
  }

  String get showColorSeedButtonInApplicationBar {
    return {
      'en': 'Show color seed button in application bar',
      'vi': 'Hiển thị nút màu hạt giống trên thanh ứng dụng',
      'de': 'Farbsamenschaltfläche in der Anwendungsleiste anzeigen',
      'cs': 'Zobrazit tlačítko barevného semínka na panelu aplikace',
      'es': 'Mostrar el botón de semilla de color en la barra de la aplicación',
      'fr':
          'Afficher le bouton de graine de couleur dans la barre d\'application',
      'it':
          'Mostra il pulsante del seme di colore nella barra dell\'applicazione',
      'ja': 'アプリケーションバーにカラーシードボタンを表示',
      'ko': '응용 프로그램 바에 색상 시드 버튼 표시',
      'no': 'Vis fargefrøknappen i programlinjen',
      'ru': 'Показать кнопку цветного семени на панели приложения',
      'sv': 'Visa färgfröknappen i applikationsfältet',
      'zh': '在应用栏中显示颜色种子按钮',
    }[locale.languageCode]!;
  }

  String get showLanguagesButtonInApplicationBar {
    return {
      'en': 'Show languages button in application bar',
      'vi': 'Hiển thị nút ngôn ngữ trên thanh ứng dụng',
      'de': 'Sprachschaltfläche in der Anwendungsleiste anzeigen',
      'cs': 'Zobrazit tlačítko jazyků na panelu aplikace',
      'es': 'Mostrar el botón de idiomas en la barra de la aplicación',
      'fr': 'Afficher le bouton des langues dans la barre d\'application',
      'it': 'Mostra il pulsante delle lingue nella barra dell\'applicazione',
      'ja': 'アプリケーションバーに言語ボタンを表示',
      'ko': '응용 프로그램 바에 언어 버튼 표시',
      'no': 'Vis språkknappen i programlinjen',
      'ru': 'Показать кнопку языков на панели приложения',
      'sv': 'Visa språkknappen i applikationsfältet',
      'zh': '在应用栏中显示语言按钮',
    }[locale.languageCode]!;
  }

  String get showMaterialDesignButtonInApplicationBar {
    return {
      'en': 'Show material design button in application bar',
      'vi': 'Hiển thị nút thiết kế vật liệu trên thanh ứng dụng',
      'de': 'Material-Design-Schaltfläche in der Anwendungsleiste anzeigen',
      'cs': 'Zobrazit tlačítko materiálového designu na panelu aplikace',
      'es':
          'Mostrar el botón de diseño de material en la barra de la aplicación',
      'fr':
          'Afficher le bouton de design matériel dans la barre d\'application',
      'it':
          'Mostra il pulsante di design del materiale nella barra dell\'applicazione',
      'ja': 'アプリケーションバーにマテリアルデザインボタンを表示',
      'ko': '응용 프로그램 바에 머티리얼 디자인 버튼 표시',
      'no': 'Vis materiell design-knapp i programlinjen',
      'ru': 'Показать кнопку материального дизайна на панели приложения',
      'sv': 'Visa materialdesignknappen i applikationsfältet',
      'zh': '在应用栏中显示材料设计按钮',
    }[locale.languageCode]!;
  }

  String get showSubTasks {
    return {
      'en': 'Show sub-tasks',
      'vi': 'Hiển thị nhiệm vụ phụ',
      'de': 'Unteraufgaben anzeigen',
      'cs': 'Zobrazit dílčí úkoly',
      'es': 'Mostrar subtareas',
      'fr': 'Afficher les sous-tâches',
      'it': 'Mostra sottotask',
      'ja': 'サブタスクを表示',
      'ko': '하위 작업 표시',
      'no': 'Vis underoppgaver',
      'ru': 'Показать подзадачи',
      'sv': 'Visa deluppgifter',
      'zh': '显示子任务',
    }[locale.languageCode]!;
  }

  String get startDate {
    return {
      'en': 'Start date',
      'vi': 'Ngày bắt đầu',
      'de': 'Startdatum',
      'cs': 'Datum zahájení',
      'es': 'Fecha de inicio',
      'fr': 'Date de début',
      'it': 'Data di inizio',
      'ja': '開始日',
      'ko': '시작 날짜',
      'no': 'Startdato',
      'ru': 'Дата начала',
      'sv': 'Startdatum',
      'zh': '开始日期',
    }[locale.languageCode]!;
  }

  String get startTime {
    return {
      'en': 'Start time',
      'vi': 'Thời gian bắt đầu',
      'de': 'Startzeit',
      'cs': 'Doba spuštění',
      'es': 'Hora de inicio',
      'fr': 'Heure de début',
      'it': 'Ora di inizio',
      'ja': '開始時間',
      'ko': '시작 시간',
      'no': 'Starttid',
      'ru': 'Время начала',
      'sv': 'Starttid',
      'zh': '开始时间',
    }[locale.languageCode]!;
  }

  String get submit {
    return {
      'en': 'Submit',
      'vi': 'Gửi đi',
      'de': 'Einreichen',
      'cs': 'Předložit',
      'es': 'Enviar',
      'fr': 'Soumettre',
      'it': 'Invia',
      'ja': '提出する',
      'ko': '제출',
      'no': 'Sende inn',
      'ru': 'Отправить',
      'sv': 'Skicka in',
      'zh': '提交',
    }[locale.languageCode]!;
  }

  String get targetType {
    return {
      'en': 'Target Type',
      'vi': 'Loại mục tiêu',
      'de': 'Zieltyp',
      'cs': 'Typ cíle',
      'es': 'Tipo de objetivo',
      'fr': 'Type de cible',
      'it': 'Tipo di obiettivo',
      'ja': 'ターゲットタイプ',
      'ko': '목표 유형',
      'no': 'Måletype',
      'ru': 'Тип цели',
      'sv': 'Måltyp',
      'zh': '目标类型',
    }[locale.languageCode]!;
  }

  String get targetAbout {
    return {
      'en': 'Target: about',
      'vi': 'Mục tiêu: khoảng',
      'de': 'Ziel: ungefähr',
      'cs': 'Cíl: o',
      'es': 'Objetivo: sobre',
      'fr': 'Cible : environ',
      'it': 'Obiettivo: circa',
      'ja': '目標：約',
      'ko': '목표: 약',
      'no': 'Mål: om',
      'ru': 'Цель: о',
      'sv': 'Mål: om',
      'zh': '目标：关于',
    }[locale.languageCode]!;
  }

  String get targetAtLeast {
    return {
      'en': 'Target: at least',
      'vi': 'Mục tiêu: ít nhất',
      'de': 'Ziel: mindestens',
      'cs': 'Cíl: alespoň',
      'es': 'Objetivo: al menos',
      'fr': 'Cible : au moins',
      'it': 'Obiettivo: almeno',
      'ja': '目標：少なくとも',
      'ko': '목표: 최소한',
      'no': 'Mål: minst',
      'ru': 'Цель: по крайней мере',
      'sv': 'Mål: minst',
      'zh': '目标：至少',
    }[locale.languageCode]!;
  }

  String get targetAtMost {
    return {
      'en': 'Target: at most',
      'vi': 'Mục tiêu: nhiều nhất',
      'de': 'Ziel: höchstens',
      'cs': 'Cíl: nejvýše',
      'es': 'Objetivo: como máximo',
      'fr': 'Cible : au plus',
      'it': 'Obiettivo: al massimo',
      'ja': '目標：最大',
      'ko': '목표: 최대',
      'no': 'Mål: høyst',
      'ru': 'Цель: максимум',
      'sv': 'Mål: högst',
      'zh': '目标：最多',
    }[locale.languageCode]!;
  }

  String get timeInterval {
    return {
      'en': 'Time Interval',
      'vi': 'Khoảng thời gian',
      'de': 'Zeitintervall',
      'cs': 'Časový interval',
      'es': 'Intervalo de tiempo',
      'fr': 'Intervalle de temps',
      'it': 'Intervallo di tempo',
      'ja': '時間間隔',
      'ko': '시간 간격',
      'no': 'Tidsintervall',
      'ru': 'Временной интервал',
      'sv': 'Tidsintervall',
      'zh': '时间间隔',
    }[locale.languageCode]!;
  }

  String get to {
    return {
      'en': 'to',
      'vi': 'đến',
      'de': 'zu',
      'cs': 'do',
      'es': 'a',
      'fr': 'à',
      'it': 'a',
      'ja': 'へ',
      'ko': '에',
      'no': 'til',
      'ru': 'к',
      'sv': 'till',
      'zh': '至',
    }[locale.languageCode]!;
  }

  String get undefined {
    return {
      'en': 'undefined',
      'vi': 'không xác định',
      'de': 'undefiniert',
      'cs': 'nedefinováno',
      'es': 'indefinido',
      'fr': 'indéfini',
      'it': 'indefinito',
      'ja': '未定義',
      'ko': '미정의',
      'no': 'udefinert',
      'ru': 'не определено',
      'sv': 'odefinierad',
      'zh': '未定义',
    }[locale.languageCode]!;
  }

  String get unit {
    return {
      'en': 'Unit',
      'vi': 'Đơn vị',
      'de': 'Einheit',
      'cs': 'Jednotka',
      'es': 'Unidad',
      'fr': 'Unité',
      'it': 'Unità',
      'ja': '単位',
      'ko': '단위',
      'no': 'Enhet',
      'ru': 'Единица',
      'sv': 'Enhet',
      'zh': '单位',
    }[locale.languageCode]!;
  }

  String get userInterfaceSettings {
    return {
      'en': 'User Interface Settings',
      'vi': 'Cài đặt giao diện người dùng',
      'de': 'Benutzeroberflächeneinstellungen',
      'cs': 'Nastavení uživatelského rozhraní',
      'es': 'Configuración de la interfaz de usuario',
      'fr': 'Paramètres de l\'interface utilisateur',
      'it': 'Impostazioni dell\'interfaccia utente',
      'ja': 'ユーザーインターフェースの設定',
      'ko': '사용자 인터페이스 설정',
      'no': 'Brukergrensesnittinnstillinger',
      'ru': 'Настройки пользовательского интерфейса',
      'sv': 'Användargränssnittsinställningar',
      'zh': '用户界面设置',
    }[locale.languageCode]!;
  }

  String
      get youAreEnteringAMinimumTargetValueThatIsGreaterThanTheMaximumTargetValue {
    return {
      'en':
          'You are entering a minimum target value that is greater than the maximum target value',
      'vi':
          'Bạn đang nhập một giá trị mục tiêu tối thiểu lớn hơn giá trị mục tiêu tối đa',
      'de':
          'Sie geben einen minimalen Zielwert ein, der größer als der maximale Zielwert ist',
      'cs':
          'Zadáváte minimální cílovou hodnotu, která je větší než maximální cílová hodnota',
      'es':
          'Estás introduciendo un valor objetivo mínimo que es mayor que el valor objetivo máximo',
      'fr':
          'Vous entrez une valeur cible minimale qui est supérieure à la valeur cible maximale',
      'it':
          'Stai inserendo un valore target minimo che è maggiore del valore target massimo',
      'ja': '最小目標値を入力していますが、それは最大目標値よりも大きいです',
      'ko': '최소 목표 값이 최대 목표 값보다 큰 값을 입력하고 있습니다',
      'no':
          'Du legger inn en minimumsmålverdi som er større enn maksimumsmålverdien',
      'ru':
          'Вы вводите минимальное целевое значение, которое больше максимального целевого значения',
      'sv':
          'Du anger ett minimimålsvärde som är större än det maximala målvärdet',
      'zh': '您输入的最小目标值大于最大目标值',
    }[locale.languageCode]!;
  }

  String get youHaveNotEnteredTheTitleOfTheList {
    return {
      'en': 'You have not entered the title of the list',
      'vi': 'Bạn chưa nhập tiêu đề của danh sách',
      'de': 'Sie haben den Titel der Liste nicht eingegeben',
      'cs': 'Nezadali jste název seznamu',
      'es': 'No has introducido el título de la lista',
      'fr': 'Vous n\'avez pas entré le titre de la liste',
      'it': 'Non hai inserito il titolo della lista',
      'ja': 'リストのタイトルを入力していません',
      'ko': '목록의 제목을 입력하지 않았습니다',
      'no': 'Du har ikke angitt tittelen på listen',
      'ru': 'Вы не ввели название списка',
      'sv': 'Du har inte angett listans titel',
      'zh': '您尚未输入列表的标题',
    }[locale.languageCode]!;
  }

  String get youHaveNotEnteredTheTitleOfTheTask {
    return {
      'en': 'You have not entered the title of the task',
      'vi': 'Bạn chưa nhập tiêu đề của nhiệm vụ',
      'de': 'Sie haben den Titel der Aufgabe nicht eingegeben',
      'cs': 'Nezadali jste název úkolu',
      'es': 'No has introducido el título de la tarea',
      'fr': 'Vous n\'avez pas entré le titre de la tâche',
      'it': 'Non hai inserito il titolo del compito',
      'ja': 'タスクのタイトルを入力していません',
      'ko': '작업의 제목을 입력하지 않았습니다',
      'no': 'Du har ikke angitt tittelen på oppgaven',
      'ru': 'Вы не ввели название задачи',
      'sv': 'Du har inte angett uppgiftens titel',
      'zh': '您尚未输入任务的标题',
    }[locale.languageCode]!;
  }

  String get openLink {
    return {
      'en': 'Open link',
      'vi': 'Mở liên kết',
      'de': 'Link öffnen',
      'cs': 'Otevřít odkaz',
      'es': 'Abrir enlace',
      'fr': 'Ouvrir le lien',
      'it': 'Apri il link',
      'ja': 'リンクを開く',
      'ko': '링크 열기',
      'no': 'Åpne lenke',
      'ru': 'Открыть ссылку',
      'sv': 'Öppna länk',
      'zh': '打开链接',
    }[locale.languageCode]!;
  }

  String get doYouWantToOpenTheLinkInYourDefaultBrowser {
    return {
      'en': 'do you want to open the link in your default browser?',
      'vi':
          'bạn có muốn mở liên kết trong trình duyệt mặc định của mình không?',
      'de': 'Möchten Sie den Link in Ihrem Standardbrowser öffnen?',
      'cs': 'Chcete otevřít odkaz ve svém výchozím prohlížeči?',
      'es': '¿Quieres abrir el enlace en tu navegador predeterminado?',
      'fr': 'Voulez-vous ouvrir le lien dans votre navigateur par défaut?',
      'it': 'Vuoi aprire il link nel tuo browser predefinito?',
      'ja': 'デフォルトのブラウザでリンクを開きますか？',
      'ko': '기본 브라우저에서 링크를 열고 싶으신가요?',
      'no': 'Vil du åpne lenken i standard nettleseren din?',
      'ru': 'Хотите открыть ссылку в вашем браузере по умолчанию?',
      'sv': 'Vill du öppna länken i din standardwebbläsare?',
      'zh': '你想在默认浏览器中打开链接吗？',
    }[locale.languageCode]!;
  }

  String get open {
    return {
      'en': 'Open',
      'vi': 'Mở',
      'de': 'Öffnen',
      'cs': 'Otevřít',
      'es': 'Abrir',
      'fr': 'Ouvrir',
      'it': 'Apri',
      'ja': '開く',
      'ko': '열기',
      'no': 'Åpne',
      'ru': 'Открыть',
      'sv': 'Öppna',
      'zh': '打开',
    }[locale.languageCode]!;
  }

  String get applicationInformation {
    return {
      'en': 'Application Information',
      'vi': 'Thông tin ứng dụng',
      'de': 'Anwendungsinformationen',
      'cs': 'Informace o aplikaci',
      'es': 'Información de la aplicación',
      'fr': 'Informations sur l\'application',
      'it': 'Informazioni sull\'applicazione',
      'ja': 'アプリケーション情報',
      'ko': '응용 프로그램 정보',
      'no': 'Applikasjonsinformasjon',
      'ru': 'Информация о приложении',
      'sv': 'Applikationsinformation',
      'zh': '应用信息',
    }[locale.languageCode]!;
  }

  String get reportAnIssue {
    return {
      'en': 'Report an Issue',
      'vi': 'Báo cáo một vấn đề',
      'de': 'Ein Problem melden',
      'cs': 'Nahlásit problém',
      'es': 'Informar de un problema',
      'fr': 'Signaler un problème',
      'it': 'Segnala un problema',
      'ja': '問題を報告する',
      'ko': '문제 보고',
      'no': 'Rapporter et problem',
      'ru': 'Сообщить о проблеме',
      'sv': 'Rapportera ett problem',
      'zh': '报告问题',
    }[locale.languageCode]!;
  }

  String get havingAnIssueReportItHere {
    return {
      'en': 'Having an issue ? Report it here',
      'vi': 'Gặp vấn đề? Báo cáo tại đây',
      'de': 'Ein Problem haben? Melden Sie es hier',
      'cs': 'Máte problém? Nahlásit to zde',
      'es': '¿Tienes un problema? Informe aquí',
      'fr': 'Vous avez un problème ? Signalez-le ici',
      'it': 'Hai un problema? Segnalalo qui',
      'ja': '問題がありますか？ここで報告してください',
      'ko': '문제가 있나요? 여기에 보고하세요',
      'no': 'Har du et problem? Rapporter det her',
      'ru': 'У вас есть проблема? Сообщите о ней здесь',
      'sv': 'Har du ett problem? Rapportera det här',
      'zh': '有问题吗？在这里报告',
    }[locale.languageCode]!;
  }

  String get privacyPolicy {
    return {
      'en': 'Privacy Policy',
      'vi': 'Chính sách bảo mật',
      'de': 'Datenschutz-Bestimmungen',
      'cs': 'Zásady ochrany osobních údajů',
      'es': 'Política de privacidad',
      'fr': 'Politique de confidentialité',
      'it': 'Politica sulla privacy',
      'ja': 'プライバシーポリシー',
      'ko': '개인정보 처리방침',
      'no': 'Personvernpolicy',
      'ru': 'Политика конфиденциальности',
      'sv': 'Integritetspolicy',
      'zh': '隐私政策',
    }[locale.languageCode]!;
  }

  String get openSource {
    return {
      'en': 'Open Source',
      'vi': 'Mã nguồn mở',
      'de': 'Open Source',
      'cs': 'Otevřený zdroj',
      'es': 'Código abierto',
      'fr': 'Open source',
      'it': 'Open source',
      'ja': 'オープンソース',
      'ko': '오픈 소스',
      'no': 'Åpen kildekode',
      'ru': 'Открытый исходный код',
      'sv': 'Öppen källkod',
      'zh': '开源',
    }[locale.languageCode]!;
  }

  String get author {
    return {
      'en': 'Author',
      'vi': 'Tác giả',
      'de': 'Autor',
      'cs': 'Autor',
      'es': 'Autor',
      'fr': 'Auteur',
      'it': 'Autore',
      'ja': '著者',
      'ko': '저자',
      'no': 'Forfatter',
      'ru': 'Автор',
      'sv': 'Författare',
      'zh': '作者',
    }[locale.languageCode]!;
  }

  String get sendAnEmail {
    return {
      'en': 'Send an Email',
      'vi': 'Gửi một Email',
      'de': 'Eine E-Mail senden',
      'cs': 'Poslat e-mail',
      'es': 'Enviar un correo electrónico',
      'fr': 'Envoyer un e-mail',
      'it': 'Invia un\'email',
      'ja': 'メールを送る',
      'ko': '이메일 보내기',
      'no': 'Send en e-post',
      'ru': 'Отправить электронное письмо',
      'sv': 'Skicka ett e-postmeddelande',
      'zh': '发送电子邮件',
    }[locale.languageCode]!;
  }

  String get openSourceAnnouncement {
    return {
      'en': 'Open Source Announcement',
      'vi': 'Thông báo mã nguồn mở',
      'de': 'Open-Source-Ankündigung',
      'cs': 'Oznámení o otevřeném zdroji',
      'es': 'Anuncio de código abierto',
      'fr': 'Annonce Open Source',
      'it': 'Annuncio Open Source',
      'ja': 'オープンソースの発表',
      'ko': '오픈 소스 공지',
      'no': 'Open Source-annonsering',
      'ru': 'Объявление об открытом исходном коде',
      'sv': 'Öppen källkodsmeddelande',
      'zh': '开源公告',
    }[locale.languageCode]!;
  }

  String
      get thisAppWillBecomeOpenSourceWeWillMakeTheSourceCodePublicAfterCleaningUpTheCode {
    return {
      'en':
          'This app will become open source. We will make the source code public after cleaning up the code.',
      'vi':
          'Ứng dụng này sẽ trở thành mã nguồn mở. Chúng tôi sẽ công khai mã nguồn sau khi dọn dẹp mã.',
      'de':
          'Diese App wird Open Source. Wir werden den Quellcode veröffentlichen, nachdem wir den Code bereinigt haben.',
      'cs':
          'Tato aplikace se stane otevřeným zdrojem. Zdrojový kód zveřejníme po vyčištění kódu.',
      'es':
          'Esta aplicación se convertirá en código abierto. Haremos público el código fuente después de limpiar el código.',
      'fr':
          'Cette application deviendra open source. Nous rendrons le code source public après avoir nettoyé le code.',
      'it':
          'Questa app diventerà open source. Rendiamo pubblico il codice sorgente dopo aver pulito il codice.',
      'ja': 'このアプリはオープンソースになります。コードのクリーンアップ後にソースコードを公開します。',
      'ko': '이 앱은 오픈 소스가 될 것입니다. 코드를 정리한 후 소스 코드를 공개하겠습니다.',
      'no':
          'Denne appen vil bli åpen kildekode. Vi vil gjøre kildekoden offentlig etter at vi har ryddet opp i koden.',
      'ru':
          'Это приложение станет открытым исходным кодом. Мы опубликуем исходный код после очистки кода.',
      'sv':
          'Denna app kommer att bli öppen källkod. Vi kommer att göra källkoden offentlig efter att vi har städat upp koden.',
      'zh': '此应用将成为开源。我们将在清理代码后公开源代码。',
    }[locale.languageCode]!;
  }

  String get ok {
    return {
      'en': 'Ok',
      'vi': 'Đồng ý',
      'de': 'Ok',
      'cs': 'Ok',
      'es': 'Ok',
      'fr': 'Ok',
      'it': 'Ok',
      'ja': 'Ok',
      'ko': 'Ok',
      'no': 'Ok',
      'ru': 'Ok',
      'sv': 'Ok',
      'zh': '好的',
    }[locale.languageCode]!;
  }

  String get supportUs {
    return {
      'en': 'Support us',
      'vi': 'Hỗ trợ chúng tôi',
      'de': 'Unterstützen Sie uns',
      'cs': 'Podpořte nás',
      'es': 'Apóyanos',
      'fr': 'Soutenez-nous',
      'it': 'Supportaci',
      'ja': '私たちをサポート',
      'ko': '우리를 지원하십시오',
      'no': 'Støtt oss',
      'ru': 'Поддержите нас',
      'sv': 'Stöd oss',
      'zh': '支持我们',
    }[locale.languageCode]!;
  }

  String get important {
    return {
      'en': 'Important',
      'vi': 'Quan trọng',
      'de': 'Wichtig',
      'cs': 'Důležité',
      'es': 'Importante',
      'fr': 'Important',
      'it': 'Importante',
      'ja': '重要',
      'ko': '중요한',
      'no': 'Viktig',
      'ru': 'Важно',
      'sv': 'Viktigt',
      'zh': '重要',
    }[locale.languageCode]!;
  }

  String get hideTargetInfor {
    return {
      'en': 'Hide target infor',
      'vi': 'Ẩn thông tin mục tiêu',
      'de': 'Zielinformationen ausblenden',
      'cs': 'Skrýt cílové informace',
      'es': 'Ocultar información del objetivo',
      'fr': 'Masquer les informations cibles',
      'it': 'Nascondi le informazioni sul target',
      'ja': 'ターゲット情報を非表示',
      'ko': '목표 정보 숨기기',
      'no': 'Skjul målinformasjon',
      'ru': 'Скрыть информацию о цели',
      'sv': 'Dölj målinformation',
      'zh': '隐藏目标信息',
    }[locale.languageCode]!;
  }

  String get showTargetInfor {
    return {
      'en': 'Show target infor',
      'vi': 'Hiển thị thông tin mục tiêu',
      'de': 'Zielinformationen anzeigen',
      'cs': 'Zobrazit cílové informace',
      'es': 'Mostrar información del objetivo',
      'fr': 'Afficher les informations cibles',
      'it': 'Mostra le informazioni sul target',
      'ja': 'ターゲット情報を表示',
      'ko': '목표 정보 표시',
      'no': 'Vis målinformasjon',
      'ru': 'Показать информацию о цели',
      'sv': 'Visa målinformation',
      'zh': '显示目标信息',
    }[locale.languageCode]!;
  }

  String get hasBeenDone {
    return {
      'en': 'has been done:',
      'vi': 'đã hoàn thành:',
      'de': 'wurde erledigt:',
      'cs': 'bylo hotovo:',
      'es': 'ha sido hecho:',
      'fr': 'a été fait :',
      'it': 'è stato fatto:',
      'ja': 'が完了しました：',
      'ko': '완료되었습니다:',
      'no': 'har blitt gjort:',
      'ru': 'было сделано:',
      'sv': 'har gjorts:',
      'zh': '已完成：',
    }[locale.languageCode]!;
  }

  String get planned {
    return {
      'en': 'Planned',
      'vi': 'Đã lên kế hoạch',
      'de': 'Geplant',
      'cs': 'Naplánováno',
      'es': 'Planificado',
      'fr': 'Prévu',
      'it': 'Pianificato',
      'ja': '計画済み',
      'ko': '계획됨',
      'no': 'Planlagt',
      'ru': 'Запланировано',
      'sv': 'Planerad',
      'zh': '已计划',
    }[locale.languageCode]!;
  }

  String get inProgress {
    return {
      'en': 'In progress',
      'vi': 'Đang tiến hành',
      'de': 'In Bearbeitung',
      'cs': 'Probíhá',
      'es': 'En progreso',
      'fr': 'En cours',
      'it': 'In corso',
      'ja': '進行中',
      'ko': '진행 중',
      'no': 'Pågår',
      'ru': 'В процессе',
      'sv': 'Pågår',
      'zh': '进行中',
    }[locale.languageCode]!;
  }

  String get gone {
    return {
      'en': 'Gone',
      'vi': 'Đã qua',
      'de': 'Weg',
      'cs': 'Pryč',
      'es': 'Ido',
      'fr': 'Parti',
      'it': 'Andato',
      'ja': '行った',
      'ko': '갔다',
      'no': 'Borte',
      'ru': 'Ушел',
      'sv': 'Borta',
      'zh': '去了',
    }[locale.languageCode]!;
  }

  String get today {
    return {
      'en': 'Today',
      'vi': 'Hôm nay',
      'de': 'Heute',
      'cs': 'Dnes',
      'es': 'Hoy',
      'fr': 'Aujourd\'hui',
      'it': 'Oggi',
      'ja': '今日',
      'ko': '오늘',
      'no': 'I dag',
      'ru': 'Сегодня',
      'sv': 'Idag',
      'zh': '今天',
    }[locale.languageCode]!;
  }

  String get from {
    return {
      'en': 'From',
      'vi': 'Từ',
      'de': 'Von',
      'cs': 'Od',
      'es': 'Desde',
      'fr': 'De',
      'it': 'Da',
      'ja': 'から',
      'ko': '에서',
      'no': 'Fra',
      'ru': 'От',
      'sv': 'Från',
      'zh': '从',
    }[locale.languageCode]!;
  }

  String get markAsIncompletedInThisTimeInterval {
    return {
      'en': 'Mark as incompleted in this time interval',
      'vi': 'Đánh dấu là chưa hoàn thành trong khoảng thời gian này',
      'de': 'Als unvollständig markieren in diesem Zeitintervall',
      'cs': 'Označit jako nedokončené v tomto časovém intervalu',
      'es': 'Marcar como incompleto en este intervalo de tiempo',
      'fr': 'Marquer comme incomplet dans cet intervalle de temps',
      'it': 'Segna come non completato in questo intervallo di tempo',
      'ja': 'この時間間隔で未完了としてマーク',
      'ko': '이 시간 간격에서 완료되지 않음으로 표시',
      'no': 'Marker som ufullstendig i dette tidsintervallet',
      'ru': 'Отметить как незавершенное в этом временном интервале',
      'sv': 'Markera som ofullständig i detta tidsintervall',
      'zh': '在此时间间隔内标记为未完成',
    }[locale.languageCode]!;
  }

  String get markAsCompletedInThisTimeInterval {
    return {
      'en': 'Mark as completed in this time interval',
      'vi': 'Đánh dấu là đã hoàn thành trong khoảng thời gian này',
      'de': 'Als abgeschlossen markieren in diesem Zeitintervall',
      'cs': 'Označit jako dokončené v tomto časovém intervalu',
      'es': 'Marcar como completado en este intervalo de tiempo',
      'fr': 'Marquer comme terminé dans cet intervalle de temps',
      'it': 'Segna come completato in questo intervallo di tempo',
      'ja': 'この時間間隔で完了としてマーク',
      'ko': '이 시간 간격에서 완료로 표시',
      'no': 'Marker som fullført i dette tidsintervallet',
      'ru': 'Отметить как завершенное в этом временном интервале',
      'sv': 'Markera som slutförd i detta tidsintervall',
      'zh': '在此时间间隔内标记为已完成',
    }[locale.languageCode]!;
  }

  String get syncDetailsFromTaskToThisTimeInterval {
    return {
      'en': 'Sync details from task to this time interval',
      'vi': 'Đồng bộ chi tiết từ nhiệm vụ đến khoảng thời gian này',
      'de': 'Details von Aufgabe zu diesem Zeitintervall synchronisieren',
      'cs': 'Synchronizovat detaily z úkolu do tohoto časového intervalu',
      'es': 'Sincronizar detalles de la tarea a este intervalo de tiempo',
      'fr': 'Synchroniser les détails de la tâche à cet intervalle de temps',
      'it': 'Sincronizza i dettagli del compito a questo intervallo di tempo',
      'ja': 'タスクの詳細をこの時間間隔に同期',
      'ko': '작업의 세부 정보를 이 시간 간격으로 동기화',
      'no': 'Synkroniser detaljer fra oppgave til dette tidsintervallet',
      'ru': 'Синхронизировать детали задачи с этим временным интервалом',
      'sv': 'Synkronisera detaljer från uppgift till detta tidsintervall',
      'zh': '将任务的详细信息同步到此时间间隔',
    }[locale.languageCode]!;
  }

  String get goToMainTask {
    return {
      'en': 'Go to main task',
      'vi': 'Đi đến nhiệm vụ chính',
      'de': 'Zur Hauptaufgabe gehen',
      'cs': 'Přejít na hlavní úkol',
      'es': 'Ir a la tarea principal',
      'fr': 'Aller à la tâche principale',
      'it': 'Vai al compito principale',
      'ja': 'メインタスクに移動',
      'ko': '메인 작업으로 이동',
      'no': 'Gå til hovedoppgaven',
      'ru': 'Перейти к основной задаче',
      'sv': 'Gå till huvuduppgiften',
      'zh': '转到主任务',
    }[locale.languageCode]!;
  }

  String get editThisTimeInterval {
    return {
      'en': 'Edit this time interval',
      'vi': 'Chỉnh sửa khoảng thời gian này',
      'de': 'Bearbeiten Sie dieses Zeitintervall',
      'cs': 'Upravit tento časový interval',
      'es': 'Editar este intervalo de tiempo',
      'fr': 'Modifier cet intervalle de temps',
      'it': 'Modifica questo intervallo di tempo',
      'ja': 'この時間間隔を編集',
      'ko': '이 시간 간격 편집',
      'no': 'Rediger dette tidsintervallet',
      'ru': 'Редактировать этот временной интервал',
      'sv': 'Redigera detta tidsintervall',
      'zh': '编辑此时间间隔',
    }[locale.languageCode]!;
  }

  String get deleteThisTimeInterval {
    return {
      'en': 'Delete this time interval',
      'vi': 'Xóa khoảng thời gian này',
      'de': 'Löschen Sie dieses Zeitintervall',
      'cs': 'Odstranit tento časový interval',
      'es': 'Eliminar este intervalo de tiempo',
      'fr': 'Supprimer cet intervalle de temps',
      'it': 'Elimina questo intervallo di tempo',
      'ja': 'この時間間隔を削除',
      'ko': '이 시간 간격 삭제',
      'no': 'Slett dette tidsintervallet',
      'ru': 'Удалить этот временной интервал',
      'sv': 'Ta bort detta tidsintervall',
      'zh': '删除此时间间隔',
    }[locale.languageCode]!;
  }

  String get update {
    return {
      'en': 'Update',
      'vi': 'Cập nhật',
      'de': 'Aktualisieren',
      'cs': 'Aktualizovat',
      'es': 'Actualizar',
      'fr': 'Mettre à jour',
      'it': 'Aggiorna',
      'ja': '更新',
      'ko': '업데이트',
      'no': 'Oppdater',
      'ru': 'Обновить',
      'sv': 'Uppdatera',
      'zh': '更新',
    }[locale.languageCode]!;
  }

  String get selectMultipleDays {
    return {
      'en': 'Select multiple days',
      'vi': 'Chọn nhiều ngày',
      'de': 'Wählen Sie mehrere Tage',
      'cs': 'Vyberte více dní',
      'es': 'Seleccionar varios días',
      'fr': 'Sélectionnez plusieurs jours',
      'it': 'Seleziona più giorni',
      'ja': '複数の日を選択',
      'ko': '여러 날짜 선택',
      'no': 'Velg flere dager',
      'ru': 'Выберите несколько дней',
      'sv': 'Välj flera dagar',
      'zh': '选择多天',
    }[locale.languageCode]!;
  }

  String get selectDateRange {
    return {
      'en': 'Select date range',
      'vi': 'Chọn phạm vi ngày',
      'de': 'Datumsbereich auswählen',
      'cs': 'Vyberte rozsah dat',
      'es': 'Seleccionar rango de fechas',
      'fr': 'Sélectionnez la plage de dates',
      'it': 'Seleziona l\'intervallo di date',
      'ja': '日付範囲を選択',
      'ko': '날짜 범위 선택',
      'no': 'Velg datoperiode',
      'ru': 'Выберите диапазон дат',
      'sv': 'Välj datumintervall',
      'zh': '选择日期范围',
    }[locale.languageCode]!;
  }

  String get notImportant {
    return {
      'en': 'Not Important',
      'vi': 'Không quan trọng',
      'de': 'Nicht wichtig',
      'cs': 'Není důležité',
      'es': 'No es importante',
      'fr': 'Pas important',
      'it': 'Non importante',
      'ja': '重要ではない',
      'ko': '중요하지 않음',
      'no': 'Ikke viktig',
      'ru': 'Не важно',
      'sv': 'Inte viktigt',
      'zh': '不重要',
    }[locale.languageCode]!;
  }

  String get map {
    return {
      'en': 'Map',
      'vi': 'Bản đồ',
      'de': 'Karte',
      'cs': 'Mapa',
      'es': 'Mapa',
      'fr': 'Carte',
      'it': 'Mappa',
      'ja': '地図',
      'ko': '지도',
      'no': 'Kart',
      'ru': 'Карта',
      'sv': 'Karta',
      'zh': '地图',
    }[locale.languageCode]!;
  }

  String get schedule {
    return {
      'en': 'Schedule',
      'vi': 'Lên kế hoạch',
      'de': 'Zeitplan',
      'cs': 'Rozvrh',
      'es': 'Horario',
      'fr': 'Calendrier',
      'it': 'Programma',
      'ja': 'スケジュール',
      'ko': '일정',
      'no': 'Tidsplan',
      'ru': 'Расписание',
      'sv': 'Schema',
      'zh': '时间表',
    }[locale.languageCode]!;
  }

  String get supportUsMessage {
    return {
      'en':
          'Thank you for using our app. We hope this app will make all your plans go smoothly and more conveniently. Currently, we are working hard to improve and add more useful features to the app. However, this requires us to spend more time and finance for the development team. We would be very grateful if you could help us with one of the following things:\n1. Upgrade the app to the paid version.\n2. Consider and rate our app on the Play Store.\n3. Share this app with your friends and relatives.\nBest regards!',
      'vi':
          'Cảm ơn bạn đã sử dụng ứng dụng của chúng tôi. Chúng tôi hy vọng ứng dụng này sẽ giúp mọi kế hoạch của bạn sẽ diễn ra trôi chảy và thuận lợi hơn. Hiện nay, chúng tôi đang rất nỗ lực để hoàn thiện và đưa thêm nhiều tính năng hữu ích vào ứng dụng. Tuy nhiên, điều này đòi hỏi chúng tôi cần thêm thời gian và tài chính cho nhóm phát triển. Chúng tôi sẽ rất biết ơn nếu bạn có thể giúp chúng tôi một trong những điều dưới đây:\n1. Nâng cấp ứng dụng lên bản trả phí.\n2. Xem xét và đánh giá ứng dụng của chúng tôi trên Play Store.\n3. Chia sẻ ứng dụng này tới bạn bè và người thân của bạn.\nTrân trọng!',
      'de':
          'Vielen Dank, dass Sie unsere App verwenden. Wir hoffen, dass diese App alle Ihre Pläne reibungslos und bequemer macht. Derzeit arbeiten wir hart daran, die App zu verbessern und nützlichere Funktionen hinzuzufügen. Dies erfordert jedoch mehr Zeit und Finanzen für das Entwicklungsteam. Wir wären sehr dankbar, wenn Sie uns bei einer der folgenden Dinge helfen könnten:\n1. Aktualisieren Sie die App auf die kostenpflichtige Version.\n2. Betrachten und bewerten Sie unsere App im Play Store.\n3. Teilen Sie diese App mit Ihren Freunden und Verwandten.\nMit freundlichen Grüßen!',
      'es':
          'Gracias por usar nuestra aplicación. Esperamos que esta aplicación haga que todos sus planes se desarrollen sin problemas y de manera más conveniente. Actualmente, estamos trabajando arduamente para mejorar y agregar más funciones útiles a la aplicación. Sin embargo, esto requiere que dediquemos más tiempo y finanzas al equipo de desarrollo. Estaríamos muy agradecidos si pudiera ayudarnos con una de las siguientes cosas:\n1. Actualice la aplicación a la versión de pago.\n2. Considere y califique nuestra aplicación en Play Store.\n3. Comparta esta aplicación con sus amigos y familiares.\n¡Saludos cordiales!',
      'fr':
          'Merci d\'utiliser notre application. Nous espérons que cette application rendra tous vos plans plus fluides et plus pratiques. Actuellement, nous travaillons dur pour améliorer l\'application et ajouter des fonctionnalités plus utiles. Cependant, cela nécessite plus de temps et de financement pour l\'équipe de développement. Nous serions très reconnaissants si vous pouviez nous aider avec l\'un des points suivants :\n1. Mettez à niveau l\'application vers la version payante.\n2. Considérez et évaluez notre application sur le Play Store.\n3. Partagez cette application avec vos amis et votre famille.\nCordialement!',
      'it':
          'Grazie per aver utilizzato la nostra app. Speriamo che questa app renda tutti i tuoi piani più fluidi e convenienti. Attualmente, stiamo lavorando duramente per migliorare l\'app e aggiungere funzionalità più utili. Tuttavia, ciò richiede più tempo e finanziamenti per il team di sviluppo. Saremmo molto grati se potessi aiutarci con una delle seguenti cose:\n1. Aggiorna l\'app alla versione a pagamento.\n2. Considera e valuta la nostra app sul Play Store.\n3. Condividi questa app con i tuoi amici e parenti.\nCordiali saluti!',
      'ja':
          '私たちのアプリをご利用いただきありがとうございます。このアプリが皆様の計画をスムーズに、そしてより便利に進めることを願っています。現在、私たちはアプリの改善とより有用な機能の追加に努力しています。しかし、これには開発チームにより多くの時間と資金が必要です。以下のいずれかで私たちを支援していただけると大変感謝いたします：\n1. アプリを有料版にアップグレードする。\n2. Playストアで私たちのアプリを評価・レビューする。\n3. このアプリをご友人やご家族に共有する。\nよろしくお願いいたします！',
      'ko':
          '저희 앱을 사용해 주셔서 감사합니다. 이 앱이 여러분의 모든 계획을 원활하게 진행하고 더 편리하게 만들어 줄 것을 바랍니다. 현재 저희는 앱을 개선하고 더 유용한 기능을 추가하기 위해 노력하고 있습니다. 그러나 이것은 개발 팀에게 더 많은 시간과 재정을 필요로 합니다. 다음 중 하나를 도와주실 수 있다면 대단히 감사하겠습니다:\n1. 앱을 유료 버전으로 업그레이드합니다.\n2. Play 스토어에서 저희 앱을 고려하고 평가합니다.\n3. 이 앱을 친구와 가족에게 공유합니다.\n감사합니다!',
      'no':
          'Takk for at du bruker appen vår. Vi håper denne appen vil gjøre alle planene dine jevnere og mer praktiske. For tiden jobber vi hardt for å forbedre appen og legge til flere nyttige funksjoner. Imidlertid krever dette at vi bruker mer tid og økonomi på utviklingsteamet. Vi ville være veldig takknemlige hvis du kunne hjelpe oss med en av følgende ting:\n1. Oppgrader appen til betalt versjon.\n2. Vurder og ranger appen vår på Play Store.\n3. Del denne appen med vennene dine og slektningene dine.\nMed vennlig hilsen!',
      'ru':
          'Спасибо за использование нашего приложения. Мы надеемся, что это приложение поможет сделать все ваши планы более плавными и удобными. В настоящее время мы усердно работаем над улучшением приложения и добавлением более полезных функций. Однако это требует от нас больше времени и финансов на команду разработчиков. Мы были бы очень благодарны, если бы вы могли помочь нам одним из следующих способов:\n1. Обновите приложение до платной версии.\n2. Рассмотрите возможность оценки нашего приложения в Play Store.\n3. Поделитесь этим приложением с друзьями и родственниками.\nС уважением!',
      'sv':
          'Tack för att du använder vår app. Vi hoppas att denna app kommer att göra alla dina planer smidigare och mer bekvämt. För närvarande arbetar vi hårt för att förbättra och lägga till fler användbara funktioner i appen. Men detta kräver att vi spenderar mer tid och finansiering för utvecklingsteamet. Vi skulle vara mycket tacksamma om du kunde hjälpa oss med något av följande:\n1. Uppgradera appen till betald version.\n2. Överväg och betygsätt vår app på Play Store.\n3. Dela denna app med dina vänner och släktingar.\nMed vänliga hälsningar!',
      'cs':
          'Děkujeme vám za používání naší aplikace. Doufáme, že tato aplikace vám pomůže, aby všechny vaše plány probíhaly hladce a pohodlněji. V současné době tvrdě pracujeme na vylepšení a přidání dalších užitečných funkcí do aplikace. To však vyžaduje, abychom věnovali více času a financí vývojovému týmu. Byli bychom velmi vděční, pokud byste nám mohli pomoci s některou z následujících věcí:\n1. Upgradujte aplikaci na placenou verzi.\n2. Zvažte a ohodnoťte naši aplikaci na Play Store.\n3. Sdílejte tuto aplikaci se svými přáteli a příbuznými.\nS pozdravem!',
      'zh':
          '感谢您使用我们的应用程序。我们希望这款应用程序能使您的所有计划更顺畅，更方便。目前，我们正在努力改进并添加更多有用的功能到应用程序中。然而，这需要我们为开发团队花费更多的时间和财力。如果您能帮助我们做以下事情中的一项，我们将非常感激：\n1. 将应用程序升级到付费版本。\n2. 考虑并在Play商店中为我们的应用程序评分。\n3. 将此应用程序分享给您的朋友和亲戚。\n顺祝商祺！',
    }[locale.languageCode]!;
  }

  String get minimum {
    return {
      'en': 'minimum',
      'vi': 'tối thiểu',
      'de': 'Minimum',
      'cs': 'minimum',
      'es': 'mínimo',
      'fr': 'minimum',
      'it': 'minimo',
      'ja': '最小',
      'ko': '최소',
      'no': 'minimum',
      'ru': 'минимум',
      'sv': 'minimum',
      'zh': '最小',
    }[locale.languageCode]!;
  }

  String get maximum {
    return {
      'en': 'maximum',
      'vi': 'tối đa',
      'de': 'Maximum',
      'cs': 'maximum',
      'es': 'máximo',
      'fr': 'maximum',
      'it': 'massimo',
      'ja': '最大',
      'ko': '최대',
      'no': 'maksimum',
      'ru': 'максимум',
      'sv': 'maximum',
      'zh': '最大',
    }[locale.languageCode]!;
  }

  String get comingSoon {
    return {
      'en': 'Coming Soon',
      'vi': 'Sắp ra mắt',
      'de': 'Demnächst',
      'cs': 'Již brzy',
      'es': 'Próximamente',
      'fr': 'Bientôt disponible',
      'it': 'In arrivo',
      'ja': '近日公開',
      'ko': '곧 출시',
      'no': 'Kommer snart',
      'ru': 'Скоро будет',
      'sv': 'Kommer snart',
      'zh': '即将推出',
    }[locale.languageCode]!;
  }

  String get availableOnProVersion {
    return {
      'en': 'Available on Pro version',
      'vi': 'Sẽ xuất hiện trên phiên bản Pro',
      'de': 'Verfügbar in der Pro-Version',
      'cs': 'Dostupné v Pro verzi',
      'es': 'Disponible en versión Pro',
      'fr': 'Disponible sur la version Pro',
      'it': 'Disponibile sulla versione Pro',
      'ja': 'Proバージョンで利用可能',
      'ko': '프로 버전에서 사용 가능',
      'no': 'Tilgjengelig på Pro-versjonen',
      'ru': 'Доступно в Pro версии',
      'sv': 'Tillgänglig på Pro-versionen',
      'zh': '在专业版上可用',
    }[locale.languageCode]!;
  }

  String get featureUnderDevelopment {
    return {
      'en':
          'This feature is under development and will be available in the Pro version',
      'vi':
          'Chức năng này đang được phát triển và sẽ xuất hiện trên phiên bản Pro',
      'de':
          'Diese Funktion befindet sich in der Entwicklung und wird in der Pro-Version verfügbar sein',
      'cs': 'Tato funkce je ve vývoji a bude k dispozici v Pro verzi',
      'es':
          'Esta función está en desarrollo y estará disponible en la versión Pro',
      'fr':
          'Cette fonctionnalité est en cours de développement et sera disponible dans la version Pro',
      'it':
          'Questa funzione è in fase di sviluppo e sarà disponibile nella versione Pro',
      'ja': 'この機能は開発中で、Proバージョンで利用可能になります',
      'ko': '이 기능은 개발 중이며 Pro 버전에서 사용할 수 있습니다',
      'no':
          'Denne funksjonen er under utvikling og vil være tilgjengelig i Pro-versjonen',
      'ru': 'Эта функция находится в разработке и будет доступна в Pro версии',
      'sv':
          'Denna funktion är under utveckling och kommer att finnas tillgänglig i Pro-versionen',
      'zh': '此功能正在开发中，将在专业版中提供',
    }[locale.languageCode]!;
  }

  String get featureAvailableSoon {
    return {
      'en': 'This feature will be available soon.',
      'vi': 'Tính năng đang được phát triển.',
      'de': 'Diese Funktion wird in Kürze verfügbar sein.',
      'cs': 'Tato funkce bude brzy k dispozici.',
      'es': 'Esta característica estará disponible pronto.',
      'fr': 'Cette fonctionnalité sera bientôt disponible.',
      'it': 'Questa funzione sarà presto disponibile.',
      'ja': 'この機能は近日中に利用可能になります。',
      'ko': '이 기능은 곧 사용 가능합니다.',
      'no': 'Denne funksjonen vil være tilgjengelig snart.',
      'ru': 'Эта функция будет доступна в ближайшее время.',
      'sv': 'Denna funktion kommer att vara tillgänglig snart.',
      'zh': '此功能即将推出。',
    }[locale.languageCode]!;
  }

  String get notification {
    return {
      'en': 'Notification',
      'vi': 'Thông báo',
      'de': 'Benachrichtigung',
      'cs': 'Oznámení',
      'es': 'Notificación',
      'fr': 'Notification',
      'it': 'Notifica',
      'ja': '通知',
      'ko': '알림',
      'no': 'Varsling',
      'ru': 'Уведомление',
      'sv': 'Meddelande',
      'zh': '通知',
    }[locale.languageCode]!;
  }

  String get enterTitleForList {
    return {
      'en': 'You have not entered a title for the list',
      'vi': 'Bạn chưa nhập tiêu đề cho danh sách',
      'de': 'Sie haben keinen Titel für die Liste eingegeben',
      'cs': 'Nezadali jste název seznamu',
      'es': 'No has introducido el título de la lista',
      'fr': 'Vous n\'avez pas entré le titre de la liste',
      'it': 'Non hai inserito il titolo della lista',
      'ja': 'リストのタイトルを入力していません',
      'ko': '목록의 제목을 입력하지 않았습니다',
      'no': 'Du har ikke angitt tittelen på listen',
      'ru': 'Вы не ввели название списка',
      'sv': 'Du har inte angett listans titel',
      'zh': '您尚未输入列表的标题',
    }[locale.languageCode]!;
  }

  String get addNewList {
    return {
      'en': 'Add a new list',
      'vi': 'Thêm danh sách mới',
      'de': 'Eine neue Liste hinzufügen',
      'cs': 'Přidat nový seznam',
      'es': 'Agregar una nueva lista',
      'fr': 'Ajouter une nouvelle liste',
      'it': 'Aggiungi una nuova lista',
      'ja': '新しいリストを追加',
      'ko': '새 목록 추가',
      'no': 'Legg til en ny liste',
      'ru': 'Добавить новый список',
      'sv': 'Lägg till en ny lista',
      'zh': '添加新列表',
    }[locale.languageCode]!;
  }

  String get enterTaskTitle {
    return {
      'en': 'You have not entered the title of the task',
      'vi': 'Bạn chưa nhập tiêu đề của nhiệm vụ',
      'de': 'Sie haben den Titel der Aufgabe nicht eingegeben',
      'cs': 'Nezadali jste název úkolu',
      'es': 'No has introducido el título de la tarea',
      'fr': 'Vous n\'avez pas entré le titre de la tâche',
      'it': 'Non hai inserito il titolo del compito',
      'ja': 'タスクのタイトルを入力していません',
      'ko': '작업의 제목을 입력하지 않았습니다',
      'no': 'Du har ikke angitt tittelen på oppgaven',
      'ru': 'Вы не ввели название задачи',
      'sv': 'Du har inte angett uppgiftens titel',
      'zh': '您尚未输入任务的标题',
    }[locale.languageCode]!;
  }

  String get minTargetGreaterThanMaxTarget {
    return {
      'en': 'You are entering a minimum target greater than the maximum target',
      'vi': 'Bạn đang nhập mục tiêu nhỏ nhất lớn hơn mục tiêu lớn nhất',
      'de': 'Sie geben ein Mindestziel ein, das größer ist als das Maximalziel',
      'cs': 'Zadáváte minimální cíl, který je větší než maximální cíl',
      'es':
          'Estás introduciendo un objetivo mínimo que es mayor que el objetivo máximo',
      'fr':
          'Vous entrez un objectif minimum qui est supérieur à l\'objectif maximum',
      'it':
          'Stai inserendo un obiettivo minimo che è maggiore dell\'obiettivo massimo',
      'ja': '最小目標を入力していますが、それは最大目標よりも大きいです',
      'ko': '최소 목표가 최대 목표보다 큰 값을 입력하고 있습니다',
      'no': 'Du legger inn et minimumsmål som er større enn maksimumsmålet',
      'ru': 'Вы вводите минимальную цель, которая больше максимальной цели',
      'sv': 'Du anger ett minimimål som är större än det maximala målet',
      'zh': '您输入的最小目标大于最大目标',
    }[locale.languageCode]!;
  }

  String get save {
    return {
      'en': 'Save',
      'vi': 'Lưu',
      'de': 'Speichern',
      'cs': 'Uložit',
      'es': 'Guardar',
      'fr': 'Enregistrer',
      'it': 'Salva',
      'ja': '保存',
      'ko': '저장',
      'no': 'Lagre',
      'ru': 'Сохранить',
      'sv': 'Spara',
      'zh': '保存',
    }[locale.languageCode]!;
  }

  String get add {
    return {
      'en': 'Add',
      'vi': 'Thêm',
      'de': 'Hinzufügen',
      'cs': 'Přidat',
      'es': 'Agregar',
      'fr': 'Ajouter',
      'it': 'Aggiungi',
      'ja': '追加',
      'ko': '추가',
      'no': 'Legg til',
      'ru': 'Добавить',
      'sv': 'Lägg till',
      'zh': '添加',
    }[locale.languageCode]!;
  }

  String get startTimeAfterEndTime {
    return {
      'en': 'The start time is not allowed to occur after the end time.',
      'vi': 'Thời gian bắt đầu không được phép xảy ra sau thời gian kết thúc.',
      'de': 'Die Startzeit darf nicht nach der Endzeit auftreten.',
      'cs': 'Čas začátku nesmí nastat po čase konce.',
      'es':
          'La hora de inicio no puede ocurrir después de la hora de finalización.',
      'fr': 'L\'heure de début ne peut pas se produire après l\'heure de fin.',
      'it': 'L\'ora di inizio non può verificarsi dopo l\'ora di fine.',
      'ja': '開始時間は終了時間の後に設定することはできません。',
      'ko': '시작 시간은 종료 시간 이후로 설정할 수 없습니다.',
      'no': 'Starttidspunktet kan ikke forekomme etter sluttidspunktet.',
      'ru': 'Время начала не может быть позже времени окончания.',
      'sv': 'Starttiden får inte inträffa efter sluttiden.',
      'zh': '开始时间不得在结束时间之后。',
    }[locale.languageCode]!;
  }

  String get enterAtLeastOneDate {
    return {
      'en': 'Please enter at least one date',
      'vi': 'Vui lòng nhập ít nhất một ngày',
      'de': 'Bitte geben Sie mindestens ein Datum ein',
      'cs': 'Zadejte prosím alespoň jeden datum',
      'es': 'Por favor, introduzca al menos una fecha',
      'fr': 'Veuillez entrer au moins une date',
      'it': 'Si prega di inserire almeno una data',
      'ja': '少なくとも1つの日付を入力してください',
      'ko': '적어도 하나의 날짜를 입력해 주세요',
      'no': 'Vennligst skriv inn minst én dato',
      'ru': 'Пожалуйста, введите хотя бы одну дату',
      'sv': 'Ange minst ett datum',
      'zh': '请至少输入一个日期',
    }[locale.languageCode]!;
  }

  String get attachFile {
    return {
      'en': 'Attach File',
      'vi': 'Đính kèm tệp',
      'de': 'Datei anhängen',
      'cs': 'Přiložit soubor',
      'es': 'Adjuntar archivo',
      'fr': 'Joindre un fichier',
      'it': 'Allega file',
      'ja': 'ファイルを添付',
      'ko': '파일 첨부',
      'no': 'Legg ved fil',
      'ru': 'Прикрепить файл',
      'sv': 'Bifoga fil',
      'zh': '附加文件',
    }[locale.languageCode]!;
  }

  String get uploadFrom {
    return {
      'en': 'Upload from',
      'vi': 'Tải lên từ',
      'de': 'Hochladen von',
      'cs': 'Nahrát z',
      'es': 'Subir desde',
      'fr': 'Télécharger à partir de',
      'it': 'Carica da',
      'ja': 'からアップロード',
      'ko': '에서 업로드',
      'no': 'Last opp fra',
      'ru': 'Загрузить из',
      'sv': 'Ladda upp från',
      'zh': '从上传',
    }[locale.languageCode]!;
  }

  String get showCalendar {
    return {
      'en': 'Show calendar',
      'vi': 'Hiển thị lịch',
      'de': 'Kalender anzeigen',
      'cs': 'Zobrazit kalendář',
      'es': 'Mostrar calendario',
      'fr': 'Afficher le calendrier',
      'it': 'Mostra calendario',
      'ja': 'カレンダーを表示',
      'ko': '달력 표시',
      'no': 'Vis kalender',
      'ru': 'Показать календарь',
      'sv': 'Visa kalender',
      'zh': '显示日历',
    }[locale.languageCode]!;
  }

  String get hideCalendar {
    return {
      'en': 'Hide calendar',
      'vi': 'Ẩn lịch',
      'de': 'Kalender ausblenden',
      'cs': 'Skrýt kalendář',
      'es': 'Ocultar calendario',
      'fr': 'Masquer le calendrier',
      'it': 'Nascondi calendario',
      'ja': 'カレンダーを非表示',
      'ko': '달력 숨기기',
      'no': 'Skjul kalender',
      'ru': 'Скрыть календарь',
      'sv': 'Dölj kalender',
      'zh': '隐藏日历',
    }[locale.languageCode]!;
  }

  String get deviceFiles {
    return {
      'en': 'Device files',
      'vi': 'Tệp thiết bị',
      'de': 'Gerätedateien',
      'cs': 'Soubory zařízení',
      'es': 'Archivos del dispositivo',
      'fr': 'Fichiers de l\'appareil',
      'it': 'File del dispositivo',
      'ja': 'デバイスのファイル',
      'ko': '장치 파일',
      'no': 'Enhetsfiler',
      'ru': 'Файлы устройства',
      'sv': 'Enhetsfiler',
      'zh': '设备文件',
    }[locale.languageCode]!;
  }

  String get camera {
    return {
      'en': 'Camera',
      'vi': 'Máy ảnh',
      'de': 'Kamera',
      'cs': 'Kamera',
      'es': 'Cámara',
      'fr': 'Caméra',
      'it': 'Fotocamera',
      'ja': 'カメラ',
      'ko': '카메라',
      'no': 'Kamera',
      'ru': 'Камера',
      'sv': 'Kamera',
      'zh': '相机',
    }[locale.languageCode]!;
  }

  String translate(String key) {
    return _languageKey[locale.languageCode]?[key] ?? key;
  }

  static const _languageKey = {
    'cs': {
      'Czech': 'Čeština',
      'German': 'Němčina',
      'English': 'Angličtina',
      'Spanish': 'Španělština',
      'French': 'Francouzština',
      'Italian': 'Italština',
      'Japanese': 'Japonština',
      'Korean': 'Korejština',
      'Norwegian': 'Norština',
      'Russian': 'Ruština',
      'Swedish': 'Švédština',
      'Vietnamese': 'Vietnamština',
      'Chinese': 'Čínština',
    },
    'de': {
      'Czech': 'Tschechisch',
      'German': 'Deutsch',
      'English': 'Englisch',
      'Spanish': 'Spanisch',
      'French': 'Französisch',
      'Italian': 'Italienisch',
      'Japanese': 'Japanisch',
      'Korean': 'Koreanisch',
      'Norwegian': 'Norwegisch',
      'Russian': 'Russisch',
      'Swedish': 'Schwedisch',
      'Vietnamese': 'Vietnamesisch',
      'Chinese': 'Chinesisch',
    },
    'en': {
      'Czech': 'Czech',
      'German': 'German',
      'English': 'English',
      'Spanish': 'Spanish',
      'French': 'French',
      'Italian': 'Italian',
      'Japanese': 'Japanese',
      'Korean': 'Korean',
      'Norwegian': 'Norwegian',
      'Russian': 'Russian',
      'Swedish': 'Swedish',
      'Vietnamese': 'Vietnamese',
      'Chinese': 'Chinese',
    },
    'es': {
      'Czech': 'Checo',
      'German': 'Alemán',
      'English': 'Inglés',
      'Spanish': 'Español',
      'French': 'Francés',
      'Italian': 'Italiano',
      'Japanese': 'Japonés',
      'Korean': 'Coreano',
      'Norwegian': 'Noruego',
      'Russian': 'Ruso',
      'Swedish': 'Sueco',
      'Vietnamese': 'Vietnamita',
      'Chinese': 'Chino',
    },
    'fr': {
      'Czech': 'Tchèque',
      'German': 'Allemand',
      'English': 'Anglais',
      'Spanish': 'Espagnol',
      'French': 'Français',
      'Italian': 'Italien',
      'Japanese': 'Japonais',
      'Korean': 'Coréen',
      'Norwegian': 'Norvégien',
      'Russian': 'Russe',
      'Swedish': 'Suédois',
      'Vietnamese': 'Vietnamien',
      'Chinese': 'Chinois',
    },
    'it': {
      'Czech': 'Ceco',
      'German': 'Tedesco',
      'English': 'Inglese',
      'Spanish': 'Spagnolo',
      'French': 'Francese',
      'Italian': 'Italiano',
      'Japanese': 'Giapponese',
      'Korean': 'Coreano',
      'Norwegian': 'Norvegese',
      'Russian': 'Russo',
      'Swedish': 'Svedese',
      'Vietnamese': 'Vietnamita',
      'Chinese': 'Cinese',
    },
    'ja': {
      'Czech': 'チェコ語',
      'German': 'ドイツ語',
      'English': '英語',
      'Spanish': 'スペイン語',
      'French': 'フランス語',
      'Italian': 'イタリア語',
      'Japanese': '日本語',
      'Korean': '韓国語',
      'Norwegian': 'ノルウェー語',
      'Russian': 'ロシア語',
      'Swedish': 'スウェーデン語',
      'Vietnamese': 'ベトナム語',
      'Chinese': '中国語',
    },
    'ko': {
      'Czech': '체코어',
      'German': '독일어',
      'English': '영어',
      'Spanish': '스페인어',
      'French': '프랑스어',
      'Italian': '이탈리아어',
      'Japanese': '일본어',
      'Korean': '한국어',
      'Norwegian': '노르웨이어',
      'Russian': '러시아어',
      'Swedish': '스웨덴어',
      'Vietnamese': '베트남어',
      'Chinese': '중국어',
    },
    'no': {
      'Czech': 'Tsjekkisk',
      'German': 'Tysk',
      'English': 'Engelsk',
      'Spanish': 'Spansk',
      'French': 'Fransk',
      'Italian': 'Italiensk',
      'Japanese': 'Japansk',
      'Korean': 'Koreansk',
      'Norwegian': 'Norsk',
      'Russian': 'Russisk',
      'Swedish': 'Svensk',
      'Vietnamese': 'Vietnamesisk',
      'Chinese': 'Kinesisk',
    },
    'ru': {
      'Czech': 'Чешский',
      'German': 'Немецкий',
      'English': 'Английский',
      'Spanish': 'Испанский',
      'French': 'Французский',
      'Italian': 'Итальянский',
      'Japanese': 'Японский',
      'Korean': 'Корейский',
      'Norwegian': 'Норвежский',
      'Russian': 'Русский',
      'Swedish': 'Шведский',
      'Vietnamese': 'Вьетнамский',
      'Chinese': 'Китайский',
    },
    'sv': {
      'Czech': 'Tjeckiska',
      'German': 'Tyska',
      'English': 'Engelska',
      'Spanish': 'Spanska',
      'French': 'Franska',
      'Italian': 'Italienska',
      'Japanese': 'Japanska',
      'Korean': 'Koreanska',
      'Norwegian': 'Norska',
      'Russian': 'Ryska',
      'Swedish': 'Svenska',
      'Vietnamese': 'Vietnamesiska',
      'Chinese': 'Kinesiska',
    },
    'vi': {
      'Czech': 'Tiếng Séc',
      'German': 'Tiếng Đức',
      'English': 'Tiếng Anh',
      'Spanish': 'Tiếng Tây Ban Nha',
      'French': 'Tiếng Pháp',
      'Italian': 'Tiếng Ý',
      'Japanese': 'Tiếng Nhật',
      'Korean': 'Tiếng Hàn',
      'Norwegian': 'Tiếng Na Uy',
      'Russian': 'Tiếng Nga',
      'Swedish': 'Tiếng Thụy Điển',
      'Vietnamese': 'Tiếng Việt',
      'Chinese': 'Tiếng Trung',
    },
    'zh': {
      'Czech': '捷克语',
      'German': '德语',
      'English': '英语',
      'Spanish': '西班牙语',
      'French': '法语',
      'Italian': '意大利语',
      'Japanese': '日语',
      'Korean': '韩语',
      'Norwegian': '挪威语',
      'Russian': '俄语',
      'Swedish': '瑞典语',
      'Vietnamese': '越南语',
      'Chinese': '中文',
    },
  };

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
  bool isSupported(Locale locale) => [
        'en',
        'vi',
        'de',
        'cs',
        'es',
        'fr',
        'it',
        'ja',
        'ko',
        'no',
        'ru',
        'sv',
        'zh'
      ].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return SynchronousFuture(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
