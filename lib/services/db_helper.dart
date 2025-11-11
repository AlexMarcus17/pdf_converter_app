// NOTE: Add hive and hive_flutter to your pubspec.yaml dependencies.
// NOTE: Run `flutter pub run build_runner build` to generate the adapter.
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'db_helper.g.dart';

@HiveType(typeId: 0)
class HistoryEntry {
  @HiveField(0)
  String type; // 'pdf', 'jpgs', 'pngs', 'text'
  @HiveField(1)
  List<String>? filePaths; // for pdf, jpgs, pngs
  @HiveField(2)
  String? text; // for plain text
  @HiveField(3)
  DateTime timestamp;

  HistoryEntry({
    required this.type,
    this.filePaths,
    this.text,
    required this.timestamp,
  });
}

class DBHelper {
  static const String boxName = 'history';

  Future<Directory> _getHistoryDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final historyDir = Directory('${docsDir.path}/history');
    if (!await historyDir.exists()) {
      await historyDir.create(recursive: true);
    }
    return historyDir;
  }

  Future<Box<HistoryEntry>> _openBox() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HistoryEntryAdapter());
    }
    return await Hive.openBox<HistoryEntry>(boxName);
  }

  Future<void> addPdf(File pdf, String fileName) async {
    final box = await _openBox();
    final historyDir = await _getHistoryDir();
    final newPath = '${historyDir.path}/$fileName';
    final newFile = await pdf.copy(newPath);
    final entry = HistoryEntry(
      type: 'pdf',
      filePaths: [newFile.path],
      timestamp: DateTime.now(),
    );
    await box.add(entry);
  }

  Future<void> addJpgs(List<File> jpgs, String fileName) async {
    final box = await _openBox();
    final historyDir = await _getHistoryDir();
    final List<String> newPaths = [];
    int index = 1;
    for (var jpg in jpgs) {
      final newPath = '${historyDir.path}/$fileName$index.jpg';
      final newFile = await jpg.copy(newPath);
      newPaths.add(newFile.path);
      index++;
    }
    final entry = HistoryEntry(
      type: 'jpgs',
      filePaths: newPaths,
      timestamp: DateTime.now(),
    );
    await box.add(entry);
  }

  Future<void> addPngs(List<File> pngs, String fileName) async {
    final box = await _openBox();
    final historyDir = await _getHistoryDir();
    final List<String> newPaths = [];
    int index = 1;
    for (var png in pngs) {
      final newPath = '${historyDir.path}/$fileName$index.png';
      final newFile = await png.copy(newPath);
      newPaths.add(newFile.path);
      index++;
    }
    final entry = HistoryEntry(
      type: 'pngs',
      filePaths: newPaths,
      timestamp: DateTime.now(),
    );
    await box.add(entry);
  }

  Future<void> addPlainText(String text, String fileName) async {
    final box = await _openBox();
    final historyDir = await _getHistoryDir();
    final newPath = '${historyDir.path}/$fileName.txt';
    final newFile = await File(newPath).writeAsString(text);
    final entry = HistoryEntry(
      type: 'text',
      filePaths: [newFile.path],
      text: text,
      timestamp: DateTime.now(),
    );
    await box.add(entry);
  }

  Future<List<HistoryEntry>> getHistory() async {
    final box = await _openBox();
    return box.values.toList().reversed.toList();
  }

  Future<void> deleteHistoryEntry(HistoryEntry entry) async {
    final box = await _openBox();

    // Find and delete the entry from the box
    for (int i = 0; i < box.length; i++) {
      final boxEntry = box.getAt(i);
      if (boxEntry != null &&
          boxEntry.type == entry.type &&
          boxEntry.timestamp == entry.timestamp) {
        // Delete associated files
        if (entry.filePaths != null) {
          for (String filePath in entry.filePaths!) {
            try {
              final file = File(filePath);
              if (await file.exists()) {
                await file.delete();
              }
            } catch (e) {
              print('Error deleting file $filePath: $e');
            }
          }
        }

        // Remove entry from box
        await box.deleteAt(i);
        break;
      }
    }
  }
}
