import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

launchURL(Uri url) async {
if (await canLaunchUrl(url)) {
  await launchUrl(url);
} else {
  throw 'Could not launch $url';
}
}

void showComingSoonDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Coming Soon"),
        content: Text("This feature will be available soon."),
        actions: [
          TextButton(
            child: Text("OK"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

