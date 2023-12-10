import 'package:flutter/material.dart';

import '../../utils/constants.dart';

class ExpandedLanguageAction extends StatelessWidget {
  const ExpandedLanguageAction({
    required this.handleLanguageSelect,
    required this.languageSelected,
  });

  final void Function(int) handleLanguageSelect;
  final AppLanguage languageSelected;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 150.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: GridView.count(
          crossAxisCount: 3,
          children: List.generate(
            AppLanguage.values.length,
            (i) => InkWell(
              borderRadius: BorderRadius.circular(4.0),
              onTap: () => handleLanguageSelect(i),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Material(
                  borderRadius: BorderRadius.circular(4.0),
                  elevation: languageSelected == AppLanguage.values[i] ? 3 : 0,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: Center(
                        child: Text(AppLanguage.values[i].short_language),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
