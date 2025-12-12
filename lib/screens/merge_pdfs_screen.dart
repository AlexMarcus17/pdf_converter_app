import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:overlay_support/overlay_support.dart';
import '../services/pdf_service.dart';

class MergePdfsScreen extends StatefulWidget {
  const MergePdfsScreen({super.key});

  @override
  State<MergePdfsScreen> createState() => _MergePdfsScreenState();
}

class _MergePdfsScreenState extends State<MergePdfsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final PDFService _pdfService = PDFService();
  final List<(String, String)> _selectedPdfs = []; // (path, name)
  bool _isSaving = false;
  bool _isMerged = false;
  File? _mergedPdfFile;
  String? _mergedPdfName;
  bool _isPickingFile =
      false; // Flag to prevent multiple simultaneous file picker requests
  @override
  void initState() {
    super.initState();
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
    _nameController.text =
        'merged_${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
  }

  Future<void> _pickPdf() async {
    // Prevent multiple simultaneous file picker requests
    if (_isPickingFile) {
      return;
    }

    try {
      _isPickingFile = true;
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final file = result.files.single;
        setState(() {
          _selectedPdfs.add((file.path!, file.name));
        });
      }
    } catch (e) {
      toast('Error picking PDF file');
    } finally {
      _isPickingFile = false;
    }
  }

  void _removePdf(int index) {
    setState(() {
      _selectedPdfs.removeAt(index);
    });
  }

  Future<void> _mergePdfs() async {
    FocusScope.of(context).unfocus();
    if (_selectedPdfs.length < 2) {
      toast('Please select at least 2 PDF files');
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      toast('Please enter a file name');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final mergedPdf = await _pdfService.mergePdfs(
        _selectedPdfs.map((pdf) => pdf.$1).toList(),
        fileName: '${_nameController.text.trim()}.pdf',
      );

      setState(() {
        _isMerged = true;
        _mergedPdfFile = mergedPdf;
        _mergedPdfName = '${_nameController.text.trim()}.pdf';
      });
      _pdfService.addPdfToHistory(mergedPdf, _mergedPdfName!);
    } catch (e) {
      toast('Error merging PDFs');
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
          'Merge PDFs',
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
                      // Selected PDFs Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SELECTED PDFs',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.black,
                              letterSpacing: 0.5,
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _pickPdf,
                            child: const Row(
                              children: [
                                Icon(
                                  CupertinoIcons.add_circled_solid,
                                  color: CupertinoColors.systemBlue,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Add PDF',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_selectedPdfs.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: CupertinoColors.systemGrey4,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'No PDFs selected',
                              style: TextStyle(
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _selectedPdfs.length,
                          itemBuilder: (context, index) {
                            final pdf = _selectedPdfs[index];
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
                                      pdf.$2,
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
                                    onPressed: () => _removePdf(index),
                                    child: const Icon(
                                      CupertinoIcons.xmark_circle_fill,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
                      if (_isMerged) ...[
                        const SizedBox(height: 32),
                        const Text(
                          'MERGED PDF',
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
                                      _mergedPdfName ??
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
                                  if (_mergedPdfFile == null) {
                                    toast('No PDF file to download');
                                    return;
                                  }
                                  if (Platform.isAndroid) {
                                    bool? result =
                                        await PDFService.downloadFile(
                                            _mergedPdfFile!, _mergedPdfName!);
                                    if (result == true) {
                                      toast('PDF downloaded successfully');
                                    } else {
                                      toast('Failed to download PDF');
                                    }
                                  } else {
                                    PDFService.downloadFile(
                                        _mergedPdfFile!, _mergedPdfName!);
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
                    onPressed: _selectedPdfs.length >= 2 &&
                            _nameController.text.trim().isNotEmpty
                        ? _mergePdfs
                        : null,
                    color: const Color.fromARGB(255, 255, 0, 0),
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _isSaving
                        ? const CupertinoActivityIndicator()
                        : const Text(
                            'Merge',
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
