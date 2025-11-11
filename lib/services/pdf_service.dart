import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf_render/pdf_render.dart' as pdf_render;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;
import 'db_helper.dart';
import 'dart:ui' as ui;

class PDFService {
  static final PDFService _instance = PDFService._internal();
  factory PDFService() => _instance;
  PDFService._internal();

  final Dio _dio = Dio();
  final TextRecognizer _textRecognizer = TextRecognizer();
  DBHelper? _dbHelper;
  Function? _onHistoryAdded; // Callback to notify when history is added

  DBHelper get dbHelper => _dbHelper!;

  void setDbHelper(DBHelper helper) {
    _dbHelper ??= helper; // Only set if not already set
  }

  void setOnHistoryAdded(Function callback) {
    _onHistoryAdded ??= callback; // Only set if not already set
  }

  Future<void> addPdfToHistory(File pdf, String fileName) async {
    await dbHelper.addPdf(pdf, fileName);
    _onHistoryAdded?.call();
  }

  Future<void> addJpgsToHistory(List<File> jpgs, String fileName) async {
    await dbHelper.addJpgs(jpgs, fileName);
    _onHistoryAdded?.call();
  }

  Future<void> addPngsToHistory(List<File> pngs, String fileName) async {
    await dbHelper.addPngs(pngs, fileName);
    _onHistoryAdded?.call();
  }

  Future<void> addPlainTextToHistory(String text, String fileName) async {
    await dbHelper.addPlainText(text, fileName);
    _onHistoryAdded?.call();
  }

  // Common PDF margins
  static const double defaultMargin = 72.0; // 1 inch
  static const double smallMargin = 36.0; // 0.5 inch
  static const double largeMargin = 108.0; // 1.5 inch

  /// Get app documents directory
  Future<Directory> get _documentsDirectory async {
    return await getApplicationDocumentsDirectory();
  }

  /// Generate unique filename
  String _generateFileName(String prefix, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$timestamp.$extension';
  }

  // =============================================================================
  // FROM PDF FEATURES
  // =============================================================================

  /// Extract JPEG images from PDF
  Future<List<String>> extractJpegFromPdf(String pdfPath) async {
    try {
      final List<String> imagePaths = [];
      final document = await pdf_render.PdfDocument.openFile(pdfPath);
      final docsDir = await _documentsDirectory;

      for (int i = 0; i < document.pageCount; i++) {
        final page = await document.getPage(i + 1);
        final pageImage = await page.render(
          width: (page.width * 2).toInt(),
          height: (page.height * 2).toInt(),
        );

        // Convert RGBA to JPEG using the image package
        final rgbaImage = img.Image.fromBytes(
          width: pageImage.width,
          height: pageImage.height,
          bytes: pageImage.pixels.buffer,
          format: img.Format.uint8,
          numChannels: 4,
        );

        final jpegBytes = img.encodeJpg(rgbaImage);
        pageImage.dispose();

        final fileName = _generateFileName('page_${i + 1}', 'jpg');
        final file = File('${docsDir.path}/$fileName');
        await file.writeAsBytes(jpegBytes);
        imagePaths.add(file.path);
      }

      await document.dispose();
      return imagePaths;
    } catch (e) {
      throw Exception('Failed to extract JPEG images: $e');
    }
  }

  /// Extract PNG images from PDF
  Future<List<String>> extractPngFromPdf(String pdfPath) async {
    try {
      final List<String> imagePaths = [];
      final document = await pdf_render.PdfDocument.openFile(pdfPath);
      final docsDir = await _documentsDirectory;

      for (int i = 0; i < document.pageCount; i++) {
        final page = await document.getPage(i + 1);
        final pageImage = await page.render(
          width: (page.width * 2).toInt(),
          height: (page.height * 2).toInt(),
        );

        // Convert RGBA to PNG using the image package
        final rgbaImage = img.Image.fromBytes(
          width: pageImage.width,
          height: pageImage.height,
          bytes: pageImage.pixels.buffer,
          format: img.Format.uint8,
          numChannels: 4,
        );

        final pngBytes = img.encodePng(rgbaImage);
        pageImage.dispose();

        final fileName = _generateFileName('page_${i + 1}', 'png');
        final file = File('${docsDir.path}/$fileName');
        await file.writeAsBytes(pngBytes);
        imagePaths.add(file.path);
      }

      await document.dispose();
      return imagePaths;
    } catch (e) {
      throw Exception('Failed to extract PNG images: $e');
    }
  }

