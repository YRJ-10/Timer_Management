import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../providers/simple_timer_provider.dart';
import 'widgets/custom_time_picker.dart';
import 'widgets/template_chip.dart';

class SimpleTimerScreen extends StatelessWidget {
  const SimpleTimerScreen({super.key});

  String _formatTime(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;

    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showAddDialog(BuildContext context, SimpleTimerProvider provider) {
    int selH = 0;
    int selM = 0;
    int selS = 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Add Template',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          height: 200,
          child: CustomTimePicker(
            showHours: true,
            onTimeChanged: (h, m, s) {
              selH = h;
              selM = m;
              selS = s;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              provider.addTemplate(selH, selM, selS);
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    SimpleTimerProvider provider,
    int index,
    int totalSecs,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Template?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Remove template ${_formatTime(totalSecs)}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              provider.removeTemplate(index);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        children: [
          Icon(Icons.timer, color: AppColors.secondary, size: 32),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick Timer', style: AppStyles.headline),
                SizedBox(height: 4),
                Text(
                  'Set a one-off timer or launch a saved template.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTimer(SimpleTimerProvider provider) {
    return Column(
      children: [
        const Text(
          'Focus Mode',
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: provider.progress.clamp(0, 1).toDouble(),
                  strokeWidth: 14,
                  backgroundColor: AppColors.surface,
                  color: AppColors.secondary,
                ),
              ),
              Text(
                _formatTime(provider.remainingSeconds),
                style: AppStyles.timerTextBig,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '${(provider.progress * 100).clamp(0, 100).round()}% complete',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSetupTimer(BuildContext context, SimpleTimerProvider provider) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              const Text(
                'Choose Duration',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              CustomTimePicker(
                showHours: true,
                onTimeChanged: (h, m, s) {
                  provider.setTime(h, m, s);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saved Templates',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (int i = 0; i < provider.templates.length; i++)
                    TemplateChip(
                      label: _formatTime(provider.templates[i]),
                      onTap: () {
                        provider.setTimeFromSeconds(provider.templates[i]);
                        provider.start();
                      },
                      onLongPress: () => _showDeleteDialog(
                        context,
                        provider,
                        i,
                        provider.templates[i],
                      ),
                    ),
                  if (provider.templates.length < 5)
                    ActionChip(
                      avatar: const Icon(
                        Icons.add,
                        color: AppColors.textPrimary,
                        size: 18,
                      ),
                      label: const Text(
                        'Add',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      onPressed: () => _showAddDialog(context, provider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                ],
              ),
              if (provider.templates.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 10.0),
                  child: Text(
                    'Hold a template to delete it.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(
    BuildContext context,
    SimpleTimerProvider provider,
    bool showCountdown,
  ) {
    if (showCountdown) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            heroTag: 'simple_pause',
            onPressed: () {
              if (provider.isPaused) {
                provider.start();
              } else {
                provider.pause();
              }
            },
            backgroundColor: AppColors.surface,
            child: Icon(
              provider.isPaused ? Icons.play_arrow : Icons.pause,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 24),
          FloatingActionButton(
            heroTag: 'simple_stop',
            onPressed: () => provider.stop(),
            backgroundColor: AppColors.surface,
            child: const Icon(Icons.stop, color: AppColors.accent, size: 32),
          ),
        ],
      );
    }

    return SizedBox(
      width: 100,
      height: 100,
      child: FloatingActionButton(
        heroTag: 'simple_play',
        onPressed: () {
          if (provider.hours > 0 ||
              provider.minutes > 0 ||
              provider.seconds > 0) {
            provider.start();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a time')),
            );
          }
        },
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleTimerProvider>(
      builder: (context, provider, child) {
        final showCountdown =
            provider.isRunning || provider.remainingSeconds > 0;

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 28),
                      if (showCountdown)
                        _buildActiveTimer(provider)
                      else
                        _buildSetupTimer(context, provider),
                      const SizedBox(height: 32),
                      _buildControls(context, provider, showCountdown),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
