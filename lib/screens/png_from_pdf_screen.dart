import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:overlay_support/overlay_support.dart';
import '../services/pdf_service.dart';

class PngFromPdfScreen extends StatefulWidget {
  final String pdfPath;
  final String originalName;

  const PngFromPdfScreen({
    super.key,
    required this.pdfPath,
    required this.originalName,
  });

  @override
  State<PngFromPdfScreen> createState() => _PngFromPdfScreenState();
}

class _PngFromPdfScreenState extends State<PngFromPdfScreen> {
  final PDFService _pdfService = PDFService();
  bool _isGenerating = false;
  bool _isGeneratedImages = false;
  List<String> _generatedImages = [];
  String? _fileSize;

  @override
  void initState() {
    super.initState();
    _getFileSize();
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

  Future<void> _generateImages() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final images = await _pdfService.extractPngFromPdf(widget.pdfPath);
      setState(() {
        _generatedImages = images;
        _isGeneratedImages = true;
        _isGenerating = false;
      });
      int index = 1;
      for (var image in images) {
        _pdfService.addPngsToHistory(
            [File(image)], '${widget.originalName}_$index.png');
        index++;
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      _showErrorDialog('Failed to generate PNG images: $e');
    }
  }

  Future<void> _downloadImage(String imagePath, int index) async {
    try {
      PDFService.downloadImages(
          [imagePath], ['${widget.originalName}_$index.png']);
      toast('Image downloaded successfully!');
    } catch (e) {
      toast('Failed to download image');
    }
  }

  Future<void> _downloadAllImages() async {
    try {
      int index = 1;
      for (var image in _generatedImages) {
        PDFService.downloadImages(
            [image], ['${widget.originalName}_$index.png']);
        index++;
      }

      toast('All images downloaded successfully!');
    } catch (e) {
      toast('Failed to download images: $e');
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
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
          'PNG from PDF',
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

                      if (_isGeneratedImages) ...[
                        const SizedBox(height: 32),
                        const Text(
                          'GENERATED IMAGES',
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
                          itemCount: _generatedImages.length,
                          itemBuilder: (context, index) {
                            final imagePath = _generatedImages[index];
                            final fileName = imagePath.split('/').last;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
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
                                  // Image thumbnail
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(imagePath),
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
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
                                          fileName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: CupertinoColors.black,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Download button
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () =>
                                        _downloadImage(imagePath, index),
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
              // Action Button
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    onPressed: _isGenerating
                        ? null
                        : (_isGeneratedImages
                            ? _downloadAllImages
                            : _generateImages),
                    color: const Color.fromARGB(255, 255, 0, 0),
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _isGenerating
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white)
                        : Text(
                            _isGeneratedImages
                                ? 'Download All'
                                : 'Generate PNGs',
                            style: const TextStyle(
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
