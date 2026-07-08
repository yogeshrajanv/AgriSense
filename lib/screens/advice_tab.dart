import 'package:flutter/material.dart';
import '../models/localization.dart';

class AdviceTab extends StatelessWidget {
  final bool isHindi;
  final Function(String, int) onSelectPlantingPlan;

  // Dynamic parameters
  final String soilType;
  final double soilMoisture;
  final double nitrogen;
  final double phosphorus;
  final double potassium;

  const AdviceTab({
    super.key,
    required this.isHindi,
    required this.onSelectPlantingPlan,
    required this.soilType,
    required this.soilMoisture,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculate dynamic crop recommendations
    final recommendedCrops = _calculateRecommendations();

    // Determine soil description based on soilType
    String soilDesc = isHindi ? 'आयरन ऑक्साइड से भरपूर' : 'Rich in Iron Oxide';
    if (soilType.contains('Black')) {
      soilDesc = isHindi ? 'कैल्शियम और खनिज समृद्ध' : 'Rich in Clay & Calcium';
    } else if (soilType.contains('Sandy')) {
      soilDesc = isHindi ? 'निकासी अच्छी, कम धारण' : 'High Drainage, Low Retention';
    } else if (soilType.contains('Clay')) {
      soilDesc = isHindi ? 'उच्च जल धारण क्षमता' : 'High Evaporative Retention';
    }

    // Determine water level text
    String moistureText = isHindi ? 'अनुकूल' : 'Optimal';
    if (soilMoisture >= 75.0) {
      moistureText = isHindi ? 'अत्यधिक' : 'Saturated';
    } else if (soilMoisture >= 40.0) {
      moistureText = isHindi ? 'अनुकूल' : 'Optimal';
    } else if (soilMoisture >= 20.0) {
      moistureText = isHindi ? 'मध्यम' : 'Moderate';
    } else {
      moistureText = isHindi ? 'निम्न' : 'Deficit';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crop Recommendations Headline
          Text(
            AgriLanguage.text('cropRecommendations', isHindi),
            style: const TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E352C),
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            AgriLanguage.text('aiDrivenPlanting', isHindi),
            style: const TextStyle(
              fontSize: 14.0,
              color: Color(0xFF70837B),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 18.0),

          // Core Metrics row: Soil Type + Water Level
          _buildMetricsRow(context, soilDesc, moistureText),
          const SizedBox(height: 16.0),

          // Market Demand
          _buildMarketDemandBanner(context),
          const SizedBox(height: 20.0),

          // Recommended list (rendered dynamically!)
          if (recommendedCrops.isEmpty)
            Center(
              child: Text(
                isHindi ? 'कोई मिलान फसल नहीं मिली' : 'No matching crops found',
                style: const TextStyle(color: Colors.grey),
              ),
            )
          else
            ...List.generate(recommendedCrops.length, (index) {
              final crop = recommendedCrops[index];
              return Column(
                children: [
                  _buildCropRecommendationCard(
                    context,
                    cropName: isHindi ? crop.nameHi : crop.name,
                    matchPercent: crop.matchScore,
                    yieldText: crop.potentialYield.toStringAsFixed(1),
                    waterReq: isHindi ? crop.waterReqHi : crop.waterReqEn,
                    duration: crop.duration,
                    imageUrl: crop.imageUrl,
                    fallbackIcon: crop.fallbackIcon,
                    hasActionPlan: index == 0, // only the top match has the button active
                  ),
                  const SizedBox(height: 16.0),
                ],
              );
            }),

          // Soil Nutrient Balance Card with tips
          _buildSoilNutrientBalanceCard(context),
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(BuildContext context, String soilDesc, String moistureText) {
    return Row(
      children: [
        // Soil Type Card
        Expanded(
          child: Container(
            height: 100,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFFE8ECE9), width: 1.0),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0EC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.grid_view_rounded, color: Color(0xFFD47053), size: 28),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AgriLanguage.text('soilType', isHindi),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        isHindi ? (soilType == 'Red Soil' ? 'लाल मिट्टी' : (soilType == 'Black Soil' ? 'काली मिट्टी' : (soilType == 'Sandy Soil' ? 'रेतीली मिट्टी' : 'चिकनी मिट्टी'))) : soilType,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E352C)),
                      ),
                      const SizedBox(height: 1.0),
                      Text(
                        soilDesc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 9, color: Color(0xFF8B6B62)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12.0),

        // Water Level Card
        Expanded(
          child: Container(
            height: 100,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFFE8ECE9), width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AgriLanguage.text('waterLevel', isHindi),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '$moistureText (${soilMoisture.toStringAsFixed(0)}%)',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B5A9E)),
                ),
                const SizedBox(height: 8.0),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.0),
                  child: Container(
                    height: 6.0,
                    width: double.infinity,
                    color: const Color(0xFFE1F0FA),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: soilMoisture / 100.0,
                        child: Container(
                          color: const Color(0xFF1E88E5),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarketDemandBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E5E4A),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AgriLanguage.text('marketDemand', isHindi).toUpperCase(),
            style: TextStyle(
              fontSize: 10.0,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.8),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AgriLanguage.text('highDemand', isHindi),
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                AgriLanguage.text('pulseCropsTrend', isHindi),
                style: const TextStyle(
                  fontSize: 13.0,
                  color: Color(0xFFD6F3E6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCropRecommendationCard(
    BuildContext context, {
    required String cropName,
    required int matchPercent,
    required String yieldText,
    required String waterReq,
    required int duration,
    required String imageUrl,
    required IconData fallbackIcon,
    required bool hasActionPlan,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: const Color(0xFFE8ECE9), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crop Header Image banner with match pill
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
                child: Image.network(
                  imageUrl,
                  height: 140.0,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 140.0,
                      width: double.infinity,
                      color: const Color(0xFFE8EFEA),
                      child: Icon(fallbackIcon, color: const Color(0xFF1E5E4A), size: 48),
                    );
                  },
                ),
              ),
              Positioned(
                top: 12.0,
                right: 12.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8F3E5).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$matchPercent% ${AgriLanguage.text('match', isHindi)}',
                    style: const TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E4F),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cropName,
                      style: const TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E352C),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AgriLanguage.text('potentialYield', isHindi).toUpperCase(),
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          '$yieldText ${AgriLanguage.text('tonsHectare', isHindi)}',
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF123428),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                const Divider(color: Color(0xFFECEFEF)),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    // Water Requirements
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.water_drop_outlined, size: 16, color: Color(0xFF5B6E66)),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AgriLanguage.text('waterReq', isHindi),
                                style: const TextStyle(fontSize: 10.0, color: Colors.grey),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                waterReq,
                                style: const TextStyle(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E352C),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Duration
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Color(0xFF5B6E66)),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AgriLanguage.text('duration', isHindi),
                                style: const TextStyle(fontSize: 10.0, color: Colors.grey),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '$duration ${AgriLanguage.text('days', isHindi)}',
                                style: const TextStyle(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E352C),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18.0),

                // Action Call Buttons
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (hasActionPlan) {
                        onSelectPlantingPlan(cropName, duration);
                      } else {
                        _showCropDetailsDialog(context, cropName, duration, yieldText, waterReq);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasActionPlan ? const Color(0xFF1E5E4A) : Colors.white,
                      foregroundColor: hasActionPlan ? Colors.white : const Color(0xFF1E5E4A),
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFF1E5E4A), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasActionPlan) ...[
                          const Icon(Icons.calendar_month_outlined, size: 16),
                          const SizedBox(width: 8),
                          Text(AgriLanguage.text('startPlanting', isHindi)),
                        ] else ...[
                          Text(AgriLanguage.text('viewDetails', isHindi)),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoilNutrientBalanceCard(BuildContext context) {
    // Generate organic custom tips based on parameters
    String customTip = AgriLanguage.text('nutrientTip', isHindi);
    if (nitrogen > 80.0) {
      customTip = isHindi
          ? 'सुझाव: खेत में नाइट्रोजन बहुत अधिक है। मिट्टी का संतुलन बनाए रखने के लिए इस सत्र में यूरिया या अमोनियम खाद का उपयोग रोक दें।'
          : 'Tip: Soil Nitrogen is very high. Suspend nitrogenous fertilizers like urea in the current cycle to protect root health.';
    } else if (potassium < 35.0) {
      customTip = isHindi
          ? 'सुझाव: मिट्टी में पोटैशियम की कमी है। मूंगफली/आलू जैसी फसलों के बेहतर विकास के लिए पोटाश उर्वरक का प्रयोग करें।'
          : 'Tip: Soil Potassium levels are low. Apply potash-rich elements to improve pod filling and root structure.';
    } else if (soilMoisture < 30.0) {
      customTip = isHindi
          ? 'सुझाव: मिट्टी में नमी की कमी है। वाष्पीकरण रोकने के लिए जैविक पत्तों अथवा मल्चिंग शीट से खेत को ढकें।'
          : 'Tip: Local moisture is low. Lay down organic mulch or cover sheets between rows to retain moisture.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2EF),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFFCDED8), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AgriLanguage.text('soilNutrientBalance', isHindi),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E352C),
            ),
          ),
          const SizedBox(height: 16.0),

          _buildNutrientLoader(
            label: isHindi ? 'नाइट्रोजन (N)' : 'Nitrogen (N)',
            percentage: nitrogen.round(),
            fillColor: const Color(0xFF12523C),
          ),
          const SizedBox(height: 12.0),
          _buildNutrientLoader(
            label: isHindi ? 'फॉस्फोरस (P)' : 'Phosphorus (P)',
            percentage: phosphorus.round(),
            fillColor: const Color(0xFF12523C),
          ),
          const SizedBox(height: 12.0),
          _buildNutrientLoader(
            label: isHindi ? 'पोटैशियम (K)' : 'Potassium (K)',
            percentage: potassium.round(),
            fillColor: const Color(0xFF12523C),
          ),
          const SizedBox(height: 18.0),

          // Tip Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFF1E5E4A),
                  size: 22.0,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    customTip,
                    style: const TextStyle(
                      fontSize: 13.0,
                      color: Color(0xFF3B4E47),
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientLoader({
    required String label,
    required int percentage,
    required Color fillColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600, color: Color(0xFF3C4D44)),
            ),
            Text(
              '$percentage%',
              style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Color(0xFF1E352C)),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 8.0,
            width: double.infinity,
            color: const Color(0xFFCDEDDE),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: percentage / 100.0,
                child: Container(color: fillColor),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCropDetailsDialog(
    BuildContext context,
    String cropName,
    int duration,
    String yieldVal,
    String water,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(cropName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E5E4A))),
          content: Text(
            isHindi 
              ? '$cropName के रोपण हेतु $duration दिन का मार्गदर्शन आवश्यक है। संभावित उपज $yieldVal टन प्रति हेक्टेयर होगी और इसमें $water पानी की आवश्यकता होगी।'
              : 'Planting plan details for $cropName. Recommended growth cycle takes $duration days. Estimated output potential registers around $yieldVal Tons per hectare, requiring $water irrigation patterns.',
            style: const TextStyle(fontSize: 14.0, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onSelectPlantingPlan(cropName, duration);
              },
              child: const Text('Adopt Plan', style: TextStyle(color: Color(0xFF1E5E4A), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // AI Matching Recommendation Algorithm
  List<_CalculatedCrop> _calculateRecommendations() {
    final List<_CropProfile> profiles = [
      _CropProfile(
        name: 'Groundnut',
        nameHi: 'मूंगफली',
        preferredSoil: 'Red Soil',
        altSoil: 'Sandy Soil',
        waterReqEn: 'Low-Medium',
        waterReqHi: 'निम्न-मध्यम',
        idealMoisture: 50.0, // 35 - 65 %
        duration: 110,
        potentialYield: 2.4,
        imageUrl: 'https://images.unsplash.com/photo-1589156191108-c762ff4b96ab?auto=format&fit=crop&q=80&w=300',
        fallbackIcon: Icons.grass,
        lovesHighPotassium: true,
      ),
      _CropProfile(
        name: 'Soybeans',
        nameHi: 'सोयाबीन',
        preferredSoil: 'Black Soil',
        altSoil: 'Clay Soil',
        waterReqEn: 'Medium',
        waterReqHi: 'मध्यम',
        idealMoisture: 65.0, // 50 - 75 %
        duration: 90,
        potentialYield: 2.8,
        imageUrl: 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?auto=format&fit=crop&q=80&w=300',
        fallbackIcon: Icons.spa,
        lovesHighNitrogen: true,
      ),
      _CropProfile(
        name: 'Pigeon Pea',
        nameHi: 'अरहर',
        preferredSoil: 'Red Soil',
        altSoil: 'Black Soil',
        waterReqEn: 'Low',
        waterReqHi: 'निम्न',
        idealMoisture: 40.0, // 25 - 55 %
        duration: 180,
        potentialYield: 1.8,
        imageUrl: 'https://images.unsplash.com/photo-1598971861713-54ad16a7e72e?auto=format&fit=crop&q=80&w=300',
        fallbackIcon: Icons.local_florist_outlined,
      ),
      _CropProfile(
        name: 'Sorghum',
        nameHi: 'ज्वार',
        preferredSoil: 'Sandy Soil',
        altSoil: 'Black Soil',
        waterReqEn: 'Very Low',
        waterReqHi: 'अति निम्न',
        idealMoisture: 30.0, // 15 - 45 %
        duration: 120,
        potentialYield: 3.2,
        imageUrl: 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&q=80&w=300',
        fallbackIcon: Icons.grass,
      ),
      _CropProfile(
        name: 'Rice',
        nameHi: 'धान',
        preferredSoil: 'Clay Soil',
        altSoil: 'Black Soil',
        waterReqEn: 'High',
        waterReqHi: 'उच्च',
        idealMoisture: 85.0, // 70 - 100 %
        duration: 120,
        potentialYield: 4.1,
        imageUrl: 'https://images.unsplash.com/photo-1530595467537-0b5996c41f2d?auto=format&fit=crop&q=80&w=300',
        fallbackIcon: Icons.water_drop,
        lovesHighNitrogen: true,
      ),
      _CropProfile(
        name: 'Wheat',
        nameHi: 'गेहूँ',
        preferredSoil: 'Black Soil',
        altSoil: 'Clay Soil',
        waterReqEn: 'Medium',
        waterReqHi: 'मध्यम',
        idealMoisture: 60.0, // 45 - 75 %
        duration: 130,
        potentialYield: 3.6,
        imageUrl: 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&q=80&w=300',
        fallbackIcon: Icons.grain,
      ),
      _CropProfile(
        name: 'Cotton',
        nameHi: 'कपास',
        preferredSoil: 'Black Soil',
        altSoil: 'Sandy Soil',
        waterReqEn: 'Medium',
        waterReqHi: 'मध्यम',
        idealMoisture: 55.0, // 40 - 70 %
        duration: 150,
        potentialYield: 2.1,
        imageUrl: 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?auto=format&fit=crop&q=80&w=300',
        fallbackIcon: Icons.check_box_outline_blank,
      ),
    ];

    final List<_CalculatedCrop> computed = [];

    for (var p in profiles) {
      double score = 0.0;

      // 1. Soil Match: weight 50%
      if (p.preferredSoil == soilType) {
        score += 50.0;
      } else if (p.altSoil == soilType) {
        score += 38.0;
      } else {
        score += 12.0;
      }

      // 2. Moisture Match: weight 30%
      final double diff = (soilMoisture - p.idealMoisture).abs();
      if (diff <= 10.0) {
        score += 30.0;
      } else if (diff <= 25.0) {
        score += 20.0;
      } else if (diff <= 40.0) {
        score += 10.0;
      } else {
        score += 2.0;
      }

      // 3. Nutrient Match: weight 20%
      double nutrientScore = 10.0;
      if (p.lovesHighNitrogen && nitrogen >= 65.0) {
        nutrientScore += 10.0;
      } else if (p.lovesHighPotassium && potassium >= 50.0) {
        nutrientScore += 10.0;
      } else if (!p.lovesHighNitrogen && !p.lovesHighPotassium && phosphorus >= 40.0) {
        nutrientScore += 8.0;
      }
      score += nutrientScore;

      final int finalMatchScore = score.round().clamp(15, 98);
      computed.add(
        _CalculatedCrop(
          name: p.name,
          nameHi: p.nameHi,
          waterReqEn: p.waterReqEn,
          waterReqHi: p.waterReqHi,
          duration: p.duration,
          potentialYield: p.potentialYield,
          imageUrl: p.imageUrl,
          fallbackIcon: p.fallbackIcon,
          matchScore: finalMatchScore,
        ),
      );
    }

    // Sort descending of match score
    computed.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    // Return top 3 recommendations
    return computed.take(3).toList();
  }
}

class _CropProfile {
  final String name;
  final String nameHi;
  final String preferredSoil;
  final String altSoil;
  final String waterReqEn;
  final String waterReqHi;
  final double idealMoisture;
  final int duration;
  final double potentialYield;
  final String imageUrl;
  final IconData fallbackIcon;
  final bool lovesHighNitrogen;
  final bool lovesHighPotassium;

  _CropProfile({
    required this.name,
    required this.nameHi,
    required this.preferredSoil,
    required this.altSoil,
    required this.waterReqEn,
    required this.waterReqHi,
    required this.idealMoisture,
    required this.duration,
    required this.potentialYield,
    required this.imageUrl,
    required this.fallbackIcon,
    this.lovesHighNitrogen = false,
    this.lovesHighPotassium = false,
  });
}

class _CalculatedCrop {
  final String name;
  final String nameHi;
  final String waterReqEn;
  final String waterReqHi;
  final int duration;
  final double potentialYield;
  final String imageUrl;
  final IconData fallbackIcon;
  final int matchScore;

  _CalculatedCrop({
    required this.name,
    required this.nameHi,
    required this.waterReqEn,
    required this.waterReqHi,
    required this.duration,
    required this.potentialYield,
    required this.imageUrl,
    required this.fallbackIcon,
    required this.matchScore,
  });
}
