import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:overlay_support/overlay_support.dart';
import '../services/pdf_service.dart';

class TextToPdfScreen extends StatefulWidget {
  const TextToPdfScreen({super.key});

  @override
  State<TextToPdfScreen> createState() => _TextToPdfScreenState();
}

class _TextToPdfScreenState extends State<TextToPdfScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String _selectedMargin = 'Normal';
  final PDFService _pdfService = PDFService();
  bool _isGenerating = false;
  bool _isGenerated = false;
  final ScrollController _scrollController = ScrollController();
  File? _pdfFile;

  @override
  void initState() {
    super.initState();
    _nameController.text =
        'text_${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
    _textController.addListener(() {
      setState(() {});
    });
    _nameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    // Hide keyboard when exiting the page
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    _textController.dispose();
    _nameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showMarginPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Margin'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedMargin = 'None');
              Navigator.pop(context);
            },
            child: const Text('None (0")'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedMargin = 'Small');
              Navigator.pop(context);
            },
            child: const Text('Small (0.5")'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedMargin = 'Normal');
              Navigator.pop(context);
            },
            child: const Text('Normal (1")'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedMargin = 'Large');
              Navigator.pop(context);
            },
            child: const Text('Large (1.5")'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _generatePdf() async {
    // Hide keyboard when Generate PDF is pressed
    FocusScope.of(context).unfocus();

    if (_textController.text.trim().isEmpty) {
      toast('Please enter some text');
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      toast('Please enter a file name');
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final margin = PDFService.getMarginValue(_selectedMargin);
      final fileName = '${_nameController.text.trim()}.pdf';

      final outputPath = await _pdfService.textToPdf(
        _textController.text.trim(),
        margin: margin,
        fileName: fileName,
      );

      setState(() {
        _isGenerated = true;
        _pdfFile = outputPath;
      });
      _pdfService.addPdfToHistory(outputPath, fileName);
      // Scroll to show the generated PDF
      Future.delayed(Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      toast('Error generating PDF');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _showSuccessDialog(String filePath) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
        content: Text('PDF created successfully!\nSaved to: $filePath'),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to home screen
            },
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
          'Text to PDF',
          style: TextStyle(
            color: CupertinoColors.black,
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
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text Input Section
                      Container(
                        height: 280,
                        margin: const EdgeInsets.only(bottom: 16),
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
                        child: CupertinoTextField(
                          controller: _textController,
                          maxLines: null,
                          // minLines: 8,
                          decoration: const BoxDecoration(),
                          padding: const EdgeInsets.all(16),
                          style: const TextStyle(
                            fontSize: 16,
                            color: CupertinoColors.black,
                            height: 1.5,
                          ),
                          placeholder: 'Start by typing something...',
                          placeholderStyle: const TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      // PDF Settings Section
                      const Text(
                        'MARGIN',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _showMarginPicker,
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
                                _selectedMargin,
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

                      const SizedBox(height: 32),

                      // Name Section
                      const Text(
                        'NAME',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CupertinoTextField(
                        controller: _nameController,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F4F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CupertinoColors.systemBrown.withOpacity(0.3),
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.black,
                        ),
                        placeholder: 'Enter file name',
                        placeholderStyle: const TextStyle(
                          color: CupertinoColors.systemGrey,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Generated PDF Section
                      if (_isGenerated) ...[
                        const Text(
                          'GENERATED PDF',
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
                                      '${_nameController.text.trim()}.pdf',
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
                                  if (_pdfFile == null) {
                                    toast('No PDF file to download');
                                    return;
                                  }
                                  if (Platform.isAndroid) {
                                    bool? result = await PDFService.downloadFile(
                                        _pdfFile!,
                                        '${_nameController.text.trim()}.pdf');
                                    if (result == true) {
                                      toast('PDF downloaded successfully');
                                    } else {
                                      toast('Failed to download PDF');
                                    }
                                  } else {
                                    PDFService.downloadFile(_pdfFile!,
                                        '${_nameController.text.trim()}.pdf');
                                  }
                                },
                                child: const Icon(
                                  CupertinoIcons.cloud_download,
                                  color: Color.fromARGB(255, 255, 0, 0),
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

              // Generate Button
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    onPressed: _textController.text.trim().isNotEmpty
                        ? _generatePdf
                        : null,
                    color: Color.fromARGB(255, 255, 0, 0),
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _isGenerating
                        ? const Center(
                            child: CupertinoActivityIndicator(),
                          )
                        : const Text(
                            'Generate PDF',
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
