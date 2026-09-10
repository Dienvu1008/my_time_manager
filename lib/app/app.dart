import 'package:appflowy_editor/appflowy_editor.dart'
    show AppFlowyEditorLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/auth/auth_config.dart';
import 'package:my_time_manager/auth/bloc/auth_bloc.dart';
import 'package:my_time_manager/auth/data/auth_repository.dart';
import 'package:my_time_manager/auth/view/auth_gate.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_list_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_time_interval_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_calendar_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_note_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_trash_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_archive_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_event_repository.dart';
import 'package:my_time_manager/domain/repositories/task_repository.dart';
import 'package:my_time_manager/domain/repositories/task_list_repository.dart';
import 'package:my_time_manager/domain/repositories/time_interval_repository.dart';
import 'package:my_time_manager/domain/repositories/calendar_repository.dart';
import 'package:my_time_manager/domain/repositories/note_repository.dart';
import 'package:my_time_manager/domain/repositories/trash_repository.dart';
import 'package:my_time_manager/domain/repositories/archive_repository.dart';
import 'package:my_time_manager/domain/repositories/event_repository.dart';
import 'package:my_time_manager/domain/services/task_completion_service.dart';
import 'package:my_time_manager/domain/services/recurrence_service.dart';
import 'package:my_time_manager/domain/services/time_interval_progress_service.dart';
import 'package:my_time_manager/home/home.dart';
import 'package:my_time_manager/screen_focus_timer/bloc/pomodoro_bloc.dart';
import 'package:my_time_manager/screen_focus_timer/view/pomodoro_floating_overlay.dart';
import 'package:my_time_manager/screen_focus_timer/view/pomodoro_overlay_controller.dart';
import 'package:my_time_manager/screen_focus_timer/data/focus_repository.dart';
import 'package:my_time_manager/screen_focus_timer/data/focus_sync_service.dart';
import 'package:my_time_manager/screen_focus_timer/data/notification_service.dart';
import 'package:my_time_manager/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class App extends StatelessWidget {
  const App({
    required bool isProVersion,
    this.firebaseReady = true,
    Key? key,
  })  : _isProVersion = isProVersion,
        super(key: key);

  final bool _isProVersion;

  /// Firebase đã khởi tạo thành công hay chưa (do main.dart truyền vào).
  /// Nếu chưa, ta không dựng AuthRepository/AuthBloc để tránh crash, và hiển
  /// thị thẳng Home (chế độ chưa cấu hình auth).
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    // FocusRepository luôn được cung cấp cho toàn app (local-first). Lớp sync
    // Firestore chỉ bật khi Firebase sẵn sàng; nếu không thì dùng NoOp (chạy
    // local-only). Bọc ngoài cùng để cả 2 nhánh (có/không auth) đều dùng được.
    return MultiRepositoryProvider(
      providers: [
        // Domain repositories for the task slice. Provided app-wide (like
        // FocusRepository) so every screen — and, in the future, AI tools —
        // depends on the domain interface instead of DatabaseManager/SQLite.
        RepositoryProvider<TaskRepository>(
          create: (_) => SqliteTaskRepository(),
        ),
        RepositoryProvider<TaskListRepository>(
          create: (_) => SqliteTaskListRepository(),
        ),
        RepositoryProvider<TaskCompletionService>(
          create: (context) =>
              TaskCompletionService(context.read<TaskRepository>()),
        ),
        RepositoryProvider<TimeIntervalRepository>(
          create: (_) => SqliteTimeIntervalRepository(),
        ),
        RepositoryProvider<RecurrenceService>(
          create: (context) =>
              RecurrenceService(context.read<TimeIntervalRepository>()),
        ),
        RepositoryProvider<TimeIntervalProgressService>(
          create: (context) => TimeIntervalProgressService(
              context.read<TimeIntervalRepository>()),
        ),
        RepositoryProvider<CalendarRepository>(
          create: (_) => SqliteCalendarRepository(),
        ),
        RepositoryProvider<NoteRepository>(
          create: (_) => SqliteNoteRepository(),
        ),
        RepositoryProvider<TrashRepository>(
          create: (_) => SqliteTrashRepository(),
        ),
        RepositoryProvider<ArchiveRepository>(
          create: (_) => SqliteArchiveRepository(),
        ),
        RepositoryProvider<EventRepository>(
          create: (_) => SqliteEventRepository(),
        ),
        // FocusRepository luôn được cung cấp cho toàn app (local-first). Lớp sync
        // Firestore chỉ bật khi Firebase sẵn sàng; nếu không thì dùng NoOp (chạy
        // local-only).
        RepositoryProvider<FocusRepository>(
          create: (_) => FocusRepository(
            syncService: firebaseReady
                ? FirestoreFocusSyncService()
                : const NoOpFocusSyncService(),
          ),
        ),
      ],
      // PomodoroBloc provide TOÀN CỤC (1 instance sống suốt vòng đời app) để
      // timer tiếp tục chạy khi người dùng chuyển sang màn hình khác.
      child: BlocProvider<PomodoroBloc>(
        create: (context) =>
            PomodoroBloc(repository: context.read<FocusRepository>()),
        child: firebaseReady ? _buildWithAuth() : _buildWithoutAuth(),
      ),
    );
  }

  /// Firebase chưa cấu hình: chạy app không có lớp auth.
  Widget _buildWithoutAuth() {
    return BlocProvider(
      create: (context) => AppBloc(
        timeIntervalRepository: context.read<TimeIntervalRepository>(),
      ),
      child: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) => _buildMaterialApp(context, state, null),
      ),
    );
  }

  /// Cung cấp AuthRepository (một instance dùng chung) và AuthBloc cho toàn app.
  Widget _buildWithAuth() {
    return RepositoryProvider(
      create: (_) => AuthRepository(
        desktopClientId: AuthConfig.googleDesktopClientId,
      ),
      child: BlocProvider(
        create: (context) => AuthBloc(
          authRepository: context.read<AuthRepository>(),
        ),
        child: BlocProvider(
          create: (context) => AppBloc(
            timeIntervalRepository: context.read<TimeIntervalRepository>(),
          ),
          child: BlocBuilder<AppBloc, AppState>(
            // Khi bypassAuth bật: truyền null cho _buildMaterialApp để vào thẳng
            // Home (bỏ qua AuthGate), nhưng AuthBloc vẫn được cung cấp phía trên
            // nên trang Account / nút Đăng xuất vẫn hoạt động khi cần test.
            builder: (context, state) => _buildMaterialApp(
              context,
              state,
              AuthConfig.bypassAuth ? null : context.read<AuthBloc>(),
            ),
          ),
        ),
      ),
    );
  }

  /// Dựng MaterialApp. Nếu [authBloc] khác null, phần `home` được bọc trong
  /// [AuthGate] để tự chuyển hướng theo trạng thái đăng nhập.
  Widget _buildMaterialApp(
    BuildContext context,
    AppState state,
    AuthBloc? authBloc,
  ) {
    return MaterialApp(
            // Cho phép cửa sổ nổi Pomodoro (nằm ngoài Navigator) hiện dialog.
            navigatorKey: PomodoroOverlayController.instance.navigatorKey,
            locale: Locale(
              [
                'cs',
                'de',
                'en',
                'es',
                'fr',
                'it',
                'ja',
                'ko',
                'no',
                'ru',
                'sv',
                'vi',
                'zh'
              ][state.language.index],
            ),
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              // Localization cho trình soạn thảo Ghi chú (appflowy_editor).
              AppFlowyEditorLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('cs'),
              Locale('de'),
              Locale('en'),
              Locale('es'),
              Locale('fr'),
              Locale('it'),
              Locale('ja'),
              Locale('ko'),
              Locale('no'),
              Locale('ru'),
              Locale('sv'),
              Locale('vi'),
              Locale('zh'),
            ],

            debugShowCheckedModeBanner: false, // remove debug banner
            // Bọc mọi màn hình trong cửa sổ nổi Pomodoro (PiP). Overlay tự
            // quyết định hiển thị dựa trên cài đặt + trạng thái timer.
            //
            // MaterialApp.builder tạo cây nằm dưới Navigator; để chắc chắn
            // overlay đọc được AppBloc và PomodoroBloc, ta chuyển tiếp hai bloc
            // này bằng .value (dùng context ngoài đã thấy chúng qua provider).
            builder: (builderContext, child) => MultiBlocProvider(
              providers: [
                BlocProvider<AppBloc>.value(value: context.read<AppBloc>()),
                BlocProvider<PomodoroBloc>.value(
                    value: context.read<PomodoroBloc>()),
              ],
              child: PomodoroFloatingOverlay(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
            title: 'My Time Manager',
            themeMode: state.themeMode,
            theme: ThemeData(
              colorSchemeSeed:
                  state.colorSelectionMethod == ColorSelectionMethod.colorSeed
                      ? state.colorSelected.color
                      : null,
              colorScheme:
                  state.colorSelectionMethod == ColorSelectionMethod.image
                      ? state.imageColorScheme
                      : null,
              useMaterial3: state.useMaterial3,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              colorSchemeSeed:
                  state.colorSelectionMethod == ColorSelectionMethod.colorSeed
                      ? state.colorSelected.color
                      : state.imageColorScheme!.primary,
              useMaterial3: state.useMaterial3,
              brightness: Brightness.dark,
            ),
            home: _buildHome(context, state, authBloc),
          );
  }

  /// Dựng Home với đầy đủ tham số, rồi bọc trong AuthGate nếu có auth.
  Widget _buildHome(BuildContext context, AppState state, AuthBloc? authBloc) {
    final home = Home(
              isProVersion: _isProVersion,
              useLightMode: state.useLightMode,
              useMaterial3: state.useMaterial3,
              useBottomBar: state.useBottomBar,
              showBrightnessButtonInAppBar: state.showBrightnessButtonInAppBar,
              showMaterialDesignButtonInAppBar:
                  state.showMaterialDesignButtonInAppBar,
              showColorSeedButtonInAppBar: state.showColorSeedButtonInAppBar,
              showColorImageButtonInAppBar: state.showColorImageButtonInAppBar,
              showLanguagesButtonInAppBar: state.showLanguagesButtonInAppBar,
              colorSelected: state.colorSelected,
              imageSelected: state.imageSelected,
              languageSelected: state.language,
              handleBrightnessChange: (useLightMode) =>
                  context.read<AppBloc>().add(
                        ToggleBrightness(useLightMode),
                      ),
              handleMaterialVersionChange: () => context
                  .read<AppBloc>()
                  .add(ToggleMaterialVersion(state.useMaterial3)),
              handleUsingBottomBarChange: () => context
                  .read<AppBloc>()
                  .add(ToggleUsingBottomBar(state.useBottomBar)),
              handleDisplayBrightnessButtonInAppBarChange: () => context
                  .read<AppBloc>()
                  .add(ToggleDisplayBrightnessButtonInAppBar(
                      state.showBrightnessButtonInAppBar)),
              handleDisplayMaterialDesignButtonInAppBarChange: () => context
                  .read<AppBloc>()
                  .add(ToggleDisplayMaterialDesignButtonInAppBar(
                      state.showMaterialDesignButtonInAppBar)),
              handleDisplayColorSeedButtonInAppBarChange: () => context
                  .read<AppBloc>()
                  .add(ToggleDisplayColorSeedButtonInAppBar(
                      state.showColorSeedButtonInAppBar)),
              handleDisplayColorImageButtonInAppBarChange: () => context
                  .read<AppBloc>()
                  .add(ToggleDisplayColorImageButtonInAppBar(
                      state.showColorImageButtonInAppBar)),
              handleDisplayLanguagesButtonInAppBarChange: () => context
                  .read<AppBloc>()
                  .add(ToggleDisplayLanguagesButtonInAppBar(
                      state.showLanguagesButtonInAppBar)),
              handleColorSelect: (value) => context.read<AppBloc>().add(
                    ChangeColor(ColorSeed.values[value]),
                  ),
              handleImageSelect: (value) => context.read<AppBloc>().add(
                    ChangeImage(ColorImageProvider.values[value]),
                  ),
              handleLanguageSelect: (value) => context.read<AppBloc>().add(
                    SelectLanguageEvent(AppLanguage.values[value]),
                  ),
              colorSelectionMethod: state.colorSelectionMethod,
              launchCount: state.launchCount,
            );

    // Nếu có auth: bọc Home trong AuthGate để tự chuyển hướng đăng nhập.
    // Nếu không (Firebase chưa cấu hình): trả thẳng Home.
    if (authBloc == null) return home;
    return AuthGate(child: home);
  }
}

