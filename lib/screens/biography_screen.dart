import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Biography tab — farmer profile, farm details, and app/device info.
class BiographyScreen extends StatelessWidget {
  const BiographyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biography')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primaryGreen,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text('Mkulima', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          const Center(
            child: Text('Shamba Smart · Farmers Hope',
                style: TextStyle(fontSize: 12, color: AppColors.textLightMuted)),
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: const [
                ListTile(leading: Icon(Icons.landscape), title: Text('Ukubwa wa Shamba'), subtitle: Text('— acre')),
                Divider(height: 1),
                ListTile(leading: Icon(Icons.grass), title: Text('Zao Kuu'), subtitle: Text('—')),
                Divider(height: 1),
                ListTile(leading: Icon(Icons.location_on), title: Text('Mkoa'), subtitle: Text('Dodoma')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: const [
                ListTile(leading: Icon(Icons.info_outline), title: Text('Toleo la App'), subtitle: Text('v3.0.0')),
                Divider(height: 1),
                ListTile(leading: Icon(Icons.developer_board), title: Text('Kifaa'), subtitle: Text('ESP32 Smart Farm Manager')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