  /// Extract text from PDF using Google ML Kit
  Future<String> extractTextFromPdf(String pdfPath) async {
    try {
      final StringBuffer extractedText = StringBuffer();
      final document = await pdf_render.PdfDocument.openFile(pdfPath);

      for (int i = 0; i < document.pageCount; i++) {
        final page = await document.getPage(i + 1);
        final pageImage = await page.render(
          width: (page.width * 2).toInt(),
          height: (page.height * 2).toInt(),
        );

        // Convert to InputImage for ML Kit
        final inputImage = InputImage.fromBytes(
          bytes: pageImage.pixels,
          metadata: InputImageMetadata(
            size: Size(pageImage.width.toDouble(), pageImage.height.toDouble()),
            rotation: InputImageRotation.rotation0deg,
            format: InputImageFormat.bgra8888,
            bytesPerRow: pageImage.width * 4,
          ),
        );

        final RecognizedText recognizedText =
            await _textRecognizer.processImage(inputImage);
        extractedText.writeln('--- Page ${i + 1} ---');
        extractedText.writeln(recognizedText.text);
        extractedText.writeln();

        pageImage.dispose();
      }

      await document.dispose();
      return extractedText.toString();
    } catch (e) {
      throw Exception('Failed to extract text from PDF: $e');
    }
  }

  // =============================================================================
  // TO PDF FEATURES
  // =============================================================================

  /// Convert multiple images to PDF
  Future<File> imagesToPdf(
    List<String> imagePaths, {
    double margin = defaultMargin,
    String? fileName,
  }) async {
    try {
      final pdf = pw.Document();
      final docsDir = await _documentsDirectory;

      for (String imagePath in imagePaths) {
        final imageFile = File(imagePath);
        final imageBytes = await imageFile.readAsBytes();
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.all(margin),
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(
                  image,
                  fit: pw.BoxFit.contain,
                ),
              );
            },
          ),
        );
      }

      final outputFileName =
          fileName ?? _generateFileName('images_to_pdf', 'pdf');
      final file = File('${docsDir.path}/$outputFileName');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      throw Exception('Failed to convert images to PDF: $e');
    }
  }

  Future<File> textToPdf(
    String text, {
    double margin = defaultMargin,
    String? fileName,
    double fontSize = 12.0,
  }) async {
    if (margin == 0) {
      margin = 8;
    }
    try {
      final pdf = pw.Document();
      final docsDir = await _documentsDirectory;

      // Load a font that supports special characters

      // Clean text to remove unsupported characters as fallback
      final cleanedText = _cleanTextForPdf(text);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(margin),
          build: (pw.Context context) => [
            pw.Paragraph(
              text: cleanedText,
              style: pw.TextStyle(
                fontSize: fontSize,
              ),
              textAlign: pw.TextAlign.left,
            ),
          ],
        ),
      );

      final outputFileName =
          fileName ?? _generateFileName('text_to_pdf', 'pdf');
      final file = File('${docsDir.path}/$outputFileName');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      throw Exception('Failed to convert text to PDF: $e');
    }
  }

