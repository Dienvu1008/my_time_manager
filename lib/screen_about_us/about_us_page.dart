// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import '../app/app_localizations.dart';
import '../utils/constants.dart';
import '../utils/utils.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AboutUsPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
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
                    ListTile(
                        leading: Icon(Icons.bug_report),
                        title: Text(
                          "Report an Issue",
                          key: ValueKey(AboutUsKeys.TITLE_REPORT),
                        ),
                        subtitle: Text(
                          "Having an issue ? Report it here",
                          key: ValueKey(AboutUsKeys.SUBTITLE_REPORT),
                        ),
                        onTap: () => launchURL(ISSUE_URL)),
                    ListTile(
                      leading: Icon(Icons.update),
                      title: Text("Version"),
                      subtitle: Text(
                        "1.0.0",
                        key: ValueKey(AboutUsKeys.VERSION_NUMBER),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.policy),
                      title: Text("Privacy Policy"),
                      onTap: () => launchURL(PRIVACY_URL),
                    ),
                    ListTile(
                      leading: Icon(Icons.help_center),
                      title: Text(localizations!.howToUse),
                      onTap: () => launchURL(README_URL),
                    ),
                  ],
                ),
              ),
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, left: 16.0),
                      child: Text("Author",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: FONT_MEDIUM)
                              ),
                    ),
                    ListTile(
                      leading: Icon(Icons.corporate_fare),
                      title: Text(
                        "TGB Soft",
                        key: ValueKey(AboutUsKeys.AUTHOR_NAME),
                      ),
                      subtitle: Text(
                        "The True, The Good, and the Beautiful",
                        key: ValueKey(AboutUsKeys.AUTHOR_USERNAME),
                      ),
                      onTap: () => launchURL(PAGE_FACEBOOK_URL),
                    ),
                    ListTile(
                      leading: Icon(Icons.perm_identity),
                      title: Text(
                        "Điền Vũ",
                        key: ValueKey(AboutUsKeys.AUTHOR_NAME),
                      ),
                      subtitle: Text(
                        "Dienvu1008",
                        key: ValueKey(AboutUsKeys.AUTHOR_USERNAME),
                      ),
                      onTap: () => launchURL(GITHUB_URL),
                    ),
                    ListTile(
                        leading: Icon(Icons.email),
                        title: Text("Send an Email"),
                        subtitle: Text(
                          "dienvu1008@gmail.com",
                          key: ValueKey(AboutUsKeys.AUTHOR_EMAIL),
                        ),
                        onTap: () => launchURL(EMAIL_URL)),
                  ],
                ),
              ),
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, left: 16.0),
                      child: Text("Ask Question ?",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: FONT_MEDIUM)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          IconButton(
                            icon: FaIcon(FontAwesomeIcons.facebook, size: 18.0),
                            //icon: Image.asset('assets/facebook_logo.png'),
                            onPressed: () => launchURL(PAGE_FACEBOOK_URL),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, left: 16.0),
                      child: Text("Apache License",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: FONT_MEDIUM)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: ListTile(
                        subtitle: Text("Copyright 2023 Điền Vũ"
                            '\n\nLicensed under the Apache License, Version 2.0 (the "License") you may not use this file except in compliance with the License. You may obtain a copy of the License at'
                            "\n\n\nhttp://www.apache.org/licenses/LICENSE-2.0"
                            '\n\nUnless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.'),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
