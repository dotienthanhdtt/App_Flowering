import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/translation-service.dart';
import '../../../shared/models/word-translation-model.dart';
import '../../../shared/widgets/word-translation-sheet.dart';

/// Stateful wrapper that loads word translation and renders the sheet.
/// Shows loading → populated/error states automatically.
class WordTranslationSheetLoader extends StatefulWidget {
  final String word;
  final String? sessionToken;

  const WordTranslationSheetLoader({
    super.key,
    required this.word,
    this.sessionToken,
  });

  @override
  State<WordTranslationSheetLoader> createState() =>
      _WordTranslationSheetLoaderState();
}

class _WordTranslationSheetLoaderState
    extends State<WordTranslationSheetLoader> {
  WordTranslationModel? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result =
          await Get.find<TranslationService>().translateWord(
            widget.word,
            sessionToken: widget.sessionToken,
          );
      if (mounted) setState(() => _data = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _retry() {
    setState(() {
      _data = null;
      _error = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return WordTranslationSheet(
      word: widget.word,
      data: _data,
      error: _error,
      onRetry: _retry,
      onClose: () => Navigator.pop(context),
    );
  }
}
