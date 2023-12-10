import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/constants.dart';
import '../../utils/utils.dart';


class MyAppDrawer extends StatelessWidget {
  final int _selectedDrawerItemIndex;
  final Function(int) _onDrawerItemTapped;
  final localizations;

  MyAppDrawer(this._selectedDrawerItemIndex, this._onDrawerItemTapped, this.localizations);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
                            const DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.blueGrey,
                    ),
                    child: Text('My Time Manager'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.checklist_outlined),
                    title: Text(localizations!.tasksAndEvents),
                    selected: _selectedDrawerItemIndex ==
                        ScreenSelected.tasksScreen.value,
                    onTap: () =>
                        _onDrawerItemTapped(ScreenSelected.tasksScreen.value),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: Text(localizations.calendar),
                    selected: _selectedDrawerItemIndex ==
                        ScreenSelected.calendarScreen.value,
                    onTap: () => _onDrawerItemTapped(
                        ScreenSelected.calendarScreen.value),
                  ),
                  ListTile(
                    leading: const Icon(Icons.timelapse_outlined),
                    title: Text(localizations.focusTimer),
                    selected: _selectedDrawerItemIndex ==
                        ScreenSelected.focusTimerScreen.value,
                    onTap: () => showComingSoonDialog(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.notes_outlined),
                    title: Text(localizations.notes),
                    selected: _selectedDrawerItemIndex ==
                        ScreenSelected.notesScreen.value,
                    onTap: () => showComingSoonDialog(context),
                  ),
                  // ListTile(
                  //   leading: const Icon(Icons.contacts_outlined),
                  //   title: Text(localizations.myContacts),
                  //   selected: _selectedDrawerItemIndex ==
                  //       ScreenSelected.contactsScreen.value,
                  //   onTap: () => showComingSoonDialog(context),
                  // ),
                  // ListTile(
                  //   leading: const Icon(Icons.query_stats_outlined),
                  //   title: Text(localizations.myStatistics),
                  //   selected: _selectedDrawerItemIndex ==
                  //       ScreenSelected.statsScreen.value,
                  //   onTap: () => showComingSoonDialog(context),
                  // ),
                  ListTile(
                    leading: const Icon(Icons.design_services_outlined),
                    title: const Text('Material Design'),
                    selected: _selectedDrawerItemIndex ==
                        ScreenSelected.materialDesignScreen.value,
                    onTap: () => _onDrawerItemTapped(
                        ScreenSelected.materialDesignScreen.value),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: Text(localizations!.settings),
                    selected: _selectedDrawerItemIndex ==
                        ScreenSelected.settingsScreen.value,
                    onTap: () => _onDrawerItemTapped(
                        ScreenSelected.settingsScreen.value),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outlined),
                    title: Text(localizations.aboutUs),
                    selected: _selectedDrawerItemIndex ==
                        ScreenSelected.aboutUsScreen.value,
                    onTap: () =>
                        _onDrawerItemTapped(ScreenSelected.aboutUsScreen.value),
                  ),
                  ListTile(
                    leading: const Icon(Icons.emoji_food_beverage_outlined),
                    title: Text(
                      localizations.supportUs,
                    ),
                    onTap: () async {
                      Uri url;
                      switch (Localizations.localeOf(context).languageCode) {
                        case 'en':
                          url = supportUsEnUrl;
                          break;
                        case 'vi':
                          url = supportUsViUrl;
                          break;
                        case 'de':
                          url = supportUsDeUrl;
                          break;
                        default:
                          url =
                              supportUsEnUrl; // fallback to English URL if the language is not supported
                      }
                      if (await canLaunchUrl(url)) {
                        await launchURL(url);
                      } else {
                        throw 'Could not launch $url';
                      }
                    },
                  ),
                  ListTile(
                      leading: const Icon(Icons.upgrade_outlined),
                      title: const Text(
                        "Upgrade to the Pro version",
                      ),
                      onTap: () => launchURL(proVersionUrl)),
        ],
      ),
    );
  }
}
