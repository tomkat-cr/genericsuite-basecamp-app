import 'package:flutter/services.dart';

import '../models/doc_manifest.dart';
import '../services/utilities.dart';

const debug = false;

class DocService {
  List<DocManifestItem> _manifest = [];

  List<DocManifestItem> get manifest => _manifest;

  Future<void> loadManifest() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/docs_manifest.json');
      _manifest = DocManifestLoader.parseManifest(jsonString);
      if (debug) {
        logDebug('Manifest loaded: ${_manifest.length} items');
      }
    } catch (e) {
      logError('Error loading manifest: $e');
      _manifest = [];
    }
  }

  // Helper to find the first page to show (e.g., if home is a section)
  DocManifestItem? getFirstPage([List<DocManifestItem>? items]) {
    final list = items ?? _manifest;
    for (var item in list) {
      if (item.type == 'page') {
        return item;
      } else if (item.children != null) {
        final childPage = getFirstPage(item.children);
        if (childPage != null) return childPage;
      }
    }
    return null;
  }
}