class AppBloc extends Bloc<AppEvent, AppState> {
  static const brightnessKey = 'brightness';
  static const colorKey = 'color';
  static const useDesignVersionKey = 'useMaterial3';
  static const useBottomBarKey = 'useBottomBar';
  static const displayBrightnessButtonInAppBar = 'showBrightnessButtonInAppBar';
  static const displayMaterialDesignButtonInAppBar =
      'showMaterialDesignButtonInAppBar';
  static const displayColorSeedButtonInAppBar = 'showColorSeedButtonInAppBar';
  static const displayColorImageButtonInAppBar = 'showColorImageButtonInAppBar';
  static const displayLanguagesButtonInAppBar = 'showLanguagesButtonInAppBar';
  static const languageKey = 'language';
  static const launchCountKey = 'launchCount';
  static const trashRetentionDaysKey = 'trashRetentionDays';
  static const keepPomodoroRunningKey = 'keepPomodoroRunningInBackground';
  static const showCalendarZoomButtonsKey = 'showCalendarZoomButtons';
  static const remindersEnabledKey = 'remindersEnabled';
  static const transparentBottomBarKey = 'transparentBottomBar';
  static const taskCardStyleKey = 'taskCardStyle';

  late SharedPreferences sharedPreferences;

  /// Used only for the reminders side effect of [ToggleRemindersEnabled]
  /// (rescheduling all reminders). Injected so AppBloc does not depend on
  /// DatabaseManager directly.
  final TimeIntervalRepository _timeIntervalRepository;

