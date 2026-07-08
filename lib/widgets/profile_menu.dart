// lib/widgets/profile_menu.dart
// Clickable profile avatar with popup menu showing farmer details and logout option.

import 'package:flutter/material.dart';
import '../models/farmer_context.dart';
import '../services/auth_service.dart';

class ProfileAvatarMenu extends StatelessWidget {
  final FarmerProfile profile;
  final VoidCallback onLogout;

  const ProfileAvatarMenu({
    super.key,
    required this.profile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Profile',
      offset: const Offset(0, 46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (val) async {
        if (val == 'logout') {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Logout?', style: TextStyle(fontWeight: FontWeight.bold)),
              content: const Text('You will be returned to the login screen.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await AuthService.logout();
            onLogout();
          }
        }
      },
      itemBuilder: (context) => [
        // Profile info header (not tappable)
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar + name
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E5E4A), Color(0xFF2D8A6B)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'F',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E352C),
                        ),
                      ),
                      Text(
                        '+91 ${profile.mobile}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              // Location
              _infoRow(Icons.location_on_outlined, profile.location),
              const SizedBox(height: 4),
              // Language
              _infoRow(Icons.translate, _langDisplay(profile.language)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        // Logout
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: Colors.red.shade600),
              const SizedBox(width: 10),
              Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade600),
              ),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E5E4A), Color(0xFF2D8A6B)],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'F',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.grey),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  String _langDisplay(String lang) {
    switch (lang) {
      case 'hi': return 'हिंदी';
      case 'ta': return 'தமிழ்';
      case 'te': return 'తెలుగు';
      case 'mr': return 'मराठी';
      default: return 'English';
    }
  }
}
