import 'package:flutter/material.dart';

import '../../app/app_localizations.dart';
import '../../utils/constants.dart';

class LanguageButton extends StatelessWidget {
  const LanguageButton(
      {required this.handleLanguageSelect, required this.languageSelected});

  final void Function(int) handleLanguageSelect;
  final AppLanguage languageSelected;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return PopupMenuButton(
      icon: Icon(
        Icons.language_outlined,
      ),
      tooltip: 'Select a language',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) {
        return List.generate(AppLanguage.values.length, (index) {
          AppLanguage currentLanguage = AppLanguage.values[index];

          return PopupMenuItem(
            value: index,
            enabled: currentLanguage != languageSelected,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 48),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Text(currentLanguage.short_language),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child:
                      Text(localizations!.translate(currentLanguage.language)),
                ),
              ],
            ),
          );
        });
      },
      onSelected: handleLanguageSelect,
    );
  }
}

class LanguageSubmenuButton extends StatelessWidget {
  const LanguageSubmenuButton(
      {required this.handleLanguageSelect, required this.languageSelected});

  final void Function(int) handleLanguageSelect;
  final AppLanguage languageSelected;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return SubmenuButton(
      menuChildren: List.generate(AppLanguage.values.length, (index) {
        AppLanguage currentLanguage = AppLanguage.values[index];

        return MenuItemButton(
          onPressed: currentLanguage != languageSelected
              ? () => handleLanguageSelect(index)
              : null,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 50,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Center(
                    child: Text(currentLanguage.short_language),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(localizations!.translate(currentLanguage.language)),
              ),
            ],
          ),
        );
      }),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.spaceAround,
        children: [
          SizedBox(
            width: 100,
            child: Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Text(localizations!.translate(languageSelected.language)),
            ),
          ),
          const SizedBox(
            width: 20,
          ),
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Center(
                child: Text(languageSelected.short_language),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
