import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../screen_ai/ai_assistant_entry.dart';
import '../../screen_ai/ai_settings_page.dart';
import '../../screen_goals/goals_list_screen.dart';
import '../../screen_learning/courses_list_screen.dart';
import '../../screen_projects/projects_list_screen.dart';
import '../../screen_reminders/upcoming_reminders_screen.dart';
import '../../utils/constants.dart';
import '../../utils/utils.dart';

class MyAppDrawer extends StatelessWidget {
  final int _selectedDrawerItemIndex;
  final Function(int) _onDrawerItemTapped;
  final localizations;
  final bool isProVersion;

  MyAppDrawer(this._selectedDrawerItemIndex, this._onDrawerItemTapped,
      this.localizations, this.isProVersion);

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
            leading: const Icon(Icons.home_outlined),
            title: Text(localizations!.overview),
            selected: _selectedDrawerItemIndex ==
                ScreenSelected.tasksOverviewScreen.value,
            onTap: () =>
                _onDrawerItemTapped(ScreenSelected.tasksOverviewScreen.value),
          ),
          ListTile(
            leading: const Icon(Icons.timeline_outlined),
            title: Text(localizations.timeline),
            selected: _selectedDrawerItemIndex ==
                ScreenSelected.tasksTimelineScreen.value,
            onTap: () =>
                _onDrawerItemTapped(ScreenSelected.tasksTimelineScreen.value),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: Text(localizations.calendar),
            selected:
                _selectedDrawerItemIndex == ScreenSelected.calendarScreen.value,
            onTap: () =>
                _onDrawerItemTapped(ScreenSelected.calendarScreen.value),
          ),
          ListTile(
            leading: const Icon(Icons.timelapse_outlined),
            title: Text(localizations.focusTimer),
            selected: _selectedDrawerItemIndex ==
                ScreenSelected.focusTimerScreen.value,
            onTap: () => _onDrawerItemTapped(ScreenSelected
                .focusTimerScreen.value), //() => showComingSoonDialog(context),
          ),
          ListTile(
              leading: const Icon(Icons.notes_outlined),
              title: Text(localizations.notes),
              selected:
                  _selectedDrawerItemIndex == ScreenSelected.notesScreen.value,
              onTap: () =>
                  _onDrawerItemTapped(ScreenSelected.notesScreen.value)),
          // Mục tiêu (Core Track C5 UI) — route đẩy giống Dự án.
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(localizations.goals),
            onTap: () {
              Navigator.of(context).pop(); // đóng drawer
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const GoalsListScreen(),
                ),
              );
            },
          ),
          // Dự án (Core Track C6) — mở dạng route đẩy (giống AI Assistant) nên
          // không đụng tới bộ chuyển màn theo index của Home.
          ListTile(
            leading: const Icon(Icons.workspaces_outlined),
            title: Text(localizations.projects),
            onTap: () {
              Navigator.of(context).pop(); // đóng drawer
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ProjectsListScreen(),
                ),
              );
            },
          ),
          // Khóa học (Core Track C7) — route đẩy giống Dự án.
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: Text(localizations.courses),
            onTap: () {
              Navigator.of(context).pop(); // đóng drawer
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CoursesListScreen(),
                ),
              );
            },
          ),
          // Nhắc sắp tới (Phase R) — route đẩy giống Khóa học.
          ListTile(
            leading: const Icon(Icons.alarm_outlined),
            title: Text(localizations.reminders),
            onTap: () {
              Navigator.of(context).pop(); // đóng drawer
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const UpcomingRemindersScreen(),
                ),
              );
            },
          ),
          // AI Assistant — opens as a pushed route (not part of the index-based
          // screen switcher) so Home's navigation stays unchanged. The pushed
          // page inherits the app-wide repository providers.
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: const Text('AI Assistant'),
            onTap: () {
              Navigator.of(context).pop(); // close the drawer
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AiAssistantEntry(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.tune_outlined),
            title: const Text('AI Settings'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AiSettingsPage(),
                ),
              );
            },
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

          // ListTile(
          //   leading: const Icon(Icons.design_services_outlined),
          //   title: const Text('Material Design'),
          //   selected: _selectedDrawerItemIndex ==
          //       ScreenSelected.materialDesignScreen.value,
          //   onTap: () =>
          //       _onDrawerItemTapped(ScreenSelected.materialDesignScreen.value),
          // ),
          ListTile(
            leading: const Icon(Icons.archive_outlined),
            title: Text(localizations.archive),
            selected:
                _selectedDrawerItemIndex == ScreenSelected.archiveScreen.value,
            onTap: () =>
                _onDrawerItemTapped(ScreenSelected.archiveScreen.value),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Thùng rác'),
            selected:
                _selectedDrawerItemIndex == ScreenSelected.trashScreen.value,
            onTap: () => _onDrawerItemTapped(ScreenSelected.trashScreen.value),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(localizations!.settings),
            selected:
                _selectedDrawerItemIndex == ScreenSelected.settingsScreen.value,
            onTap: () =>
                _onDrawerItemTapped(ScreenSelected.settingsScreen.value),
          ),
          ListTile(
            leading: const Icon(Icons.info_outlined),
            title: Text(localizations.aboutUs),
            selected:
                _selectedDrawerItemIndex == ScreenSelected.aboutUsScreen.value,
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
          if (!isProVersion)
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
