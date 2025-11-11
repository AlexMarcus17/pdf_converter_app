import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:overlay_support/overlay_support.dart';
import '../services/pdf_service.dart';

class ImagesToPdfScreen extends StatefulWidget {
  final List<XFile>? selectedImages;

  const ImagesToPdfScreen({super.key, this.selectedImages});

  @override
  State<ImagesToPdfScreen> createState() => _ImagesToPdfScreenState();
}

class _ImagesToPdfScreenState extends State<ImagesToPdfScreen> {
  final List<XFile> _selectedImages = [];
  final TextEditingController _nameController = TextEditingController();
  String _selectedMargin = 'None';
  final PDFService _pdfService = PDFService();
  bool _isConverting = false;
  bool _isConverted = false;
  final ScrollController _scrollController = ScrollController();
  File? _pdfFile;

  @override
  void initState() {
    super.initState();
    _nameController.text =
        'IMG_${DateTime.now().millisecondsSinceEpoch ~/ 1000}';

    // Add any pre-selected images
    if (widget.selectedImages != null) {
      _selectedImages.addAll(widget.selectedImages!);
    }
    _nameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to pick images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
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

  Future<void> _convertToPdf() async {
    if (_selectedImages.isEmpty) {
      _showErrorDialog('Please select at least one image');
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter a file name');
      return;
    }

    setState(() {
      _isConverting = true;
    });

    try {
      final imagePaths = _selectedImages.map((image) => image.path).toList();
      final margin = PDFService.getMarginValue(_selectedMargin);
      final fileName = '${_nameController.text.trim()}.pdf';

      final outputPath = await _pdfService.imagesToPdf(
        imagePaths,
        margin: margin,
        fileName: fileName,
      );
      _pdfService.addPdfToHistory(outputPath, fileName);

      setState(() {
        _isConverted = true;
        _pdfFile = outputPath;
      });
      Future.delayed(Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      _showErrorDialog('Failed to convert images to PDF: $e');
    } finally {
      setState(() {
        _isConverting = false;
      });
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
          'Images to PDF',
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
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selected Images Section
                      if (_selectedImages.isNotEmpty) ...[
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            final image = _selectedImages[index];

                            final String fileName = image.name
                                    .startsWith('image_picker_')
                                ? image.name.replaceFirst('image_picker_', '')
                                : image.name;

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
                                      File(image.path),
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // File name
                                  Expanded(
                                    child: Text(
                                      fileName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: CupertinoColors.black,
                                      ),
                                    ),
                                  ),
                                  // Remove button
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () => _removeImage(index),
                                    child: const Icon(
                                      CupertinoIcons.delete,
                                      size: 22,
                                      color: CupertinoColors.systemRed,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],

                      // Add More Images Button
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _pickImages,
                        child: Container(
                          padding: const EdgeInsets.all(16),
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
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Color.fromARGB(255, 0, 0, 0),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.add,
                                  color: CupertinoColors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Add More Images',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

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
                      if (_isConverted) ...[
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

              // Convert Button
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    onPressed:
                        _selectedImages.isNotEmpty ? _convertToPdf : null,
                    color: Color.fromARGB(255, 255, 0, 0),
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _isConverting
                        ? const Center(
                            child: CupertinoActivityIndicator(),
                          )
                        : const Text(
                            'Convert',
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
