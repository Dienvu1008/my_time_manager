import 'package:flutter/material.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/utils/constants.dart';

import '../home/component_widgets/button_color_image.dart';
import '../home/component_widgets/button_color_seed.dart';
import '../home/component_widgets/button_language.dart';

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

    return Expanded(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: <Widget>[
              Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      title: Text(
                        localizations!.userInterfaceSettings,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    ListTile(
                      leading: Theme.of(context).brightness == Brightness.light
                          ? const Icon(Icons.dark_mode_outlined)
                          : const Icon(Icons.light_mode_outlined),
                      title: Text(localizations.brightness),
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
                      leading: const Icon(
                        Icons.palette_outlined,
                      ),
                      title: Text(localizations.chooseThemeColor),
                      trailing: Container(
                        width: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: ColorSeedButton(
                            handleColorSelect: widget.handleColorSelect,
                            colorSelected: widget.colorSelected,
                            colorSelectionMethod: widget.colorSelectionMethod,
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.image_outlined,
                      ),
                      title: Text(localizations.chooseThemeColorFromImageColor),
                      trailing: Container(
                        width: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: ColorImageButton(
                            handleImageSelect: widget.handleImageSelect,
                            imageSelected: widget.imageSelected,
                            colorSelectionMethod: widget.colorSelectionMethod,
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.language_outlined,
                      ),
                      title: Text(localizations.chooseApplicationLanguage),
                      trailing: Container(
                        width: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: LanguageButton(
                            handleLanguageSelect: widget.handleLanguageSelect,
                            languageSelected: widget.languageSelected,
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      title: Text(
                          localizations.showBrightnessButtonInApplicationBar),
                      trailing: Switch(
                          value: widget.showBrightnessButtonInAppBar,
                          onChanged: (_) {
                            widget
                                .handleDisplayBrightnessButtonInAppBarChange();
                          }),
                    ),
                    ListTile(
                      title: Text(localizations
                          .showMaterialDesignButtonInApplicationBar),
                      trailing: Switch(
                          value: widget.showMaterialDesignButtonInAppBar,
                          onChanged: (_) {
                            widget
                                .handleDisplayMaterialDesignButtonInAppBarChange();
                          }),
                    ),
                    ListTile(
                      title: Text(
                          localizations.showColorSeedButtonInApplicationBar),
                      trailing: Switch(
                          value: widget.showColorSeedButtonInAppBar,
                          onChanged: (_) {
                            widget.handleDisplayColorSeedButtonInAppBarChange();
                          }),
                    ),
                    ListTile(
                      title: Text(
                          localizations.showColorImageButtonInApplicationBar),
                      trailing: Switch(
                          value: widget.showColorImageButtonInAppBar,
                          onChanged: (_) {
                            widget
                                .handleDisplayColorImageButtonInAppBarChange();
                          }),
                    ),
                    ListTile(
                      title: Text(
                          localizations.showLanguagesButtonInApplicationBar),
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
