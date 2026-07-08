// lib/main.dart — AgriSense SuperApp
// Integrates: Login gate | Shared FarmerContext | Gemini AI | Voice Assistant | Profile Menu

import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'models/localization.dart';
import 'models/farmer_context.dart';
import 'screens/login_screen.dart';
import 'screens/home_tab.dart';
import 'screens/advice_tab.dart';
import 'screens/weather_tab.dart';
import 'screens/crops_tab.dart';
import 'screens/expert_tab.dart';
import 'screens/camera_scanner_screen.dart';
import 'screens/voice_assistant_sheet.dart';
import 'services/auth_service.dart';
import 'widgets/profile_menu.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AgriSenseApp());
}

class AgriSenseApp extends StatelessWidget {
  const AgriSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriSense SuperApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Outfit',
        scaffoldBackgroundColor: const Color(0xFFFFF7F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E5E4A),
          primary: const Color(0xFF1E5E4A),
          secondary: const Color(0xFFD8F3E5),
          surface: const Color(0xFFFFF7F5),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFD8F3E5),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF123F32));
            }
            return const TextStyle(fontSize: 12, color: Colors.grey);
          }),
        ),
      ),
      home: const AppGate(),
    );
  }
}

// ─── Auth Gate ────────────────────────────────────────────────────────────────

