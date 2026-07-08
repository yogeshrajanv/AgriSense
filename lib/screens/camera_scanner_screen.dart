// lib/screens/camera_scanner_screen.dart
// Enhanced AI crop image analysis using Gemini API.
// Features: camera capture, gallery upload, image preview, AI diagnosis with farm context.
// Falls back gracefully to mock diagnosis when API key is absent.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../models/farmer_context.dart';
import '../services/gemini_service.dart';

class CameraScannerScreen extends StatefulWidget {
  final bool isHindi;
  final FarmSnapshot? farmSnapshot;

  const CameraScannerScreen({
    super.key,
    required this.isHindi,
    this.farmSnapshot,
  });

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen>
    with TickerProviderStateMixin {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isCameraError = false;
  String _cameraErrorMessage = '';

  // Image state
  File? _selectedImageFile;
  String? _base64Image;

  // Analysis state
  bool _isAnalyzing = false;
  double _scanProgress = 0.0;
  String _currentStepText = 'Initializing scan...';
  Map<String, dynamic>? _diagnosisResult;

  // Demo sample selection (fallback)
  int _selectedDemoIndex = 0;

  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final ImagePicker _imagePicker = ImagePicker();

  final List<Map<String, dynamic>> _demoSamples = [
    {
      'name': 'Tomato Leaf (Blight)',
      'cropName': 'Tomato',
      'disease': 'Early Blight',
      'confidence': 94.2,
      'status': 'In Review',
      'desc': 'Early Blight symptoms detected. Concentric rings on older leaves. Recommended: Treat with copper fungicide, prune lower foliage.',
      'imageUrl': 'https://images.unsplash.com/photo-1592417817098-8f3d6eb19675?auto=format&fit=crop&q=80&w=200',
    },
    {
      'name': 'Rice Leaf (Blast)',
      'cropName': 'Rice',
      'disease': 'Blast',
      'confidence': 89.6,
      'status': 'Resolved',
      'desc': 'Rice Blast symptoms detected. Spindle-shaped lesions. Recommended: Apply organic potassium fungicide, limit nitrogen distribution.',
      'imageUrl': 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?auto=format&fit=crop&q=80&w=200',
    },
    {
      'name': 'Maize Leaf (Chlorosis)',
      'cropName': 'Maize',
      'disease': 'Chlorosis',
      'confidence': 91.5,
      'status': 'In Review',
      'desc': 'Chlorosis detected. Interveinal yellowing indicative of Nitrogen deficiency. Recommended: Increase Nitrogen application by 15%.',
      'imageUrl': 'https://images.unsplash.com/photo-1530595467537-0b5996c41f2d?auto=format&fit=crop&q=80&w=200',
    },
    {
      'name': 'Healthy Soybean',
      'cropName': 'Soybeans',
      'disease': 'None (Healthy)',
      'confidence': 98.1,
      'status': 'Resolved',
      'desc': 'Healthy Soybean canopy. Green ratios optimal. Recommended: Maintain standard irrigation weather routing.',
      'imageUrl': 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&q=80&w=200',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _controller = CameraController(
          _cameras[0],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _controller!.initialize();
        if (mounted) setState(() => _isCameraInitialized = true);
      } else {
        if (mounted) {
          setState(() {
            _isCameraError = true;
            _cameraErrorMessage = 'No cameras found. Use gallery upload below.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraError = true;
          _cameraErrorMessage = 'Camera access failed. Use gallery upload below.';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Image Capture / Select ───────────────────────────────────────────────

  Future<void> _captureFromCamera() async {
    if (_controller == null || !_isCameraInitialized) return;
    try {
      final xFile = await _controller!.takePicture();
      await _loadImageFile(File(xFile.path));
    } catch (e) {
      _showError('Failed to capture: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
      );
      if (picked != null) {
        await _loadImageFile(File(picked.path));
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _loadImageFile(File file) async {
    final bytes = await file.readAsBytes();
    setState(() {
      _selectedImageFile = file;
      _base64Image = base64Encode(bytes);
      _diagnosisResult = null;
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade700,
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── AI Analysis ─────────────────────────────────────────────────────────

  Future<void> _startGeminiAnalysis() async {
    final farm = widget.farmSnapshot ?? const FarmSnapshot(
      location: 'Pune, Maharashtra', temperature: 32, humidity: 64,
      rainfallChance: 20, soilType: 'Red Soil', soilMoisture: 65,
      phLevel: 6.5, nitrogen: 85, phosphorus: 70, potassium: 40,
      marketPrice: 2450, activeCrops: [], harvestLogs: [], historicalDiagnoses: [],
    );

    setState(() {
      _isAnalyzing = true;
      _scanProgress = 0.0;
      _currentStepText = 'Scanning crop features...';
    });

    // Animate progress
    const steps = [
      'Locating foliage boundaries...',
      'Analyzing leaf pigmentation...',
      'Cross-referencing disease database...',
      'Evaluating farm conditions...',
      'Generating diagnostic report...',
    ];

    int stepIndex = 0;
    final progressTimer = Timer.periodic(const Duration(milliseconds: 350), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _scanProgress = (_scanProgress + 0.08).clamp(0.0, 0.85);
        if (stepIndex < steps.length - 1) {
          _currentStepText = steps[stepIndex];
          stepIndex++;
        }
      });
    });

    Map<String, dynamic> result;
    if (_base64Image != null) {
      result = await GeminiService.diagnoseCropImage(
        base64Image: _base64Image!,
        farm: farm,
      );
    } else {
      // Demo sample path
      final sample = _demoSamples[_selectedDemoIndex];
      await Future.delayed(const Duration(seconds: 2));
      result = {
        'crop': sample['cropName'],
        'disease': sample['disease'],
        'confidence': sample['confidence'].toInt(),
        'severity': 'Medium',
        'symptoms': sample['desc'],
        'causes': 'Fungal/bacterial pathogen identified via visual markers.',
        'immediateAction': 'Isolate affected plants. Apply recommended treatment.',
        'treatment': sample['desc'],
        'irrigationAdvice': farm.irrigationAdvice,
        'fertilizerAdvice': farm.fertilizerAdvice,
        'preventionTips': 'Rotate crops, maintain plant spacing, apply preventive fungicide.',
        'expertRecommended': (sample['confidence'] as double) < 90,
        'isDemo': true,
        'imageUrl': sample['imageUrl'],
      };
    }

    progressTimer.cancel();

    if (!mounted) return;
    setState(() {
      _scanProgress = 1.0;
      _isAnalyzing = false;
      _diagnosisResult = result;
    });
  }

  void _returnResult() {
    if (_diagnosisResult == null) return;
    final r = _diagnosisResult!;
    Navigator.pop(context, {
      'cropName': r['crop'] ?? 'Unknown',
      'disease': r['disease'] ?? 'Unknown',
      'confidence': (r['confidence'] as num?)?.toDouble() ?? 80.0,
      'status': 'In Review',
      'desc': r['treatment'] ?? r['symptoms'] ?? '',
      'imageUrl': _selectedImageFile != null
          ? '' // local file — handled in caller
          : (r['imageUrl'] ?? _demoSamples[_selectedDemoIndex]['imageUrl']),
      'fullResult': r,
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.isHindi ? 'फसल पत्ता स्कैन' : 'Crop Leaf Scanner',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!GeminiService.hasApiKey)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('DEMO', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _diagnosisResult != null
          ? _buildResultView()
          : _isAnalyzing
              ? _buildAnalyzingView()
              : _buildScannerView(),
    );
  }

  // ─── Scanner View ─────────────────────────────────────────────────────────

  Widget _buildScannerView() {
    return Stack(
      children: [
        // Viewfinder or selected image
        Positioned.fill(
          child: _selectedImageFile != null
              ? _buildImagePreview()
              : (_isCameraInitialized && _controller != null)
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: CameraPreview(_controller!),
                    )
                  : _buildFallbackPreview(),
        ),

        // Scan overlay (only if no image selected)
        if (_selectedImageFile == null && !_isCameraError)
          _buildScanningOverlay(),

        // Bottom tray
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: _buildBottomTray(),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _selectedImageFile!,
                fit: BoxFit.contain,
                height: MediaQuery.of(context).size.height * 0.6,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() { _selectedImageFile = null; _base64Image = null; }),
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackPreview() {
    return Container(
      color: const Color(0xFF121A16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.no_photography_outlined, size: 52, color: Colors.white38),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _isCameraError ? _cameraErrorMessage : 'Live camera unavailable.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a demo leaf sample or upload from gallery:',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 16),
            _buildDemoSelectorGrid(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoSelectorGrid() {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _demoSamples.length,
        itemBuilder: (context, index) {
          final sample = _demoSamples[index];
          final isSelected = _selectedDemoIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedDemoIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 130,
              margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1E3A28) : const Color(0xFF1E2823),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF2E7D3F) : Colors.transparent,
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      sample['imageUrl'],
                      width: 50, height: 50, fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.amber, size: 28),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sample['name'],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Positioned.fill(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: double.infinity,
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            child: Text(
              widget.isHindi
                  ? 'रोग की पहचान के लिए पत्ते को फ्रेम में रखें'
                  : 'Align a leaf inside the scanner frame',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (ctx, _) => Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 220, height: 220,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.greenAccent, width: 2.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 160),
        ],
      ),
    );
  }

  Widget _buildBottomTray() {
    return Container(
      color: Colors.black.withOpacity(0.82),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Upload / Analyze row
          Row(
            children: [
              // Gallery button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Camera capture (if available)
              if (_isCameraInitialized)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _captureFromCamera,
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Capture'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Analyze / Scan button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startGeminiAnalysis,
              icon: const Icon(Icons.biotech_outlined, size: 20),
              label: Text(
                _selectedImageFile != null
                    ? (widget.isHindi ? 'छवि का विश्लेषण करें (Gemini AI)' : 'Analyze This Image with Gemini AI')
                    : (widget.isHindi ? 'नमूना स्कैन प्रारंभ करें' : 'Run Demo Scan'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E5E4A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Analyzing View ───────────────────────────────────────────────────────

  Widget _buildAnalyzingView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140, height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      border: Border.all(color: Colors.greenAccent.withOpacity(0.3), width: 1.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(
                    width: 110, height: 110,
                    child: CircularProgressIndicator(
                      value: _scanProgress,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                      backgroundColor: Colors.white10,
                      strokeWidth: 3,
                    ),
                  ),
                  const Icon(Icons.science, color: Colors.greenAccent, size: 40),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                widget.isHindi ? 'Gemini AI विश्लेषण चल रहा है...' : 'Running Gemini AI Analysis...',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _currentStepText,
                style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _scanProgress,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_scanProgress * 100).toInt()}% Analysed',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Result View ──────────────────────────────────────────────────────────

  Widget _buildResultView() {
    final r = _diagnosisResult!;
    final bool isDemo = r['isDemo'] as bool? ?? false;
    final bool expertRecommended = r['expertRecommended'] as bool? ?? false;
    final int confidence = (r['confidence'] as num?)?.toInt() ?? 80;
    final String severity = r['severity']?.toString() ?? 'Medium';
    final Color severityColor = severity == 'High' ? Colors.red :
        severity == 'Medium' ? Colors.orange : Colors.green;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF7F5),
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF123C32),
        elevation: 0,
        title: Text(
          widget.isHindi ? 'निदान परिणाम' : 'Diagnosis Result',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF123C32)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header labels
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8F3E5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isDemo ? '⚗️ Demo Analysis' : '🤖 AI-assisted preliminary diagnosis',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E5E4A)),
                  ),
                ),
                if (expertRecommended) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: const Text(
                      '👨‍⚕️ Expert review recommended',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Main diagnosis card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8ECE9)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${r['crop'] ?? 'Unknown Crop'}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E352C)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              r['disease'] ?? 'No disease detected',
                              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$confidence%',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E5E4A)),
                          ),
                          const Text('Confidence', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: severityColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Severity: $severity',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: severityColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  _resultRow(Icons.visibility_outlined, 'Symptoms', r['symptoms']),
                  _resultRow(Icons.help_outline, 'Causes', r['causes']),
                  _resultRow(Icons.flash_on_outlined, 'Immediate Action', r['immediateAction']),
                  _resultRow(Icons.medical_services_outlined, 'Treatment', r['treatment']),
                  _resultRow(Icons.water_drop_outlined, 'Irrigation', r['irrigationAdvice']),
                  _resultRow(Icons.science_outlined, 'Fertilizer', r['fertilizerAdvice']),
                  _resultRow(Icons.shield_outlined, 'Prevention', r['preventionTips']),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action buttons
            ElevatedButton.icon(
              onPressed: _returnResult,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                widget.isHindi ? 'लॉग में सहेजें' : 'Save to Diagnosis Log',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E5E4A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _diagnosisResult = null;
                _selectedImageFile = null;
                _base64Image = null;
                _scanProgress = 0;
              }),
              icon: const Icon(Icons.refresh, size: 18, color: Color(0xFF1E5E4A)),
              label: Text(
                widget.isHindi ? 'पुनः स्कैन करें' : 'Scan Again',
                style: const TextStyle(color: Color(0xFF1E5E4A)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1E5E4A)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(IconData icon, String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1E5E4A)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value.toString(), style: const TextStyle(fontSize: 13, color: Color(0xFF1E352C), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