  AppBloc({TimeIntervalRepository? timeIntervalRepository})
      : _timeIntervalRepository =
            timeIntervalRepository ?? SqliteTimeIntervalRepository(),
        super(AppState(
            useMaterial3: true,
            useBottomBar: true,
            showBrightnessButtonInAppBar: true,
            showMaterialDesignButtonInAppBar: true,
            showColorSeedButtonInAppBar: true,
            showColorImageButtonInAppBar: true,
            showLanguagesButtonInAppBar: true,
            themeMode: ThemeMode.system,
            colorSelected: ColorSeed.baseColor,
            imageSelected: ColorImageProvider.leaves,
            imageColorScheme: const ColorScheme.light(),
            colorSelectionMethod: ColorSelectionMethod.colorSeed,
            language: AppLanguage.english,
            launchCount: 0)) {
    //Get back saved states of theme mode when the app is turned on
    SharedPreferences.getInstance().then((value) {
      sharedPreferences = value;

      add(ToggleBrightness(
        sharedPreferences.getString(brightnessKey) == 'dark' ? false : true,
      ));

      add(ChangeColor(
        ColorSeed.values.firstWhere(
          (color) => color.color.value == sharedPreferences.getInt(colorKey),
          orElse: () => ColorSeed.baseColor,
        ),
      ));

      add(ToggleMaterialVersion(
        sharedPreferences.getString(useDesignVersionKey) == 'useMaterial3'
            ? true
            : false,
      ));

      add(ToggleUsingBottomBar(
        sharedPreferences.getString(useBottomBarKey) == 'useBottomBar'
            ? true
            : false,
      ));

      add(ToggleDisplayBrightnessButtonInAppBar(
        sharedPreferences.getString(displayBrightnessButtonInAppBar) ==
                'showBrightnessButtonInAppBar'
            ? true
            : false,
      ));

      add(ToggleDisplayMaterialDesignButtonInAppBar(
        sharedPreferences.getString(displayMaterialDesignButtonInAppBar) ==
                'showMaterialDesignButtonInAppBar'
            ? true
            : false,
      ));

      add(ToggleDisplayColorSeedButtonInAppBar(
        sharedPreferences.getString(displayColorSeedButtonInAppBar) ==
                'showColorSeedButtonInAppBar'
            ? true
            : false,
      ));

      add(ToggleDisplayColorImageButtonInAppBar(
        sharedPreferences.getString(displayColorImageButtonInAppBar) ==
                'showColorImageButtonInAppBar'
            ? true
            : false,
      ));

      add(ToggleDisplayLanguagesButtonInAppBar(
        sharedPreferences.getString(displayLanguagesButtonInAppBar) ==
                'showLanguagesButtonInAppBar'
            ? true
            : false,
      ));

      if (sharedPreferences.getInt(languageKey) != null) {
        add(SelectLanguageEvent(
            AppLanguage.values[sharedPreferences.getInt(languageKey)!]));
      }

      add(LoadLaunchCountEvent(sharedPreferences.getInt(launchCountKey) ?? 0));

      add(IncrementLaunchCountEvent());

      // Nạp số ngày giữ thùng rác (mặc định 30 nếu chưa lưu).
      add(ChangeTrashRetentionDays(
          sharedPreferences.getInt(trashRetentionDaysKey) ?? 30));

      // Nạp cài đặt cho phép Pomodoro chạy nền (mặc định false).
      add(ToggleKeepPomodoroRunning(
          sharedPreferences.getBool(keepPomodoroRunningKey) ?? false));

      // Nạp cài đặt hiện nút zoom trên lịch (mặc định true).
      add(ToggleShowCalendarZoomButtons(
          sharedPreferences.getBool(showCalendarZoomButtonsKey) ?? true));

      // Nạp cài đặt bật nhắc bằng thông báo (mặc định true).
      add(ToggleRemindersEnabled(
          sharedPreferences.getBool(remindersEnabledKey) ?? true));

      // Nạp cài đặt bottom bar trong suốt (mặc định false).
      add(ToggleTransparentBottomBar(
          sharedPreferences.getBool(transparentBottomBarKey) ?? false));

      // Nạp kiểu hiển thị thẻ task (mặc định filled = nền đầy màu).
      final styleIndex = sharedPreferences.getInt(taskCardStyleKey) ?? 0;
      add(ChangeTaskCardStyle(TaskCardStyle.values[
          styleIndex >= 0 && styleIndex < TaskCardStyle.values.length
              ? styleIndex
              : 0]));
    });

    on<ToggleBrightness>((event, emit) {
      sharedPreferences.setString(
          brightnessKey, event.useLightMode ? 'light' : 'dark');
      emit(state.copyWith(
        themeMode: event.useLightMode ? ThemeMode.light : ThemeMode.dark,
      ));
    });

    on<ToggleMaterialVersion>((event, emit) {
      sharedPreferences.setString(useDesignVersionKey,
          event.useMaterial3 ? 'useMaterial3' : 'useMaterial2');
      emit(state.copyWith(useMaterial3: !event.useMaterial3));
    });

    on<ToggleUsingBottomBar>((event, emit) {
      sharedPreferences.setString(useBottomBarKey,
          event.useBottomBar ? 'useBottomBar' : 'notUseBottomBar');
      emit(state.copyWith(useBottomBar: !event.useBottomBar));
    });

    on<ToggleDisplayBrightnessButtonInAppBar>((event, emit) {
      sharedPreferences.setString(
          displayBrightnessButtonInAppBar,
          event.showBrightnessButtonInAppBar
              ? 'showBrightnessButtonInAppBar'
              : 'hideBrightnessButtonInAppBar');
      emit(state.copyWith(
          showBrightnessButtonInAppBar: !event.showBrightnessButtonInAppBar));
    });

    on<ToggleDisplayMaterialDesignButtonInAppBar>((event, emit) {
      sharedPreferences.setString(
          displayMaterialDesignButtonInAppBar,
          event.showMaterialDesignButtonInAppBar
              ? 'showMaterialDesignButtonInAppBar'
              : 'hideMaterialDesignButtonInAppBar');
      emit(state.copyWith(
          showMaterialDesignButtonInAppBar:
              !event.showMaterialDesignButtonInAppBar));
    });

    on<ToggleDisplayColorSeedButtonInAppBar>((event, emit) {
      sharedPreferences.setString(
          displayColorSeedButtonInAppBar,
          event.showColorSeedButtonInAppBar
              ? 'showColorSeedButtonInAppBar'
              : 'hideColorSeedButtonInAppBar');
      emit(state.copyWith(
          showColorSeedButtonInAppBar: !event.showColorSeedButtonInAppBar));
    });

    on<ToggleDisplayColorImageButtonInAppBar>((event, emit) {
      sharedPreferences.setString(
          displayColorImageButtonInAppBar,
          event.showColorImageButtonInAppBar
              ? 'showColorImageButtonInAppBar'
              : 'hideColorImageButtonInAppBar');
      emit(state.copyWith(
          showColorImageButtonInAppBar: !event.showColorImageButtonInAppBar));
    });

    on<ToggleDisplayLanguagesButtonInAppBar>((event, emit) {
      sharedPreferences.setString(
          displayLanguagesButtonInAppBar,
          event.showLanguagesButtonInAppBar
              ? 'showLanguagesButtonInAppBar'
              : 'hideLanguagesButtonInAppBar');
      emit(state.copyWith(
          showLanguagesButtonInAppBar: !event.showLanguagesButtonInAppBar));
    });

    on<ChangeColor>((event, emit) {
      sharedPreferences.setInt(colorKey, event.color.color.value);
      emit(state.copyWith(
        colorSelected: event.color,
        colorSelectionMethod: ColorSelectionMethod.colorSeed,
      ));
    });

    on<ChangeImage>((event, emit) async {
      final String url = event.image.url;
      final newScheme =
          await ColorScheme.fromImageProvider(provider: NetworkImage(url));
      emit(state.copyWith(
        imageSelected: event.image,
        imageColorScheme: newScheme,
        colorSelectionMethod: ColorSelectionMethod.image,
      ));
    });

    on<SelectLanguageEvent>((event, emit) {
      sharedPreferences.setInt(languageKey, event.language.index);
      emit(state.copyWith(language: event.language));
    });

    on<LoadLanguageEvent>((event, emit) async {
      final prefs = await SharedPreferences.getInstance();
      final languageIndex = prefs.getInt(languageKey);
      if (languageIndex != null) {
        emit(state.copyWith(language: AppLanguage.values[languageIndex]));
      }
    });

    on<IncrementLaunchCountEvent>((event, emit) {
      final newLaunchCount = state.launchCount + 1;
      sharedPreferences.setInt(launchCountKey, newLaunchCount);
      emit(state.copyWith(launchCount: newLaunchCount));
    });

    on<LoadLaunchCountEvent>((event, emit) {
      emit(state.copyWith(launchCount: event.launchCount));
    });

    on<ChangeTrashRetentionDays>((event, emit) {
      sharedPreferences.setInt(trashRetentionDaysKey, event.days);
      emit(state.copyWith(trashRetentionDays: event.days));
    });

    on<ToggleKeepPomodoroRunning>((event, emit) {
      sharedPreferences.setBool(keepPomodoroRunningKey, event.enabled);
      emit(state.copyWith(keepPomodoroRunningInBackground: event.enabled));
    });

    on<ToggleShowCalendarZoomButtons>((event, emit) {
      sharedPreferences.setBool(showCalendarZoomButtonsKey, event.enabled);
      emit(state.copyWith(showCalendarZoomButtons: event.enabled));
    });

    on<ToggleRemindersEnabled>((event, emit) {
      sharedPreferences.setBool(remindersEnabledKey, event.enabled);
      emit(state.copyWith(remindersEnabled: event.enabled));
      // Đồng bộ với hệ thống thông báo: tắt -> hủy hết; bật -> lên lịch lại
      // toàn bộ interval từ DB. Bọc trong service/DB (an toàn nếu lỗi).
      NotificationService.instance.setEnabled(event.enabled);
      _timeIntervalRepository.rescheduleAllReminders();
    });

    on<ToggleTransparentBottomBar>((event, emit) {
      sharedPreferences.setBool(transparentBottomBarKey, event.enabled);
      emit(state.copyWith(transparentBottomBar: event.enabled));
    });

    on<ChangeTaskCardStyle>((event, emit) {
      sharedPreferences.setInt(taskCardStyleKey, event.style.index);
      emit(state.copyWith(taskCardStyle: event.style));
    });
  }
}

