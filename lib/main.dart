import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:pdfconverter/services/db_helper.dart';
import 'package:pdfconverter/services/pdf_service.dart';
import 'screens/home_screen.dart';
import 'screens/scanner_page.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(HistoryEntryAdapter());
  await Hive.openBox<HistoryEntry>(DBHelper.boxName);

  // Initialize PDFService once globally
  final dbHelper = DBHelper();
  final pdfService = PDFService();
  pdfService.setDbHelper(dbHelper);

  runApp(PDFConverterApp(dbHelper: dbHelper, pdfService: pdfService));
}

class PDFConverterApp extends StatelessWidget {
  final DBHelper dbHelper;
  final PDFService pdfService;

  const PDFConverterApp({
    super.key,
    required this.dbHelper,
    required this.pdfService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            final historyProvider = HistoryProvider(dbHelper: dbHelper);

            // Set up PDFService callback
            pdfService.setOnHistoryAdded(() {
              historyProvider.refreshHistory();
            });

            return historyProvider;
          },
        ),
      ],
      child: const OverlaySupport(
        child: CupertinoApp(
          theme: CupertinoThemeData(
            brightness: Brightness.dark,
          ),
          title: 'PDF Converter',
          home: MainTabScaffold(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

class MainTabScaffold extends StatefulWidget {
  const MainTabScaffold({super.key});

  @override
  State<MainTabScaffold> createState() => _MainTabScaffoldState();
}

class _MainTabScaffoldState extends State<MainTabScaffold> {
  late final CupertinoTabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = CupertinoTabController();
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 2 && mounted) {
      // History tab index is 2
      // Refresh history when switching to history tab
      Provider.of<HistoryProvider>(context, listen: false).refreshHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      controller: _tabController,
      tabBar: CupertinoTabBar(
        backgroundColor: const Color.fromARGB(255, 1, 4, 37).withOpacity(0.75),
        activeColor: const Color.fromARGB(222, 255, 255, 255),
        inactiveColor: const Color.fromARGB(193, 166, 166, 172),
        height: 55,
        items: const [
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/menu1.png'),
              size: 26,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/menu2.png'),
              size: 25,
            ),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/menu3.png'),
              size: 28,
            ),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/menu4.png'),
              size: 25,
            ),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return const HomeScreen();
          case 1:
            return const ScannerPage();
          case 2:
            return const HistoryScreen();
          case 3:
            return const SettingsScreen();
          default:
            return const HomeScreen();
        }
      },
    );
  }
}
