import 'package:flutter/material.dart';
import '../models/localization.dart';
import '../widgets/custom_charts.dart';

class HomeTab extends StatelessWidget {
  final bool isHindi;
  final VoidCallback onViewSoilReport;
  final VoidCallback onLogHarvest;
  final VoidCallback onMicTap;
  final Function(int) onNavigateTab;

  // Dynamic parameters
  final String location;
  final double temperature;
  final double humidity;
  final double rainfallChance;
  final String soilType;
  final double soilMoisture;
  final double phLevel;
  final double nitrogen;
  final double marketPrice;
  final List<double> marketPriceHistory;
  final VoidCallback onConfigureParameters;

  const HomeTab({
    super.key,
    required this.isHindi,
    required this.onViewSoilReport,
    required this.onLogHarvest,
    required this.onMicTap,
    required this.onNavigateTab,
    required this.location,
    required this.temperature,
    required this.humidity,
    required this.rainfallChance,
    required this.soilType,
    required this.soilMoisture,
    required this.phLevel,
    required this.nitrogen,
    required this.marketPrice,
    required this.marketPriceHistory,
    required this.onConfigureParameters,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 0. Manual Parameter settings card
          _buildManualParamsCard(context),
          const SizedBox(height: 16.0),

          // 1. Urgent Alert Card
          _buildUrgentAlert(context),
          const SizedBox(height: 16.0),

          // 2. Weather Today Card
          _buildWeatherCard(context),
          const SizedBox(height: 16.0),

          // 3. Soil Health Card
          _buildSoilHealthCard(context),
          const SizedBox(height: 16.0),

          // 4. Grid Rows: Market Price + Log Harvest
          _buildMarketAndHarvestRow(context),
          const SizedBox(height: 16.0),

          // 5. Speak Banner Card
          _buildMicAdvisoryBanner(context),
          const SizedBox(height: 20.0),

          // 6. Quick Insights Header
          Text(
            AgriLanguage.text('quickInsights', isHindi),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C2D27),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12.0),

          // 7. Quick Insights items
          _buildQuickInsightsList(context),
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }

