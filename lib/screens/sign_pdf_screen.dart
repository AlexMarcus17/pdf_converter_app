import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:pdfconverter/screens/signature_creator_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/pdf_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SignPdfScreen extends StatefulWidget {
  final String pdfPath;
  final String originalName;

  const SignPdfScreen({
    super.key,
    required this.pdfPath,
    required this.originalName,
  });

  @override
  State<SignPdfScreen> createState() => _SignPdfScreenState();
}

class _SignPdfScreenState extends State<SignPdfScreen> {
  final PDFService _pdfService = PDFService();
  final GlobalKey _pdfContainerKey = GlobalKey();

  List<Map<String, dynamic>> _signatures = [];
  Map<String, dynamic>? _selectedSignature;
  bool _isLoading = false;
  bool _isPdfSigned = false;

  // Signature positioning relative to the PDF content area
  Offset _signaturePosition =
      const Offset(300, 400); // Start in bottom-right area
  Size _signatureSize = const Size(150, 75);
  bool _isResizing = false;

  // PDF state
  int _currentPage = 0;
  int _totalPages = 0;
  PDFViewController? _pdfController;

  // PDF content area tracking
  Rect _pdfContentRect = Rect.zero;

  File? _signedPdfFile;
  String? _signedPdfName;

  @override
  void initState() {
    super.initState();
    _loadSignatures();
    _loadPdfInfo();
  }

  Future<void> _loadPdfInfo() async {
    try {
      final pageCount = await _pdfService.getPdfPageCount(widget.pdfPath);
      setState(() {
        _totalPages = pageCount;
      });
    } catch (e) {
      print('Error loading PDF info: $e');
    }
  }

  Future<void> _loadSignatures() async {
    final prefs = await SharedPreferences.getInstance();
    final signaturesJson = prefs.getStringList('signatures') ?? [];
    setState(() {
      _signatures = signaturesJson
          .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
          .toList();
    });
  }

  void _onPdfViewCreated(PDFViewController controller) {
    _pdfController = controller;
    // Give the PDF some time to render, then calculate content area
    Future.delayed(const Duration(milliseconds: 500), _calculatePdfContentArea);
  }

  void _onPageChanged(int? page, int? total) {
    if (page != null) {
      setState(() {
        _currentPage = page;
      });
      // Recalculate content area when page changes
      Future.delayed(
          const Duration(milliseconds: 300), _calculatePdfContentArea);
    }
  }

  void _onRender(int? pages) {
    if (pages != null) {
      setState(() {
        _totalPages = pages;
      });
    }
  }

  Future<void> _calculatePdfContentArea() async {
    final RenderBox? renderBox =
        _pdfContainerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    try {
      // Get PDF page size
      final pageSize =
          await _pdfService.getPdfPageSize(widget.pdfPath, _currentPage);
      final containerSize = renderBox.size;

      // Calculate how the PDF page is displayed in the container (assuming FitPolicy.WIDTH)
      final pageAspectRatio = pageSize.width / pageSize.height;
      final containerAspectRatio = containerSize.width / containerSize.height;

      double contentWidth, contentHeight, offsetX, offsetY;

      if (pageAspectRatio > containerAspectRatio) {
        // PDF is wider - fit to width
        contentWidth = containerSize.width;
        contentHeight = contentWidth / pageAspectRatio;
        offsetX = 0;
        offsetY = (containerSize.height - contentHeight) / 2;
      } else {
        // PDF is taller - fit to height
        contentHeight = containerSize.height;
        contentWidth = contentHeight * pageAspectRatio;
        offsetX = (containerSize.width - contentWidth) / 2;
        offsetY = 0;
      }

      setState(() {
        _pdfContentRect =
            Rect.fromLTWH(offsetX, offsetY, contentWidth, contentHeight);
      });
    } catch (e) {
      print('Error calculating PDF content area: $e');
    }
  }

  // Convert signature position from container coordinates to PDF page coordinates (0-1 range)
  Map<String, double> _getSignaturePositionForPdf() {
    if (_pdfContentRect == Rect.zero) {
      return {'x': 0.7, 'y': 0.8, 'width': 100.0, 'height': 50.0};
    }

    // Calculate position relative to PDF content area
    final relativeX =
        (_signaturePosition.dx - _pdfContentRect.left) / _pdfContentRect.width;
    final relativeY =
        (_signaturePosition.dy - _pdfContentRect.top) / _pdfContentRect.height;
    final relativeWidth = _signatureSize.width / _pdfContentRect.width;
    final relativeHeight = _signatureSize.height / _pdfContentRect.height;

    return {
      'x': relativeX.clamp(0.0, 1.0),
      'y': relativeY.clamp(0.0, 1.0),
      'width': relativeWidth,
      'height': relativeHeight,
    };
  }

