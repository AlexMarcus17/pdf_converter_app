import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:overlay_support/overlay_support.dart';
import '../services/pdf_service.dart';

class EncryptPdfScreen extends StatefulWidget {
  final String pdfPath;
  final String originalName;

  const EncryptPdfScreen({
    super.key,
    required this.pdfPath,
    required this.originalName,
  });

  @override
  State<EncryptPdfScreen> createState() => _EncryptPdfScreenState();
}

class _EncryptPdfScreenState extends State<EncryptPdfScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final PDFService _pdfService = PDFService();
  bool _isSaving = false;
  bool _isEncrypted = false;
  String? _fileSize;
  File? _encryptedPdfFile;
  String? _encryptedPdfName;
  @override
  void initState() {
    super.initState();
    _initializeFileName();
    _getFileSize();
    _nameController.addListener(() {
      setState(() {});
    });
    _passwordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _initializeFileName() {
    final fileName = widget.originalName.replaceAll('.pdf', '');
    _nameController.text = '${fileName}_encrypted';
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

  Future<void> _encryptPdf() async {
    FocusScope.of(context).unfocus();
    if (_nameController.text.trim().isEmpty) {
      toast('Please enter a file name');
      return;
    }

    if (_passwordController.text.trim().isEmpty) {
      toast('Please enter a password');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final encryptedPdf = await _pdfService.encryptPdf(
        widget.pdfPath,
        _passwordController.text.trim(),
        fileName: '${_nameController.text.trim()}.pdf',
      );

      setState(() {
        _isEncrypted = true;
        _encryptedPdfFile = encryptedPdf;
        _encryptedPdfName = '${_nameController.text.trim()}.pdf';
      });
      _pdfService.addPdfToHistory(encryptedPdf, _encryptedPdfName!);
    } catch (e) {
      toast('Error encrypting PDF');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSuccessDialog(String message, String filePath) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
        content: Text('$message\nSaved to: $filePath'),
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
          'Encrypt PDF',
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
                      // Original File Section
                      const Text(
                        'ORIGINAL PDF',
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
                            color: CupertinoColors.systemGrey4.withOpacity(1),
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

                      // Password Section
                      const Text(
                        'PASSWORD',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CupertinoTextField(
                        controller: _passwordController,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F4F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CupertinoColors.systemGrey4.withOpacity(1),
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.black,
                        ),
                        placeholder: 'Enter password',
                        placeholderStyle: const TextStyle(
                          color: CupertinoColors.systemGrey,
                        ),
                        obscureText: true,
                      ),
                      if (_isEncrypted) ...[
                        const SizedBox(height: 32),
                        const Text(
                          'ENCRYPTED PDF',
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
                                      _encryptedPdfName ??
                                          '${widget.originalName.replaceAll('.pdf', '')}_encrypted.pdf',
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
                                  if (_encryptedPdfFile == null) {
                                    toast('No PDF file to download');
                                    return;
                                  }
                                  if (Platform.isAndroid) {
                                    bool? result =
                                        await PDFService.downloadFile(
                                      _encryptedPdfFile!,
                                      '${widget.originalName.replaceAll('.pdf', '')}_encrypted.pdf',
                                    );
                                    if (result == true) {
                                      toast('PDF downloaded successfully');
                                    } else {
                                      toast('Failed to download PDF');
                                    }
                                  } else {
                                    PDFService.downloadFile(_encryptedPdfFile!,
                                        '${widget.originalName.replaceAll('.pdf', '')}_encrypted.pdf');
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
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    onPressed: _nameController.text.trim().isNotEmpty &&
                            _passwordController.text.trim().isNotEmpty
                        ? _encryptPdf
                        : null,
                    color: const Color.fromARGB(255, 255, 0, 0),
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _isSaving
                        ? const CupertinoActivityIndicator()
                        : const Text(
                            'Encrypt',
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
