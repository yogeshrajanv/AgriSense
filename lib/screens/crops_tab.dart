import 'package:flutter/material.dart';
import '../models/localization.dart';

class CropsTab extends StatelessWidget {
  final bool isHindi;
  final List<Map<String, dynamic>> activeCrops;
  final List<Map<String, dynamic>> harvestLogs;
  final VoidCallback onLogHarvest;
  final void Function(String, int) onAddCropPlan;

  const CropsTab({
    super.key,
    required this.isHindi,
    required this.activeCrops,
    required this.harvestLogs,
    required this.onLogHarvest,
    required this.onAddCropPlan,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row for header + quick add
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AgriLanguage.text('myCrops', isHindi),
                style: const TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E352C),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showAddCropDialog(context),
                icon: const Icon(Icons.add, size: 16, color: Color(0xFF1E5E4A)),
                label: Text(
                  AgriLanguage.text('addNewCrop', isHindi),
                  style: const TextStyle(fontSize: 12.0, color: Color(0xFF1E5E4A), fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1E5E4A)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            isHindi ? 'आपके खेत में लगाई गई फसलों की सक्रिय सूची।' : 'Monitor active planting plans and growth progress on your acreage.',
            style: const TextStyle(
              fontSize: 14.0,
              color: Color(0xFF70837B),
            ),
          ),
          const SizedBox(height: 18.0),

          // Active crops list
          if (activeCrops.isEmpty) ...[
            _buildEmptyState(context)
          ] else ...[
            ...activeCrops.map((c) => _buildCropProgressCard(context, c)).toList(),
          ],

          const SizedBox(height: 24.0),

          // Logs Section: completed harvests
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isHindi ? 'फसल कटाई के रिकॉर्ड' : 'Harvest Records Log',
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E352C),
                ),
              ),
              IconButton(
                onPressed: onLogHarvest,
                icon: const Icon(Icons.note_add_outlined, color: Color(0xFF1E5E4A)),
                tooltip: 'Log Harvest',
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          if (harvestLogs.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAF9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEDF0ED)),
              ),
              child: Center(
                child: Text(
                  isHindi ? 'अभी कोई फसल कटाई दर्ज नहीं है।' : 'No logged harvests yet. Use the "Log Harvest" button to record database.',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            )
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: harvestLogs.length,
              separatorBuilder: (c, i) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final h = harvestLogs[index];
                return _buildHarvestLogTile(context, h);
              },
            ),
          ],
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE8ECE9)),
      ),
      child: Column(
        children: [
          const Icon(Icons.grass, color: Colors.grey, size: 48),
          const SizedBox(height: 12),
          Text(
            isHindi ? 'कोई सक्रिय फसल नहीं' : 'No Active Crops',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E352C)),
          ),
          const SizedBox(height: 6),
          Text(
            isHindi 
              ? 'सलाह टैब पर जाएं और अपनी पहली रोपण योजना चुनें!'
              : 'Go to the Advice tab to select an AI-recommended planting plan, or add one using the button above.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildCropProgressCard(BuildContext context, Map<String, dynamic> crop) {
    final String cropName = crop['name'];
    final int duration = crop['duration'];
    final int progress = crop['progress'];
    final String date = crop['plantedDate'];

    // calculate remaining days
    final int remaining = (duration * (100 - progress) / 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE8ECE9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cropName,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E352C)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8F3E5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$progress% active',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B5E4F)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            '${AgriLanguage.text('plantedOn', isHindi)}: $date',
            style: const TextStyle(fontSize: 12.0, color: Colors.grey),
          ),
          const SizedBox(height: 16.0),

          // Progress indicator bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.spa_outlined, color: Color(0xFF1E5E4A), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5.0),
                  child: Container(
                    height: 8.0,
                    color: const Color(0xFFEDF0ED),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress / 100.0,
                        child: Container(color: const Color(0xFF1E5E4A)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$remaining ${AgriLanguage.text('daysRemaining', isHindi)}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E5E4A)),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
        ],
      ),
    );
  }

  Widget _buildHarvestLogTile(BuildContext context, Map<String, dynamic> log) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECE9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFE6EFEA),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.task_alt, color: Color(0xFF1B5E4F), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log['crop']} - ${log['sector']}',
                  style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Color(0xFF1E352C)),
                ),
                Text(
                  'Date: ${log['date']}',
                  style: const TextStyle(fontSize: 11.0, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${log['quantity']} Qtl',
                style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: Color(0xFF1E5E4A)),
              ),
              const Text(
                'Success',
                style: TextStyle(fontSize: 9.0, color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddCropDialog(BuildContext context) {
    final nameController = TextEditingController();
    final durationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            AgriLanguage.text('addNewCrop', isHindi),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E5E4A)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Crop Name (e.g. Groundnut / Soybeans)',
                  labelStyle: TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (in Days)',
                  labelStyle: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final String n = nameController.text.trim();
                final int d = int.tryParse(durationController.text) ?? 100;
                if (n.isNotEmpty) {
                  onAddCropPlan(n, d);
                }
                Navigator.pop(context);
              },
              child: const Text('Add', style: TextStyle(color: Color(0xFF1E5E4A), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