  void _showSignatureSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text(
          'Signatures',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        message: const Text(
          'Select a signature or create a new one',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        actions: [
          ..._signatures.map(
            (signature) => CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedSignature = signature;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.memory(
                    base64Decode(signature['data']),
                    height: 50,
                    color: CupertinoColors.systemGrey4,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    signature['name'],
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => SignatureCreatorScreen(
                    onSignatureSaved: (name, signatureBytes) {
                      _saveSignature(name, signatureBytes);
                    },
                  ),
                ),
              );
            },
            child: const Text('Create New Signature',
                style: const TextStyle(
                  color: CupertinoColors.systemGrey4,
                )),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _saveSignature(String name, Uint8List signatureBytes) async {
    final signature = {
      'name': name,
      'data': base64Encode(signatureBytes),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final prefs = await SharedPreferences.getInstance();
    final signaturesJson = prefs.getStringList('signatures') ?? [];
    signaturesJson.add(jsonEncode(signature));
    await prefs.setStringList('signatures', signaturesJson);

    setState(() {
      _signatures.add(signature);
      _selectedSignature = signature;
    });
  }

  Future<void> _signPdf() async {
    if (_selectedSignature == null) {
      _showErrorDialog('Please select a signature first');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final signatureBytes = base64Decode(_selectedSignature!['data']);
      final pdfPosition = _getSignaturePositionForPdf();

      final signedPdfBytes = await _pdfService.signPdf(
        widget.pdfPath,
        signatureBytes,
        pdfPosition['x']!,
        pdfPosition['y']!,
        pdfPosition['width']!,
        pdfPosition['height']!,
        pageIndex: _currentPage,
      );

      final docsDir = await getApplicationDocumentsDirectory();
      final outputFileName = _generateFileName('signed', 'pdf');
      final file = File('${docsDir.path}/$outputFileName');
      setState(() {
        _signedPdfName = outputFileName;
      });
      await file.writeAsBytes(signedPdfBytes);
      setState(() {
        _signedPdfFile = file;
      });

      setState(() {
        _isLoading = false;
        _isPdfSigned = true;
      });
      _pdfService.addPdfToHistory(file, outputFileName);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to sign PDF: $e');
    }
  }

  String _generateFileName(String prefix, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$timestamp.$extension';
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

  Widget _buildResizeHandle(Alignment alignment) {
    return Positioned(
      top: alignment == Alignment.topLeft || alignment == Alignment.topRight
          ? -12
          : null,
      bottom: alignment == Alignment.bottomLeft ||
              alignment == Alignment.bottomRight
          ? -12
          : null,
      left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
          ? -12
          : null,
      right:
          alignment == Alignment.topRight || alignment == Alignment.bottomRight
              ? -12
              : null,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() {
            _isResizing = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            final delta = details.delta;

            if (alignment == Alignment.bottomRight) {
              _signatureSize = Size(
                (_signatureSize.width + delta.dx).clamp(50.0, 300.0),
                (_signatureSize.height + delta.dy).clamp(25.0, 150.0),
              );
            } else if (alignment == Alignment.bottomLeft) {
              final newWidth =
                  (_signatureSize.width - delta.dx).clamp(50.0, 300.0);
              _signaturePosition = Offset(
                _signaturePosition.dx + (_signatureSize.width - newWidth),
                _signaturePosition.dy,
              );
              _signatureSize = Size(
                newWidth,
                (_signatureSize.height + delta.dy).clamp(25.0, 150.0),
              );
            } else if (alignment == Alignment.topRight) {
              final newHeight =
                  (_signatureSize.height - delta.dy).clamp(25.0, 150.0);
              _signaturePosition = Offset(
                _signaturePosition.dx,
                _signaturePosition.dy + (_signatureSize.height - newHeight),
              );
              _signatureSize = Size(
                (_signatureSize.width + delta.dx).clamp(50.0, 300.0),
                newHeight,
              );
            } else if (alignment == Alignment.topLeft) {
              final newWidth =
                  (_signatureSize.width - delta.dx).clamp(50.0, 300.0);
              final newHeight =
                  (_signatureSize.height - delta.dy).clamp(25.0, 150.0);
              _signaturePosition = Offset(
                _signaturePosition.dx + (_signatureSize.width - newWidth),
                _signaturePosition.dy + (_signatureSize.height - newHeight),
              );
              _signatureSize = Size(newWidth, newHeight);
            }
          });
        },
        onPanEnd: (_) {
          setState(() {
            _isResizing = false;
          });
        },
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: CupertinoColors.systemBlue,
            border: Border.all(color: CupertinoColors.white, width: 2),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignedPdfWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 12),
          const Text(
            'SIGNED PDF',
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
                  color: CupertinoColors.systemGrey4.withOpacity(0.3),
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
                        _signedPdfName ??
                            '${widget.originalName.replaceAll('.pdf', '')}_signed.pdf',
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
                    if (_signedPdfFile == null) {
                      toast('No PDF file to download');
                      return;
                    }
                    if (Platform.isAndroid) {
                      bool? result = await PDFService.downloadFile(
                          _signedPdfFile!, '${widget.originalName}_signed.pdf');
                      if (result == true) {
                        toast('PDF downloaded successfully');
                      } else {
                        toast('Failed to download PDF');
                      }
                    } else {
                      PDFService.downloadFile(
                          _signedPdfFile!, '${widget.originalName}_signed.pdf');
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
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CupertinoActivityIndicator(
        radius: 20,
        color: CupertinoColors.systemBlue,
      ),
    );
  }

  Widget _buildPdfEditingState() {
    return Column(
      children: [
        // Page indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Page ${_currentPage + 1} of $_totalPages',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              if (_selectedSignature != null)
                Text(
                  'Signature: ${_selectedSignature!['name']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.systemBlue,
                  ),
                ),
            ],
          ),
        ),
        // PDF with signature overlay
        Expanded(
          child: Container(
            key: _pdfContainerKey,
            child: Stack(
              children: [
                PDFView(
                  filePath: widget.pdfPath,
                  enableSwipe: true,
                  swipeHorizontal: true,
                  autoSpacing: true,
                  pageFling: true,
                  pageSnap: true,
                  defaultPage: _currentPage,
                  fitPolicy: FitPolicy.WIDTH,
                  preventLinkNavigation: true,
                  backgroundColor: Color(0xFFF8F9FA),
                  onViewCreated: _onPdfViewCreated,
                  onPageChanged: _onPageChanged,
                  onRender: _onRender,
                ),
                if (_selectedSignature != null)
                  Positioned(
                    left: _signaturePosition.dx,
                    top: _signaturePosition.dy,
                    child: Stack(
                      children: [
                        GestureDetector(
                          onPanUpdate: !_isResizing
                              ? (details) {
                                  setState(() {
                                    _signaturePosition += details.delta;
                                  });
                                }
                              : null,
                          child: Container(
                            width: _signatureSize.width,
                            height: _signatureSize.height,
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemBackground
                                  .withOpacity(0.0),
                              border: Border.all(
                                color:
                                    CupertinoColors.systemBlue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Image.memory(
                              base64Decode(_selectedSignature!['data']),
                              width: _signatureSize.width,
                              height: _signatureSize.height,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        _buildResizeHandle(Alignment.topLeft),
                        _buildResizeHandle(Alignment.topRight),
                        _buildResizeHandle(Alignment.bottomLeft),
                        _buildResizeHandle(Alignment.bottomRight),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Bottom buttons
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  onPressed: _showSignatureSheet,
                  color: CupertinoColors.systemBlue,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Text(
                    'Signatures',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CupertinoButton(
                  onPressed: _selectedSignature != null ? _signPdf : null,
                  color: const Color.fromARGB(255, 255, 0, 0),
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Sign Page ${_currentPage + 1}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _selectedSignature != null
                          ? CupertinoColors.white
                          : const Color.fromARGB(255, 174, 174, 174),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFFF8F9FA),
        border: null,
        middle: Text(
          'Sign PDF',
          style: const TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _isPdfSigned
                ? _buildSignedPdfWidget()
                : _buildPdfEditingState(),
      ),
    );
  }
}
