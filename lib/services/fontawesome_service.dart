// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../services/utilities.dart';

const debug = false;

// For :icon: syntax, a pre-processing step is often best:
String preprocessMarkdownIcons(String originalText) {
  String text = originalText;
  // Color color = Colors.black;

  Map<String, String> faIconMap = {
    'invalid': '',
    'python': '',
    'react': '',
    'linux': '',
    'github': '',
    'npm': '',
    'flutter': '',
  };
  // Map<String, FaIcon> faIconMap = {
  //   'invalid': FaIcon(
  //     FontAwesomeIcons.python,
  //     color: color,
  //   ),
  //   'python': FaIcon(
  //     FontAwesomeIcons.python,
  //     color: color,
  //   ),
  //   'react': FaIcon(
  //     FontAwesomeIcons.react,
  //     color: color,
  //   ),
  //   'linux': FaIcon(
  //     FontAwesomeIcons.linux,
  //     color: color,
  //   ),
  //   'github': FaIcon(
  //     FontAwesomeIcons.github,
  //     color: color,
  //   ),
  //   'npm': FaIcon(
  //     FontAwesomeIcons.npm,
  //     color: color,
  //   ),
  //   'flutter': FaIcon(
  //     FontAwesomeIcons.flutter,
  //     color: color,
  //   ),
  // };
  RegExp pattern =
      RegExp(r'\:fontawesome-brands\-([a-zA-Z0-9]+)\:\{ \.([a-zA-Z0-9]+) \}');
  faIconMap.forEach((key, value) {
    // Replace ":fontawesome-brands-icon-name:{ .icon-name }" with <i class="fa fa-icon-name"></i> for easier handling if using HTML
    Iterable<Match> matches = pattern.allMatches(text);
    if (debug) {
      logDebug('Font Awesome Service | preprocessMarkdownIcons'
          '\n pattern: $pattern'
          '\n matches: ${matches.toString()}');
    }
    for (Match match in matches) {
      String iconPattern = match.group(0)!;
      String iconName = match.group(1)!;
      // String iconColor = match.group(2)!;
      if (debug) {
        logDebug('Icon found'
            '\n iconName: $iconName'
            '\n match: ${match.toString()}'
            '\n iconPattern: $iconPattern');
      }
      text = text.replaceAll(iconPattern, value);
      // TODO: make icons work properly because now it's replacing the patters with a blank space
      // text = text.replaceAll(iconPattern, value.toString());
      // text = text.replaceAll(iconPattern, '<i class="fa fa-$iconName"></i>');
    }
  });
  return text;
}
