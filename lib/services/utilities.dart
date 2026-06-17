import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

const utDebug = false;

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

// Browser launch

Future<void> launchURLBrowser(String url) async {
  // Parse the URL string into a Uri object
  final Uri uri = Uri.parse(url);

  // Check if the URL can be launched before attempting to do so
  if (await canLaunchUrl(uri)) {
    // Launch the URL in the external application (default browser)
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  } else {
    // Handle the case where the URL cannot be launched
    throw 'Could not launch $url';
  }
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

// Device specific functions

String getDeviceCurrentLanguage() {
  // Get the system's primary preferred locale
  final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;

  // Extract the language code
  final languageCode = systemLocale.languageCode;

  if (utDebug) {
    logDebug('System Language Code: $languageCode');
  }

  return languageCode;
}

String getLangForApp() {
  String lang = getDeviceCurrentLanguage();
  if (lang.startsWith('es')) {
    return 'es';
  }
  if (lang.startsWith('en')) {
    return 'en';
  }
  // Default to English for any other language
  return 'en';
}
