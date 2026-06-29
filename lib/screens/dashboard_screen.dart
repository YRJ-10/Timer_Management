import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../models/session_log.dart';
import '../providers/sequence_timer_provider.dart';
import '../providers/session_history_provider.dart';
import '../providers/simple_timer_provider.dart';

class DashboardScreen extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.secondary),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.secondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(SessionLog session) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.18),
        child: Icon(
          session.type == 'Sequence' ? Icons.repeat : Icons.timer,
          color: AppColors.secondary,
        ),
      ),
      title: Text(
        session.title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${session.type} • ${_formatDuration(session.durationSeconds)} • ${_formatTime(session.completedAt)}',
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: session.stepCount > 1
          ? Text(
              '${session.stepCount} steps',
              style: const TextStyle(color: AppColors.textSecondary),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<SessionHistoryProvider>();
    final simple = context.watch<SimpleTimerProvider>();
    final sequence = context.watch<SequenceTimerProvider>();
    final hasQuickTemplates = simple.templates.isNotEmpty;
    final hasRoutine = sequence.sequence.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timer Management',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Quick starts, routines, and session history in one place.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStat(
                'Completed',
                history.completedCount.toString(),
                Icons.check_circle,
              ),
              const SizedBox(width: 12),
              _buildStat(
                'Total Time',
                _formatDuration(history.totalSeconds),
                Icons.timelapse,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCommandButton(
            icon: Icons.timer,
            title: hasQuickTemplates
                ? 'Start a quick timer'
                : 'Create a quick timer',
            subtitle: hasQuickTemplates
                ? 'Use your saved templates or set a new duration.'
                : 'Add your first reusable quick timer.',
            onTap: () => onNavigate(1),
          ),
          const SizedBox(height: 12),
          _buildCommandButton(
            icon: Icons.format_list_numbered,
            title: hasRoutine ? 'Open routine timer' : 'Build a routine timer',
            subtitle: hasRoutine
                ? '${sequence.sequence.length} steps ready to run.'
                : 'Create named steps for work, rest, study, or cooking.',
            onTap: () => onNavigate(2),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Sessions',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: history.sessions.isEmpty ? null : history.clear,
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (history.recentSessions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: const Column(
                children: [
                  Icon(Icons.history, color: AppColors.secondary, size: 40),
                  SizedBox(height: 12),
                  Text(
                    'No completed sessions yet',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Finished timers will appear here automatically.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  for (final session in history.recentSessions)
                    _buildHistoryItem(session),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
