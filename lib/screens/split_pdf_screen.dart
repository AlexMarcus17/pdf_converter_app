import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:overlay_support/overlay_support.dart';
import '../services/pdf_service.dart';

class SplitPdfScreen extends StatefulWidget {
  final String pdfPath;
  final String originalName;

  const SplitPdfScreen({
    super.key,
    required this.pdfPath,
    required this.originalName,
  });

  @override
  State<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends State<SplitPdfScreen> {
  final TextEditingController _pagesController = TextEditingController();
  final PDFService _pdfService = PDFService();
  bool _isSaving = false;
  String? _fileSize;
  int? _pageCount;
  List<File> _splitPdfFiles = [];
  bool _isSplit = false;
  String _baseName = '';

  @override
  void initState() {
    super.initState();
    _initializeFileName();
    _getFileInfo();
    _pagesController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    _pagesController.dispose();
    super.dispose();
  }

  void _initializeFileName() {
    final fileName = widget.originalName.replaceAll('.pdf', '');
    _baseName = fileName;
  }

  Future<void> _getFileInfo() async {
    try {
      final size = await _pdfService.getPdfFileSize(widget.pdfPath);
      final pageCount = await _pdfService.getPdfPageCount(widget.pdfPath);
      setState(() {
        _fileSize = size;
        _pageCount = pageCount;
      });
    } catch (e) {
      // Ignore errors
    }
  }

  List<List<int>> _parsePageRanges(String input) {
    final List<List<int>> ranges = [];
    final parts = input.split(',');
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.contains('-')) {
        final range = trimmed.split('-');
        if (range.length == 2) {
          final start = int.tryParse(range[0].trim());
          final end = int.tryParse(range[1].trim());
          if (start != null && end != null && start <= end) {
            ranges.add([for (int i = start; i <= end; i++) i]);
          }
        }
      } else {
        final page = int.tryParse(trimmed);
        if (page != null) {
          ranges.add([page]);
        }
      }
    }
    return ranges;
  }

  bool _validatePageNumbers(List<int> pages) {
    if (pages.isEmpty) return false;
    if (_pageCount == null) return false;
    for (final page in pages) {
      if (page < 1 || page > _pageCount!) {
        return false;
      }
    }
    return true;
  }

  Future<void> _splitPdf() async {
    FocusScope.of(context).unfocus();
    if (_pagesController.text.trim().isEmpty) {
      toast('Please enter page numbers');
      return;
    }

    final ranges = _parsePageRanges(_pagesController.text);
    if (ranges.isEmpty) {
      toast('Invalid page numbers');
      return;
    }

    // Validate all page numbers in all ranges
    for (final range in ranges) {
      if (!_validatePageNumbers(range)) {
        toast(
            'Invalid page numbers. Please enter numbers between 1 and $_pageCount');
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _splitPdfFiles.clear();
      _isSplit = false;
    });

    try {
      // Use the updated splitPdf method that accepts List<List<int>> and returns List<File>
      final splitFiles = await _pdfService.splitPdf(
        widget.pdfPath,
        ranges,
        baseFileName: _baseName,
      );

      // Store the File objects directly
      _splitPdfFiles = splitFiles;

      setState(() {
        _isSplit = true;
      });
      int index = 1;
      for (var file in splitFiles) {
        _pdfService.addPdfToHistory(file, '${_baseName}_$index.pdf');
        index++;
      }
    } catch (e) {
      toast('Error splitting PDF');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xFFF8F9FA),
        border: null,
        middle: Text(
          'Split PDF',
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
                                  if (_fileSize != null ||
                                      _pageCount != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_fileSize ?? ''} ${_pageCount != null ? '• $_pageCount pages' : ''}',
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

                      // Pages Section
                      const Text(
                        'PAGES (e.g. 1, 3-5, 7)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.black,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 12),
                      CupertinoTextField(
                        controller: _pagesController,
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
                        placeholder: 'Enter page numbers, separated by commas',
                        placeholderStyle: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 14,
                        ),
                        keyboardType: TextInputType.text,
                      ),

                      if (_isSplit && _splitPdfFiles.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        const Text(
                          'SPLIT PDFs',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _splitPdfFiles.length,
                          itemBuilder: (context, index) {
                            final file = _splitPdfFiles[index];
                            final name = file.path.split('/').last;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
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
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.systemRed,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        CupertinoIcons.doc_text_fill,
                                        color: CupertinoColors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: CupertinoColors.black,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () async {
                                      if (Platform.isAndroid) {
                                        bool? result =
                                            await PDFService.downloadFile(
                                                _splitPdfFiles[index],
                                                '${_baseName}_$index.pdf');
                                        if (result == true) {
                                          toast('PDF downloaded successfully');
                                        } else {
                                          toast('Failed to download PDF');
                                        }
                                      } else {
                                        PDFService.downloadFile(
                                            _splitPdfFiles[index],
                                            '${_baseName}_$index.pdf');
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
                            );
                          },
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
                    onPressed:
                        _pagesController.text.trim().isNotEmpty && !_isSaving
                            ? _splitPdf
                            : null,
                    color: const Color.fromARGB(255, 255, 0, 0),
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _isSaving
                        ? const CupertinoActivityIndicator()
                        : const Text(
                            'Split',
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