  Widget _buildManualParamsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
        border: Border.all(color: const Color(0xFFE8ECE9), width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.settings_input_composite_outlined, color: Color(0xFF2E7D32), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? 'सिमुलेशन कंट्रोल पैनल' : 'Simulation Control Panel',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E352C)),
                ),
                const SizedBox(height: 2),
                Text(
                  isHindi 
                      ? 'खेत के सेंसर और मौसम के मान खुद बदलें' 
                      : 'Manually adjust sensor, soil & weather parameters.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF70837B)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onConfigureParameters,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E5E4A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tune_rounded, size: 14),
                const SizedBox(width: 4),
                Text(
                  isHindi ? 'बदलें' : 'Adjust',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentAlert(BuildContext context) {
    final bool isHealthy = soilMoisture >= 40.0;
    final bool isModerate = soilMoisture >= 20.0 && soilMoisture < 40.0;

    final Color bgColor = isHealthy 
        ? const Color(0xFFE8F5E9) 
        : (isModerate ? const Color(0xFFFFFDE7) : const Color(0xFFFFF1F0));
    final Color borderColor = isHealthy 
        ? const Color(0xFFC8E6C9) 
        : (isModerate ? const Color(0xFFFFF59D) : const Color(0xFFF9D6D3));
    final Color iconColor = isHealthy 
        ? const Color(0xFF2E7D32) 
        : (isModerate ? const Color(0xFFF9A825) : const Color(0xFFD32F2F));
    final Color textColor = isHealthy 
        ? const Color(0xFF1B5E20) 
        : (isModerate ? const Color(0xFFE65100) : const Color(0xFF8B1E1E));
    final IconData icon = isHealthy 
        ? Icons.check_circle_outline_rounded 
        : (isModerate ? Icons.info_outline_rounded : Icons.warning_amber_rounded);

    final String title = isHealthy 
        ? (isHindi ? 'सभी क्षेत्र स्वस्थ हैं' : 'All Fields Healthy')
        : (isModerate ? (isHindi ? 'नमी चेतावनी' : 'Moisture Warning') : AgriLanguage.text('urgentAlert', isHindi));
        
    final String caption = isHealthy 
        ? (isHindi ? '(इष्टतम अवस्था)' : '(Optimal State)')
        : (isModerate ? (isHindi ? '(मध्यम अवस्था)' : '(Moderate State)') : (isHindi ? '(तत्काल सूचना)' : '(Urgent Info)'));

    final String desc = isHealthy 
        ? (isHindi 
            ? 'मिट्टी की नमी इष्टतम स्तर पर है (${soilMoisture.toStringAsFixed(1)}%)। किसी तात्कालिक सिंचाई की आवश्यकता नहीं है।'
            : 'Soil moisture is optimal at ${soilMoisture.toStringAsFixed(1)}%. No immediate irrigation needed.')
        : (isModerate
            ? (isHindi
                ? 'मिट्टी की नमी मध्यम है (${soilMoisture.toStringAsFixed(1)}%)। जल्द ही उत्तर क्षेत्र के लिए सिंचाई निर्धारित करें।'
                : 'Soil moisture is moderate at ${soilMoisture.toStringAsFixed(1)}%. Consider scheduling irrigation soon.')
            : (isHindi
                ? 'उत्तरी क्षेत्र के लिए सिंचाई आवश्यक है। मिट्टी की नमी ${soilMoisture.toStringAsFixed(1)}% (20% से नीचे) है।'
                : 'Irrigation needed for North Field. Soil moisture below 20% (Current: ${soilMoisture.toStringAsFixed(1)}%).'));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 28.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      caption,
                      style: TextStyle(
                        fontSize: 12.0,
                        color: textColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: textColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(BuildContext context) {
    return InkWell(
      onTap: () => onNavigateTab(2), // Navigate to Weather tab
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: const Color(0xFFE8ECE9), width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AgriLanguage.text('weatherToday', isHindi),
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E352C),
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      location,
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Color(0xFF70837B),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${temperature.round()}°C',
                  style: TextStyle(
                    fontSize: 34.0,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF165A42),
                    fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.umbrella_outlined, color: Color(0xFF2E7D3F), size: 18),
                          const SizedBox(width: 6.0),
                          Text(
                            AgriLanguage.text('rainfallChance', isHindi),
                            style: const TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3B4E47),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6.0),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Container(
                          height: 8.0,
                          width: double.infinity,
                          color: const Color(0xFFFCEBE7),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: rainfallChance / 100.0,
                              child: Container(
                                color: const Color(0xFF3E8062),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        isHindi 
                            ? '${rainfallChance.round()}% संभावना' 
                            : '${rainfallChance.round()}% probability',
                        style: const TextStyle(
                          fontSize: 11.0,
                          color: Color(0xFF70837B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24.0),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Icon(
                        Icons.wb_cloudy_outlined,
                        color: Color(0xFF165A42),
                        size: 32,
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        AgriLanguage.text('partlyCloudy', isHindi),
                        style: const TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E352C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoilHealthCard(BuildContext context) {
    final String nitrogenStatus = nitrogen >= 70.0
        ? (isHindi ? 'उच्च' : 'High')
        : (nitrogen >= 40.0 ? (isHindi ? 'इष्टतम' : 'Optimal') : (isHindi ? 'निम्न' : 'Low'));
    final Color nitrogenColor = nitrogen >= 40.0 ? Colors.green[800]! : Colors.orange[800]!;

    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: const Color(0xFFE8ECE9), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    AgriLanguage.text('soilHealth', isHindi),
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E352C),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    isHindi ? '(मिट्टी की सेहत)' : '(Soil quality)',
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: Color(0xFF70837B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8F3E5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  soilMoisture >= 40.0 
                      ? AgriLanguage.text('optimal', isHindi)
                      : (isHindi ? 'चेतावनी' : 'Warning'),
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: soilMoisture >= 40.0 ? const Color(0xFF1B5E4F) : const Color(0xFFC62828),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18.0),
          _buildHealthRow(AgriLanguage.text('nitrogen', isHindi), nitrogenStatus, nitrogenColor),
          const SizedBox(height: 12.0),
          _buildHealthRow(AgriLanguage.text('phLevel', isHindi), phLevel.toStringAsFixed(1), const Color(0xFF165A42)),
          const SizedBox(height: 14.0),
          const Divider(color: Color(0xFFECEFEF), thickness: 1.5),
          const SizedBox(height: 8.0),
          InkWell(
            onTap: onViewSoilReport,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  AgriLanguage.text('viewDetailedReport', isHindi),
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF165A42),
                  ),
                ),
                const SizedBox(width: 4.0),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Color(0xFF165A42),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15.0,
            color: Color(0xFF5B6E66),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15.0,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMarketAndHarvestRow(BuildContext context) {
    return Row(
      children: [
        // Market Price Card (Interactive Graph)
        Expanded(
          child: Container(
            height: 160,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F2), // Light peach background
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFFF5E2DD), width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.trending_up, color: Color(0xFF2E7D5F), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      AgriLanguage.text('marketPrice', isHindi),
                      style: const TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5B6E66),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  isHindi ? '₹${marketPrice.round().toString()}' : '₹${marketPrice.round().toString()}',
                  style: const TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF123428),
                  ),
                ),
                Text(
                  '/ ${AgriLanguage.text('quintal', isHindi)}',
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: Color(0xFF5C6E66),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '↑ 5.2% ${AgriLanguage.text('fromLastWeek', isHindi)}',
                  style: const TextStyle(
                    fontSize: 10.0,
                    color: Color(0xFF2E7D5F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Custom drawn stock curve graph dynamically bound to state
                SizedBox(
                  height: 38,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: LineChartPainter(marketPriceHistory),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14.0),

        // Log Harvest Button (Interactive Dialog trigger)
        Expanded(
          child: InkWell(
            onTap: onLogHarvest,
            borderRadius: BorderRadius.circular(16.0),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFF1E5E4A), // Deep Green Accent
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E5E4A).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 14.0),
                    Text(
                      AgriLanguage.text('logHarvest', isHindi),
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      isHindi ? '(फसल कटाई दर्ज करें)' : '(Record harvesting)',
                      style: TextStyle(
                        fontSize: 11.0,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMicAdvisoryBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFECE6), // Light warm peach pink
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFFCDED4), width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onMicTap,
          borderRadius: BorderRadius.circular(16.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                // Floating Micro styling
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E5E4A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 22.0,
                  ),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AgriLanguage.text('needExpertAdvice', isHindi),
                        style: const TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E352C),
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        AgriLanguage.text('helperMic', isHindi),
                        style: const TextStyle(
                          fontSize: 13.0,
                          color: Color(0xFF5B6E66),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickInsightsList(BuildContext context) {
    return Column(
      children: [
        // 1. Crop Growth Phase
        _buildInsightItem(
          title: AgriLanguage.text('cropGrowthPhase', isHindi),
          subtitle: AgriLanguage.text('soybeansStage', isHindi),
          imageUrl: 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?auto=format&fit=crop&q=80&w=200',
          fallbackIcon: Icons.spa,
          onTap: () {
            _showInsightDetails(
              context,
              AgriLanguage.text('cropGrowthPhase', isHindi),
              AgriLanguage.text('soybeansStage', isHindi),
              isHindi 
                  ? 'उत्तरी खेत सेक्टर B में सोयाबीन फसल वर्तमान में वानस्पतिक V3 चरण में है। पानी की आवश्यकता अनुकूल है और मिट्टी में नाइट्रोजन स्तर ${nitrogen.toStringAsFixed(0)}% है।'
                  : 'Your Soybean crop in North Field Sector B is currently in its Vegetative V3 stage (3 fully unrolled trifoliolate leaves). Water requirements are normal, and soil nitrogen levels are optimal at ${nitrogen.toStringAsFixed(0)}%. Keep checking for early signs of defoliation.',
            );
          },
        ),
        const SizedBox(height: 12.0),

        // 2. Field Satellite View
        _buildInsightItem(
          title: AgriLanguage.text('satelliteView', isHindi),
          subtitle: AgriLanguage.text('updatedHoursAgo', isHindi),
          imageUrl: 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&q=80&w=200',
          fallbackIcon: Icons.satellite_alt_outlined,
          onTap: () {
            // NDVI calculated based on parameters
            final double ndvi = 0.5 + 0.35 * (soilMoisture / 100.0);
            _showInsightDetails(
              context,
              AgriLanguage.text('satelliteView', isHindi),
              AgriLanguage.text('updatedHoursAgo', isHindi),
              isHindi
                  ? 'NDVI स्पेक्ट्रल इमेजिंग दक्षिणी सेक्टर में ${ndvi.toStringAsFixed(2)} का स्वस्थ पर्णसमूह घनत्व सूचकांक दर्शाती है। मिट्टी की नमी (${soilMoisture.toStringAsFixed(0)}%) का सीधा प्रभाव घनत्व पर पड़ता है।'
                  : 'NDVI spectral imaging indicates a canopy density index of ${ndvi.toStringAsFixed(2)} across the south sector. The density correlates directly with the localized ground soil moisture parameters (currently ${soilMoisture.toStringAsFixed(0)}%).',
            );
          },
        ),
      ],
    );
  }

  Widget _buildInsightItem({
    required String title,
    required String subtitle,
    required String imageUrl,
    required IconData fallbackIcon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE8ECE9), width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.network(
                    imageUrl,
                    width: 60.0,
                    height: 60.0,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60.0,
                        height: 60.0,
                        color: const Color(0xFFE6EFEA),
                        child: Icon(fallbackIcon, color: const Color(0xFF1E5E4A)),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D2E27),
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13.0,
                          color: Color(0xFF5B6E66),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF70837B),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInsightDetails(BuildContext context, String title, String subtitle, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E5E4A)),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          content: Text(
            content,
            style: const TextStyle(fontSize: 14, color: Color(0xFF2C3E35), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: Color(0xFF1E5E4A), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