////////////////////////////////////////////////////////////////
/// APP EVENTS
abstract class AppEvent {}

class ToggleBrightness extends AppEvent {
  final bool useLightMode;

  ToggleBrightness(this.useLightMode);
}

class ToggleMaterialVersion extends AppEvent {
  final bool useMaterial3;

  ToggleMaterialVersion(this.useMaterial3);
}

class ToggleUsingBottomBar extends AppEvent {
  final bool useBottomBar;

  ToggleUsingBottomBar(this.useBottomBar);
}
class ToggleDisplayBrightnessButtonInAppBar extends AppEvent {
  final bool showBrightnessButtonInAppBar;

  ToggleDisplayBrightnessButtonInAppBar(this.showBrightnessButtonInAppBar);
}

class ToggleDisplayMaterialDesignButtonInAppBar extends AppEvent {
  final bool showMaterialDesignButtonInAppBar;

  ToggleDisplayMaterialDesignButtonInAppBar(
      this.showMaterialDesignButtonInAppBar);
}

class ToggleDisplayColorSeedButtonInAppBar extends AppEvent {
  final bool showColorSeedButtonInAppBar;

  ToggleDisplayColorSeedButtonInAppBar(this.showColorSeedButtonInAppBar);
}

class ToggleDisplayColorImageButtonInAppBar extends AppEvent {
  final bool showColorImageButtonInAppBar;

