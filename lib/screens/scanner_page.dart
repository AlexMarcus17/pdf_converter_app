import 'package:flutter/cupertino.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/services.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../services/pdf_service.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  void _showPermissionDeniedDialog() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text(
          'Camera Permission Required',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        message: const Text(
          'To scan documents, please enable camera access in Settings.',
          style: TextStyle(fontSize: 14),
        ),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text(
              'Open Settings',
              style: TextStyle(color: CupertinoColors.activeBlue),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _startScanning() async {
    PermissionStatus cameraStatus = await Permission.camera.status;
    if (cameraStatus.isDenied) {
      cameraStatus = await Permission.camera.request();
    }
    if (cameraStatus.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
      return;
    }
    if (cameraStatus.isGranted) {
      try {
        List<String> pictures =
            await CunningDocumentScanner.getPictures() ?? [];
        if (pictures.isNotEmpty) {
          if (!mounted) return;
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (_) => ScannerConvertScreen(scannedImages: pictures),
            ),
          );
        }
      } catch (exception) {
        print('Error scanning: $exception');
      }
    } else {
      _showPermissionDeniedDialog();
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
          'Scanner',
          style: TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.camera_viewfinder,
                size: 80,
                color: Color(0xFF8E8E93),
              ),
              const SizedBox(height: 20),
              const Text(
                'Camera Scanner',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Auto-crop and enhance documents\nusing edge detection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 40),
              CupertinoButton.filled(
                onPressed: _startScanning,
                borderRadius: BorderRadius.circular(12),
                child: const Text(
                  'Tap to Scan',
                  style: TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
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

class ScannerConvertScreen extends StatefulWidget {
  final List<String> scannedImages;
  const ScannerConvertScreen({super.key, required this.scannedImages});

  @override
  State<ScannerConvertScreen> createState() => _ScannerConvertScreenState();
}

class _ScannerConvertScreenState extends State<ScannerConvertScreen> {
  late List<String> _scannedImages;
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
    _scannedImages = List<String>.from(widget.scannedImages);
    _nameController.text =
        'SCN_${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
    _nameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    _nameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showPermissionDeniedDialog() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text(
          'Camera Permission Required',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        message: const Text(
          'To scan documents, please enable camera access in Settings.',
          style: TextStyle(fontSize: 14),
        ),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text(
              'Open Settings',
              style: TextStyle(color: CupertinoColors.activeBlue),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _startScanning() async {
    PermissionStatus cameraStatus = await Permission.camera.status;
    if (cameraStatus.isDenied) {
      cameraStatus = await Permission.camera.request();
    }
    if (cameraStatus.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
      return;
    }
    if (cameraStatus.isGranted) {
      try {
        List<String> pictures =
            await CunningDocumentScanner.getPictures() ?? [];
        if (pictures.isNotEmpty) {
          setState(() {
            _scannedImages.addAll(pictures);
          });
        }
      } catch (exception) {
        print('Error scanning: $exception');
      }
    } else {
      _showPermissionDeniedDialog();
    }
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

  void _removeImage(int index) {
    setState(() {
      _scannedImages.removeAt(index);
    });
  }

  Future<void> _convertToPdf() async {
    FocusScope.of(context).unfocus();
    if (_scannedImages.isEmpty) {
      toast('Please scan at least one image');
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      toast('Please enter a file name');
      return;
    }
    setState(() {
      _isConverting = true;
    });
    try {
      final margin = PDFService.getMarginValue(_selectedMargin);
      final fileName = '${_nameController.text.trim()}.pdf';
      final outputPath = await _pdfService.imagesToPdf(
        _scannedImages,
        margin: margin,
        fileName: fileName,
      );
      _pdfFile = File(outputPath.path);
      _pdfService.addPdfToHistory(outputPath, fileName);
      setState(() {
        _isConverted = true;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      toast('Error converting images to PDF');
    } finally {
      setState(() {
        _isConverting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFFF8F9FA),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Icon(CupertinoIcons.xmark, color: Color(0xFF1A1A1A)),
        ),
        middle: const Text(
          'Scanner',
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
                      if (_scannedImages.isNotEmpty) ...[
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _scannedImages.length,
                          itemBuilder: (context, index) {
                            final imagePath = _scannedImages[index];
                            final fileName =
                                imagePath.split(Platform.pathSeparator).last;
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
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          await _startScanning();
                          // After scanning, do not push again, just update state
                        },
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
                                  CupertinoIcons.camera,
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
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    onPressed: _scannedImages.isNotEmpty ? _convertToPdf : null,
                    color: const Color.fromARGB(255, 255, 0, 0),
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
