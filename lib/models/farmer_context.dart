// lib/models/farmer_context.dart
// Shared farmer context — single source of truth for all AI features.
// When simulation params change, everything (AI, voice, disease analysis) re-reads from here.

import 'package:flutter/material.dart';

class FarmerProfile {
  final String name;
  final String mobile;
  final String location;
  final String language; // 'en' | 'hi' | 'ta' | 'te' | 'mr'

  const FarmerProfile({
    required this.name,
    required this.mobile,
    required this.location,
    this.language = 'en',
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'mobile': mobile,
    'location': location,
    'language': language,
  };

  factory FarmerProfile.fromMap(Map<String, dynamic> m) => FarmerProfile(
    name: m['name'] ?? 'Demo Farmer',
    mobile: m['mobile'] ?? '9876543210',
    location: m['location'] ?? 'Pune, Maharashtra',
    language: m['language'] ?? 'en',
  );

  static FarmerProfile get demo => const FarmerProfile(
    name: 'Ramesh Patil',
    mobile: '9876543210',
    location: 'Pune, Maharashtra',
    language: 'en',
  );
}

/// Immutable snapshot of the current farm environment.
class FarmSnapshot {
  final String location;
  final double temperature;
  final double humidity;
  final double rainfallChance;
  final String soilType;
  final double soilMoisture;
  final double phLevel;
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final double marketPrice;
  final List<Map<String, dynamic>> activeCrops;
  final List<Map<String, dynamic>> harvestLogs;
  final List<Map<String, dynamic>> historicalDiagnoses;

  const FarmSnapshot({
    required this.location,
    required this.temperature,
    required this.humidity,
    required this.rainfallChance,
    required this.soilType,
    required this.soilMoisture,
    required this.phLevel,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.marketPrice,
    required this.activeCrops,
    required this.harvestLogs,
    required this.historicalDiagnoses,
  });

  String get primaryCropName =>
    activeCrops.isNotEmpty ? (activeCrops.first['name'] as String? ?? 'Unknown Crop') : 'No Active Crop';

  String get primaryCropGrowthStage {
    if (activeCrops.isEmpty) return 'N/A';
    final progress = activeCrops.first['progress'] as int? ?? 0;
    if (progress < 20)  return 'Germination';
    if (progress < 40)  return 'Vegetative';
    if (progress < 60)  return 'Flowering';
    if (progress < 80)  return 'Pod / Grain Fill';
    return 'Maturity / Harvest';
  }

  String get irrigationAdvice {
    if (soilMoisture < 30) return 'Critical: Irrigate immediately. Soil moisture is dangerously low at ${soilMoisture.round()}%.';
    if (soilMoisture < 50) return 'Recommended: Schedule irrigation in the next 24 hours. Moisture at ${soilMoisture.round()}%.';
    if (rainfallChance > 60) return 'Hold: ${rainfallChance.round()}% rain probability today. Skip irrigation and monitor.';
    return 'Optimal: Soil moisture is at ${soilMoisture.round()}%. No irrigation needed today.';
  }

  String get fertilizerAdvice {
    final issues = <String>[];
    if (nitrogen < 40)    issues.add('Low Nitrogen — apply Urea (50kg/ha)');
    if (phosphorus < 40)  issues.add('Low Phosphorus — apply DAP (25kg/ha)');
    if (potassium < 40)   issues.add('Low Potassium — apply MOP (30kg/ha)');
    if (issues.isEmpty)   return 'Nutrients balanced. No fertilizer needed right now.';
    return issues.join('. ') + '.';
  }

  bool get hasUrgentAlert => soilMoisture < 20 || temperature > 42 || (rainfallChance > 80 && soilMoisture > 80);

