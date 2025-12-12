import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:pdfconverter/services/pdf_service.dart';
import 'package:provider/provider.dart';
import '../services/db_helper.dart';

class HistoryProvider extends ChangeNotifier {
  final DBHelper dbHelper;
  List<HistoryItem> _historyItems = [];
  List<HistoryItem> _filteredHistoryItems = [];
  bool _loading = false;
  String _searchQuery = '';

  List<HistoryItem> get historyItems => _filteredHistoryItems;
  bool get loading => _loading;
  String get searchQuery => _searchQuery;

  HistoryProvider({required this.dbHelper});

  // Add this method to refresh history from other parts of the app
  Future<void> refreshHistory() async {
    await loadHistory();
  }

  Future<void> loadHistory() async {
    _loading = true;
    notifyListeners();

    try {
      final history = await dbHelper.getHistory();
      _historyItems = [];

      for (var entry in history) {
        if (entry.type == 'jpgs' || entry.type == 'pngs') {
          // Create separate items for each image
          for (int i = 0; i < entry.filePaths!.length; i++) {
            final filePath = entry.filePaths![i];
            _historyItems.add(HistoryItem(
              filePath: filePath,
              type: entry.type == 'jpgs' ? 'jpg' : 'png',
              timestamp: entry.timestamp,
              originalEntry: entry,
              imageIndex: i,
            ));
          }
        } else {
          // Single item for PDF and text
          _historyItems.add(HistoryItem(
            filePath: entry.filePaths?.first ?? '',
            type: entry.type,
            timestamp: entry.timestamp,
            originalEntry: entry,
            text: entry.text,
          ));
        }
      }

      // Apply current search filter
      _filterHistoryItems();
    } catch (e) {
      print('Error loading history: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _filterHistoryItems() {
    if (_searchQuery.isEmpty) {
      _filteredHistoryItems = List.from(_historyItems);
    } else {
      _filteredHistoryItems = _historyItems.where((item) {
        final fileName = item.type == 'text'
            ? 'Text Document'
            : item.filePath.split('/').last;
        return fileName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  void searchHistory(String query) {
    _searchQuery = query;
    _filterHistoryItems();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filterHistoryItems();
    notifyListeners();
  }

  // Add method to add new history item and refresh
  Future<void> addHistoryItem(HistoryEntry entry) async {
    // Refresh the entire history to get the latest data
    await loadHistory();
  }

  // Helper methods to add different types of history items
  Future<void> addPdfToHistory(File pdf, String fileName) async {
    await dbHelper.addPdf(pdf, fileName);
    await addHistoryItem(HistoryEntry(
      type: 'pdf',
      filePaths: [pdf.path],
      timestamp: DateTime.now(),
    ));
  }

  Future<void> addJpgsToHistory(List<File> jpgs, String fileName) async {
    await dbHelper.addJpgs(jpgs, fileName);
    await addHistoryItem(HistoryEntry(
      type: 'jpgs',
      filePaths: jpgs.map((e) => e.path).toList(),
      timestamp: DateTime.now(),
    ));
  }

  Future<void> addPngsToHistory(List<File> pngs, String fileName) async {
    await dbHelper.addPngs(pngs, fileName);
    await addHistoryItem(HistoryEntry(
      type: 'pngs',
      filePaths: pngs.map((e) => e.path).toList(),
      timestamp: DateTime.now(),
    ));
  }

  Future<void> addTextToHistory(String text, String fileName) async {
    await dbHelper.addPlainText(text, fileName);
    await addHistoryItem(HistoryEntry(
      type: 'text',
      text: text,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> deleteHistoryItem(HistoryItem item) async {
    try {
      await dbHelper.deleteHistoryEntry(item.originalEntry);
      await loadHistory(); // Refresh the history list
    } catch (e) {
      print('Error deleting history item: $e');
      rethrow;
    }
  }
}

class HistoryItem {
  final String filePath;
  final String type;
  final DateTime timestamp;
  final HistoryEntry originalEntry;
  final int? imageIndex;
  final String? text;

  HistoryItem({
    required this.filePath,
    required this.type,
    required this.timestamp,
    required this.originalEntry,
    this.imageIndex,
    this.text,
  });
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load history when screen is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<HistoryProvider>(context, listen: false).loadHistory();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Refresh history when app comes back to foreground
      Provider.of<HistoryProvider>(context, listen: false).refreshHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, provider, _) {
        return CupertinoPageScaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          navigationBar: const CupertinoNavigationBar(
            backgroundColor: Color(0xFFFFFFFF),
            middle: Text(
              'History',
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
              child: provider.loading
                  ? const Center(child: CupertinoActivityIndicator())
                  : Column(
                      children: [
                        // Search bar
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: CupertinoSearchTextField(
                            prefixIcon: const Icon(
                              CupertinoIcons.search,
                              color: Color(0xFF1A1A1A),
                            ),
                            suffixIcon: const Icon(
                              CupertinoIcons.xmark_circle_fill,
                              color: Color(0xFF1A1A1A),
                            ),
                            placeholder: 'Search files...',
                            onChanged: (value) {
                              provider.searchHistory(value);
                            },
                            onSuffixTap: () {
                              provider.clearSearch();
                            },
                            style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                            ),
                            placeholderStyle: const TextStyle(
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ),
                        // Grid view
                        Expanded(
                          child: provider.historyItems.isEmpty
                              ? Center(
                                  child: Text(
                                  provider.searchQuery.isEmpty
                                      ? 'No history yet'
                                      : 'No files found',
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 15, 15, 15),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ))
                              : Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16, right: 16, bottom: 16),
                                  child: GridView.builder(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 0.9,
                                    ),
                                    itemCount: provider.historyItems.length,
                                    itemBuilder: (context, index) {
                                      final item = provider.historyItems[index];
                                      return _HistoryCard(item: item);
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _HistoryCard extends StatefulWidget {
  final HistoryItem item;

  const _HistoryCard({required this.item});

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  String? _fileSize;

  @override
  void initState() {
    super.initState();
    _getFileSize();
  }

  Future<void> _getFileSize() async {
    try {
      if (widget.item.type == 'text' && widget.item.text != null) {
        final bytes = widget.item.text!.length;
        _fileSize = _formatFileSize(bytes);
      } else if (widget.item.filePath.isNotEmpty) {
        final file = File(widget.item.filePath);
        if (await file.exists()) {
          final bytes = await file.length();
          _fileSize = _formatFileSize(bytes);
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      _fileSize = '--';
      print(e);
      if (mounted) setState(() {});
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  Widget _getIconThumbnail() {
    IconData icon;
    Color iconColor;
    Color gradientColor;

    switch (widget.item.type) {
      case 'pdf':
        icon = CupertinoIcons.doc_text_fill;
        iconColor = const Color(0xFFFF3B30); // Red
        gradientColor = const Color(0xFFFF3B30);
        break;
      case 'jpg':
        icon = CupertinoIcons.photo_fill;
        iconColor = const Color(0xFF007AFF); // Blue
        gradientColor = const Color(0xFF007AFF);
        break;
      case 'png':
        icon = CupertinoIcons.photo_fill;
        iconColor = const Color(0xFF34C759); // Green
        gradientColor = const Color(0xFF34C759);
        break;
      case 'text':
        icon = CupertinoIcons.doc_text_fill;
        iconColor = const Color(0xFF1A1A1A); // Black
        gradientColor = const Color(0xFF1A1A1A);
        break;
      default:
        icon = CupertinoIcons.question_circle_fill;
        iconColor = const Color(0xFF8E8E93);
        gradientColor = const Color(0xFF8E8E93);
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientColor.withOpacity(0.1),
            gradientColor.withOpacity(0.2),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 60,
          color: iconColor,
        ),
      ),
    );
  }

  String _getFileName() {
    if (widget.item.type == 'text') {
      return 'Text Document';
    }
    return widget.item.filePath.split('/').last;
  }

  String _getFileType() {
    switch (widget.item.type) {
      case 'pdf':
        return 'PDF';
      case 'jpg':
        return 'JPG';
      case 'png':
        return 'PNG';
      case 'text':
        return 'TXT';
      default:
        return widget.item.type.toUpperCase();
    }
  }

  String _getFormattedDate() {
    final date = widget.item.timestamp;
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showDeleteConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete File'),
        content: const Text(
            'Are you sure you want to delete this file? This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final provider =
                    Provider.of<HistoryProvider>(context, listen: false);
                await provider.deleteHistoryItem(widget.item);
                toast('File deleted successfully');
              } catch (e) {
                toast('Failed to delete file');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showActionSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        if (widget.item.type == 'text') {
          return CupertinoActionSheet(
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: widget.item.text!));
                  toast('Text copied to clipboard');
                },
                child: const Text('Copy to Clipboard'),
              ),
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.pop(context);
                  File textFile = File(widget.item.filePath);
                  if (Platform.isAndroid) {
                    bool? result = await PDFService.downloadFile(textFile,
                        '${widget.item.filePath.split('/').last.replaceAll('.txt', '')}.txt');
                    if (result == true) {
                      toast('TXT downloaded successfully');
                    } else {
                      toast('Failed to download TXT file');
                    }
                  } else {
                    PDFService.downloadFile(textFile,
                        '${widget.item.filePath.split('/').last.replaceAll('.txt', '')}.txt');
                  }
                },
                child: const Text('Download'),
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation();
                },
                child: const Text('Delete'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          );
        } else if (widget.item.type == 'jpg') {
          return CupertinoActionSheet(
            actions: [
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.pop(context);
                  List<String> images = widget.item.originalEntry.filePaths!
                      .map((e) => e)
                      .toList();
                  try {
                    int index = 1;
                    List<String> imagePaths = [];
                    List<String> fileNames = [];

                    for (var image in images) {
                      imagePaths.add(image);
                      fileNames.add(
                          '${widget.item.filePath.split('/').last}_$index.jpg');
                      index++;
                    }

                    final success = await PDFService.downloadImages(
                        imagePaths, fileNames,
                        format: 'jpg');

                    if (success) {
                      toast('All images downloaded successfully!');
                    } else {
                      toast('Failed to download some images');
                    }
                  } catch (e) {
                    toast('Failed to download images: $e');
                  }
                },
                child: const Text('Download'),
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation();
                },
                child: const Text('Delete'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          );
        } else if (widget.item.type == 'png') {
          return CupertinoActionSheet(
            actions: [
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.pop(context);
                  List<String> images = widget.item.originalEntry.filePaths!
                      .map((e) => e)
                      .toList();
                  try {
                    int index = 1;
                    List<String> imagePaths = [];
                    List<String> fileNames = [];

                    for (var image in images) {
                      imagePaths.add(image);
                      fileNames.add(
                          '${widget.item.filePath.split('/').last}_$index.png');
                      index++;
                    }

                    final success = await PDFService.downloadImages(
                        imagePaths, fileNames,
                        format: 'png');

                    if (success) {
                      toast('All images downloaded successfully!');
                    } else {
                      toast('Failed to download some images');
                    }
                  } catch (e) {
                    toast('Failed to download images: $e');
                  }
                },
                child: const Text('Download'),
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation();
                },
                child: const Text('Delete'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          );
        } else {
          return CupertinoActionSheet(
            actions: [
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.pop(context);
                  File pdfFile = File(widget.item.filePath);
                  if (Platform.isAndroid) {
                    bool? result = await PDFService.downloadFile(pdfFile,
                        '${widget.item.filePath.split('/').last.replaceAll('.pdf', '')}.pdf');
                    if (result == true) {
                      toast('PDF downloaded successfully');
                    } else {
                      toast('Failed to download PDF');
                    }
                  } else {
                    PDFService.downloadFile(pdfFile,
                        '${widget.item.filePath.split('/').last.replaceAll('.pdf', '')}.pdf');
                  }
                },
                child: const Text('Download'),
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation();
                },
                child: const Text('Delete'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _showActionSheet,
      child: Container(
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
        child: Column(
          children: [
            // Icon section (takes up most of the card)
            Expanded(
              flex: 3,
              child: _getIconThumbnail(),
            ),
            // Info section
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // File name
                    Text(
                      _getFileName(),
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // File type and size
                    Row(
                      children: [
                        Text(
                          _getFileType(),
                          style: const TextStyle(
                            color: Color(0xFF007AFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            color: const Color(0xFF8E8E93),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _fileSize ?? '--',
                            style: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Date
                    Text(
                      _getFormattedDate(),
                      style: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