// Helper function to clean text of unsupported characters
  String _cleanTextForPdf(String text) {
    // Replace common problematic characters with alternatives
    return text
        .replaceAll('•', '-') // Replace bullet points with dashes
        .replaceAll(''', "'")  // Replace smart quotes
      .replaceAll(''', "'")
        .replaceAll('"', '"')
        .replaceAll('"', '"')
        .replaceAll('—', '-') // Replace em dash
        .replaceAll('–', '-') // Replace en dash
        .replaceAll(RegExp(r'[^\x00-\x7F]'),
            ''); // Remove non-ASCII characters as last resort
  }

  /// Download PDF from URL
  Future<File> downloadPdfFromUrl(String url, {String? fileName}) async {
    try {
      if (!url.toLowerCase().endsWith('.pdf')) {
        throw Exception(
            'URL must point to a PDF file (.pdf extension required)');
      }

      final docsDir = await _documentsDirectory;
      final outputFileName = fileName ?? _generateFileName('downloaded', 'pdf');
      final filePath = '${docsDir.path}/$outputFileName';

      await _dio.download(
        url,
        filePath,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      return File(filePath);
    } catch (e) {
      throw Exception('Failed to download PDF: $e');
    }
  }

  // =============================================================================
  // OTHER TOOLS
  // =============================================================================
  Future<Size> getPdfPageSize(String pdfPath, int pageIndex) async {
    try {
      final document = await pdf_render.PdfDocument.openFile(pdfPath);

      if (pageIndex >= document.pageCount) {
        await document.dispose();
        throw Exception(
            'Page index $pageIndex exceeds document page count ${document.pageCount}');
      }

      final page = await document
          .getPage(pageIndex + 1); // pdf_render uses 1-based indexing
      final size = Size(page.width, page.height);

      await document.dispose();

      return size;
    } catch (e) {
      throw Exception('Failed to get PDF page size: $e');
    }
  }

  /// PDF signing using relative positioning within the actual PDF content area
  Future<Uint8List> signPdf(
    String pdfPath,
    Uint8List signatureBytes,
    double xPercent, // 0.0 to 1.0 (left to right)
    double yPercent, // 0.0 to 1.0 (top to bottom)
    double widthPercent, // Width relative to PDF page width
    double heightPercent, // Height relative to PDF page height
    {
    int pageIndex = 0,
    String? fileName,
  }) async {
    try {
      final inputBytes = await File(pdfPath).readAsBytes();

      // Load the existing PDF
      final syncfusion.PdfDocument document =
          syncfusion.PdfDocument(inputBytes: inputBytes);

      // Validate page index
      if (pageIndex >= document.pages.count) {
        document.dispose();
        throw Exception(
            'Page index $pageIndex exceeds document page count ${document.pages.count}');
      }

      final syncfusion.PdfPage page = document.pages[pageIndex];

      // Create signature image
      final syncfusion.PdfBitmap signatureImage =
          syncfusion.PdfBitmap(signatureBytes);

      // Calculate actual PDF coordinates and size based on relative values
      final pdfX = xPercent * page.size.width;
      final pdfY = yPercent * page.size.height;
      final maxWidth = widthPercent * page.size.width;
      final maxHeight = heightPercent * page.size.height;

      // Preserve aspect ratio - calculate final size maintaining signature's original proportions
      final originalAspectRatio = signatureImage.width / signatureImage.height;
      final containerAspectRatio = maxWidth / maxHeight;

      double finalWidth, finalHeight;

      if (originalAspectRatio > containerAspectRatio) {
        // Signature is wider - fit to width
        finalWidth = maxWidth;
        finalHeight = finalWidth / originalAspectRatio;
      } else {
        // Signature is taller - fit to height
        finalHeight = maxHeight;
        finalWidth = finalHeight * originalAspectRatio;
      }

      // Center the signature within the designated area
      final centeredX = pdfX + (maxWidth - finalWidth) / 2;
      final centeredY = pdfY + (maxHeight - finalHeight) / 2;

      // Ensure signature stays within page bounds
      final clampedX = centeredX.clamp(0.0, page.size.width - finalWidth);
      final clampedY = centeredY.clamp(0.0, page.size.height - finalHeight);

      // Draw the signature on the specified page
      page.graphics.drawImage(
        signatureImage,
        Rect.fromLTWH(
          clampedX,
          clampedY,
          finalWidth,
          finalHeight,
        ),
      );

      // Save the modified PDF and return bytes
      final List<int> bytes = await document.save();
      document.dispose();

      return Uint8List.fromList(bytes);
    } catch (e) {
      throw Exception('Failed to sign PDF: $e');
    }
  }

  Future<File> encryptPdf(
    String pdfPath,
    String password, {
    String? fileName,
  }) async {
    try {
      final docsDir = await _documentsDirectory;
      final inputBytes = await File(pdfPath).readAsBytes();

      // Load and encrypt the PDF
      final syncfusion.PdfDocument document =
          syncfusion.PdfDocument(inputBytes: inputBytes);
      final syncfusion.PdfSecurity security = document.security;

      security.userPassword = password;
      security.ownerPassword = password;
      security.permissions.addAll([
        syncfusion.PdfPermissionsFlags.print,
        syncfusion.PdfPermissionsFlags.editContent,
        syncfusion.PdfPermissionsFlags.copyContent,
        syncfusion.PdfPermissionsFlags.editAnnotations,
        syncfusion.PdfPermissionsFlags.fillFields,
        syncfusion.PdfPermissionsFlags.accessibilityCopyContent,
        syncfusion.PdfPermissionsFlags.assembleDocument,
        syncfusion.PdfPermissionsFlags.fullQualityPrint,
      ]);

      // Save the encrypted PDF
      final List<int> bytes = await document.save();
      document.dispose();

      final outputFileName = fileName ?? _generateFileName('encrypted', 'pdf');
      final file = File('${docsDir.path}/$outputFileName');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      throw Exception('Failed to encrypt PDF: $e');
    }
  }

  Future<File> mergePdfs(
    List<String> pdfPaths, {
    String? fileName,
  }) async {
    try {
      final docsDir = await _documentsDirectory;

      if (pdfPaths.isEmpty) {
        throw Exception('No PDF files to merge');
      }

      final document = pw.Document();

      for (String pdfPath in pdfPaths) {
        final pdf = await pdf_render.PdfDocument.openFile(pdfPath);

        for (var i = 0; i < pdf.pageCount; i++) {
          final page = await pdf.getPage(i + 1);

          final pageImage = await page.render(
            width: (page.width * 2).toInt(),
            height: (page.height * 2).toInt(),
          );

          final image =
              pw.MemoryImage(await _convertPdfImageToBytes(pageImage));

          document.addPage(
            pw.Page(
              margin: pw.EdgeInsets.all(0),
              build: (context) => pw.Center(
                child: pw.Image(image),
              ),
            ),
          );

          pageImage.dispose();
        }

        await pdf.dispose();
      }

// Save the merged PDF

      final outputFileName = fileName ?? _generateFileName('merged', 'pdf');

      final file = File('${docsDir.path}/$outputFileName');

      await file.writeAsBytes(await document.save());

      return file;
    } catch (e) {
      throw Exception('Failed to merge PDFs: $e');
    }
  }

  /// Split PDF by extracting specific pages
  Future<List<File>> splitPdf(
    String pdfPath,
    List<List<int>> pageRanges, {
    String? baseFileName,
  }) async {
    try {
      final docsDir = await _documentsDirectory;

      if (pageRanges.isEmpty) {
        throw Exception('No page ranges specified for splitting');
      }

      // Load the source PDF once
      final pdf = await pdf_render.PdfDocument.openFile(pdfPath);
      final List<File> splitFiles = [];

      // Create a separate PDF for each page range
      for (int rangeIndex = 0; rangeIndex < pageRanges.length; rangeIndex++) {
        final pageNumbers = pageRanges[rangeIndex];

        if (pageNumbers.isEmpty) {
          continue; // Skip empty ranges
        }

        // Create a new PDF document for this range
        final document = pw.Document();

        // Extract pages for this range
        for (int pageNumber in pageNumbers) {
          if (pageNumber < 1 || pageNumber > pdf.pageCount) {
            await pdf.dispose();
            throw Exception('Invalid page number: $pageNumber');
          }

          final page = await pdf.getPage(pageNumber);
          final pageImage = await page.render(
            width: (page.width * 2).toInt(),
            height: (page.height * 2).toInt(),
          );

          final image =
              pw.MemoryImage(await _convertPdfImageToBytes(pageImage));

          document.addPage(
            pw.Page(
              margin: pw.EdgeInsets.all(0),
              build: (context) => pw.Center(
                child: pw.Image(image),
              ),
            ),
          );

          pageImage.dispose();
        }

        // Save this split PDF
        final outputFileName = baseFileName != null
            ? '${baseFileName}_split_${rangeIndex + 1}.pdf'
            : _generateFileName('split_${rangeIndex + 1}', 'pdf');

        final file = File('${docsDir.path}/$outputFileName');
        await file.writeAsBytes(await document.save());
        splitFiles.add(file);
      }

      await pdf.dispose();
      return splitFiles;
    } catch (e) {
      throw Exception('Failed to split PDF: $e');
    }
  }

  Future<Uint8List> _convertPdfImageToBytes(
      pdf_render.PdfPageImage pageImage) async {
    final ui.Image image = await pageImage.createImageDetached();
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    if (byteData == null) {
      throw Exception('Failed to convert image to bytes');
    }

    return byteData.buffer.asUint8List();
  }

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================

  /// Get PDF page count
  Future<int> getPdfPageCount(String pdfPath) async {
    try {
      final document = await pdf_render.PdfDocument.openFile(pdfPath);
      final pageCount = document.pageCount;
      await document.dispose();
      return pageCount;
    } catch (e) {
      throw Exception('Failed to get PDF page count: $e');
    }
  }

  /// Get PDF file size
  Future<String> getPdfFileSize(String pdfPath) async {
    try {
      final file = File(pdfPath);
      final bytes = await file.length();
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1048576) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / 1048576).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      throw Exception('Failed to get PDF file size: $e');
    }
  }

  /// Validate PDF file
  Future<bool> isValidPdf(String pdfPath) async {
    try {
      final document = await pdf_render.PdfDocument.openFile(pdfPath);
      await document.dispose();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get margin value from string
  static double getMarginValue(String marginType) {
    switch (marginType.toLowerCase()) {
      case 'none':
        return 0.0;
      case 'small':
        return smallMargin;
      case 'normal':
        return defaultMargin;
      case 'large':
        return largeMargin;
      default:
        return defaultMargin;
    }
  }

  static Future<bool?> downloadFile(File file, String fileName) async {
    try {
      if (Platform.isAndroid) {
        // Request storage permission for Android
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            return false;
          }
        }

        // Get the Downloads directory
        Directory? downloadsDirectory;

        if (Platform.isAndroid) {
          // For Android, use the Downloads folder
          downloadsDirectory = Directory('/storage/emulated/0/Download');

          // Fallback to external storage directory if Downloads doesn't exist
          if (!await downloadsDirectory.exists()) {
            downloadsDirectory = await getExternalStorageDirectory();
          }
        }

        if (downloadsDirectory == null) {
          return false;
        }

        // Ensure the fileName has the correct extension
        String fileExtension = fileName.toLowerCase().endsWith('.pdf') ||
                fileName.toLowerCase().endsWith('.txt')
            ? ''
            : '.${file.path.split('.').last}';
        String fullFileName = fileName + fileExtension;

        // Create the destination file path
        String destinationPath = '${downloadsDirectory.path}/$fullFileName';

        // Copy the file to Downloads directory
        await file.copy(destinationPath);

        return true;
      } else if (Platform.isIOS) {
        // For iOS, use share_plus to share the file
        final XFile xFile = XFile(file.path);
        await Share.shareXFiles([xFile]);

        return null; // Return null for iOS as requested
      }

      return false;
    } catch (e) {
      debugPrint('Error in downloadFile: $e');
      return false;
    }
  }

  static Future<bool> downloadImages(
      List<String> imagePaths, List<String> fileNames) async {
    try {
      // Request permission to access photos
      var status = await Permission.photos.status;
      if (!status.isGranted) {
        status = await Permission.photos.request();
        if (!status.isGranted) {
          return false;
        }
      }

      bool allSuccessful = true;

      for (int index = 0; index < imagePaths.length; index++) {
        String imagePath = imagePaths[index];
        try {
          File imageFile = File(imagePath);

          // Check if file exists
          if (!await imageFile.exists()) {
            debugPrint('Image file does not exist: $imagePath');
            allSuccessful = false;
            continue;
          }

          // Read image bytes
          List<int> imageBytes = await imageFile.readAsBytes();

          // Save to gallery
          final result = await ImageGallerySaver.saveImage(
            Uint8List.fromList(imageBytes),
            quality: 100,
            name: fileNames[index],
          );

          // Check if save was successful
          if (result['isSuccess'] != true) {
            debugPrint('Failed to save image: $imagePath');
            allSuccessful = false;
          }
        } catch (e) {
          debugPrint('Error saving image $imagePath: $e');
          allSuccessful = false;
        }
      }

      return allSuccessful;
    } catch (e) {
      debugPrint('Error in downloadImages: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}
