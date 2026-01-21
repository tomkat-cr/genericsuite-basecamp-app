import 'dart:developer';

import 'package:intl/intl.dart';

// General date/time functions

int nowToTimestamp() {
  return DateTime.now().millisecondsSinceEpoch;
}

String getTimeStampFormatted([int timestamp = 0]) {
  // Define the desired format using a pattern
  // HH is for 24-hour format (00-23)
  // hh is for 12-hour format (01-12)
  final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  if (timestamp == 0) {
    timestamp = DateTime.now().millisecondsSinceEpoch;
  }

  // Format the DateTime object into a String
  final String formattedDate =
      formatter.format(DateTime.fromMillisecondsSinceEpoch(timestamp));
  return formattedDate;
}

String getDateTime([int timestamp = 0]) {
  if (timestamp == 0) {
    return getTodayDateTime();
  }
  return getTimeStampFormatted(timestamp);
}

String getTodayDateTime() {
  return getTimeStampFormatted();
}

// Misc

String getValueToEdit(var itemValue, var defaultValue,
    [Map<String, dynamic>? userData = const {}]) {
  Map<String, dynamic> vars = {
    'defaultValueString': defaultValue.toString(),
    'itemValueString': itemValue.toString(),
  };
  for (var key in vars.keys) {
    switch (vars[key]) {
      case "CurrentUserId":
      case "{CurrentUserId}":
        vars[key] = userData!.containsKey('id') ? userData['id'] : vars[key];
        break;
      case 'current_timestamp':
        vars[key] = getTimeStampFormatted();
        break;
      default:
        break;
    }
  }
  return itemValue == null || vars['itemValueString'].isEmpty
      ? vars['defaultValueString']
      : vars['itemValueString'];
}

Map<String, dynamic> replaceSpecialVars(
    Map<String, dynamic> params, Map<String, dynamic> currentUser) {
  params.forEach((key, value) {
    if (value == "{CurrentUserId}") {
      params[key] = currentUser['id'];
    }
    if (value == "{current_timestamp}") {
      params[key] = nowToTimestamp();
    }
  });
  return params;
}

dynamic defaultValue(Map<String, dynamic> map, String key,
    [dynamic defaultValue = ""]) {
  if (map.containsKey(key)) {
    return map[key];
  }
  return defaultValue;
}

// Log functions

Future<void> logDebug(String message) async {
  log("[DEBUG] ${getDateTime()} - $message");
}

Future<void> logInfo(String message) async {
  log("[INFO] ${getDateTime()} - $message");
}

Future<void> logWarning(String message) async {
  log("[WARNING] ${getDateTime()} - $message");
}

Future<void> logError(String message) async {
  log("[ERROR] ${getDateTime()} - $message");
}
