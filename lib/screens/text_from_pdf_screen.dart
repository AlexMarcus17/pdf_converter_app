import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:path_provider/path_provider.dart';
import '../services/pdf_service.dart';

class TextFromPdfScreen extends StatefulWidget {
  final String pdfPath;
  final String originalName;

  const TextFromPdfScreen({
    super.key,
    required this.pdfPath,
    required this.originalName,
  });

  @override
  State<TextFromPdfScreen> createState() => _TextFromPdfScreenState();
}

class _TextFromPdfScreenState extends State<TextFromPdfScreen> {
  final PDFService _pdfService = PDFService();
  bool _isExtracting = false;
  bool _isTextExtracted = false;
  String? _extractedText;
  String? _fileSize;
  String _selectedFormat = '.txt';
  File? _textFile;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getFileSize();
    _initializeFileName();
    _nameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    _nameController.dispose();
    super.dispose();
  }

  void _initializeFileName() {
    _nameController.text = widget.originalName.replaceAll('.pdf', '');
  }

  Future<void> _getFileSize() async {
    try {
      final size = await _pdfService.getPdfFileSize(widget.pdfPath);
      setState(() {
        _fileSize = size;
      });
    } catch (e) {
      // Ignore size error
    }
  }

  Future<void> _extractText() async {
    if (_isExtracting) return;

    setState(() {
      _isExtracting = true;
    });

    try {
      final text = await _pdfService.extractTextFromPdf(widget.pdfPath);

      await _saveTextToFile(text);
      setState(() {
        _extractedText = text;
        _isTextExtracted = true;
        _isExtracting = false;
      });
    } catch (e) {
      setState(() {
        _isExtracting = false;
      });
      toast('Error extracting text');
    }
  }

  Future<void> _saveTextToFile(String text) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final fileName = '${widget.originalName.replaceAll('.pdf', '')}.txt';
      final file = File('${docsDir.path}/$fileName');
      await file.writeAsString(text);
      setState(() {
        _textFile = file;
      });
      _pdfService.addPlainTextToHistory(text, fileName);
    } catch (e) {
      toast('Error extracting text');
    }
  }

  void _showFormatPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Format'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedFormat = '.txt');
              Navigator.pop(context);
            },
            child: const Text('.txt file'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedFormat = 'plain');
              Navigator.pop(context);
            },
            child: const Text('Plain text'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xFFF8F9FA),
        border: null,
        middle: Text(
          'Text from PDF',
          style: TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Original PDF Section
                      const Text(
                        'SELECTED PDF',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  CupertinoColors.systemGrey4.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // PDF thumbnail/icon
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemRed,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.doc_text_fill,
                                    color: CupertinoColors.white,
                                    size: 24,
                                  ),
                                  Text(
                                    'PDF',
                                    style: TextStyle(
                                      color: CupertinoColors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // File info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.originalName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: CupertinoColors.black,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_fileSize != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _fileSize!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: CupertinoColors.systemGrey,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Format Section
                      const Text(
                        'FORMAT',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      GestureDetector(
                        onTap: _showFormatPicker,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F4F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  CupertinoColors.systemBrown.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedFormat == '.txt'
                                    ? '.txt file'
                                    : 'Plain text',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: CupertinoColors.black,
                                ),
                              ),
                              const Icon(
                                CupertinoIcons.chevron_down,
                                color: CupertinoColors.systemGrey,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (_isTextExtracted && _selectedFormat == 'plain') ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'EXTRACTED TEXT',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => {
                                Clipboard.setData(
                                  ClipboardData(text: _extractedText ?? ''),
                                ),
                                toast('Text copied to clipboard'),
                              },
                              child: const Row(
                                children: [
                                  Icon(CupertinoIcons.square_on_square,
                                      size: 16),
                                  SizedBox(width: 4),
                                  Text('Copy'),
                                  SizedBox(width: 4),
                                ],
                              ),
                            ),
                          ],
                        ),
                        //const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F4F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  CupertinoColors.systemBrown.withOpacity(0.3),
                            ),
                          ),
                          child: SelectableText(
                            _extractedText ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: CupertinoColors.black,
                            ),
                          ),
                        ),
                      ],
                      if (_isTextExtracted && _selectedFormat == '.txt') ...[
                        const SizedBox(height: 32),
                        const Text(
                          'TEXT FILE',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.systemGrey4
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // PDF thumbnail/icon
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemBlue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.doc_text_fill,
                                      color: CupertinoColors.white,
                                      size: 24,
                                    ),
                                    Text(
                                      'TXT',
                                      style: TextStyle(
                                        color: CupertinoColors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // File info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${widget.originalName.replaceAll('.pdf', '')}.txt',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: CupertinoColors.black,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () async {
                                  if (_textFile == null) {
                                    toast('No TXT file to download');
                                    return;
                                  }
                                  if (Platform.isAndroid) {
                                    bool? result = await PDFService.downloadFile(
                                        _textFile!,
                                        '${_nameController.text.trim()}.txt');
                                    if (result == true) {
                                      toast('TXT downloaded successfully');
                                    } else {
                                      toast('Failed to download TXT file');
                                    }
                                  } else {
                                    PDFService.downloadFile(_textFile!,
                                        '${_nameController.text.trim()}.txt');
                                  }
                                },
                                child: const Icon(
                                  CupertinoIcons.cloud_download,
                                  color: CupertinoColors.systemBlue,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Action Button
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    onPressed: _isExtracting ? null : _extractText,
                    color: const Color.fromARGB(255, 255, 0, 0),
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _isExtracting
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white)
                        : const Text(
                            'Extract Text',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
