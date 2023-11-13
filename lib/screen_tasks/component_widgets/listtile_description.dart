import 'package:flutter/material.dart';
import 'package:my_time_manager/app/app_localizations.dart';

class DescriptionListTile extends StatelessWidget {
  final TextEditingController descriptionController;

  DescriptionListTile({required this.descriptionController});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Column(
      children: [
        ListTile(
          leading: const Padding(
            padding: EdgeInsets.only(left: 0.0, right: 4.0),
            child: Icon(Icons.description_outlined),
          ),
          title: TextField(
            controller: descriptionController,
            maxLines: null,
            decoration: InputDecoration(
              hintText: localizations!.description,
              border: InputBorder.none,
            ),
          ),
        ),
        const Divider(
          height: 4,
        ),
      ],
    );
  }
}
