import 'package:flutter/material.dart';
import '../models/localization.dart';
import '../widgets/custom_charts.dart';

class WeatherTab extends StatelessWidget {
  final bool isHindi;
  final bool thermalView;
  final VoidCallback onToggleThermalView;

  // Dynamic parameters
  final String location;
  final double temperature;
  final double humidity;
  final double rainfallChance;
  final double soilMoisture;

  const WeatherTab({
    super.key,
    required this.isHindi,
    required this.thermalView,
    required this.onToggleThermalView,
    required this.location,
    required this.temperature,
    required this.humidity,
    required this.rainfallChance,
    required this.soilMoisture,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            AgriLanguage.text('weatherAdvisory', isHindi),
            style: const TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E352C),
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            AgriLanguage.text('weatherSub', isHindi),
            style: const TextStyle(
              fontSize: 14.0,
              color: Color(0xFF70837B),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 18.0),

          // Dynamic Warning Banner
          _buildDynamicAlertBanner(context),
          const SizedBox(height: 18.0),

          // Currently condition card
          _buildCurrentlyCard(context),
          const SizedBox(height: 18.0),

          // 7-day farming outlook
          _build7DayOutlook(context),
          const SizedBox(height: 18.0),

          // Fertilizer absorption window
          _buildFertilizerWindowCard(context),
          const SizedBox(height: 18.0),

          // IoT Ground sensor network mapping
          _buildSensorNetworkCard(context),
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }

