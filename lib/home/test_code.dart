// class MyHomePage extends StatelessWidget {
//   final String title;

//   MyHomePage({Key? key, required this.title}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final localizations = AppLocalizations.of(context);
//     return Scaffold(
//       appBar: AppBar(title: Text(localizations?.title ?? title)),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text('Select a language:'),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () => context
//                   .read<AppBloc>()
//                   .add(SelectLanguageEvent(AppLanguage.english)),
//               child: Text(localizations!.english),
//             ),
//             const SizedBox(height: 8),
//             ElevatedButton(
//               onPressed: () => context
//                   .read<AppBloc>()
//                   .add(SelectLanguageEvent(AppLanguage.vietnamese)),
//               child: Text(localizations.vietnamese),
//             ),
//             const SizedBox(height: 8),
//             ElevatedButton(
//               onPressed: () => context
//                   .read<AppBloc>()
//                   .add(SelectLanguageEvent(AppLanguage.german)),
//               child: Text(localizations.german),
//             ),
//             Text('This app has been launched:'),
//             SizedBox(height: 16),
//             BlocBuilder<AppBloc, AppState>(
//               builder: (context, state) {
//                 return Text(
//                   '${state.launchCount} times',
//                   style: Theme.of(context).textTheme.headline4,
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   _HomePageState createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   int _selectedPageIndex = 0;

//   static final List<Widget> _pages = <Widget>[
//     OverviewPage(),
//     TimelinePage(),
//     TimetablePage(),
//   ];

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedPageIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Home'),
//       ),
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: <Widget>[
//             const DrawerHeader(
//               decoration: BoxDecoration(
//                 color: Colors.blue,
//               ),
//               child: Text('Drawer Header'),
//             ),
//             ListTile(
//               title: const Text('Home'),
//               onTap: () {
//                 Navigator.pop(context);
//               },
//             ),
//             ListTile(
//               title: const Text('Settings'),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => SettingsPage()),
//                 );
//               },
//             ),
//             ListTile(
//               title: const Text('About'),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => AboutPage()),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//       body: Center(
//         child: _pages.elementAt(_selectedPageIndex),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Overview',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.timeline),
//             label: 'Timeline',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.schedule),
//             label: 'Timetable',
//           ),
//         ],
//         currentIndex: _selectedPageIndex,
//         selectedItemColor: Colors.amber[800],
//         onTap: _onItemTapped,
//       ),
//     );
//   }
// }

// class OverviewPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Text('Overview Page');
//   }
// }

// class TimelinePage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Text('Timeline Page');
//   }
// }

// class TimetablePage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Text('Timetable Page');
//   }
// }

// class SettingsPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Settings'),
//       ),
//       body: Center(
//         child: Text('Settings Page'),
//       ),
//     );
//   }
// }

// class AboutPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('About'),
//       ),
//       body: Center(
//         child: Text('About Page'),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedDrawerIndex = 0;
  int _selectedBottomNavIndex = 0;

  static final List<Widget> _homePages = <Widget>[
    OverviewPage(),
    TimelinePage(),
    TimetablePage(),
  ];

  static final List<Widget> _otherPages = <Widget>[
    SettingsPage(),
    AboutPage(),
  ];

  void _onDrawerItemTapped(int index) {
    setState(() {
      _selectedDrawerIndex = index;
      _selectedBottomNavIndex = 0;
    });
    Navigator.pop(context);
  }

  void _onBottomNavItemTapped(int index) {
    setState(() {
      _selectedBottomNavIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedDrawerIndex == 0
            ? 'Home'
            : _selectedDrawerIndex == 1
                ? 'Others'
                : 'Upgrade'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('Drawer Header'),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              title: Text('Home'),
              selected: _selectedDrawerIndex == 0,
              onTap: () => _onDrawerItemTapped(0),
            ),
            ListTile(
              title: Text('Others'),
              selected: _selectedDrawerIndex == 1,
              onTap: () => _onDrawerItemTapped(1),
            ),
            ListTile(
              title: Text('Upgrade to pro version'),
              onTap: () => _onDrawerItemTapped(2),
            ),
          ],
        ),
      ),
      body: //Center(
          //child:
          _selectedDrawerIndex == 0
              ? _homePages.elementAt(_selectedBottomNavIndex)
              : _selectedDrawerIndex == 1
                  ? _otherPages.elementAt(_selectedBottomNavIndex)
                  : UpgradePage(),
      //),
      bottomNavigationBar: _selectedDrawerIndex == 2
          ? null
          : BottomNavigationBar(
              items: _selectedDrawerIndex == 0
                  ? const <BottomNavigationBarItem>[
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Overview',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.timeline),
                        label: 'Timeline',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.table_chart),
                        label: 'Timetable',
                      ),
                    ]
                  : const <BottomNavigationBarItem>[
                      BottomNavigationBarItem(
                        icon: Icon(Icons.settings),
                        label: 'Settings',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.info),
                        label: 'About',
                      ),
                    ],
              currentIndex: _selectedBottomNavIndex,
              onTap: _onBottomNavItemTapped,
            ),
    );
  }
}

class OverviewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Overview Page'));
  }
}

class TimelinePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Timeline Page'));
  }
}

class TimetablePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Timetable Page'));
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Settings Page'));
  }
}

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('About Page'));
  }
}

class UpgradePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Upgrade Page'));
  }
}
