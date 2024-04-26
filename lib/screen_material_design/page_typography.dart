// Copyright 2021 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../utils/utils.dart';

class TypographyPage extends StatelessWidget {
  const TypographyPage({super.key});

  @override
  Widget build(BuildContext context) {
    // final textTheme = Theme.of(context)
    //     .textTheme
    //     .apply(displayColor: Theme.of(context).colorScheme.onSurface);
    // return Expanded(
    //   child: ListView(
    //     children: <Widget>[
    //       const SizedBox(height: 7),
    //       TextStyleExample(
    //           name: 'Display Large', style: textTheme.displayLarge!),
    //       TextStyleExample(
    //           name: 'Display Medium', style: textTheme.displayMedium!),
    //       TextStyleExample(
    //           name: 'Display Small', style: textTheme.displaySmall!),
    //       TextStyleExample(
    //           name: 'Headline Large', style: textTheme.headlineLarge!),
    //       TextStyleExample(
    //           name: 'Headline Medium', style: textTheme.headlineMedium!),
    //       TextStyleExample(
    //           name: 'Headline Small', style: textTheme.headlineSmall!),
    //       TextStyleExample(name: 'Title Large', style: textTheme.titleLarge!),
    //       TextStyleExample(name: 'Title Medium', style: textTheme.titleMedium!),
    //       TextStyleExample(name: 'Title Small', style: textTheme.titleSmall!),
    //       TextStyleExample(name: 'Label Large', style: textTheme.labelLarge!),
    //       TextStyleExample(name: 'Label Medium', style: textTheme.labelMedium!),
    //       TextStyleExample(name: 'Label Small', style: textTheme.labelSmall!),
    //       TextStyleExample(name: 'Body Large', style: textTheme.bodyLarge!),
    //       TextStyleExample(name: 'Body Medium', style: textTheme.bodyMedium!),
    //       TextStyleExample(name: 'Body Small', style: textTheme.bodySmall!),
    //     ],
    //   ),
    // );

    return Expanded(
      child: ListView(
        children: <Widget>[
          const SizedBox(height: 7),
          TextStyleExample(
            name: 'Display Large',
            style: context.getTextStyle('Display Large'),
          ),
          TextStyleExample(
            name: 'Display Medium',
            style: context.getTextStyle('Display Medium'),
          ),
          TextStyleExample(
            name: 'Display Small',
            style: context.getTextStyle('Display Small'),
          ),
          TextStyleExample(
            name: 'Headline Large',
            style: context.getTextStyle('Headline Large'),
          ),
          TextStyleExample(
            name: 'Headline Medium',
            style: context.getTextStyle('Headline Medium'),
          ),
          TextStyleExample(
            name: 'Headline Small',
            style: context.getTextStyle('Headline Small'),
          ),
          TextStyleExample(
            name: 'Title Large',
            style: context.getTextStyle('Title Large'),
          ),
          TextStyleExample(
            name: 'Title Medium',
            style: context.getTextStyle('Title Medium'),
          ),
          TextStyleExample(
            name: 'Title Small',
            style: context.getTextStyle('Title Small'),
          ),
          TextStyleExample(
            name: 'Label Large',
            style: context.getTextStyle('Label Large'),
          ),
          TextStyleExample(
            name: 'Label Medium',
            style: context.getTextStyle('Label Medium'),
          ),
          TextStyleExample(
            name: 'Label Small',
            style: context.getTextStyle('Label Small'),
          ),
          TextStyleExample(
            name: 'Body Large',
            style: context.getTextStyle('Body Large'),
          ),
          TextStyleExample(
            name: 'Body Medium',
            style: context.getTextStyle('Body Medium'),
          ),
          TextStyleExample(
            name: 'Body Small',
            style: context.getTextStyle('Body Small'),
          ),
        ],
      ),
    );
  }
}

class TextStyleExample extends StatelessWidget {
  const TextStyleExample({
    super.key,
    required this.name,
    required this.style,
  });

  final String name;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(name, style: style),
    );
  }
}