  String get urgentAlertMessage {
    if (soilMoisture < 20) return '⚠️ Critical: Soil moisture at ${soilMoisture.round()}%. Irrigate immediately!';
    if (temperature > 42)  return '🌡️ Heat Stress: ${temperature.round()}°C — protect crops with shade/mulch.';
    if (rainfallChance > 80 && soilMoisture > 80) return '🌧️ Flood Risk: Heavy rain expected, excess moisture. Check drainage.';
    return '';
  }

  /// Build a formatted context prompt for Gemini
  String toAIContext() {
    return '''
Current Farm Context:
- Location: $location
- Active Crop: $primaryCropName (Stage: $primaryCropGrowthStage)
- Soil Type: $soilType | pH: ${phLevel.toStringAsFixed(1)}
- Soil Moisture: ${soilMoisture.round()}% | Temperature: ${temperature.round()}°C | Humidity: ${humidity.round()}%
- Rain Probability: ${rainfallChance.round()}%
- Nutrients — N: ${nitrogen.round()}%, P: ${phosphorus.round()}%, K: ${potassium.round()}%
- Irrigation Advice: $irrigationAdvice
- Fertilizer Status: $fertilizerAdvice
- Harvest History: ${harvestLogs.length} records logged
- Diagnosis History: ${historicalDiagnoses.length} diagnoses completed
''';
  }
}

/// ChangeNotifier so widgets can listen and rebuild when context changes
class FarmerContextNotifier extends ChangeNotifier {
  FarmerProfile _profile = FarmerProfile.demo;
  FarmerProfile get profile => _profile;

  late FarmSnapshot _snapshot;
  FarmSnapshot get snapshot => _snapshot;

  FarmerContextNotifier() {
    _snapshot = const FarmSnapshot(
      location: 'Pune, Maharashtra',
      temperature: 32.0,
      humidity: 64.0,
      rainfallChance: 20.0,
      soilType: 'Red Soil',
      soilMoisture: 65.0,
      phLevel: 6.5,
      nitrogen: 85.0,
      phosphorus: 70.0,
      potassium: 40.0,
      marketPrice: 2450.0,
      activeCrops: [
        {'name': 'Soybeans', 'duration': 90, 'progress': 30, 'plantedDate': 'June 10, 2026'},
        {'name': 'Groundnut', 'duration': 110, 'progress': 70, 'plantedDate': 'May 15, 2026'},
      ],
      harvestLogs: [],
      historicalDiagnoses: [],
    );
  }

  void updateProfile(FarmerProfile p) {
    _profile = p;
    notifyListeners();
  }

  void updateSnapshot({
    String? location,
    double? temperature,
    double? humidity,
    double? rainfallChance,
    String? soilType,
    double? soilMoisture,
    double? phLevel,
    double? nitrogen,
    double? phosphorus,
    double? potassium,
    double? marketPrice,
    List<Map<String, dynamic>>? activeCrops,
    List<Map<String, dynamic>>? harvestLogs,
    List<Map<String, dynamic>>? historicalDiagnoses,
  }) {
    _snapshot = FarmSnapshot(
      location: location ?? _snapshot.location,
      temperature: temperature ?? _snapshot.temperature,
      humidity: humidity ?? _snapshot.humidity,
      rainfallChance: rainfallChance ?? _snapshot.rainfallChance,
      soilType: soilType ?? _snapshot.soilType,
      soilMoisture: soilMoisture ?? _snapshot.soilMoisture,
      phLevel: phLevel ?? _snapshot.phLevel,
      nitrogen: nitrogen ?? _snapshot.nitrogen,
      phosphorus: phosphorus ?? _snapshot.phosphorus,
      potassium: potassium ?? _snapshot.potassium,
      marketPrice: marketPrice ?? _snapshot.marketPrice,
      activeCrops: activeCrops ?? _snapshot.activeCrops,
      harvestLogs: harvestLogs ?? _snapshot.harvestLogs,
      historicalDiagnoses: historicalDiagnoses ?? _snapshot.historicalDiagnoses,
    );
    notifyListeners();
  }
}
