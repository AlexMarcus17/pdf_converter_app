import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:path_provider/path_provider.dart';
import '../services/pdf_service.dart';

class UrlToPdfScreen extends StatefulWidget {
  final File pdfPath;
  final String originalUrl;

  const UrlToPdfScreen({
    super.key,
    required this.pdfPath,
    required this.originalUrl,
  });

  @override
  State<UrlToPdfScreen> createState() => _UrlToPdfScreenState();
}

class _UrlToPdfScreenState extends State<UrlToPdfScreen> {
  final TextEditingController _nameController = TextEditingController();
  final PDFService _pdfService = PDFService();
  bool _isSaving = false;
  String? _fileSize;
  File? _pdfFile;

  @override
  void initState() {
    super.initState();
    _initializeFileName();
    _getFileSize();
  }

  @override
  void dispose() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    _nameController.dispose();
    super.dispose();
  }

  void _initializeFileName() {
    // Extract filename from URL or use timestamp
    String fileName;
    try {
      final uri = Uri.parse(widget.originalUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        fileName = pathSegments.last.replaceAll('.pdf', '');
      } else {
        fileName = 'pdf_${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
      }
    } catch (e) {
      fileName = 'pdf_${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
    }
    _nameController.text = fileName;
  }

  Future<void> _getFileSize() async {
    try {
      final size = await _pdfService.getPdfFileSize(widget.pdfPath.path);
      setState(() {
        _fileSize = size;
      });
    } catch (e) {
      // Ignore size error
    }
  }

  Future<void> _savePdf() async {
    if (_nameController.text.trim().isEmpty) {
      toast('Please enter a file name');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final newFileName = '${_nameController.text.trim()}.pdf';
      final newPath = '${docsDir.path}/$newFileName';

      // Copy file to new location with new name
      final originalFile = File(widget.pdfPath.path);
      await originalFile.copy(newPath);

      _pdfService.addPdfToHistory(File(newPath), newFileName);
      _pdfFile = File(newPath);
      if (_pdfFile == null) {
        toast('No PDF file to download');
        return;
      }
      if (Platform.isAndroid) {
        bool? result = await PDFService.downloadFile(
            _pdfFile!, '${_nameController.text.trim()}.pdf');
        if (result == true) {
          toast('PDF downloaded successfully');
        } else {
          toast('Failed to download PDF');
        }
      } else {
        PDFService.downloadFile(
            _pdfFile!, '${_nameController.text.trim()}.pdf');
      }
    } catch (e) {
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSuccessDialog(String filePath) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
        content: Text('PDF saved successfully!\nSaved to: $filePath'),
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
          'Download PDF',
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
          child: _isSaving
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CupertinoActivityIndicator(radius: 20),
                      SizedBox(height: 16),
                      Text(
                        'Saving PDF...',
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Original File Section
                            const Text(
                              'DOWNLOADED PDF',
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_nameController.text}.pdf',
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
                                  // Edit button

                                  const SizedBox(width: 8),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Convert Button
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          onPressed: _nameController.text.trim().isNotEmpty
                              ? _savePdf
                              : null,
                          color: Color.fromARGB(255, 255, 0, 0),
                          borderRadius: BorderRadius.circular(12),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: const Text(
                            'Download',
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