  Widget _buildDynamicAlertBanner(BuildContext context) {
    // 3 states based on weather/soil parameters
    final bool isDry = soilMoisture < 30.0 && rainfallChance < 40.0;
    final bool isRainy = rainfallChance >= 75.0;

    if (isDry) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFDEBED),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFFF9C8C5), width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny_rounded, color: Color(0xFFB71C1C), size: 22.0),
                const SizedBox(width: 8.0),
                Text(
                  AgriLanguage.text('drySpellAlert', isHindi),
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB71C1C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              isHindi
                  ? 'अगले 10 दिनों में कम वर्षा का अनुमान है। नमी का स्तर गिरकर ${soilMoisture.toStringAsFixed(0)}% हो गया है।'
                  : 'Low precipitation forecast for next 10 days. Moisture levels dropping to ${soilMoisture.toStringAsFixed(0)}% in sector networks.',
              style: const TextStyle(
                fontSize: 14.0,
                color: Color(0xFF8B1E1E),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                _buildWarningLabel(AgriLanguage.text('delaySowing', isHindi), const Color(0xFF8B1E1E)),
                const SizedBox(width: 8.0),
                _buildWarningLabel(AgriLanguage.text('increaseWater', isHindi), const Color(0xFF8B1E1E)),
              ],
            ),
            const SizedBox(height: 14.0),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E1E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showDetailedPlanDialog(context, 'dry'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.analytics_outlined, size: 16.0),
                    const SizedBox(width: 8.0),
                    Text(
                      AgriLanguage.text('viewDetailedPlan', isHindi),
                      style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else if (isRainy) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F7FA), // Light cyan warning
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFFB2EBF2), width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.thunderstorm_rounded, color: Color(0xFF006064), size: 22.0),
                const SizedBox(width: 8.0),
                Text(
                  isHindi ? 'अत्यधिक वर्षा की चेतावनी' : 'Heavy Rainfall Advisory',
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF006064),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              isHindi
                  ? 'खेत क्षेत्र में भारी बारिश (${rainfallChance.toStringAsFixed(0)}% संभावना) की आशंका है। सुरक्षा के लिए जल निकासी नाली साफ करें।'
                  : 'High precipitation forecast (${rainfallChance.toStringAsFixed(0)}% probability). Accumulation likely. Clear field drainage channels immediately.',
              style: const TextStyle(
                fontSize: 14.0,
                color: Color(0xFF006064),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                _buildWarningLabel(isHindi ? 'उर्वरक रोकें' : 'Delay Fertilizing', const Color(0xFF006064)),
                const SizedBox(width: 8.0),
                _buildWarningLabel(isHindi ? 'जल निकास खोलें' : 'Clear Channels', const Color(0xFF006064)),
              ],
            ),
            const SizedBox(height: 14.0),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006064),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showDetailedPlanDialog(context, 'rain'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.analytics_outlined, size: 16.0),
                    const SizedBox(width: 8.0),
                    Text(
                      AgriLanguage.text('viewDetailedPlan', isHindi),
                      style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Normal favorable state
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9), // Light green
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFFC8E6C9), width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 22.0),
                const SizedBox(width: 8.0),
                Text(
                  isHindi ? 'अनुकूल मौसम' : 'Favorable Weather',
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              isHindi
                  ? 'मौसम की स्थिति अनुकूल है। हल्की वर्षा की संभावना (${rainfallChance.toStringAsFixed(0)}%) कृषि के लिए आदर्श है।'
                  : 'Favorable crop conditions detected. Moderate rainfall probability (${rainfallChance.toStringAsFixed(0)}%) serves normal crop growth.',
              style: const TextStyle(
                fontSize: 14.0,
                color: Color(0xFF1B5E20),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                _buildWarningLabel(isHindi ? 'छिड़काव ठीक' : 'Spraying OK', const Color(0xFF2E7D32)),
                const SizedBox(width: 8.0),
                _buildWarningLabel(isHindi ? 'सिंचाई जारी रखें' : 'Maintain Irrigation', const Color(0xFF2E7D32)),
              ],
            ),
            const SizedBox(height: 14.0),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showDetailedPlanDialog(context, 'normal'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.analytics_outlined, size: 16.0),
                    const SizedBox(width: 8.0),
                    Text(
                      AgriLanguage.text('viewDetailedPlan', isHindi),
                      style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildWarningLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_filled, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentlyCard(BuildContext context) {
    // Dynamic irrigation message based on moisture parameter
    String recommendationMsg = AgriLanguage.text('recommendedAmt', isHindi);
    String irrigationTime = '05:30 AM';
    if (soilMoisture < 30.0) {
      irrigationTime = isHindi ? 'अभी शुरू करें' : 'Start Immediately';
      recommendationMsg = isHindi ? 'सिफारिश: १५ लीटर प्रति वर्ग मीटर' : 'Recommended: 15L per m² (High necessity)';
    } else if (soilMoisture >= 70.0) {
      irrigationTime = isHindi ? 'स्थगित रखें' : 'Deferred';
      recommendationMsg = isHindi ? 'सिफारिश: आवश्यकता नहीं (नमी पर्याप्त है)' : 'Recommended: None needed (Sufficient moisture)';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE3F2FD),
            Color(0xFFFFF7F5),
          ],
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFCCDDF2), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AgriLanguage.text('currently', isHindi),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.blue[900]?.withOpacity(0.7),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Icon(Icons.wb_cloudy_rounded, size: 40, color: Color(0xFF1E5E4A)),
              const SizedBox(width: 14.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${temperature.round()}°C',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF123428)),
                  ),
                  Text(
                    '${AgriLanguage.text('partlyCloudy', isHindi)} • ${AgriLanguage.text('humidity', isHindi)} ${humidity.round()}%',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF5B6E66), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18.0),

          // Next Irrigation Window
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2EBE5), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_alarm_rounded, color: Color(0xFF2E7D3F), size: 24),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AgriLanguage.text('nextIrrigation', isHindi),
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        irrigationTime,
                        style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF1E352C)),
                      ),
                      Text(
                        recommendationMsg,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF70837B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _build7DayOutlook(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE8ECE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AgriLanguage.text('outlook', isHindi),
                style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Color(0xFF1E352C)),
              ),
              Text(
                isHindi ? 'अद्यतित अभी' : 'Updated just now',
                style: const TextStyle(fontSize: 10.0, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildForecastDay(
                AgriLanguage.text('mon', isHindi),
                '${(temperature - 0.5).round()}°',
                rainfallChance >= 75.0 ? Icons.thunderstorm_outlined : Icons.wb_sunny_outlined,
                rainfallChance < 75.0,
                isHindi,
              ),
              _buildForecastDay(
                AgriLanguage.text('tue', isHindi),
                '${(temperature + 1).round()}°',
                Icons.cloud_queue_outlined,
                true,
                isHindi,
              ),
              _buildForecastDay(
                AgriLanguage.text('wed', isHindi),
                '${(temperature - 3.5).round()}°',
                rainfallChance >= 40.0 ? Icons.umbrella_rounded : Icons.wb_cloudy_outlined,
                false,
                isHindi,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForecastDay(String day, String temp, IconData icon, bool sprayingOk, bool isHi) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDF0ED)),
      ),
      child: Column(
        children: [
          Text(day, style: const TextStyle(fontSize: 12.0, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6.0),
          Icon(icon, color: const Color(0xFF1E5E4A), size: 24),
          const SizedBox(height: 4.0),
          Text(temp, style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Color(0xFF1E352C))),
          const SizedBox(height: 10.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: sprayingOk ? const Color(0xFFD8F3E5) : const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              sprayingOk 
                ? (isHi ? 'छिड़काव ठीक' : 'Spraying OK') 
                : (isHi ? 'खाद डालें' : 'Fertilize'),
              style: TextStyle(
                fontSize: 9.0, 
                fontWeight: FontWeight.bold, 
                color: sprayingOk ? const Color(0xFF1B5E4F) : const Color(0xFF0D47A1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFertilizerWindowCard(BuildContext context) {
    String optimalMsg = AgriLanguage.text('48hours', isHindi);
    String tipMsg = AgriLanguage.text('soilCondOpt', isHindi);
    double sliderFactor = 260.0;

    if (rainfallChance >= 75.0) {
      optimalMsg = isHindi ? 'स्थगित रखें (भारी बारिश)' : 'Postpone (Heavy Rain)';
      tipMsg = isHindi 
          ? 'चेतावनी: अगले २४ घंटों में भारी बारिश की आशंका है। नाइट्रोजन उर्वरक के बह जाने की संभावना होने के कारण छिड़काव स्थगित रखें।'
          : 'Warning: Impending heavy precipitation will wash away nutrients. Suspend Urea application until dry conditions settle.';
      sliderFactor = 50.0;
    } else if (soilMoisture < 30.0) {
      optimalMsg = isHindi ? 'मध्यम अनुकूल' : 'Moderate Window';
      tipMsg = isHindi
          ? 'सलाह: मिट्टी शुष्क है। यूरिया के बेहतर अवशोषण के लिए छिड़काव से पहले अथवा तुरंत बाद खेत में हल्की सिंचाई करें।'
          : 'Advisory: Dry soil conditions. Perform light irrigation concurrently with fertilization to prevent nitrogen volatization.';
      sliderFactor = 150.0;
    }

    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE8ECE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_outlined, color: Color(0xFF1E5E4A), size: 20),
              const SizedBox(width: 6.0),
              Text(
                AgriLanguage.text('fertilizerWindow', isHindi),
                style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Color(0xFF1E352C)),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AgriLanguage.text('optimalTime', isHindi), style: const TextStyle(fontSize: 13, color: Colors.grey)),
              Text(
                optimalMsg,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E5E4A)),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.0),
            child: Container(
              height: 6.0,
              width: double.infinity,
              color: const Color(0xFFFFEAEA),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: sliderFactor,
                  color: const Color(0xFF1E5E4A),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10.0),
          Text(
            tipMsg,
            style: const TextStyle(fontSize: 13.0, color: Color(0xFF5B6E66), height: 1.3),
          ),
          const SizedBox(height: 14.0),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FDFA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEAEEEC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AgriLanguage.text('recommended', isHindi).toUpperCase(),
                  style: const TextStyle(fontSize: 9.0, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  AgriLanguage.text('ureaApp', isHindi),
                  style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Color(0xFF1E352C)),
                ),
                Text(
                  AgriLanguage.text('ureaAmount', isHindi),
                  style: const TextStyle(fontSize: 12.0, color: Color(0xFF1E5E4A), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorNetworkCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE8ECE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AgriLanguage.text('sensorNetwork', isHindi),
                style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Color(0xFF1E352C)),
              ),
              InkWell(
                onTap: () {
                  _showSensorDetailsDialog(context);
                },
                child: Row(
                  children: [
                    Text(
                      AgriLanguage.text('fullscreenMap', isHindi),
                      style: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: Color(0xFF1E5E4A)),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.open_in_new, size: 10, color: Color(0xFF1E5E4A)),
                  ],
                ),
              ),
            ],
          ),
          Text(
            AgriLanguage.text('sensorDesc', isHindi),
            style: const TextStyle(fontSize: 12.0, color: Colors.grey),
          ),
          const SizedBox(height: 16.0),

          // Custom graphics map vector dynamically bound to soilMoisture
          SizedBox(
            height: 180,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: SensorMapPainter(thermalMode: thermalView, averageMoisture: soilMoisture),
              ),
            ),
          ),
          const SizedBox(height: 14.0),

          // Map Legend / toggles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildLegendItem('Max', const Color(0xFF1E88E5)),
                  const SizedBox(width: 8),
                  _buildLegendItem('Opt', const Color(0xFF4CAF50)),
                  const SizedBox(width: 8),
                  _buildLegendItem('Low', const Color(0xFFE53935)),
                ],
              ),
              OutlinedButton(
                onPressed: onToggleThermalView,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1E5E4A)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                child: Row(
                  children: [
                    Icon(
                      thermalView ? Icons.visibility_off_outlined : Icons.thermostat_auto,
                      size: 14,
                      color: const Color(0xFF1E5E4A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      thermalView ? AgriLanguage.text('normalView', isHindi) : AgriLanguage.text('thermalView', isHindi),
                      style: const TextStyle(fontSize: 11.0, color: Color(0xFF1E5E4A), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  void _showDetailedPlanDialog(BuildContext context, String mode) {
    String title = AgriLanguage.text('viewDetailedPlan', isHindi);
    String step1 = '';
    String step2 = '';
    String step3 = '';

    if (mode == 'dry') {
      step1 = isHindi ? 'बुवाई में देरी करें। उत्तरी खंड Sector B-4 में तात्कालिक सिंचाई चक्र शुरू करें।' : 'Postpone sowing. Engage low-volume trickle irrigation in target Sector B-4.';
      step2 = isHindi ? 'मिट्टी के तापमान और नमी को पुनर्स्थापित करने के लिए सूखी पत्तियों/मल्च का फैलाव करें।' : 'Apply organic mulching sheet to reduce localized surface evaporation by 20%.';
      step3 = isHindi ? 'नमी सेंसरों को पुनः सिंक कर डेटा जांचें। बुधवार की बारिश के बाद यूरिया का छिड़काव करें।' : 'Re-verify NPK values. Prepare Urea spreading for post-Wednesday shower integration.';
    } else if (mode == 'rain') {
      step1 = isHindi ? 'खेत के जल निकासी फाटकों को खोलें ताकि पानी जमा न हो।' : 'Open all main drainage gates across Sector A & B to prevent pooling.';
      step2 = isHindi ? 'उर्वरक छिड़काव रोक दें। तेज़ बारिश में यूरिया पानी में बह सकती है।' : 'Suspend fertilizer applications immediately. Keep items dry in stores.';
      step3 = isHindi ? 'ढलान वाले क्षेत्रों में कटाव रोकने के लिए मिट्टी की मेढ़ें मज़बूत करें।' : 'Assess terraced boundaries. Reinforce soil Bunds to prevent mud/nutrient runoff.';
    } else {
      step1 = isHindi ? 'दैनिक आधार पर सेंसर नमी स्तर (इष्टतम: ४०-६०%) की निगरानी करें।' : 'Conduct scheduled sensor network checks. Hold average moisture around 42-60%.';
      step2 = isHindi ? 'बुधवार को होने वाली हल्की बारिश का लाभ उठाने के लिए खाद छिड़काव नियोजित करें।' : 'Coordinate Wednesday\'s light rain slot to distribute Potassium/Urea fertilizers.';
      step3 = isHindi ? 'वानस्पतिक विकास ठीक है, पत्तों की स्वस्थ वृद्धि की जांच करें।' : 'Examine soybean vegetative pods. Ensure clean leaves with visual inspections.';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E5E4A)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimelineStep('Day 1-3:', step1),
              const SizedBox(height: 8),
              _buildTimelineStep('Day 4-6:', step2),
              const SizedBox(height: 8),
              _buildTimelineStep('Day 7-10:', step3),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Color(0xFF1E5E4A), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimelineStep(String dayRange, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dayRange,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E5E4A)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF2C3E35), height: 1.3),
          ),
        ),
      ],
    );
  }

  void _showSensorDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('IoT Nodes Detail', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E5E4A))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('24 Ground Sensors active inside Sector Block A, B, C & D.'),
              const SizedBox(height: 8),
              Text(isHindi 
                  ? 'सेंसर डेटा दर: प्रत्येक 15 मिनट में लोरावान (LoRaWAN) गेटवे द्वारा प्राप्त। प्रणाली सामान्य है। नमी औसत सेंसर मूल्य ${soilMoisture.toStringAsFixed(1)}% पर सिंक है।' 
                  : 'Telemetry frequency: Every 15 minutes via LoRaWAN node gateways. Operating normally. Average moisture level currently synched at ${soilMoisture.toStringAsFixed(1)}%.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back', style: TextStyle(color: Color(0xFF1E5E4A))),
            ),
          ],
        );
      },
    );
  }
}
