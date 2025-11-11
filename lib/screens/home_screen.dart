import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdfconverter/services/db_helper.dart';
import '../services/pdf_service.dart';
import 'images_to_pdf_screen.dart';
import 'text_to_pdf_screen.dart';
import 'url_to_pdf_screen.dart';
import 'jpg_from_pdf_screen.dart';
import 'png_from_pdf_screen.dart';
import 'text_from_pdf_screen.dart';
import 'sign_pdf_screen.dart';
import 'encrypt_pdf_screen.dart';
import 'merge_pdfs_screen.dart';
import 'split_pdf_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PDFService _pdfService = PDFService();
  @override
  void initState() {
    super.initState();
    _pdfService.setDbHelper(DBHelper());
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xFFFFFFFF),
        middle: Text(
          'Home',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        border: null,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildSectionHeader('From PDF'),
                  const SizedBox(height: 16),
                  _buildToolsRow([
                    _ToolItem(
                        'assets/jpg.png', 'JPG from PDF', _handleJpgFromPdf),
                    _ToolItem(
                        'assets/png.png', 'PNG from PDF', _handlePngFromPdf),
                    _ToolItem(
                        'assets/text.png', 'Text from PDF', _handleTextFromPdf),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionHeader('To PDF'),
                  const SizedBox(height: 16),
                  _buildToolsRow([
                    _ToolItem('assets/fromphotos.png', 'Images to PDF',
                        _handleImagesToPdf),
                    _ToolItem(
                        'assets/fromtext.png', 'Text to PDF', _handleTextToPdf),
                    _ToolItem(
                        'assets/fromweb.png', 'URL to PDF', _handleUrlToPdf),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Other Tools'),
                  const SizedBox(height: 16),
                  _buildToolsRow([
                    _ToolItem('assets/sign.png', 'Sign PDF', _handleSignPdf),
                    _ToolItem(
                        'assets/lock.png', 'Encrypt PDF', _handleEncryptPdf),
                    _ToolItem(
                        'assets/merge.png', 'Merge PDFs', _handleMergePdfs),
                  ]),
                  const SizedBox(height: 16),
                  _buildToolsRow([
                    _ToolItem('assets/split.png', 'Split PDF', _handleSplitPdf),
                    null,
                    null,
                  ]),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A1A),
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildToolsRow(List<_ToolItem?> tools) {
    return Row(
      children: tools.map((tool) {
        if (tool == null) {
          return const Expanded(child: SizedBox());
        }
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: _buildToolCard(tool),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToolCard(_ToolItem tool) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(16),
        onPressed: tool.onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Image.asset(
                tool.iconPath,
                width: 64,
                height: 64,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tool.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Handler methods for each PDF tool
  Future<void> _handleJpgFromPdf() async {
    final result = await _pickPdfFile();
    if (result != null) {
      final file = File(result.$1);
      final fileName = result.$2;
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => JpgFromPdfScreen(
            pdfPath: file.path,
            originalName: fileName,
          ),
        ),
      );
    }
  }

  Future<void> _handlePngFromPdf() async {
    final result = await _pickPdfFile();
    if (result != null) {
      final file = File(result.$1);
      final fileName = result.$2;
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => PngFromPdfScreen(
            pdfPath: file.path,
            originalName: fileName,
          ),
        ),
      );
    }
  }

  Future<void> _handleTextFromPdf() async {
    final result = await _pickPdfFile();
    if (result != null) {
      final file = File(result.$1);
      final fileName = result.$2;
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => TextFromPdfScreen(
            pdfPath: file.path,
            originalName: fileName,
          ),
        ),
      );
    }
  }

  Future<(String, String)?> _pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final file = result.files.single;
        return (file.path!, file.name);
      }
    } catch (e) {
      _showErrorDialog('Failed to pick PDF file: $e');
    }
    return null;
  }

  void _handleImagesToPdf() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();

      if (images.isNotEmpty) {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => ImagesToPdfScreen(selectedImages: images),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to pick images: $e');
    }
  }

  void _handleTextToPdf() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const TextToPdfScreen(),
      ),
    );
  }

  void _handleUrlToPdf() {
    _showUrlInputDialog();
  }

  void _showUrlInputDialog() {
    final TextEditingController urlController = TextEditingController();

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Download PDF'),
        content: Column(
          children: [
            const SizedBox(height: 16),
            const Text('Paste a link that ends with .pdf'),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: urlController,
              placeholder: 'Enter url',
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _downloadPdfFromUrl(urlController.text.trim());
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPdfFromUrl(String url) async {
    if (url.isEmpty) {
      _showErrorDialog('Please enter a URL');
      return;
    }

    if (!url.toLowerCase().endsWith('.pdf')) {
      _showErrorDialog(
          'URL must point to a PDF file (.pdf extension required)');
      return;
    }

    // Show loading dialog
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CupertinoAlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoActivityIndicator(radius: 20),
            SizedBox(height: 16),
            Text('Downloading PDF...'),
          ],
        ),
      ),
    );

    try {
      final pdfService = PDFService();
      final pdfPath = await pdfService.downloadPdfFromUrl(url);

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to URL to PDF screen
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => UrlToPdfScreen(
            pdfPath: pdfPath,
            originalUrl: url,
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      _showErrorDialog('Failed to download PDF: $e');
    }
  }

  void _handleSignPdf() async {
    try {
      final result = await _pickPdfFile();
      if (result != null) {
        final file = File(result.$1);
        final fileName = result.$2;
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => SignPdfScreen(
              pdfPath: file.path,
              originalName: fileName,
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to open PDF: $e');
    }
  }

  void _handleEncryptPdf() async {
    try {
      final result = await _pickPdfFile();
      if (result != null) {
        final file = File(result.$1);
        final fileName = result.$2;
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => EncryptPdfScreen(
              pdfPath: file.path,
              originalName: fileName,
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to open PDF: $e');
    }
  }

  void _handleMergePdfs() {
    try {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => const MergePdfsScreen(),
        ),
      );
    } catch (e) {
      _showErrorDialog('Failed to open merge screen: $e');
    }
  }

  void _handleSplitPdf() async {
    try {
      final result = await _pickPdfFile();
      if (result != null) {
        final file = File(result.$1);
        final fileName = result.$2;
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => SplitPdfScreen(
              pdfPath: file.path,
              originalName: fileName,
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to open PDF: $e');
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
}

class _ToolItem {
  final String iconPath;
  final String title;
  final VoidCallback onPressed;

  const _ToolItem(this.iconPath, this.title, this.onPressed);
}
