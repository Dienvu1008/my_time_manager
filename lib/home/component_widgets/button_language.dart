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
        //color: Theme.of(context).colorScheme.onSurfaceVariant,
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
