import 'package:flutter/material.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/utils/utils.dart';

class LocationListTile extends StatefulWidget {
  final TextEditingController locationController;

  LocationListTile({required this.locationController});

  @override
  _LocationListTileState createState() => _LocationListTileState();
}

class _LocationListTileState extends State<LocationListTile> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Column(
      children: [
        ListTile(
          leading: const Padding(
            padding: EdgeInsets.only(left: 0.0, right: 4.0),
            child: Icon(Icons.location_on_outlined),
          ),
          title: TextField(
            controller: widget.locationController,
            maxLines: null,
            decoration: InputDecoration(
              hintText: localizations!.location,
              border: InputBorder.none,
            ),
          ),
          trailing: TextButton(
            child: Text(localizations.map),
            onPressed: () => {
              launchURL(Uri.parse(
                  'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.locationController.text)}')),
            },
          ),
        ),
        const Divider(
          height: 4,
        ),
      ],
    );
  }
}
