import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_time_manager/app/app_localizations.dart';

/// MaterialApp (locale en + app/Material/Widgets/Cupertino localizations)
/// inside a [MultiRepositoryProvider] of [providers], showing [home].
///
/// Example: `testApp([RepositoryProvider<GoalRepository>.value(value: fake)],
/// launcher(screen))`.
Widget testApp(List<RepositoryProvider> providers, Widget home) {
  final app = MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: home,
  );
  if (providers.isEmpty) return app;
  return MultiRepositoryProvider(providers: providers, child: app);
}

/// A home screen with an 'open' button that pushes [screen]. The value the
/// screen pops with is stored in [result] (if given) and shown as
/// `Text('result: <value>')` (a [PickerEntry]-like object is shown via its
/// `toString()`; use [result] to assert on its fields).
Widget launcher(Widget screen, {ValueNotifier<Object?>? result}) =>
    _Launcher(screen: screen, result: result);

class _Launcher extends StatefulWidget {
  const _Launcher({required this.screen, this.result});

  final Widget screen;
  final ValueNotifier<Object?>? result;

  @override
  State<_Launcher> createState() => _LauncherState();
}

class _LauncherState extends State<_Launcher> {
  Object? _result;

  Future<void> _open() async {
    final r = await Navigator.of(context)
        .push<Object?>(MaterialPageRoute(builder: (_) => widget.screen));
    widget.result?.value = r;
    if (mounted) setState(() => _result = r);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(onPressed: _open, child: const Text('open')),
          Text('result: $_result'),
        ],
      ),
    );
  }
}
