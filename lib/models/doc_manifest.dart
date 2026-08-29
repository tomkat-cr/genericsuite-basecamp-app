import 'dart:convert';

class DocManifestItem {
  final String title;
  final String? path;
  final List<DocManifestItem>? children;
  final String type; // 'page' or 'section'
  final String source; // 'nav' or 'external'
  final String lang; // 'en' or 'es'

  DocManifestItem({
    required this.title,
    this.path,
    this.children,
    required this.type,
    required this.source,
    required this.lang,
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
      lang: json['lang'] as String,
    );
  }

  DocManifestItem copyWithLang(String newLang) {
    return DocManifestItem(
      title: title,
      path: path,
      children: children,
      type: type,
      source: source,
      lang: newLang,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocManifestItem &&
        other.path == path &&
        other.title == title &&
        other.type == type &&
        other.source == source &&
        other.lang == lang;
  }

  @override
  int get hashCode => Object.hash(path, title, type, source, lang);
}

class DocManifestLoader {
  static List<DocManifestItem> parseManifest(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => DocManifestItem.fromJson(e)).toList();
  }
}
