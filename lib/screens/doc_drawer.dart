import 'package:flutter/material.dart';

import '../models/doc_manifest.dart';

class DocDrawer extends StatefulWidget {
  final List<DocManifestItem> manifest;
  final Function(DocManifestItem) onItemSelected;
  final DocManifestItem? selectedItem;
  final Function(String) onLangChanged;
  final String lang;

  const DocDrawer({
    super.key,
    required this.manifest,
    required this.onItemSelected,
    this.selectedItem,
    required this.lang,
    required this.onLangChanged,
  });

  @override
  State<DocDrawer> createState() => _DocDrawerState();
}

class _DocDrawerState extends State<DocDrawer> {
  String lang = '';

  @override
  void initState() {
    super.initState();
    lang = widget.lang;
  }

  Widget _buildItem(DocManifestItem item, BuildContext context,
      [int depth = 0]) {
    if (item.type == 'section') {
      return ExpansionTile(
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16 - (depth * 1.0), // Slightly smaller for deeper levels
          ),
        ),
        childrenPadding: const EdgeInsets.only(left: 16.0),
        children: item.children
                ?.map((child) => _buildItem(child, context, depth + 1))
                .toList() ??
            [],
      );
    } else {
      final isSelected = widget.selectedItem == item;
      return ListTile(
        selected: isSelected,
        selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
        contentPadding:
            EdgeInsets.only(left: 16.0 + (depth * 16.0), right: 16.0),
        title: Text(item.title),
        onTap: () {
          widget.onItemSelected(item);
          Navigator.pop(context); // Close drawer
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + 2.0,
              left: 15.0,
              bottom: 17.0,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image(
                  width: 90,
                  height: 90,
                  image: AssetImage(
                      'assets/docs_$lang/images/gs_ai_logo_circle.png'),
                ),
                const SizedBox(width: 12),
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GenericSuite',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Documentation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // const SizedBox(height: 10),
          Row(
            // mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 5),
              SizedBox(
                width: 90,
                child: ListTile(
                  title: const Text('English', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    lang = 'en';
                    widget.onLangChanged(lang);
                    setState(() {});
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: 2),
              SizedBox(
                width: 90,
                child: ListTile(
                  title: const Text('Spanish', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    lang = 'es';
                    widget.onLangChanged(lang);
                    setState(() {});
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
          // const SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 0.0, left: 5.0, bottom: 5.0),
              shrinkWrap: true,
              children: widget.manifest
                  .where((item) => item.source == 'nav' && item.lang == lang)
                  .map((item) => _buildItem(item, context))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