  ToggleDisplayColorImageButtonInAppBar(this.showColorImageButtonInAppBar);
}

class ToggleDisplayLanguagesButtonInAppBar extends AppEvent {
  final bool showLanguagesButtonInAppBar;

  ToggleDisplayLanguagesButtonInAppBar(this.showLanguagesButtonInAppBar);
}

class ChangeColor extends AppEvent {
  final ColorSeed color;

  ChangeColor(this.color);
}

class ChangeImage extends AppEvent {
  final ColorImageProvider image;

  ChangeImage(this.image);
}

class LoadLanguageEvent extends AppEvent {}

class SelectLanguageEvent extends AppEvent {
  final AppLanguage language;

  SelectLanguageEvent(this.language);
}

class IncrementLaunchCountEvent extends AppEvent {}

class LoadLaunchCountEvent extends AppEvent {
  final int launchCount;

  LoadLaunchCountEvent(this.launchCount);
}

/// Thay đổi (hoặc nạp) số ngày giữ mục trong thùng rác.
class ChangeTrashRetentionDays extends AppEvent {
  final int days;

  ChangeTrashRetentionDays(this.days);
}

/// Bật/tắt (hoặc nạp) cài đặt cho phép Pomodoro chạy khi rời màn hình.
class ToggleKeepPomodoroRunning extends AppEvent {
  final bool enabled;

