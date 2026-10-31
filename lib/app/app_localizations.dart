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
      'en': 'Projects will appear here once they are created.',
      'vi': 'Các dự án sẽ hiển thị ở đây khi được tạo.',
      'de': 'Projekte erscheinen hier, sobald sie erstellt wurden.',
      'cs': 'Projekty se zde zobrazí, jakmile budou vytvořeny.',
      'es': 'Los proyectos aparecerán aquí cuando se creen.',
      'fr': 'Les projets apparaîtront ici une fois créés.',
      'it': 'I progetti appariranno qui una volta creati.',
      'ja': 'プロジェクトを作成するとここに表示されます。',
      'ko': '프로젝트가 생성되면 여기에 표시됩니다.',
      'no': 'Prosjekter vises her når de er opprettet.',
      'ru': 'Проекты появятся здесь после создания.',
      'sv': 'Projekt visas här när de har skapats.',
      'zh': '项目创建后将显示在这里。',
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
