import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/home/home.dart';
import 'package:my_time_manager/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppBloc(),
      child: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          return MaterialApp(
            locale: Locale(
              ['en', 'vi', 'de'][state.language.index],
            ),
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('vi'),
              Locale('de'),
            ],
            debugShowCheckedModeBanner: false, // remove debug banner
            title: 'Material 3',
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
            home: Home(
              useLightMode: state.useLightMode,
              useMaterial3: state.useMaterial3,
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
            ),

            //home: MyHomePage(title: 'Demo',),
          );
        },
      ),
    );
  }
}

class AppBloc extends Bloc<AppEvent, AppState> {
  static const brightnessKey = 'brightness';
  static const colorKey = 'color';
  static const useDesignVersionKey = 'useMaterial';
  static const languageKey = 'language';
  static const launchCountKey = 'launchCount';

  late SharedPreferences sharedPreferences;

  AppBloc()
      : super(AppState(
            useMaterial3: true,
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
            ? false
            : true,
      ));
      
      if (sharedPreferences.getInt(languageKey) != null) {
        add(SelectLanguageEvent(
            AppLanguage.values[sharedPreferences.getInt(languageKey)!]));
      }

      add(LoadLaunchCountEvent(sharedPreferences.getInt(launchCountKey) ?? 0));

      add(IncrementLaunchCountEvent());
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
      emit(state.copyWith(useMaterial3: !state.useMaterial3));
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

////////////////////////////////////////////////////////////////
///APP STATE
class AppState {
  final bool useMaterial3;
  final ThemeMode themeMode;
  final ColorSeed colorSelected;
  final ColorImageProvider imageSelected;
  final ColorScheme? imageColorScheme;
  final ColorSelectionMethod colorSelectionMethod;
  final AppLanguage language;
  final int launchCount;

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
    required this.themeMode,
    required this.colorSelected,
    required this.imageSelected,
    required this.imageColorScheme,
    required this.colorSelectionMethod,
    required this.language,
    required this.launchCount,
  });

  AppState copyWith({
    bool? useMaterial3,
    ThemeMode? themeMode,
    ColorSeed? colorSelected,
    ColorImageProvider? imageSelected,
    ColorScheme? imageColorScheme,
    ColorSelectionMethod? colorSelectionMethod,
    AppLanguage? language,
    int? launchCount,
  }) {
    return AppState(
      useMaterial3: useMaterial3 ?? this.useMaterial3,
      themeMode: themeMode ?? this.themeMode,
      colorSelected: colorSelected ?? this.colorSelected,
      imageSelected: imageSelected ?? this.imageSelected,
      imageColorScheme: imageColorScheme ?? this.imageColorScheme,
      colorSelectionMethod: colorSelectionMethod ?? this.colorSelectionMethod,
      language: language ?? this.language,
      launchCount: launchCount ?? this.launchCount,
    );
  }

  // factory AppState.loading() => AppState(
  //       useMaterial3: false,
  //       themeMode: ThemeMode.system,
  //       colorSelected: ColorSeed.baseColor,
  //       imageSelected: ColorImageProvider.leaves,
  //       imageColorScheme: const ColorScheme.light(),
  //       colorSelectionMethod: ColorSelectionMethod.colorSeed,
  //     );

  // factory AppState.loaded(String? language) => AppState(
  //       useMaterial3: false,
  //       themeMode: ThemeMode.system,
  //       colorSelected: ColorSeed.baseColor,
  //       imageSelected: ColorImageProvider.leaves,
  //       imageColorScheme: const ColorScheme.light(),
  //       colorSelectionMethod: ColorSelectionMethod.colorSeed,
  //       selectedLanguage: language,
  //     );
}