  ToggleKeepPomodoroRunning(this.enabled);
}

/// Bật/tắt (hoặc nạp) cài đặt hiển thị nút +/- zoom trên các màn hình lịch.
class ToggleShowCalendarZoomButtons extends AppEvent {
  final bool enabled;

  ToggleShowCalendarZoomButtons(this.enabled);
}

/// Bật/tắt (hoặc nạp) cài đặt nhắc bằng thông báo cho các khoảng thời gian.
class ToggleRemindersEnabled extends AppEvent {
  final bool enabled;

  ToggleRemindersEnabled(this.enabled);
}

/// Bật/tắt (hoặc nạp) cài đặt hiển thị bottom bar ở chế độ trong suốt.
class ToggleTransparentBottomBar extends AppEvent {
  final bool enabled;

  ToggleTransparentBottomBar(this.enabled);
}

class ChangeTaskCardStyle extends AppEvent {
  final TaskCardStyle style;

  ChangeTaskCardStyle(this.style);
}



////////////////////////////////////////////////////////////////
///APP STATE
class AppState {
  final bool useMaterial3;
  final bool useBottomBar;
  final ThemeMode themeMode;
  final ColorSeed colorSelected;
  final ColorImageProvider imageSelected;
  final ColorScheme? imageColorScheme;
  final ColorSelectionMethod colorSelectionMethod;
  final AppLanguage language;
  final int launchCount;

