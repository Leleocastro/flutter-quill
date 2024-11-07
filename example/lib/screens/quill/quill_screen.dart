import 'dart:convert' show jsonEncode;
import 'dart:io' as io show Directory, File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart'
    show FlutterQuillEmbeds;
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart' show Share;

import '../../extensions/scaffold_messenger.dart';
import '../shared/widgets/home_screen_button.dart';
import 'my_quill_editor.dart';
import 'my_quill_toolbar.dart';

@immutable
class QuillScreenArgs {
  const QuillScreenArgs({required this.document});

  final Document document;
}

class QuillScreen extends StatefulWidget {
  const QuillScreen({
    required this.args,
    super.key,
  });

  final QuillScreenArgs args;

  static const routeName = '/quill';

  @override
  State<QuillScreen> createState() => _QuillScreenState();
}

class _QuillScreenState extends State<QuillScreen> {
  late final QuillController _controller;
  final _editorFocusNode = FocusNode();
  final _editorScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic(
      config: QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(
          onImagePaste: (imageBytes) async {
            if (kIsWeb) {
              return null;
            }
            // We will save it to system temporary files
            final newFileName =
                'imageFile-${DateTime.now().toIso8601String()}.png';
            final newPath = path.join(
              io.Directory.systemTemp.path,
              newFileName,
            );
            final file = await io.File(
              newPath,
            ).writeAsBytes(imageBytes, flush: true);
            return file.path;
          },
          onGifPaste: (gifBytes) async {
            if (kIsWeb) {
              return null;
            }
            // We will save it to system temporary files
            final newFileName =
                'gifFile-${DateTime.now().toIso8601String()}.gif';
            final newPath = path.join(
              io.Directory.systemTemp.path,
              newFileName,
            );
            final file = await io.File(
              newPath,
            ).writeAsBytes(gifBytes, flush: true);
            return file.path;
          },
        ),
      ),
    );

    _controller.document = widget.args.document;
  }

  @override
  void dispose() {
    _controller.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Quill'),
        actions: [
          IconButton(
            tooltip: 'Share',
            onPressed: () {
              final plainText = _controller.document.toPlainText(
                FlutterQuillEmbeds.defaultEditorBuilders(),
              );
              if (plainText.trim().isEmpty) {
                ScaffoldMessenger.of(context).showText(
                  "We can't share empty document, please enter some text first",
                );
                return;
              }
              Share.share(plainText);
            },
            icon: const Icon(Icons.share),
          ),
          IconButton(
            tooltip: 'Print to log',
            onPressed: () {
              debugPrint(
                jsonEncode(_controller.document.toDelta().toJson()),
              );
              ScaffoldMessenger.of(context).showText(
                'The quill delta json has been printed to the log.',
              );
            },
            icon: const Icon(Icons.print),
          ),
          const HomeScreenButton(),
        ],
      ),
      body: Column(
        children: [
          if (!_controller.readOnly)
            MyQuillToolbar(
              controller: _controller,
              editorFocusNode: _editorFocusNode,
            ),
          Builder(
            builder: (context) {
              return Expanded(
                child: MyQuillEditor(
                  controller: _controller,
                  config: QuillEditorConfig(
                    characterShortcutEvents: standardCharactersShortcutEvents,
                    spaceShortcutEvents: standardSpaceShorcutEvents,
                    searchConfig: const QuillSearchConfig(
                      searchEmbedMode: SearchEmbedMode.plainText,
                    ),
                  ),
                  scrollController: _editorScrollController,
                  focusNode: _editorFocusNode,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(!_controller.readOnly ? Icons.lock : Icons.edit),
        onPressed: () =>
            setState(() => _controller.readOnly = !_controller.readOnly),
      ),
    );
  }
}