class AppGate extends StatefulWidget {
  const AppGate({super.key});
  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  bool _checking = true;
  bool _isLoggedIn = false;
  FarmerProfile? _profile;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _isLoggedIn = false;
          _profile = null;
          _checking = false;
        });
      } else {
        final profile = await AuthService.getProfile();
        if (!mounted) return;
        setState(() {
          _isLoggedIn = true;
          _profile = profile;
          _checking = false;
        });
      }
    });
  }

  Future<void> _checkAuth() async {
    final loggedIn = await AuthService.isLoggedIn();
    FarmerProfile? profile;
    if (loggedIn) profile = await AuthService.getProfile();
    if (!mounted) return;
    setState(() {
      _isLoggedIn = loggedIn;
      _profile = profile;
      _checking = false;
    });
  }

  Future<void> _onLoginSuccess() async {
    final profile = await AuthService.getProfile();
    setState(() {
      _isLoggedIn = true;
      _profile = profile;
    });
  }

  void _onLogout() {
    setState(() {
      _isLoggedIn = false;
      _profile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF7F5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1E5E4A))),
      );
    }
    if (!_isLoggedIn) {
      return LoginScreen(onLoginSuccess: _onLoginSuccess);
    }
    return MainScreen(
      profile: _profile ?? FarmerProfile.demo,
      onLogout: _onLogout,
    );
  }
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class MainScreen extends StatefulWidget {
  final FarmerProfile profile;
  final VoidCallback onLogout;

  const MainScreen({super.key, required this.profile, required this.onLogout});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  bool _isHindi = false;
  bool _thermalView = false;
  bool _isLoadingLocation = false;

  // ── Shared farm context (single source of truth) ──────────────────────────
  String _location = 'Pune, Maharashtra';
  double _temperature = 32.0;
  double _humidity = 64.0;
  double _rainfallChance = 20.0;
  String _soilType = 'Red Soil';
  double _soilMoisture = 65.0;
  double _phLevel = 6.5;
  double _nitrogen = 85.0;
  double _phosphorus = 70.0;
  double _potassium = 40.0;
  double _marketPrice = 2450.0;
  final List<double> _marketPriceHistory = [2400, 2415, 2380, 2410, 2435, 2450];

  // ── Lists ─────────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _activeCrops = [
    {'name': 'Soybeans', 'duration': 90, 'progress': 30, 'plantedDate': 'June 10, 2026'},
    {'name': 'Groundnut', 'duration': 110, 'progress': 70, 'plantedDate': 'May 15, 2026'},
  ];

  final List<Map<String, dynamic>> _harvestLogs = [
    {'crop': 'Wheat', 'sector': 'Sector A-2', 'quantity': 32.5, 'date': 'June 20, 2026'},
    {'crop': 'Soybeans', 'sector': 'South Sector', 'quantity': 18.0, 'date': 'June 05, 2026'},
  ];

  final List<Map<String, dynamic>> _historicalLogs = [
    {
      'crop': 'Tomato',
      'issue': 'Wilt',
      'status': 'Resolved',
      'desc': 'Success: Copper fungicide applied as recommended. Growth recovered by 15%. Ground moisture is healthy.',
      'date': 'Oct 24',
      'imageUrl': 'https://images.unsplash.com/photo-1592417817098-8f3d6eb19675?auto=format&fit=crop&q=80&w=200',
    },
    {
      'crop': 'Maize',
      'issue': 'Chlorosis',
      'status': 'In Review',
      'desc': 'Expert assigned from local RSK center. Waiting for final nitrogen & soil moisture sensor network audits.',
      'date': 'Oct 21',
      'imageUrl': 'https://images.unsplash.com/photo-1530595467537-0b5996c41f2d?auto=format&fit=crop&q=80&w=200',
    },
    {
      'crop': 'Cotton',
      'issue': 'Aphids',
      'status': 'Resolved',
      'desc': 'Bio-pesticide treatment completed successfully. Field cleared and monitored. Harvest normal.',
      'date': 'Oct 15',
      'imageUrl': 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?auto=format&fit=crop&q=80&w=200',
    },
  ];

  // ── AI Diagnosis ──────────────────────────────────────────────────────────
  bool _isDiagnosing = false;
  double _diagnosisProgress = 0.0;
  Timer? _diagnosisTimer;

  // ── Shared farm data snapshot (feeds all AI) ──────────────────────────────
  FarmSnapshot get _farmSnapshot => FarmSnapshot(
    location: _location,
    temperature: _temperature,
    humidity: _humidity,
    rainfallChance: _rainfallChance,
    soilType: _soilType,
    soilMoisture: _soilMoisture,
    phLevel: _phLevel,
    nitrogen: _nitrogen,
    phosphorus: _phosphorus,
    potassium: _potassium,
    marketPrice: _marketPrice,
    activeCrops: _activeCrops,
    harvestLogs: _harvestLogs,
    historicalDiagnoses: _historicalLogs,
  );

  @override
  void dispose() {
    _diagnosisTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _isHindi = widget.profile.language == 'hi';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMyLocationAndData(showSnackbar: false);
    });
  }

  // ─── GPS + Weather ─────────────────────────────────────────────────────────

  Future<void> _fetchMyLocationAndData({bool showSnackbar = true}) async {
    setState(() => _isLoadingLocation = true);

    try {
      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              SizedBox(width: 25, height: 25,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)),
              SizedBox(width: 14),
              Text('Connecting to GPS & scanning environmental sensors...'),
            ]),
            duration: Duration(seconds: 3),
          ),
        );
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled on this device.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Location permissions are denied by user.';
      }
      if (permission == LocationPermission.deniedForever) throw 'Location permissions are permanently disabled.';

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 5)),
      );

      double lat = position.latitude, lon = position.longitude;
      double temp = _temperature, hum = _humidity, rainPr = _rainfallChance;

      // Open-Meteo weather
      try {
        final weatherResponse = await http.get(Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m&daily=precipitation_probability_max&timezone=auto&forecast_days=1'
        )).timeout(const Duration(seconds: 4));
        if (weatherResponse.statusCode == 200) {
          final d = jsonDecode(weatherResponse.body);
          if (d['current'] != null) {
            temp = (d['current']['temperature_2m'] as num).toDouble();
            hum = (d['current']['relative_humidity_2m'] as num).toDouble();
          }
          final probs = d['daily']?['precipitation_probability_max'] as List?;
          if (probs != null && probs.isNotEmpty) rainPr = (probs[0] as num).toDouble();
        }
      } catch (e) { debugPrint('Weather: $e'); }

      // Nominatim reverse geocode
      String locName = 'Lat: ${lat.toStringAsFixed(3)}, Lon: ${lon.toStringAsFixed(3)}';
      try {
        final geoResponse = await http.get(
          Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon'),
          headers: {'User-Agent': 'AgriSenseApp/1.0'},
        ).timeout(const Duration(seconds: 4));
        if (geoResponse.statusCode == 200) {
          final data = jsonDecode(geoResponse.body);
          final addr = data['address'];
          if (addr != null) {
            final place = addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['suburb'] ?? addr['county'];
            final state = addr['state'];
            if (place != null && state != null) locName = '$place, $state';
            else if (place != null) locName = place;
            else if (state != null) locName = state;
          }
        }
      } catch (e) { debugPrint('Geocode: $e'); }

      // Soil classification
      final sType = getSoilTypeFromLocation(lat, lon);
      final soilVals = _getSoilValuesForType(sType);

      setState(() {
        _location = locName;
        _temperature = temp;
        _humidity = hum;
        _rainfallChance = rainPr;
        _soilType = sType;
        _soilMoisture = soilVals['moisture']!;
        _phLevel = soilVals['ph']!;
        _nitrogen = soilVals['n']!;
        _phosphorus = soilVals['p']!;
        _potassium = soilVals['k']!;
        _isLoadingLocation = false;
      });

      if (showSnackbar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: const Color(0xFF1E5E4A),
          content: Text('GPS Location updated to $_location! Soil: $sType.'),
        ));
      }

      // Check urgent alerts from shared context
      if (_farmSnapshot.hasUrgentAlert && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
          content: Text(_farmSnapshot.urgentAlertMessage),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if (showSnackbar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red[800],
          content: Text('GPS failed: $e. Using default Pune data.'),
        ));
      }
    }
  }

  Map<String, double> _getSoilValuesForType(String sType) {
    switch (sType) {
      case 'Black Soil': return {'moisture': 72, 'ph': 7.6, 'n': 78, 'p': 62, 'k': 80};
      case 'Red Soil':   return {'moisture': 48, 'ph': 6.2, 'n': 55, 'p': 75, 'k': 45};
      case 'Sandy Soil': return {'moisture': 22, 'ph': 7.1, 'n': 30, 'p': 40, 'k': 35};
      default:           return {'moisture': 80, 'ph': 6.5, 'n': 75, 'p': 55, 'k': 68}; // Clay
    }
  }

  String getSoilTypeFromLocation(double lat, double lon) {
    if (lat >= 8 && lat <= 36 && lon >= 68 && lon <= 97) {
      if (lat >= 24 && lat <= 30 && lon >= 69 && lon <= 75) return 'Sandy Soil';
      if (lat >= 16 && lat <= 23 && lon >= 72 && lon <= 79) return 'Black Soil';
      if (lat >= 8  && lat <= 15 && lon >= 74 && lon <= 80) return 'Red Soil';
    }
    switch ((lat.abs() * 100 + lon.abs() * 100).toInt() % 4) {
      case 0: return 'Red Soil';
      case 1: return 'Black Soil';
      case 2: return 'Sandy Soil';
      default: return 'Clay Soil';
    }
  }

  // ─── Camera Scanner ────────────────────────────────────────────────────────

  Future<void> _startCameraScanner() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (ctx) => CameraScannerScreen(
          isHindi: _isHindi,
          farmSnapshot: _farmSnapshot,
        ),
      ),
    );

    if (result != null && mounted) {
      final fullResult = result['fullResult'] as Map<String, dynamic>? ?? {};
      setState(() {
        _selectedTab = 4;
        _historicalLogs.insert(0, {
          'crop': result['cropName'],
          'issue': result['disease'],
          'status': result['status'],
          'desc': _isHindi
              ? 'सफलता: ${result['cropName']} में ${result['disease']} रोग का विश्लेषण पूरा। ${result['desc']}'
              : 'Success: ${result['cropName']} ${result['disease']} analyzed. ${result['desc']}',
          'date': 'Today',
          'imageUrl': result['imageUrl'] ?? 'https://images.unsplash.com/photo-1592417817098-8f3d6eb19675?auto=format&fit=crop&q=80&w=200',
        });
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(_isHindi ? 'विश्लेषण पूरा हुआ!' : 'Analysis Complete!',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          content: Text(
            _isHindi
                ? 'रोग: ${result['disease']} (${result['confidence']}% सटीक).\n${result['desc']}'
                : 'Detected: ${result['disease']} (${result['confidence'].toStringAsFixed(0)}% confidence).\n${result['desc']}',
          ),
          actions: [
            if (fullResult['expertRecommended'] == true)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showBookVisitDialog();
                },
                child: Text(_isHindi ? 'विशेषज्ञ बुलाएं' : 'Book Expert',
                    style: const TextStyle(color: Colors.deepOrange)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: Color(0xFF1E5E4A), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  // ─── Voice Assistant ───────────────────────────────────────────────────────

  void _triggerVoiceAssistant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      builder: (ctx) => VoiceAssistantSheet(
        farmSnapshot: _farmSnapshot,
        isHindi: _isHindi,
        onAction: _handleVoiceAction,
      ),
    );
  }

  void _handleVoiceAction(String action, {Map<String, dynamic>? params}) {
    switch (action) {
      case 'navigate_home':
        _onTabChanged(0);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Color(0xFF1E5E4A),
          content: Text('Navigating to Home Dashboard'),
        ));
        break;
      case 'navigate_advice':
        _onTabChanged(1);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Color(0xFF1E5E4A),
          content: Text('Navigating to Advisory page'),
        ));
        break;
      case 'navigate_weather':
        _onTabChanged(2);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Color(0xFF1E5E4A),
          content: Text('Navigating to Weather & Advisories'),
        ));
        break;
      case 'navigate_crops':
        _onTabChanged(3);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Color(0xFF1E5E4A),
          content: Text('Navigating to Crops & Market section'),
        ));
        break;
      case 'navigate_expert':
        _onTabChanged(4);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Color(0xFF1E5E4A),
          content: Text('Navigating to Experts and scanner'),
        ));
        break;
      case 'start_diagnosis':
        _onTabChanged(4);
        Future.delayed(const Duration(milliseconds: 300), _startCameraScanner);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Color(0xFF1E5E4A),
          content: Text('Opening Crop Scanner...'),
        ));
        break;
      case 'log_harvest':
        Future.delayed(const Duration(milliseconds: 300), _showHarvestFormDialog);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Color(0xFF1E5E4A),
          content: Text('Opening Harvest Form...'),
        ));
        break;
      case 'book_expert':
        _onTabChanged(4);
        Future.delayed(const Duration(milliseconds: 300), _showBookVisitDialog);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Color(0xFF1E5E4A),
          content: Text('Opening Expert Appointment form...'),
        ));
        break;
      case 'irrigate_confirm':
        _showIrrigationConfirm();
        break;
      case 'fertilizer_confirm':
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: const Color(0xFF1E5E4A),
          content: Text(_farmSnapshot.fertilizerAdvice),
          duration: const Duration(seconds: 5),
        ));
        break;
      case 'configure_parameters':
        Future.delayed(const Duration(milliseconds: 300), _showConfigureParametersDialog);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Color(0xFF1E5E4A),
          content: Text('Opening Farm Parameter configurations panel'),
        ));
        break;
      case 'change_language_hi':
        setState(() { _isHindi = true; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Color(0xFF1E5E4A),
          content: Text('भाषा बदलकर हिंदी की गई।'),
        ));
        break;
      case 'change_language_en':
        setState(() { _isHindi = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Color(0xFF1E5E4A),
          content: Text('Language switched to English.'),
        ));
        break;
      case 'change_language_ta':
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Color(0xFF1E5E4A),
          content: Text('Switched voice assistant context to Tamil.'),
        ));
        break;
      case 'change_language_te':
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Color(0xFF1E5E4A),
          content: Text('Switched voice assistant context to Telugu.'),
        ));
        break;
      case 'change_language_mr':
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Color(0xFF1E5E4A),
          content: Text('Switched voice assistant context to Marathi.'),
        ));
        break;
    }
  }

  void _showIrrigationConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.water_drop_outlined, color: Color(0xFF1E5E4A)),
          SizedBox(width: 8),
          Text('Schedule Irrigation?', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        content: Text(_farmSnapshot.irrigationAdvice),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                backgroundColor: Color(0xFF1E5E4A),
                content: Text('Irrigation scheduled for today. Field sensors will monitor progress.'),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E5E4A), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _onTabChanged(int index) => setState(() => _selectedTab = index);

  // ─── Diagnosis ─────────────────────────────────────────────────────────────

  void _startDiagnosis() {
    _diagnosisTimer?.cancel();
    setState(() {
      _selectedTab = 4;
      _isDiagnosing = true;
      _diagnosisProgress = 0.0;
    });
    _diagnosisTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      setState(() {
        if (_diagnosisProgress < 1.0) {
          _diagnosisProgress += 0.04;
        } else {
          _isDiagnosing = false;
          timer.cancel();
          _finalizeDiagnosis();
        }
      });
    });
  }

  void _finalizeDiagnosis() {
    setState(() {
      _historicalLogs.insert(0, {
        'crop': 'Rice',
        'issue': 'Blast',
        'status': 'Resolved',
        'desc': _isHindi
            ? 'सफलता: धान के ब्लास्ट लक्षणों का नियंत्रण पूरा। जैविक पोटेशियम छिड़काव की सिफारिश।'
            : 'Success: Rice Blast analyzed. Organic Potassium fungicide recommended.',
        'date': 'Today',
        'imageUrl': 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?auto=format&fit=crop&q=80&w=200',
      });
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: const [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('Diagnosis Complete!', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        content: Text(
          _isHindi
              ? 'धान के ब्लास्ट रोग के लक्षणों की पहचान। यूरिया सीमित करें और पोटेशियम कवकनाशी (2g/L) डालें।'
              : 'Rice Blast symptoms detected. Stop urea immediately. Apply potassium fungicide 2g/L at sunset.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Color(0xFF1E5E4A), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _cancelDiagnosis() {
    _diagnosisTimer?.cancel();
    setState(() { _isDiagnosing = false; _diagnosisProgress = 0.0; });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Diagnosis cancelled.')));
  }

  // ─── Dialogs ───────────────────────────────────────────────────────────────

  void _showSoilReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AgriLanguage.text('soilHealth', _isHindi),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E5E4A))),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildSoilMetricBar('Nitrogen (N) - ${_nitrogen.round()}%', _nitrogen / 100, _nitrogen >= 40 ? Colors.green : Colors.orange),
            const SizedBox(height: 10),
            _buildSoilMetricBar('Phosphorus (P) - ${_phosphorus.round()}%', _phosphorus / 100, _phosphorus >= 40 ? Colors.green : Colors.orange),
            const SizedBox(height: 10),
            _buildSoilMetricBar('Potassium (K) - ${_potassium.round()}%', _potassium / 100, _potassium >= 40 ? Colors.green : Colors.orange),
            const SizedBox(height: 10),
            _buildSoilMetricBar('pH Level - ${_phLevel.toStringAsFixed(1)}', (_phLevel - 4) / 5, Colors.green),
            const SizedBox(height: 10),
            _buildSoilMetricBar('Moisture - ${_soilMoisture.round()}%', _soilMoisture / 100, _soilMoisture >= 30 ? Colors.blue : Colors.red),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 8),
            // AI-driven recommendation from shared context
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF0F6F3), borderRadius: BorderRadius.circular(10)),
              child: Text(
                '🤖 ${_farmSnapshot.fertilizerAdvice}',
                style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF1E352C)),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF1E5E4A))),
          ),
        ],
      ),
    );
  }

  Widget _buildSoilMetricBar(String label, double ratio, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 6, width: double.infinity, color: const Color(0xFFECEFEF),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: ratio.clamp(0.0, 1.0),
              child: Container(color: color),
            ),
          ),
        ),
      ),
    ]);
  }

  void _showHarvestFormDialog() {
    final quantityController = TextEditingController();
    String cropSelected = 'Soybeans';
    String sectorSelected = 'North Field';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(AgriLanguage.text('logNewHarvest', _isHindi),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E5E4A))),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                initialValue: cropSelected,
                decoration: const InputDecoration(labelText: 'Crop Title'),
                items: ['Soybeans', 'Groundnut', 'Wheat', 'Pigeon Pea']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setDialogState(() => cropSelected = val ?? cropSelected),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: sectorSelected,
                decoration: const InputDecoration(labelText: 'Field Sector'),
                items: ['North Field', 'South Field', 'Sector B-4', 'Sector A']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setDialogState(() => sectorSelected = val ?? sectorSelected),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harvested Weight (Quintals)'),
              ),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
              TextButton(
                onPressed: () {
                  final qty = double.tryParse(quantityController.text) ?? 0;
                  if (qty > 0) {
                    setState(() {
                      _harvestLogs.insert(0, {'crop': cropSelected, 'sector': sectorSelected, 'quantity': qty, 'date': 'Today'});
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      backgroundColor: Color(0xFF1E5E4A),
                      content: Text('Harvest logged successfully!'),
                    ));
                  }
                },
                child: const Text('Save', style: TextStyle(color: Color(0xFF1E5E4A), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBookVisitDialog() {
    final nameController = TextEditingController(text: widget.profile.name);
    String slotSelected = 'Morning Slot: 9 AM - 12 PM';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(AgriLanguage.text('bookVisit', _isHindi),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0277BD))),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Farmer Full Name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: slotSelected,
              decoration: const InputDecoration(labelText: 'Preferred Time Slot'),
              items: ['Morning Slot: 9 AM - 12 PM', 'Afternoon Slot: 2 PM - 5 PM']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => setDialogState(() => slotSelected = val ?? slotSelected),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Visit Booked!', style: TextStyle(fontWeight: FontWeight.bold)),
                      content: Text(
                        _isHindi
                            ? 'रायथू सेवा केंद्र विशेषज्ञ नियुक्त किया गया। टिकट: RSK-24017।'
                            : 'Expert scheduled. Ticket: RSK-24017. Advisor will visit $slotSelected.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('OK', style: TextStyle(color: Color(0xFF0277BD))),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: const Text('Confirm', style: TextStyle(color: Color(0xFF0277BD), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Simulation Panel ──────────────────────────────────────────────────────
  // When params change here → _farmSnapshot re-computed → AI, voice, home all update

  void _showConfigureParametersDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + bottomInset),
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(_isHindi ? 'फ़ार्म पैरामीटर सेटिंग्स' : 'Farm Parameter Adjustments',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E5E4A))),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ]),
                  const SizedBox(height: 8),

                  // AI alerts from current settings
                  if (_farmSnapshot.hasUrgentAlert)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(_farmSnapshot.urgentAlertMessage,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                    ),

                  // Soil Type
                  const Text('Soil Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _soilType,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: ['Red Soil', 'Black Soil', 'Sandy Soil', 'Clay Soil']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() => _soilType = val);
                        final v = _getSoilValuesForType(val);
                        setSheetState(() {
                          _soilMoisture = v['moisture']!;
                          _phLevel = v['ph']!;
                          _nitrogen = v['n']!;
                          _phosphorus = v['p']!;
                          _potassium = v['k']!;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildSliderOption(_isHindi ? 'मिट्टी की नमी' : 'Soil Moisture', _soilMoisture, 0, 100, '%',
                      (v) => setSheetState(() => _soilMoisture = v)),
                  _buildSliderOption('pH Level', _phLevel, 4, 9, '', (v) => setSheetState(() => _phLevel = v), divisions: 50),
                  _buildSliderOption('Nitrogen (N)', _nitrogen, 0, 100, '%', (v) => setSheetState(() => _nitrogen = v)),
                  _buildSliderOption('Phosphorus (P)', _phosphorus, 0, 100, '%', (v) => setSheetState(() => _phosphorus = v)),
                  _buildSliderOption('Potassium (K)', _potassium, 0, 100, '%', (v) => setSheetState(() => _potassium = v)),
                  _buildSliderOption(_isHindi ? 'तापमान' : 'Temperature', _temperature, 10, 50, '°C',
                      (v) => setSheetState(() => _temperature = v)),
                  _buildSliderOption(_isHindi ? 'आर्द्रता' : 'Humidity', _humidity, 10, 100, '%',
                      (v) => setSheetState(() => _humidity = v)),
                  _buildSliderOption(_isHindi ? 'वर्षा की संभावना' : 'Rain Probability', _rainfallChance, 0, 100, '%',
                      (v) => setSheetState(() => _rainfallChance = v)),
                  _buildSliderOption(_isHindi ? 'बाजार मूल्य' : 'Market Price (₹)', _marketPrice, 1500, 5000, '',
                      (v) => setSheetState(() => _marketPrice = v), divisions: 70),

                  const SizedBox(height: 18),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF1E5E4A)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          setSheetState(() {
                            _location = 'Pune, Maharashtra'; _temperature = 32; _humidity = 64; _rainfallChance = 20;
                            _soilType = 'Red Soil'; _soilMoisture = 65; _phLevel = 6.5;
                            _nitrogen = 85; _phosphorus = 70; _potassium = 40; _marketPrice = 2450;
                          });
                        },
                        child: Text(_isHindi ? 'रिसेट करें' : 'Reset to Demo',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E5E4A))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E5E4A), foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          // setState triggers _farmSnapshot recompute → all AI features update
                          setState(() {
                            if (_marketPriceHistory.isEmpty || _marketPriceHistory.last != _marketPrice) {
                              _marketPriceHistory.add(_marketPrice);
                              if (_marketPriceHistory.length > 7) _marketPriceHistory.removeAt(0);
                            }
                          });
                          Navigator.pop(context);

                          // Show AI-driven update summary
                          final snap = _farmSnapshot;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            backgroundColor: snap.hasUrgentAlert ? Colors.red.shade700 : const Color(0xFF1E5E4A),
                            duration: const Duration(seconds: 4),
                            behavior: SnackBarBehavior.floating,
                            content: Text(snap.hasUrgentAlert
                                ? snap.urgentAlertMessage
                                : '✅ Parameters applied. ${snap.irrigationAdvice}'),
                          ));
                        },
                        child: Text(_isHindi ? 'लागू करें' : 'Apply Changes',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSliderOption(String label, double val, double min, double max, String suffix,
      Function(double) onChange, {int? divisions}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        Text(
          '${divisions != null && divisions > 10 ? val.toStringAsFixed(1) : val.round()}$suffix',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E352C)),
        ),
      ]),
      Slider(
        value: val, min: min, max: max,
        divisions: divisions ?? (max - min).toInt(),
        activeColor: const Color(0xFF1E5E4A),
        inactiveColor: const Color(0xFFE8ECE9),
        onChanged: onChange,
      ),
    ]);
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      HomeTab(
        isHindi: _isHindi,
        onViewSoilReport: _showSoilReportDialog,
        onLogHarvest: _showHarvestFormDialog,
        onMicTap: _triggerVoiceAssistant,
        onNavigateTab: _onTabChanged,
        location: _location,
        temperature: _temperature,
        humidity: _humidity,
        rainfallChance: _rainfallChance,
        soilType: _soilType,
        soilMoisture: _soilMoisture,
        phLevel: _phLevel,
        nitrogen: _nitrogen,
        marketPrice: _marketPrice,
        marketPriceHistory: _marketPriceHistory,
        onConfigureParameters: _showConfigureParametersDialog,
      ),
      AdviceTab(
        isHindi: _isHindi,
        onSelectPlantingPlan: (cropName, duration) {
          setState(() {
            _activeCrops.insert(0, {'name': cropName, 'duration': duration, 'progress': 10, 'plantedDate': 'Today'});
            _selectedTab = 3;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: const Color(0xFF1E5E4A),
            content: Text('$cropName planting plan started!'),
          ));
        },
        soilType: _soilType,
        soilMoisture: _soilMoisture,
        nitrogen: _nitrogen,
        phosphorus: _phosphorus,
        potassium: _potassium,
      ),
      WeatherTab(
        isHindi: _isHindi,
        thermalView: _thermalView,
        onToggleThermalView: () => setState(() => _thermalView = !_thermalView),
        location: _location,
        temperature: _temperature,
        humidity: _humidity,
        rainfallChance: _rainfallChance,
        soilMoisture: _soilMoisture,
      ),
      CropsTab(
        isHindi: _isHindi,
        activeCrops: _activeCrops,
        harvestLogs: _harvestLogs,
        onLogHarvest: _showHarvestFormDialog,
        onAddCropPlan: (name, dur) => setState(() {
          _activeCrops.insert(0, {'name': name, 'duration': dur, 'progress': 5, 'plantedDate': 'Today'});
        }),
      ),
      ExpertTab(
        isHindi: _isHindi,
        isDiagnosing: _isDiagnosing,
        diagnosisProgress: _diagnosisProgress,
        historicalLogs: _historicalLogs,
        onTakePhoto: _startCameraScanner,
        onCancelDiagnosis: _cancelDiagnosis,
        onBookVisit: _showBookVisitDialog,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF7F5),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 44,
        leading: _isLoadingLocation
            ? const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Center(child: SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E5E4A)))),
              )
            : Padding(
                padding: const EdgeInsets.only(left: 6),
                child: IconButton(
                  icon: const Icon(Icons.location_on_outlined, color: Color(0xFF1E5E4A), size: 24),
                  tooltip: _isHindi ? 'स्थान अपडेट करें' : 'Update location',
                  onPressed: () => _fetchMyLocationAndData(showSnackbar: true),
                ),
              ),
        title: Text(
          AgriLanguage.text('title', _isHindi),
          style: const TextStyle(color: Color(0xFF123C32), fontSize: 22, fontWeight: FontWeight.w900),
        ),
        actions: [
          // Simulation panel
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF123C32)),
            tooltip: 'Adjust Parameters',
            onPressed: _showConfigureParametersDialog,
          ),
          // Urgent alert indicator
          if (_farmSnapshot.hasUrgentAlert)
            IconButton(
              icon: const Icon(Icons.warning_amber_rounded, color: Colors.red),
              tooltip: _farmSnapshot.urgentAlertMessage,
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: Colors.red.shade700,
                content: Text(_farmSnapshot.urgentAlertMessage),
              )),
            ),
          // Language toggle
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              onTap: () => setState(() => _isHindi = !_isHindi),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFD8F3E5), borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  const Icon(Icons.translate, size: 14, color: Color(0xFF1B5E4F)),
                  const SizedBox(width: 4),
                  Text(_isHindi ? 'English' : 'हिंदी',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B5E4F))),
                ]),
              ),
            ),
          ),
          // Notifications
          IconButton(
            icon: Icon(
              Icons.notifications_none_rounded,
              color: _farmSnapshot.hasUrgentAlert ? Colors.red : const Color(0xFF123C32),
            ),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(_farmSnapshot.hasUrgentAlert
                  ? _farmSnapshot.urgentAlertMessage
                  : 'No urgent alerts. Soil moisture at ${_soilMoisture.round()}%.'),
            )),
          ),
          // Profile Avatar Menu
          ProfileAvatarMenu(
            profile: widget.profile,
            onLogout: widget.onLogout,
          ),
        ],
      ),
      body: tabs[_selectedTab],
      floatingActionButton: FloatingActionButton(
        onPressed: _triggerVoiceAssistant,
        backgroundColor: const Color(0xFF124338),
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.mic, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: _onTabChanged,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home),
              label: AgriLanguage.text('home', _isHindi)),
          NavigationDestination(icon: const Icon(Icons.psychology_outlined), selectedIcon: const Icon(Icons.psychology),
              label: AgriLanguage.text('advice', _isHindi)),
          NavigationDestination(icon: const Icon(Icons.calendar_month_outlined), selectedIcon: const Icon(Icons.calendar_month),
              label: AgriLanguage.text('weather', _isHindi)),
          NavigationDestination(icon: const Icon(Icons.spa_outlined), selectedIcon: const Icon(Icons.spa),
              label: AgriLanguage.text('crops', _isHindi)),
          NavigationDestination(icon: const Icon(Icons.support_agent_outlined), selectedIcon: const Icon(Icons.support_agent),
              label: AgriLanguage.text('expert', _isHindi)),
        ],
      ),
    );
  }
}