  /// Số ngày giữ mục trong thùng rác trước khi tự động xóa vĩnh viễn.
  final int trashRetentionDays;

  /// Cho phép đồng hồ Pomodoro tiếp tục chạy khi người dùng chuyển màn hình.
  final bool keepPomodoroRunningInBackground;

  /// Hiển thị nút +/- zoom trên các màn hình lịch (pinch/Ctrl+cuộn vẫn luôn bật).
  final bool showCalendarZoomButtons;

  /// Bật nhắc bằng thông báo cho các khoảng thời gian đã đặt mốc nhắc.
  final bool remindersEnabled;

  /// Hiển thị bottom navigation bar ở chế độ trong suốt (nền trong, không đổ
  /// bóng) thay vì nền đặc mặc định.
  final bool transparentBottomBar;

  /// Kiểu hiển thị thẻ task ở màn Overview (nền đầy màu hoặc dải màu bên trái).
  final TaskCardStyle taskCardStyle;

  final bool showBrightnessButtonInAppBar;
  final bool showMaterialDesignButtonInAppBar;
  final bool showColorSeedButtonInAppBar;
  final bool showColorImageButtonInAppBar;
  final bool showLanguagesButtonInAppBar;

  bool get useLightMode {
    switch (themeMode) {
      case ThemeMode.system:
        return WidgetsBinding.instance.window.platformBrightness ==
            Brightness.light;
      case ThemeMode.light:
        return true;
      case ThemeMode.dark:
        return false;
    }
  }

