import 'package:flutter/material.dart';
import '../models/localization.dart';

class ExpertTab extends StatelessWidget {
  final bool isHindi;
  final bool isDiagnosing;
  final double diagnosisProgress;
  final List<Map<String, dynamic>> historicalLogs;
  final VoidCallback onTakePhoto;
  final VoidCallback onCancelDiagnosis;
  final VoidCallback onBookVisit;

  const ExpertTab({
    super.key,
    required this.isHindi,
    required this.isDiagnosing,
    required this.diagnosisProgress,
    required this.historicalLogs,
    required this.onTakePhoto,
    required this.onCancelDiagnosis,
    required this.onBookVisit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. New Diagnosis Header Card
          _buildNewDiagnosisCard(context),
          const SizedBox(height: 18.0),

          // 2. Ongoing Diagnosis (Scanning simulator if active)
          if (isDiagnosing || diagnosisProgress > 0) ...[
            _buildOngoingDiagnosisCard(context),
            const SizedBox(height: 18.0),
          ],

          // 3. Rythu Seva Kendra Expert card (Blue backdrop)
          _buildRSKCard(context),
          const SizedBox(height: 22.0),

          // 4. Historical Logs Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AgriLanguage.text('historicalLogs', isHindi),
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E352C),
                ),
              ),
              InkWell(
                onTap: () {
                  _showToast(context, isHindi ? 'इतिहास के सभी रिकॉर्ड लोड हो रहे हैं...' : 'Displaying complete history logs...');
                },
                child: Row(
                  children: [
                    Text(
                      AgriLanguage.text('viewAll', isHindi),
                      style: const TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E5E4A),
                      ),
                    ),
                    const SizedBox(width: 3.0),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: Color(0xFF1E5E4A),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // 5. Hist list
          ...historicalLogs.map((log) => _buildHistoricalLogCard(context, log)).toList(),
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }

  Widget _buildNewDiagnosisCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE8ECE9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AgriLanguage.text('newDiagnosis', isHindi),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF123428),
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            AgriLanguage.text('diagnosisDesc', isHindi),
            style: const TextStyle(
              fontSize: 13.0,
              color: Color(0xFF5B6E66),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20.0),

          // Photo Uploader button
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF124338), // Forest green
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: onTakePhoto,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_outlined, size: 24.0),
                  const SizedBox(width: 12.0),
                  Text(
                    AgriLanguage.text('takePhoto', isHindi),
                    style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          if (isDiagnosing) ...[
            const SizedBox(height: 16.0),
            // Progress Bar simulation
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    height: 38.0,
                    width: double.infinity,
                    color: const Color(0xFFD3F2E3),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: diagnosisProgress,
                            child: Container(
                              color: const Color(0xFFA6ECC9),
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            '${(diagnosisProgress * 100).toInt()}% ${AgriLanguage.text('processed', isHindi)}',
                            style: const TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF123428),
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildOngoingDiagnosisCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFD6ECC3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AgriLanguage.text('ongoingDiagnosis', isHindi).toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8F3E5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(diagnosisProgress * 100).toInt()}%',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B5E4F)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            AgriLanguage.text('analyzingRice', isHindi),
            style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: Color(0xFF1E352C)),
          ),
          const SizedBox(height: 14.0),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.network(
                  'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?auto=format&fit=crop&q=80&w=200', // Rice blast leaf spots
                  width: 90.0,
                  height: 90.0,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 90.0,
                      height: 90.0,
                      color: const Color(0xFFFFECE8),
                      child: const Icon(Icons.sick, color: Color(0xFFD32F2F)),
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
                      AgriLanguage.text('crossReference', isHindi),
                      style: const TextStyle(
                        fontSize: 13.0,
                        color: Color(0xFF5B6E66),
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Light animated green scanning bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 4,
                        width: 100,
                        color: const Color(0xFFEDF5F1),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: diagnosisProgress,
                            child: Container(color: Colors.green),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Cancel or View Detail
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onCancelDiagnosis,
                child: Text(
                  AgriLanguage.text('cancel', isHindi),
                  style: const TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12.0),
              ElevatedButton(
                onPressed: () {
                  _showDetailedDiagnosis(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E5E4A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('View Details', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRSKCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0277BD), // Dark Blue RSK layout
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0277BD).withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 22.0),
              ),
              const SizedBox(width: 12.0),
              Text(
                AgriLanguage.text('rythuExpert', isHindi),
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Text(
            AgriLanguage.text('specialistAvail', isHindi),
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.white.withOpacity(0.9),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 18.0),

          // Core Book Visit Button (Full Width White Accent)
          InkWell(
            onTap: onBookVisit,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month, color: Color(0xFF0039A6), size: 18),
                    const SizedBox(width: 8.0),
                    Text(
                      AgriLanguage.text('bookVisit', isHindi),
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0039A6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricalLogCard(BuildContext context, Map<String, dynamic> log) {
    final String crop = log['crop'];
    final String issue = log['issue'];
    final String status = log['status'];
    final String desc = log['desc'];
    final String date = log['date'];
    final String imageUrl = log['imageUrl'];

    final bool isResolved = status == 'Resolved';

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE8ECE9)),
      ),
      child: InkWell(
        onTap: () {
          _showDiagnosisReportDialog(context, crop, issue, status, desc, date);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.network(
                  imageUrl,
                  width: 70.0,
                  height: 70.0,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 70.0,
                      height: 70.0,
                      color: const Color(0xFFEDF2F0),
                      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isResolved ? const Color(0xFFD8F3E5) : const Color(0xFFFFF0EC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isResolved ? AgriLanguage.text('resolved', isHindi) : AgriLanguage.text('inReview', isHindi),
                            style: TextStyle(
                              fontSize: 9.0,
                              fontWeight: FontWeight.bold,
                              color: isResolved ? const Color(0xFF1B5E4F) : const Color(0xFF8B1E1E),
                            ),
                          ),
                        ),
                        Text(
                          date,
                          style: const TextStyle(fontSize: 10.0, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      '$crop $issue',
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E352C),
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: Color(0xFF70837B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailedDiagnosis(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Diagnosis Progress Details', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E5E4A))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Analyzing Leaf Sample Node 74-B.'),
              SizedBox(height: 8),
              Text('Matched symptoms of Rice Blast. System is cross-referencing soil nutrients (N: 45%) and temperature (28°C) to calculate probability of cure.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: Color(0xFF1E5E4A))),
            ),
          ],
        );
      },
    );
  }

  void _showDiagnosisReportDialog(
    BuildContext context,
    String crop,
    String issue,
    String status,
    String desc,
    String date,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$crop $issue', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E352C))),
              Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: status == 'Resolved' ? const Color(0xFFD8F3E5) : const Color(0xFFFFF0EC),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: status == 'Resolved' ? const Color(0xFF1B5E4F) : const Color(0xFF8B1E1E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Diagnosis & Advice:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(fontSize: 13.5, height: 1.3, color: Color(0xFF334A3E))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFF1E5E4A))),
            ),
          ],
        );
      },
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
