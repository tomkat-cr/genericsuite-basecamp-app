import 'dart:convert';

class DocManifestItem {
  final String title;
  final String? path;
  final List<DocManifestItem>? children;
  final String type; // 'page' or 'section'
  final String source; // 'nav' or 'external'

  DocManifestItem({
    required this.title,
    this.path,
    this.children,
    required this.type,
    required this.source,
  });

  factory DocManifestItem.fromJson(Map<String, dynamic> json) {
    return DocManifestItem(
      title: json['title'] as String,
      path: json['path'] as String?,
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => DocManifestItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      type: json['type'] as String,
      source: json['source'] as String,
    );
  }
}

class DocManifestLoader {
  static List<DocManifestItem> parseManifest(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => DocManifestItem.fromJson(e)).toList();
  }
}