  AppState({
    required this.useMaterial3,
    required this.useBottomBar,
    required this.showBrightnessButtonInAppBar,
    required this.showMaterialDesignButtonInAppBar,
    required this.showColorSeedButtonInAppBar,
    required this.showColorImageButtonInAppBar,
    required this.showLanguagesButtonInAppBar,
    required this.themeMode,
    required this.colorSelected,
    required this.imageSelected,
    required this.imageColorScheme,
    required this.colorSelectionMethod,
    required this.language,
    required this.launchCount,
    this.trashRetentionDays = 30,
    this.keepPomodoroRunningInBackground = false,
    this.showCalendarZoomButtons = true,
    this.remindersEnabled = true,
    this.transparentBottomBar = false,
    this.taskCardStyle = TaskCardStyle.filled,
  });

  AppState copyWith({
    bool? useMaterial3,
    bool? useBottomBar,
    bool? showBrightnessButtonInAppBar,
    bool? showMaterialDesignButtonInAppBar,
    bool? showColorSeedButtonInAppBar,
    bool? showColorImageButtonInAppBar,
    bool? showLanguagesButtonInAppBar,
    ThemeMode? themeMode,
    ColorSeed? colorSelected,
    ColorImageProvider? imageSelected,
    ColorScheme? imageColorScheme,
    ColorSelectionMethod? colorSelectionMethod,
    AppLanguage? language,
    int? launchCount,
    int? trashRetentionDays,
    bool? keepPomodoroRunningInBackground,
    bool? showCalendarZoomButtons,
    bool? remindersEnabled,
    bool? transparentBottomBar,
    TaskCardStyle? taskCardStyle,
  }) {
    return AppState(
      useMaterial3: useMaterial3 ?? this.useMaterial3,
      useBottomBar: useBottomBar ?? this.useBottomBar,
      showBrightnessButtonInAppBar:
          showBrightnessButtonInAppBar ?? this.showBrightnessButtonInAppBar,
      showMaterialDesignButtonInAppBar: showMaterialDesignButtonInAppBar ??
          this.showMaterialDesignButtonInAppBar,
      showColorSeedButtonInAppBar:
          showColorSeedButtonInAppBar ?? this.showColorSeedButtonInAppBar,
      showColorImageButtonInAppBar:
          showColorImageButtonInAppBar ?? this.showColorImageButtonInAppBar,
      showLanguagesButtonInAppBar:
          showLanguagesButtonInAppBar ?? this.showLanguagesButtonInAppBar,
      themeMode: themeMode ?? this.themeMode,
      colorSelected: colorSelected ?? this.colorSelected,
      imageSelected: imageSelected ?? this.imageSelected,
      imageColorScheme: imageColorScheme ?? this.imageColorScheme,
      colorSelectionMethod: colorSelectionMethod ?? this.colorSelectionMethod,
      language: language ?? this.language,
      launchCount: launchCount ?? this.launchCount,
      trashRetentionDays: trashRetentionDays ?? this.trashRetentionDays,
      keepPomodoroRunningInBackground: keepPomodoroRunningInBackground ??
          this.keepPomodoroRunningInBackground,
      showCalendarZoomButtons:
          showCalendarZoomButtons ?? this.showCalendarZoomButtons,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      transparentBottomBar: transparentBottomBar ?? this.transparentBottomBar,
      taskCardStyle: taskCardStyle ?? this.taskCardStyle,
    );
  }
}
