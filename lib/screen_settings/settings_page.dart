import 'package:flutter/material.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/utils/constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.useLightMode,
    required this.useMaterial3,
    required this.showBrightnessButtonInAppBar,
    required this.showMaterialDesignButtonInAppBar,
    required this.showColorSeedButtonInAppBar,
    required this.showColorImageButtonInAppBar,
    required this.showLanguagesButtonInAppBar,
    required this.colorSelected,
    required this.handleBrightnessChange,
    required this.handleMaterialVersionChange,
    required this.handleDisplayBrightnessButtonInAppBarChange,
    required this.handleDisplayMaterialDesignButtonInAppBarChange,
    required this.handleDisplayColorSeedButtonInAppBarChange,
    required this.handleDisplayColorImageButtonInAppBarChange,
    required this.handleDisplayLanguagesButtonInAppBarChange,
    required this.handleColorSelect,
    required this.handleImageSelect,
    required this.handleLanguageSelect,
    required this.colorSelectionMethod,
    required this.imageSelected,
    required this.languageSelected,
    required this.launchCount,
  });

  final bool useLightMode;
  final bool useMaterial3;
  final bool showBrightnessButtonInAppBar;
  final bool showMaterialDesignButtonInAppBar;
  final bool showColorSeedButtonInAppBar;
  final bool showColorImageButtonInAppBar;
  final bool showLanguagesButtonInAppBar;
  final ColorSeed colorSelected;
  final ColorImageProvider imageSelected;
  final ColorSelectionMethod colorSelectionMethod;
  final AppLanguage languageSelected;
  final int launchCount;

  final void Function(bool useLightMode) handleBrightnessChange;
  final void Function() handleMaterialVersionChange;
  final void Function() handleDisplayBrightnessButtonInAppBarChange;
  final void Function() handleDisplayMaterialDesignButtonInAppBarChange;
  final void Function() handleDisplayColorSeedButtonInAppBarChange;
  final void Function() handleDisplayColorImageButtonInAppBarChange;
  final void Function() handleDisplayLanguagesButtonInAppBarChange;
  final void Function(int value) handleColorSelect;
  final void Function(int value) handleImageSelect;
  final void Function(int value) handleLanguageSelect;

    @override
  _SettingsPageState createState() => _SettingsPageState();
}


class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isBright = Theme.of(context).brightness == Brightness.light;

    return Expanded(
      child: Scaffold(
        //appBar: appBar,
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: <Widget>[
              Card(
                child: Column(
                  children: <Widget>[
                    const ListTile(
                      title: Text(
                        "User Interface Settings",
                      ),
                    ),
                    ListTile(
                      leading: Theme.of(context).brightness == Brightness.light
                          ? const Icon(Icons.dark_mode_outlined)
                          : const Icon(Icons.light_mode_outlined),
                      title: Text("Brightness"),
                      trailing: Switch(
                          value: widget.useLightMode,
                          onChanged: (value) {
                            widget.handleBrightnessChange(value);
                          }),
                    ),
                    ListTile(
                      leading: widget.useMaterial3
                          ? const Icon(Icons.filter_3)
                          : const Icon(Icons.filter_2),
                      title: widget.useMaterial3
                          ? const Text("Material Design 3")
                          : const Text("Material Design 2"),
                      trailing: Switch(
                          value: widget.useMaterial3,
                          onChanged: (_) {
                            widget.handleMaterialVersionChange();
                          }),
                    ),
                    ListTile(
                      title: const Text("Show Brightness Button In Application Bar"),
                      trailing: Switch(
                          value: widget.showBrightnessButtonInAppBar,
                          onChanged: (_) {
                            widget.handleDisplayBrightnessButtonInAppBarChange();
                          }),
                    ),
                    ListTile(
                      title: const Text(
                          "Show Material Design Button In Application Bar"),
                      trailing: Switch(
                          value: widget.showMaterialDesignButtonInAppBar,
                          onChanged: (_) {
                            widget.handleDisplayMaterialDesignButtonInAppBarChange();
                          }),
                    ),
                    ListTile(
                      title: const Text("Show Color Seed Button In Application Bar"),
                      trailing: Switch(
                          value: widget.showColorSeedButtonInAppBar,
                          onChanged: (_) {
                            widget.handleDisplayColorSeedButtonInAppBarChange();
                          }),
                    ),
                    ListTile(
                      title: const Text("Show Color Image Button In Application Bar"),
                      trailing: Switch(
                          value: widget.showColorImageButtonInAppBar,
                          onChanged: (_) {
                            widget.handleDisplayColorImageButtonInAppBarChange();
                          }),
                    ),
                    ListTile(
                      title: const Text("Show Languages Button In Application Bar"),
                      trailing: Switch(
                          value: widget.showLanguagesButtonInAppBar,
                          onChanged: (_) {
                            widget.handleDisplayLanguagesButtonInAppBarChange();
                          }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
