import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.secondary,
        secondary: Icon(icon, color: AppColors.secondary),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tune the timer behavior for focus, routine, and alarm sessions.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        _buildSwitchTile(
          icon: Icons.volume_up,
          title: 'Alarm sound',
          subtitle: 'Play beep and completion alarm sounds.',
          value: settings.alarmSoundEnabled,
          onChanged: settings.setAlarmSoundEnabled,
        ),
        _buildSwitchTile(
          icon: Icons.vibration,
          title: 'Vibrate on complete',
          subtitle: 'Use haptic feedback when a timer finishes.',
          value: settings.vibrateOnComplete,
          onChanged: settings.setVibrateOnComplete,
        ),
        _buildSwitchTile(
          icon: Icons.wb_sunny,
          title: 'Keep screen awake',
          subtitle: 'Prevent the screen from sleeping while a timer runs.',
          value: settings.keepScreenAwake,
          onChanged: settings.setKeepScreenAwake,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.secondary),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'History is stored locally on this device and is cleared if the app is uninstalled.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
