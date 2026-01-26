import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../models/doc_manifest.dart';
import '../services/fontawesome_service.dart';
import '../services/utilities.dart';
import 'doc_drawer.dart';

const debug = false;
const contentLoadError = '# Error\nCould not load content:';

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

class DocViewerScreen extends StatefulWidget {
  final DocManifestItem? initialItem;
  final List<DocManifestItem> manifest;
  final Function(DocManifestItem) onPageChanged;

  const DocViewerScreen({
    super.key,
    required this.manifest,
    this.initialItem,
    required this.onPageChanged,
  });

  @override
  State<DocViewerScreen> createState() => _DocViewerScreenState();
}

class _DocViewerScreenState extends State<DocViewerScreen> {
  String? _markdownContent;
  String? _currentPath;
  bool _isLoading = false;
  DocManifestItem? _previousItem;
  late bool _firstTime = true;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _anchorKeys = {};
  final Map<String, AnchorHeaderBuilder> _builders = {};

  @override
  void didUpdateWidget(DocViewerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialItem != oldWidget.initialItem) {
      _previousItem = oldWidget.initialItem;
      _loadContent();
      _firstTime = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _firstTime = true;
    _loadContent();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getPath(dynamic originalPath, [String basePath = '']) {
    String path = originalPath.toString();
    path = path.replaceAll('%20', ' ');
    String currentBasePath = basePath;
    if (path.startsWith('./') || path.startsWith('../')) {
      for (int i = 0; i < path.split('/').length - 1; i++) {
        if (path.startsWith('./')) {
          path = path.substring(2);
          break;
        }
        if (path.startsWith('../')) {
          currentBasePath = _getParentPath(currentBasePath);
          path = path.substring(3);
        }
      }
      path = '$currentBasePath${currentBasePath.isNotEmpty ? '/' : ''}$path';
    }
    if (debug) {
      logDebug(
          'DocViewerScreen | _getPath | originalPath: $originalPath | basePath: $basePath | currentBasePath: $currentBasePath | Final path: $path');
    }
    return path;
  }

  String _getParentPath(dynamic path) {
    path = path.toString();
    if (path.isEmpty) {
      return '';
    }
    path = path.split('/').length > 1
        ? path.split('/').sublist(0, path.split('/').length - 1).join('/')
        : '';
    return path;
  }

  Future<dynamic> _getFileContent(dynamic path, [String basePath = '']) async {
    if (debug) {
      logDebug(
          'DocViewerScreen | _getFileContent | path: $path | basePath: $basePath');
    }
    dynamic content;
    String fullPath = _getPath(path, basePath);
    if (fullPath.contains('#')) {
      fullPath = fullPath.substring(0, fullPath.indexOf('#'));
      if (debug) {
        logDebug('DocViewerScreen | New path: $fullPath');
      }
    }

    try {
      content = await rootBundle.loadString('assets/docs/$fullPath');
    } catch (e) {
      // Try adding .md if it's missing
      if (!fullPath.endsWith('.md')) {
        try {
          content = await rootBundle.loadString('assets/docs/$fullPath.md');
        } catch (e2) {
          logError(
              '$contentLoadError File "$fullPath.md" (or .md). Error: $e \n[GFC-E-010]');
        }
      } else {
        logError('$contentLoadError File "$fullPath". Error: $e \n[GFC-E-020]');
      }
    }
    return content;
  }

  Future<void> _loadContent() async {
    if (widget.initialItem?.path == null) {
      setState(() {
        _markdownContent = '# Welcome\nSelect a page from the menu.';
        _currentPath = null;
        _isLoading = false;
        if (debug) {
          logDebug('DocViewerScreen | initialItem: ${widget.initialItem}');
        }
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _anchorKeys.clear();
    });

    try {
      final content = await _getFileContent(widget.initialItem!.path);
      setState(() {
        _markdownContent = content ??
            '$contentLoadError File: ${widget.initialItem!.path} \n[DVS-E-020]';
        _currentPath =
            content != null ? _getPath(widget.initialItem!.path) : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _markdownContent =
            '$contentLoadError File: ${widget.initialItem!.path}. Error: $e \n[DVS-E-030]';
        _currentPath = null;
        _isLoading = false;
      });
    }
  }

  String replaceBr(String content) {
    content = content.replaceAll('<BR/>', '\n');
    content = content.replaceAll('<BR>', '\n');
    content = content.replaceAll('<br/>', '\n');
    content = content.replaceAll('<br>', '\n');
    return content;
  }

  String transformContent(String content) {
    return preprocessMarkdownIcons(replaceBr(content));
  }

  void _buildAnchors() {
    // Search for anchors in markdown content
    _anchorKeys.clear();
    _builders.clear();
    (_markdownContent ?? '').split('\n').forEach((line) {
      if (line.startsWith('#')) {
        String anchor = line.split('#').last.trim();
        anchor = anchor.replaceAll(' ', '-').toLowerCase();
        anchor =
            anchor.replaceAll('?', '').replaceAll('(', '').replaceAll(')', '');
        // anchor = '#$anchor';
        if (debug) {
          logDebug('DocViewerScreen | anchor: $anchor');
        }
        _anchorKeys[anchor] = GlobalKey();
      }
    });
    for (var key in _anchorKeys.keys) {
      _builders[key] = AnchorHeaderBuilder(_anchorKeys);
    }
    if (debug) {
      logDebug('DocViewerScreen | _anchorKeys: ${_anchorKeys.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    _buildAnchors();
    return Scaffold(
      appBar: AppBar(
        // Back button (go to the previous visited page)
        leading: _firstTime
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () {
                  if (_previousItem != null) {
                    widget.onPageChanged(_previousItem!);
                  }
                }),
        title: Text(widget.initialItem?.title ?? 'Documentation'),
      ),
      // Drawer (menu at the right side with the documentation index)
      endDrawer: DocDrawer(
        manifest: widget.manifest,
        selectedItem: widget.initialItem,
        onItemSelected: widget.onPageChanged,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              // Show documentation content
              padding: const EdgeInsets.all(10.0),
              controller: _scrollController,
              children: <Widget>[
                MarkdownBody(
                  data: _markdownContent != null
                      ? transformContent(_markdownContent!)
                      : '--No content--',
                  selectable: true,
                  imageBuilder: (uri, title, alt) {
                    String path = uri.toString();
                    String parentPath = _getParentPath(_currentPath ?? "");
                    String assetPath = '';
                    dynamic image;
                    if (path.startsWith('http')) {
                      image = Image.network(path, semanticLabel: alt);
                    } else {
                      // Resolve relative path to assets
                      if (!path.startsWith('./') &&
                          !path.startsWith('../') &&
                          !path.startsWith('/') &&
                          parentPath.isNotEmpty) {
                        path = './$path';
                      }
                      assetPath = 'assets/docs/${_getPath(path, parentPath)}';
                      try {
                        image = Image.asset(assetPath, semanticLabel: alt);
                      } catch (e) {
                        logError(
                            'DocViewerScreen | imageBuilder | path: $path | '
                            'currentPath: $_currentPath | assetPath: $assetPath | Error: $e');
                        image = Text('Image not found: $assetPath',
                            style: const TextStyle(color: Colors.red));
                      }
                    }
                    if (debug) {
                      logDebug('DocViewerScreen | imageBuilder | path: $path | '
                          'currentPath: $_currentPath | assetPath: $assetPath');
                    }
                    return image;
                  },
                  // TODO: fix the anchors link
                  // Let's assume standard markdown links for now.
                  builders: _builders,
                  // builders: {
                  //   'h1': AnchorHeaderBuilder(_anchorKeys),
                  //   'h2': AnchorHeaderBuilder(_anchorKeys),
                  //   'h3': AnchorHeaderBuilder(_anchorKeys),
                  //   'h4': AnchorHeaderBuilder(_anchorKeys),
                  //   'h5': AnchorHeaderBuilder(_anchorKeys),
                  //   'h6': AnchorHeaderBuilder(_anchorKeys),
                  // },
                  onTapLink: (text, href, title) async {
                    if (href == null) {
                      return;
                    }
                    if (href.startsWith('http')) {
                      // Open external link
                      if (debug) {
                        logDebug('DocViewerScreen | href: $href');
                      }
                      try {
                        await launchURLBrowser(href);
                      } catch (e) {
                        logError('DocViewerScreen | Error: $e');
                      }
                    } else if (href.startsWith('#')) {
                      // Scroll to anchor
                      final anchor = href.substring(1);
                      if (debug) {
                        logDebug(
                            'DocViewerScreen | Scrolling to anchor: $anchor | _anchorKeys: ${_anchorKeys.toString()}');
                      }
                      final key = _anchorKeys[anchor];
                      if (key != null) {
                        if (debug) {
                          logDebug('DocViewerScreen | key!: $key');
                        }
                        if (key.currentContext != null) {
                          if (debug) {
                            logDebug(
                                'DocViewerScreen | key.currentContext!: ${key.currentContext}');
                          }
                          Scrollable.ensureVisible(
                            key.currentContext!,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          logError(
                              'DocViewerScreen | Key found but context is null for'
                              ' anchor: $anchor. Widget might be disposed or off-screen.');
                        }
                      } else {
                        if (debug) {
                          logDebug(
                              'DocViewerScreen | Anchor key not found for: $anchor');
                        }
                      }
                    } else {
                      // Open link
                      if (debug) {
                        logDebug('DocViewerScreen | href: $href');
                        logDebug(
                            'DocViewerScreen | manifest: ${widget.manifest.toString()}');
                      }
                      dynamic item;
                      for (var element in widget.manifest) {
                        if (element.children != null) {
                          for (var child in element.children!) {
                            if (child.path == href) {
                              item = child;
                              break;
                            }
                          }
                        } else {
                          if (element.path == href) {
                            item = element;
                            break;
                          }
                        }
                      }
                      if (debug) {
                        logDebug('DocViewerScreen | FOUND item: $item');
                      }
                      if (item != null) {
                        widget.onPageChanged(item);
                      } else {
                        String resolvedPath =
                            _getPath(href, _getParentPath(_currentPath));
                        dynamic content = await _getFileContent(resolvedPath);

                        if (content != null) {
                          // Standardize path - ensure it uses the full resolved path
                          String path = resolvedPath.endsWith('.md')
                              ? resolvedPath
                              : '$resolvedPath.md';

                          // Get the title from the first line
                          String title = content.split('\n').first;
                          title = title.replaceAll('#', '').trim();
                          if (title.isEmpty) title = href.split('/').last;

                          item = DocManifestItem.fromJson({
                            'path': path,
                            'title': title,
                            'children': null,
                            'type': 'file',
                            'source': 'calculated',
                          });
                          widget.onPageChanged(item);
                        }
                      }
                    }
                    if (debug) {
                      logDebug('DocViewerScreen | Link tapped: $href');
                    }
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}

class AnchorHeaderBuilder extends MarkdownElementBuilder {
  final Map<String, GlobalKey> anchorKeys;

  AnchorHeaderBuilder(this.anchorKeys);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final text = element.textContent;
    // Simple slugification: lowercase, remove non-alphanumeric (except hyphens/spaces), replace spaces with hyphens
    // This regex allows alphanumeric, spaces, and hyphens.
    // Then we replace spaces with hyphens.
    // Note: This must match how the markdown generator creates anchors.
    // Standard python-markdown or github slugify might be slightly different.
    // We'll mimic a common one: lowercase, alphanumeric and hyphens only.
    final slug = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '') // Remove invalid chars
        .trim()
        .replaceAll(RegExp(r'\s+'), '-'); // Replace spaces with hyphens

    final key = GlobalKey();
    anchorKeys[slug] = key;

    // We return a SizedBox which wraps the text to provide the context for the key.
    // However, simply returning Text might lose the header styling (h1, h2, etc).
    // MarkdownElementBuilder.visitElementAfter replaces the default rendering.
    // To preserve styling, we use the preferredStyle provided by flutter_markdown.
    return SizedBox(
      key: key,
      width: double.infinity,
      child: Text(
        text,
        style: preferredStyle,
      ),
    );
  }
}
